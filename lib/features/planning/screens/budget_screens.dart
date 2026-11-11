import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../categories/repositories/category_repository.dart';
import '../../recurring/repositories/recurring_repository.dart';
import '../domain/budget_math.dart';
import '../domain/spend_rules.dart';
import '../domain/what_if.dart';
import '../repositories/budget_repository.dart';

class BudgetDashboardScreen extends ConsumerWidget {
  const BudgetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final home = ref.watch(budgetsProvider);
    final recurring = ref.watch(recurringProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetDashboard),
        actions: [
          IconButton(
            tooltip: l10n.whatIf,
            onPressed: () => context.push('/plan/what-if'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/budgets/new'),
        child: const Icon(Icons.add),
      ),
      body: home.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(budgetsForUserProvider),
        ),
        data: (data) {
          final items = [...data.rollup.overall, ...data.rollup.categories];
          if (items.isEmpty) {
            return EmptyState(
              title: l10n.noPlanData,
              message: l10n.planBudget,
              actionLabel: l10n.newBudget,
              onAction: () => context.push('/plan/budgets/new'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(l10n.overallBudget, style: Theme.of(context).textTheme.titleMedium),
              for (final item in data.rollup.overall) _BudgetCard(item: item, events: data.events),
              const SizedBox(height: 16),
              Text(l10n.categoryBudget, style: Theme.of(context).textTheme.titleMedium),
              for (final item in data.rollup.categories) _BudgetCard(item: item, events: data.events),
              const SizedBox(height: 16),
              Text(l10n.recurringSection, style: Theme.of(context).textTheme.titleMedium),
              ...recurring.maybeWhen(
                data: (rows) => rows.where((row) => row.isActive && (row.type == 'EXPENSE' || row.type == 'PAYMENT')).map(
                      (row) => ListTile(
                        title: Text(row.description ?? row.type),
                        subtitle: Text(row.nextExecutionDate.toLocal().toString().split(' ').first),
                        trailing: Text(row.amount.toString()),
                      ),
                    ),
                orElse: () => [Text(l10n.noPlanData)],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.item, required this.events});

  final BudgetProgress item;
  final List<SpendEvent> events;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final forecast = forecastFor(item, events, DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => context.push('/plan/budgets/${item.spec.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.spec.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: item.ratio.clamp(0, 1).toDouble()),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, _) => LinearProgressIndicator(value: value),
              ),
              const SizedBox(height: 8),
              Text('${l10n.spentLabel}: ${Money.format(item.spent, item.spec.currency)}'),
              Text('${l10n.remainingLabel}: ${Money.format(item.remaining, item.spec.currency)}'),
              Text('${item.percent}%'),
              Text('${l10n.previousPeriod}: ${Money.format(item.previousSpent, item.spec.currency)}'),
              Text(
                forecast.sufficient && forecast.projected != null
                    ? '${l10n.forecastLabel}: ${Money.format(forecast.projected!, item.spec.currency)}'
                    : l10n.forecastInsufficient,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              for (final threshold in item.crossedThresholds) Text(l10n.alertReached(threshold)),
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budgetId});

  final String? budgetId;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _name = TextEditingController();
  final _limit = TextEditingController();
  String _period = 'monthly';
  String _currency = 'TND';
  String? _categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(widget.budgetId == null ? l10n.newBudget : l10n.edit)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppTextField(controller: _name, label: l10n.budgetName),
          const SizedBox(height: 12),
          AppTextField(
            controller: _limit,
            label: l10n.budgetLimit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _period,
            items: [
              DropdownMenuItem(value: 'monthly', child: Text(l10n.periodMonthly)),
              DropdownMenuItem(value: 'weekly', child: Text(l10n.periodWeekly)),
            ],
            onChanged: (value) => setState(() => _period = value ?? _period),
            decoration: InputDecoration(labelText: l10n.periodMonthly),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            items: [
              for (final currency in Currencies.all)
                DropdownMenuItem(value: currency.code, child: Text(currency.code)),
            ],
            onChanged: (value) => setState(() => _currency = value ?? _currency),
            decoration: InputDecoration(labelText: l10n.currency),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _categoryId,
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.allCategories)),
              for (final category in categories)
                DropdownMenuItem(value: category.id, child: Text(category.name)),
            ],
            onChanged: (value) => setState(() => _categoryId = value),
            decoration: InputDecoration(labelText: l10n.categoryBudget),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.save,
            loading: _saving,
            onPressed: () async {
              final amount = Money.tryParse(_limit.text);
              if (amount == null || _name.text.trim().isEmpty) return;
              setState(() => _saving = true);
              try {
                await ref.read(budgetRepositoryProvider).save(
                      id: widget.budgetId,
                      name: _name.text,
                      period: _period,
                      currency: _currency,
                      limit: amount,
                      categoryId: _categoryId,
                    );
                ref.invalidate(budgetsForUserProvider);
                if (context.mounted) context.pop();
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

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key, required this.budgetId});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final home = ref.watch(budgetsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetDashboard)),
      body: home.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(message: '$error'),
        data: (data) {
          final items = [...data.rollup.overall, ...data.rollup.categories];
          final item = items.where((row) => row.spec.id == budgetId).firstOrNull;
          if (item == null) return Center(child: Text(l10n.noPlanData));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BudgetCard(item: item, events: data.events),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(budgetRepositoryProvider).archive(budgetId);
                  ref.invalidate(budgetsForUserProvider);
                  if (context.mounted) context.pop();
                },
                child: Text(l10n.archive),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(budgetRepositoryProvider).delete(budgetId);
                  ref.invalidate(budgetsForUserProvider);
                  if (context.mounted) context.pop();
                },
                child: Text(l10n.deleteBudget),
              ),
            ],
          );
        },
      ),
    );
  }
}

class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  final _reduction = TextEditingController(text: '100');
  final _months = TextEditingController(text: '12');
  final _currency = 'TND';

  @override
  void dispose() {
    _reduction.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final home = ref.watch(budgetsProvider).asData?.value;
    final reduction = Money.tryParse(_reduction.text) ?? 0;
    final months = int.tryParse(_months.text) ?? 0;
    final result = simulateSavings(monthlyReduction: reduction, months: months, currency: _currency);
    final spends = <CategorySpend>[];
    if (home != null) {
      final window = periodWindow('monthly', DateTime.now());
      final totals = spendingByCategory(home.events, window: window, currency: _currency);
      totals.forEach((name, amount) {
        spends.add(CategorySpend(name: name, amount: amount, currency: _currency));
      });
    }
    final cuts = suggestCuts(spends: spends, currency: _currency);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.whatIf)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppTextField(
            controller: _reduction,
            label: l10n.monthlyReduction,
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
          Text('${l10n.potentialSavings}: ${Money.format(result.savings, result.currency)}'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: months <= 0 ? 0 : (months.clamp(0, 60) / 60)),
          const SizedBox(height: 16),
          if (!cuts.sufficient)
            Text(l10n.forecastInsufficient)
          else
            Text('${l10n.potentialSavings}: ${Money.format(cuts.monthlyFreed, cuts.currency)} / ${l10n.periodMonthly}'),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
