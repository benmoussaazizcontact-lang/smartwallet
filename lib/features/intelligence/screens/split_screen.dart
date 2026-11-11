import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../planning/repositories/budget_repository.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../domain/advanced_finance.dart';
import 'insights_screen.dart';

class SplitExpenseScreen extends ConsumerStatefulWidget {
  const SplitExpenseScreen({super.key});

  @override
  ConsumerState<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends ConsumerState<SplitExpenseScreen> {
  final _total = TextEditingController();
  final _first = TextEditingController();
  final _second = TextEditingController();
  final _merchant = TextEditingController();
  final _ids = [const Uuid().v4(), const Uuid().v4()];
  String? _walletId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _total.dispose();
    _first.dispose();
    _second.dispose();
    _merchant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider).asData?.value ?? [];
    final total = Money.tryParse(_total.text) ?? 0;
    final parts = [Money.tryParse(_first.text) ?? 0, Money.tryParse(_second.text) ?? 0];
    final check = checkSplit(total: total, parts: parts);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.splitExpense)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.splitHint),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _walletId ?? (wallets.isEmpty ? null : wallets.first.walletId),
            items: [
              for (final wallet in wallets)
                DropdownMenuItem(value: wallet.walletId, child: Text('${wallet.name} · ${wallet.currency}')),
            ],
            onChanged: (value) => setState(() => _walletId = value),
            decoration: InputDecoration(labelText: l10n.chooseWallet),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _merchant, label: l10n.merchant, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          AppTextField(
            controller: _total,
            label: l10n.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _first,
            label: '${l10n.splitPart} 1',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _second,
            label: '${l10n.splitPart} 2',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(check.valid ? l10n.splitReady : '${l10n.splitRemainder} ${check.remainder.toStringAsFixed(3)}'),
          if (_error != null) Text(_error!),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.confirm,
            loading: _saving,
            onPressed: !check.valid || wallets.isEmpty
                ? null
                : () async {
                    final walletId = _walletId ?? wallets.first.walletId;
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    try {
                      final repo = ref.read(transactionRepositoryProvider);
                      await repo.create(
                        walletId: walletId,
                        type: 'EXPENSE',
                        amount: parts[0],
                        merchant: _merchant.text,
                        description: 'Split 1/2',
                        clientRequestId: _ids[0],
                      );
                      await repo.create(
                        walletId: walletId,
                        type: 'EXPENSE',
                        amount: parts[1],
                        merchant: _merchant.text,
                        description: 'Split 2/2',
                        clientRequestId: _ids[1],
                      );
                      ref.invalidate(budgetsForUserProvider);
                      ref.invalidate(insightTransactionsProvider);
                      if (context.mounted) context.pop();
                    } catch (error) {
                      setState(() => _error = error.toString());
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
