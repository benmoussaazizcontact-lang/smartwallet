import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../wallets/models/wallet.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../models/recurring.dart';
import '../repositories/recurring_repository.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(recurringProvider);
    final wallets = ref.watch(walletsProvider).asData?.value ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recurring-add-fab',
        onPressed: () => _create(context, ref, wallets),
        child: const Icon(Icons.add),
      ),
      body: items.when(
        loading: () => const LoadingSkeleton(),
        error: (e, _) =>
            ErrorView(message: '$e', onRetry: () => ref.invalidate(recurringForUserProvider)),
        data: (rows) => ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final item = rows[index];
            final wallet = wallets.where((w) => w.walletId == item.walletId);
            final currency = wallet.isEmpty ? 'TND' : wallet.first.currency;
            return ListTile(
              title: Text(item.description ?? item.type),
              subtitle: Text(
                '${item.frequency} · next ${item.nextExecutionDate.toIso8601String().split('T').first} · ${Money.format(item.amount, currency)}',
              ),
              trailing: Switch(
                value: item.isActive,
                onChanged: (v) async {
                  await ref.read(recurringRepositoryProvider).setActive(item.id, v);
                  ref.invalidate(recurringForUserProvider);
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context, ref, item),
              ),
              onTap: () => _executions(context, ref, item),
            );
          },
        ),
      ),
    );
  }

  Future<void> _executions(
    BuildContext context,
    WidgetRef ref,
    RecurringItem item,
  ) async {
    final rows = await ref.read(recurringRepositoryProvider).executions(item.id);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l10n.executions, style: Theme.of(context).textTheme.titleLarge),
          if (rows.isEmpty) Text(context.l10n.noExecutions),
          ...rows.map(
            (r) => ListTile(
              title: Text('${r['executed_on']}'),
              subtitle: Text('${r['transaction_id'] ?? 'pending'}'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    RecurringItem item,
  ) async {
    final amount = TextEditingController(text: item.amount.toString());
    final description = TextEditingController(text: item.description ?? '');
    String frequency = item.frequency;
    DateTime next = item.nextExecutionDate;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.editRecurrence),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  items: [
                    DropdownMenuItem(value: 'DAILY', child: Text(context.l10n.daily)),
                    DropdownMenuItem(value: 'WEEKLY', child: Text(context.l10n.weekly)),
                    DropdownMenuItem(value: 'MONTHLY', child: Text(context.l10n.monthly)),
                    DropdownMenuItem(value: 'YEARLY', child: Text(context.l10n.yearly)),
                  ],
                  onChanged: (v) => setState(() => frequency = v ?? frequency),
                ),
                AppTextField(
                  controller: amount,
                  label: context.l10n.amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                AppTextField(controller: description, label: context.l10n.description),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: next,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => next = picked);
                  },
                  child: Text(context.l10n.nextRun(next.toIso8601String().split('T').first)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.save)),
          ],
        ),
      ),
    );
    final parsed = Money.tryParse(amount.text);
    if (ok == true && parsed != null) {
      await ref.read(recurringRepositoryProvider).update(
            id: item.id,
            frequency: frequency,
            nextExecutionDate: next,
            amount: parsed,
            description: description.text,
          );
      ref.invalidate(recurringForUserProvider);
    }
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    List<WalletBalance> wallets,
  ) async {
    final amount = TextEditingController();
    final description = TextEditingController();
    String? walletId;
    String type = 'EXPENSE';
    String frequency = 'MONTHLY';
    DateTime next = DateTime.now().add(const Duration(days: 1));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.newRecurrence),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  items: wallets
                      .map((w) => DropdownMenuItem(value: w.walletId, child: Text(w.name)))
                      .toList(),
                  onChanged: (v) => walletId = v,
                  decoration: InputDecoration(labelText: context.l10n.filterWallet),
                ),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: [
                    DropdownMenuItem(value: 'EXPENSE', child: Text(context.l10n.typeExpense)),
                    DropdownMenuItem(value: 'INCOME', child: Text(context.l10n.typeIncome)),
                  ],
                  onChanged: (v) => setState(() => type = v ?? type),
                ),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  items: [
                    DropdownMenuItem(value: 'DAILY', child: Text(context.l10n.daily)),
                    DropdownMenuItem(value: 'WEEKLY', child: Text(context.l10n.weekly)),
                    DropdownMenuItem(value: 'MONTHLY', child: Text(context.l10n.monthly)),
                    DropdownMenuItem(value: 'YEARLY', child: Text(context.l10n.yearly)),
                  ],
                  onChanged: (v) => setState(() => frequency = v ?? frequency),
                ),
                AppTextField(
                  controller: amount,
                  label: context.l10n.amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                AppTextField(controller: description, label: context.l10n.description),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: next,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => next = picked);
                  },
                  child: Text(context.l10n.nextRun(next.toIso8601String().split('T').first)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.create)),
          ],
        ),
      ),
    );
    final parsed = Money.tryParse(amount.text);
    if (ok == true && walletId != null && parsed != null) {
      await ref.read(recurringRepositoryProvider).create(
            walletId: walletId!,
            type: type,
            amount: parsed,
            frequency: frequency,
            nextExecutionDate: next,
            description: description.text,
          );
      ref.invalidate(recurringForUserProvider);
    }
  }
}

class RecurringScreen extends RecurringTransactionsScreen {
  const RecurringScreen({super.key});
}
