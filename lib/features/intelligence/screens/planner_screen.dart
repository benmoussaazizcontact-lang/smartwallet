import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../domain/advanced_finance.dart';
import 'insights_screen.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final _target = TextEditingController(text: '3000');
  final _months = TextEditingController(text: '6');

  @override
  void dispose() {
    _target.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = ref.watch(insightTransactionsProvider).asData?.value ?? const [];
    final wallets = ref.watch(walletsProvider).asData?.value ?? const [];
    num income = 0;
    num expense = 0;
    final monthsSeen = <String>{};
    for (final row in rows) {
      if (row.currency != 'TND') continue;
      monthsSeen.add('${row.date.year}-${row.date.month}');
      if (row.isIncome) income += row.amount;
      if (row.isSpend) expense += row.amount;
    }
    final span = monthsSeen.isEmpty ? 1 : monthsSeen.length;
    final surplus = (income - expense) / span;
    final cash = wallets.where((wallet) => wallet.currency == 'TND' && wallet.walletType != 'CREDIT_CARD').fold<num>(0, (sum, wallet) => sum + wallet.currentBalance);
    final gap = Money.tryParse(_target.text) ?? 0;
    final months = int.tryParse(_months.text) ?? 0;
    final plan = planSavings(
      gap: gap,
      months: months < 1 ? 1 : months,
      monthlySurplus: surplus,
      cashBalance: cash < 0 ? 0 : cash,
      currency: 'TND',
    );
    final scenario = goalFeasibility(gap: gap, months: months < 1 ? 1 : months, monthlySurplus: surplus);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.plannerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.mlBaselineNote),
          const SizedBox(height: 12),
          AppTextField(
            controller: _target,
            label: l10n.goalTarget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _months,
            label: l10n.monthsLabel,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('${l10n.surplusLabel}: ${Money.format(surplus, 'TND')}'),
          Text('${l10n.requiredMonthly}: ${Money.format(scenario.requiredMonthly, 'TND')}'),
          Text('${l10n.recommendedSave}: ${Money.format(plan.recommended, 'TND')}'),
          Text(scenario.assumption),
          const SizedBox(height: 8),
          for (final step in plan.steps)
            ListTile(title: Text(step.title), subtitle: Text(step.detail)),
          const SizedBox(height: 8),
          Text(l10n.notAdvice),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.newGoal,
            onPressed: () => context.push('/plan/goals/new'),
          ),
        ],
      ),
    );
  }
}
