import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../../shared/widgets/pressable.dart';
import '../../planning/domain/goal_math.dart';
import '../../planning/repositories/budget_repository.dart';
import '../../planning/repositories/goal_repository.dart';
import '../../planning/repositories/investment_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../domain/advanced_finance.dart';

final insightTransactionsProvider = FutureProvider<List<TxnObs>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final rows = await ref.watch(supabaseProvider)
      .from('transactions')
      .select('id, transaction_type, amount, currency, status, merchant, description, transaction_date, categories(name)')
      .eq('user_id', userId)
      .order('transaction_date', ascending: false)
      .limit(500);
  return [
    for (final row in rows)
      if ((row['status'] as String?) != 'VOIDED')
        TxnObs(
          id: row['id'] as String,
          date: DateTime.parse(row['transaction_date'] as String).toLocal(),
          type: (row['transaction_type'] as String?) ?? 'EXPENSE',
          amount: num.parse(row['amount'].toString()),
          currency: row['currency'] as String,
          merchant: row['merchant'] as String?,
          description: row['description'] as String?,
          category: row['categories'] is Map ? (row['categories'] as Map)['name'] as String? : null,
        ),
  ];
});

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tx = ref.watch(insightTransactionsProvider);
    final budgets = ref.watch(budgetsProvider).asData?.value;
    final goals = ref.watch(goalsProvider).asData?.value ?? const <GoalRecord>[];
    final portfolios = ref.watch(portfoliosProvider).asData?.value ?? const <PortfolioView>[];
    final wallets = ref.watch(walletsProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.insightsTitle)),
      body: tx.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.noPlanData)),
        data: (rows) {
          final now = DateTime.now();
          const currency = 'TND';
          final forecast = forecastSpending(rows, now: now);
          final anomalies = detectAnomalies(rows, now: now);
          final subscriptions = detectSubscriptions(rows, now: now);
          final behavior = analyzeBehavior(rows, now: now, currency: currency);
          final allocation = suggestAllocation(rows, now: now, currency: currency);
          final monthStart = DateTime(now.year, now.month);
          final report = reportFor(rows, start: monthStart, end: DateTime(now.year, now.month + 1), currency: currency);
          final spends = rows.where((row) => row.isSpend).map((row) => row.amount).toList();
          final balances = checkBalances(
            wallets: [
              for (final wallet in wallets)
                (
                  name: wallet.name,
                  type: wallet.walletType,
                  initial: wallet.initialBalance,
                  current: wallet.currentBalance,
                  creditLimit: wallet.creditLimit,
                  available: wallet.availableCredit,
                ),
            ],
            movementSizes: spends,
          );
          final budgetRows = [
            if (budgets != null)
              for (final item in [...budgets.rollup.overall, ...budgets.rollup.categories])
                if (item.spec.currency == currency)
                  (name: item.spec.name, spent: item.spent, limit: item.spec.limit),
          ];
          final claims = [
            for (final row in rows.where((row) => row.isSpend))
              Claim(
                id: row.id,
                amount: row.amount,
                currency: row.currency,
                merchant: row.merchant,
                date: row.date,
                description: row.description,
              ),
          ];
          final reconciled = reconcile(claims, claims);
          final risks = overspendRisks(budgets: budgetRows, now: now, sampleCount: forecast.sampleCount);
          final income = rows.where((row) => row.isIncome && row.currency == currency).fold<num>(0, (sum, row) => sum + row.amount);
          final expense = rows.where((row) => row.isSpend && row.currency == currency).fold<num>(0, (sum, row) => sum + row.amount);
          final months = rows.map((row) => DateTime(row.date.year, row.date.month)).toSet().length.clamp(1, 36);
          final surplus = (income - expense) / months;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Pressable(
                haptic: true,
                onTap: () => context.push('/plan/studio'),
                child: GlassPanel(
                  child: Row(
                    children: [
                      const Icon(Icons.auto_graph_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.openDetailedAnalyses, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(l10n.studioTitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Icon(Directionality.of(context) == ui.TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.mlBaselineNote),
              const SizedBox(height: 12),
              _section(context, l10n.forecastLabel, [
                if (!forecast.sufficient)
                  Text(l10n.forecastInsufficient)
                else ...[
                  Text('${l10n.next7Days}: ${Money.format(forecast.next7, currency)}'),
                  Text('${l10n.next30Days}: ${Money.format(forecast.next30, currency)} ± ${Money.format(forecast.uncertainty30, currency)}'),
                  Text('${l10n.endOfMonth}: ${Money.format(forecast.endOfMonth, currency)}'),
                ],
              ]),
              _section(context, l10n.overspendTitle, [
                if (risks.isEmpty) Text(l10n.forecastInsufficient),
                for (final risk in risks)
                  Text(
                    '${risk.name}: ${Money.format(risk.expected, currency)} / ${Money.format(risk.limit, currency)} · ${risk.level} · ${l10n.daysLeft} ${risk.daysLeft} · ${l10n.dailyLimit} ${Money.format(risk.dailyLimit, currency)}',
                  ),
              ]),
              _section(context, l10n.subscriptionsTitle, [
                if (subscriptions.isEmpty) Text(l10n.noPlanData),
                for (final item in subscriptions)
                  Text(
                    '${item.name} · ${item.cadence} · ${Money.format(item.lastAmount, item.currency)}'
                    '${item.priceIncreased ? ' · ${l10n.priceUp}' : ''}'
                    '${item.inactive ? ' · ${l10n.inactiveSub}' : ''}'
                    '${item.duplicate ? ' · ${l10n.duplicateSub}' : ''}',
                  ),
              ]),
              _section(context, l10n.duplicateSub, [
                if (reconciled.duplicateReceipts.isEmpty) Text(l10n.noPlanData),
                if (reconciled.duplicateReceipts.isNotEmpty)
                  Text('${reconciled.duplicateReceipts.length}'),
              ]),
              _section(context, l10n.anomaliesTitle, [
                Text(l10n.anomalyDoesNotBlock),
                if (!anomalies.sufficient) Text(l10n.forecastInsufficient),
                for (final alert in anomalies.alerts) Text('${alert.severity} · ${alert.code} · ${alert.detail}'),
              ]),
              _section(context, l10n.allocationTitle, [
                if (!allocation.sufficient) Text(l10n.forecastInsufficient),
                if (allocation.sufficient) Text('${l10n.surplusLabel}: ${Money.format(allocation.surplus, currency)}'),
                for (final line in allocation.lines)
                  Text('${line.name}: ${Money.format(line.amount, currency)} (${line.note})'),
              ]),
              _section(context, l10n.behaviorTitle, [
                if (!behavior.sufficient) Text(l10n.forecastInsufficient),
                if (behavior.sufficient) ...[
                  Text('${l10n.weekendShare}: ${(behavior.weekendShare * 100).toStringAsFixed(0)}%'),
                  Text('${l10n.monthChange}: ${Money.format(behavior.monthChange, currency)}'),
                  for (final change in behavior.categoryChanges)
                    Text('${change.category}: ${Money.format(change.delta, currency)}'),
                ],
              ]),
              _section(context, l10n.reportsTitle, [
                Text('${l10n.income}: ${Money.format(report.income, currency)}'),
                Text('${l10n.expenses}: ${Money.format(report.expense, currency)}'),
                Text('${l10n.netLabel}: ${Money.format(report.net, currency)}'),
                for (final entry in report.byCategory.entries)
                  Text('${entry.key}: ${Money.format(entry.value, currency)}'),
              ]),
              _section(context, l10n.goalsPlanTitle, [
                for (final goal in goals.where((goal) => goal.status == 'active'))
                  _goalLine(goal, surplus, currency, now),
                if (goals.isEmpty) Text(l10n.noPlanData),
              ]),
              _section(context, l10n.riskTitle, [
                Text(l10n.notAdvice),
                for (final portfolio in portfolios) _riskLine(portfolio),
                if (portfolios.isEmpty) Text(l10n.noPlanData),
              ]),
              _section(context, l10n.balanceChecks, [
                for (final check in balances)
                  Text('${check.name}: ${check.consistent ? l10n.consistent : l10n.inconsistent}${check.unusual ? ' · ${l10n.unusualMovement}' : ''}'),
              ]),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(label: Text(l10n.splitExpense), onPressed: () => context.push('/plan/split')),
                  ActionChip(label: Text(l10n.plannerTitle), onPressed: () => context.push('/plan/planner')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _goalLine(GoalRecord goal, num surplus, String currency, DateTime now) {
    final snap = goal.snapshot(now);
    final months = goal.targetDate == null ? 6 : monthsRemaining(now, goal.targetDate!);
    final scenario = goalFeasibility(gap: snap.gap, months: months, monthlySurplus: surplus);
    if (!scenario.sufficient) return Text('${goal.name}: ${Money.format(snap.gap, goal.currency)}');
    return Text(
      '${goal.name}: ${Money.format(scenario.requiredMonthly, currency)} / ${l10nSafe(surplus)} · ${scenario.expected ? 'expected' : 'short'} · ${(scenario.reachRate * 100).toStringAsFixed(0)}%',
    );
  }

  String l10nSafe(num surplus) => surplus.toStringAsFixed(3);

  Widget _riskLine(PortfolioView portfolio) {
    num value = 0;
    var largest = 0.0;
    final prices = <num>[];
    for (final asset in portfolio.assets) {
      final holding = asset.marketValue;
      if (holding == null || holding <= 0) continue;
      value += holding;
      prices.add(asset.currentPrice ?? 0);
    }
    if (value > 0) {
      for (final asset in portfolio.assets) {
        final holding = asset.marketValue;
        if (holding == null) continue;
        final share = holding / value;
        if (share > largest) largest = share.toDouble();
      }
    }
    final risk = portfolioRisk(value: value, largestShare: largest, prices: prices);
    return Text('${portfolio.name}: −10% ${Money.format(risk.loss10, portfolio.currency)} · ${risk.limitation}');
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
