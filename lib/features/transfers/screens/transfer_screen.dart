import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../planning/repositories/budget_repository.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../repositories/transfer_repository.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String? _from;
  String? _to;
  bool _loading = false;
  bool _submitted = false;
  bool _success = false;
  final _requestId = const Uuid().v4();

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitted || !_formKey.currentState!.validate()) return;
    if (_from == null || _to == null) return;
    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sameWallet)),
      );
      return;
    }
    final amount = Money.tryParse(_amount.text);
    if (amount == null) return;
    final wallets = ref.read(walletsProvider).asData?.value ?? [];
    final source = wallets.where((w) => w.walletId == _from);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.confirmTransfer),
        content: Text(
          context.l10n.confirmTransferBody(
            Money.format(amount, source.isEmpty ? 'TND' : source.first.currency),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.confirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _loading = true;
      _submitted = true;
    });
    try {
      await ref.read(transferRepositoryProvider).transfer(
            fromWalletId: _from!,
            toWalletId: _to!,
            amount: amount,
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            clientRequestId: _requestId,
          );
      ref.invalidate(walletsForUserProvider);
      ref.invalidate(dashboardActivityForUserProvider);
      ref.invalidate(budgetsForUserProvider);
      if (mounted) {
        setState(() => _success = true);
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submitted = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider).asData?.value ?? [];
    final fromWallet = wallets.where((w) => w.walletId == _from);
    if (_success) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.transferSuccess, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassPanel(
              child: Column(
                children: [
                  Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(height: 8),
                  Text(l10n.transfer, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _from,
              items: wallets
                  .map(
                    (w) => DropdownMenuItem(
                      value: w.walletId,
                      child: Text('${w.name} · ${Money.format(w.currentBalance, w.currency)}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _from = v),
              decoration: InputDecoration(labelText: l10n.fromWallet),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _to,
              items: wallets
                  .map((w) => DropdownMenuItem(value: w.walletId, child: Text(w.name)))
                  .toList(),
              onChanged: (v) => setState(() => _to = v),
              decoration: InputDecoration(labelText: l10n.toWallet),
            ),
            if (fromWallet.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.availableBalance(
                    Money.format(fromWallet.first.currentBalance, fromWallet.first.currency),
                    fromWallet.first.currency,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amount,
              label: l10n.amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Money.validate(v ?? '', l10n: l10n),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _description, label: l10n.description),
            const SizedBox(height: 24),
            AppButton(label: l10n.transfer, loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
