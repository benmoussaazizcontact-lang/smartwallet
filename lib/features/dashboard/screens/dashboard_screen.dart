import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/privacy_controller.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../../shared/widgets/wallet_visual_card.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../categories/models/category.dart';
import '../../categories/repositories/category_repository.dart';
import '../../planning/domain/budget_math.dart';
import '../../planning/domain/spend_rules.dart';
import '../../planning/repositories/budget_repository.dart';
import '../../planning/repositories/goal_repository.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../../receipts/providers/receipt_providers.dart';
import '../../wallets/repositories/wallet_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider);
    final txs = ref.watch(recentTransactionsProvider);
    final activity = ref.watch(dashboardActivityProvider);
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    final hide = ref.watch(hideBalancesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletsForUserProvider);
            ref.invalidate(recentTransactionsForUserProvider);
            ref.invalidate(dashboardActivityForUserProvider);
          },
          child: wallets.when(
            loading: () => const LoadingSkeleton(),
            error: (e, _) => ErrorView(
              message: '$e',
              onRetry: () => ref.invalidate(walletsForUserProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  children: [
                    EmptyState(
                      title: l10n.noWalletsYet,
                      message: l10n.noWalletsHint,
                      actionLabel: l10n.addWallet,
                      onAction: () => context.go('/wallets/new'),
                    ),
                  ],
                );
              }
              final byCurrency = <String, num>{};
              for (final w in items) {
                byCurrency.update(
                  w.currency,
                  (v) => v + w.currentBalance,
                  ifAbsent: () => w.currentBalance,
                );
              }
              final monthTx = activity.asData?.value;
              final activityReady = monthTx != null;
              return txs.when(
                loading: () => const LoadingSkeleton(),
                error: (e, _) => ErrorView(message: '$e'),
                data: (recent) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      FadeSlideIn(child: _Greeting(hide: hide)),
                      const _PendingReceiptBanner(),
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(
                        delay: AppMotion.stagger(context, 1),
                        child: _HeroBalance(
                          byCurrency: byCurrency,
                          hide: hide,
                          monthTx: monthTx ?? const <MoneyTransaction>[],
                          ready: activityReady,
                        ),
                      ),
                      if (byCurrency.length > 1) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.currenciesSeparated,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(
                        delay: AppMotion.stagger(context, 2),
                        child: _IncomeExpenseRow(
                          monthTx: monthTx ?? const <MoneyTransaction>[],
                          currencies: byCurrency.keys.toList(),
                          hide: hide,
                          ready: activityReady,
                          failed: !activityReady && activity.hasError,
                          onRetry: () => ref.invalidate(dashboardActivityForUserProvider),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(l10n.quickActions, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: AppMotion.stagger(context, 3),
                        child: const _QuickActions(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const HomePlanEntry(),
                      const SizedBox(height: AppSpacing.sm),
                      const HomeAssistantEntry(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.expensesChart, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: AppMotion.stagger(context, 4),
                        child: _Charts(
                          monthTx: monthTx ?? const <MoneyTransaction>[],
                          currencies: byCurrency.keys.toList(),
                          categories: categories,
                          ready: activityReady,
                        ),
                      ),
                      const _Attention(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.myWallets, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ...items.take(4).toList().asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FadeSlideIn(
                                delay: AppMotion.stagger(context, e.key),
                                child: WalletVisualCard(
                                  wallet: e.value,
                                  compact: true,
                                  hideBalance: hide,
                                  onTap: () => context.go('/wallets/${e.value.walletId}'),
                                ),
                              ),
                            ),
                          ),
                      Text(
                        l10n.recentTransactions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (recent.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(l10n.noTransactionsYet),
                        )
                      else
                        ...recent.asMap().entries.map(
                              (e) => FadeSlideIn(
                                delay: AppMotion.stagger(context, e.key),
                                child: TransactionTile(
                                  transaction: e.value,
                                  onTap: () => context.go('/transactions/${e.value.id}'),
                                ),
                              ),
                            ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PendingReceiptBanner extends ConsumerWidget {
  const _PendingReceiptBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingReceiptsProvider).asData?.value ?? const [];
    if (pending.isEmpty) return const SizedBox.shrink();
    final operation = pending.first;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                operation.hasTransaction
                    ? l10n.receiptUploadRetry
                    : l10n.receiptPendingBody,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => context.go('/scan?resume=1'),
                    child: Text(l10n.receiptAttachAgain),
                  ),
                  TextButton(
                    onPressed: () async {
                      final userId = ref.read(currentUserIdProvider);
                      if (userId == null) return;
                      await ref.read(receiptOperationStoreProvider).remove(
                            userId,
                            operation.operationId,
                          );
                      ref.invalidate(pendingReceiptsForUserProvider);
                    },
                    child: Text(l10n.receiptDismissReminder),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.hide});
  final bool hide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authUserProvider).asData?.value;
    final name = user?.firstName?.trim();
    final label = (name != null && name.isNotEmpty) ? name : (user?.email ?? '');
    final initial = label.isEmpty ? '?' : label.substring(0, 1).toUpperCase();
    final hour = DateTime.now().hour;
    final hello = hour < 12
        ? l10n.greetingMorning
        : hour < 18
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
    final month = DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag()).format(DateTime.now());
    return Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/profile'),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name != null && name.isNotEmpty ? '$hello, $name' : hello,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(month, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: hide ? l10n.showBalance : l10n.hideBalance,
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(hideBalancesProvider.notifier).toggle();
          },
          icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        ),
        IconButton(
          tooltip: l10n.navSettings,
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _HeroBalance extends StatelessWidget {
  const _HeroBalance({
    required this.byCurrency,
    required this.hide,
    required this.monthTx,
    required this.ready,
  });

  final Map<String, num> byCurrency;
  final bool hide;
  final List<MoneyTransaction> monthTx;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final monthCurrency = byCurrency.length == 1 ? byCurrency.keys.first : null;
    String? trend;
    if (ready && monthCurrency != null) {
      final events = [for (final item in monthTx) item.toSpendEvent()];
      final thisExp = monthCashflow(events, now: now, currency: monthCurrency).expense;
      final lastExp = sumSpending(
        events,
        window: previousWindow('monthly', now),
        currency: monthCurrency,
      );
      if (lastExp > 0) {
        final delta = ((thisExp - lastExp) / lastExp) * 100;
        if (delta.abs() < 1) {
          trend = l10n.monthTrendFlat;
        } else if (delta < 0) {
          trend = l10n.monthTrendDown(delta.abs().toStringAsFixed(0));
        } else {
          trend = l10n.monthTrendUp(delta.toStringAsFixed(0));
        }
      }
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1B3A), Color(0xFF1D4ED8), Color(0xFF4776FF)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        boxShadow: AppShadows.glow(),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -28,
            child: CircleAvatar(
              radius: 64,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.totalBalance,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ...byCurrency.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Text(
                      hide ? '••••  ${e.key}' : Money.format(e.value, e.key),
                      key: ValueKey('${hide}_${e.key}_${e.value}'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                DateFormat.yMMMM(locale).format(now),
                style: const TextStyle(color: Colors.white70),
              ),
              if (trend != null) ...[
                const SizedBox(height: 8),
                Text(trend, style: const TextStyle(color: Color(0xFFC7D2FE))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({
    required this.monthTx,
    required this.currencies,
    required this.hide,
    required this.ready,
    required this.failed,
    required this.onRetry,
  });

  final List<MoneyTransaction> monthTx;
  final List<String> currencies;
  final bool hide;
  final bool ready;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final monthCurrency = currencies.length == 1 ? currencies.first : null;
    final flow = ready && monthCurrency != null
        ? monthCashflow(
            [for (final item in monthTx) item.toSpendEvent()],
            now: now,
            currency: monthCurrency,
          )
        : null;
    final income = flow?.income ?? 0;
    final expense = flow?.expense ?? 0;
    String fmt(num v) {
      if (!ready) return '…';
      if (failed || monthCurrency == null) return '—';
      if (hide) return '••••';
      return Money.format(v, monthCurrency);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: l10n.income,
                value: fmt(income),
                color: AppColors.success,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                title: l10n.expenses,
                value: fmt(expense),
                color: AppColors.danger,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.monthExcludesTransfers, style: Theme.of(context).textTheme.bodySmall),
        if (failed)
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (l10n.addExpense, Icons.remove_circle_outline, AppColors.danger, () => context.push('/add-transaction?type=EXPENSE')),
      (l10n.addIncome, Icons.add_circle_outline, AppColors.success, () => context.push('/add-transaction?type=INCOME')),
      (l10n.transfer, Icons.swap_horiz_rounded, AppColors.primary, () => context.push('/transfer')),
      (l10n.scanReceipt, Icons.document_scanner_outlined, AppColors.secondary, () => context.go('/scan')),
    ];
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Pressable(
                  haptic: true,
                  onTap: item.$4,
                  child: Column(
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: item.$3.withValues(alpha: 0.14),
                          boxShadow: AppShadows.card(Theme.of(context).brightness),
                        ),
                        child: Icon(item.$2, color: item.$3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class HomePlanEntry extends StatelessWidget {
  const HomePlanEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Pressable(
      haptic: true,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/plan'),
      child: Material(
        color: AppColors.surface(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0x221D4ED8),
                child: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.planTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(l10n.planRowBody, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Directionality.of(context) == ui.TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeAssistantEntry extends StatelessWidget {
  const HomeAssistantEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Pressable(
      haptic: true,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/plan/assistant'),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.planAssistant, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(l10n.aiAsk, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Directionality.of(context) == ui.TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Attention extends ConsumerWidget {
  const _Attention();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final budgets = ref.watch(budgetsProvider).asData?.value;
    final goals = ref.watch(goalsProvider).asData?.value;
    final now = DateTime.now();
    final hot = <BudgetProgress>[
      if (budgets != null)
        for (final item in [...budgets.rollup.overall, ...budgets.rollup.categories])
          if (item.spec.limit > 0 && item.ratio >= 0.8) item,
    ]..sort((a, b) => b.ratio.compareTo(a.ratio));
    final openGoals = [
      if (goals != null)
        for (final goal in goals)
          if (goal.status != 'archived' && goal.snapshot(now).progress < 1) goal,
    ]..sort((a, b) {
        final byPriority = a.priority.compareTo(b.priority);
        if (byPriority != 0) return byPriority;
        return a.snapshot(now).progress.compareTo(b.snapshot(now).progress);
      });
    if (hot.isEmpty && openGoals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.homeAttention, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in hot.take(2))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.pie_chart_outline, color: AppColors.danger),
            title: Text(item.spec.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${item.percent}%'),
            onTap: () => context.push('/plan/budgets/${item.spec.id}'),
          ),
        if (openGoals.isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.flag_outlined, color: AppColors.primary),
            title: Text(openGoals.first.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${openGoals.first.snapshot(now).percent}%'),
            onTap: () => context.push('/plan/goals/${openGoals.first.id}'),
          ),
      ],
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({
    required this.monthTx,
    required this.currencies,
    required this.categories,
    required this.ready,
  });

  final List<MoneyTransaction> monthTx;
  final List<String> currencies;
  final List<CategoryItem> categories;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final monthCurrency = currencies.length == 1 ? currencies.first : null;
    final window = periodWindow('monthly', now);
    num income = 0;
    num expense = 0;
    final catTotals = <String, num>{};
    final daily = <int, double>{};
    if (ready && monthCurrency != null) {
      for (final t in monthTx) {
        final event = t.toSpendEvent();
        if (event.currency != monthCurrency || !window.contains(event.date.toLocal())) continue;
        if (countsAsSpending(event)) {
          expense += event.amount;
          daily.update(event.date.toLocal().day, (v) => v + event.amount.toDouble(), ifAbsent: () => event.amount.toDouble());
          if (event.categoryId != null) {
            catTotals.update(event.categoryId!, (v) => v + event.amount, ifAbsent: () => event.amount);
          }
        } else if (countsAsIncome(event)) {
          income += event.amount;
        }
      }
      expense = (expense * 1000).round() / 1000;
      income = (income * 1000).round() / 1000;
    }
    final days = DateTime(now.year, now.month + 1, 0).day;
    final spots = <FlSpot>[
      for (var d = 1; d <= days; d++) FlSpot(d.toDouble(), daily[d] ?? 0),
    ];
    final hasSpend = expense > 0;
    return Column(
      children: [
        if (ready && !hasSpend)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(l10n.chartEmptyMonth),
          )
        else
        RepaintBoundary(
          child: Container(
            height: 210,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.surface(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final day = value.round();
                        if (day != 1 && day != 10 && day != 20 && day != days) {
                          return const SizedBox.shrink();
                        }
                        return Text('$day', style: Theme.of(context).textTheme.labelSmall);
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            s.y.toStringAsFixed(monthCurrency == 'TND' ? 3 : 2),
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.6,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.35),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: AppMotion.of(context, AppMotion.chart),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      v == 0 ? l10n.chartIn : l10n.chartOut,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(
                    toY: income.toDouble(),
                    color: AppColors.success,
                    width: 28,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(
                    toY: expense.toDouble(),
                    color: AppColors.danger,
                    width: 28,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ]),
              ],
            ),
            duration: AppMotion.of(context, AppMotion.chart),
          ),
        ),
        if (catTotals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(l10n.spendingByCategory, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: catTotals.entries.map((e) {
                  final matches = categories.where((c) => c.id == e.key);
                  final raw = matches.isEmpty ? l10n.other : matches.first.name;
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: localizedCategoryName(l10n, raw),
                    radius: 52,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
