import 'spend_rules.dart';

const budgetThresholds = [50, 80, 90, 100];

class BudgetSpec {
  const BudgetSpec({
    required this.id,
    required this.name,
    required this.period,
    required this.currency,
    required this.limit,
    this.categoryId,
    this.archived = false,
  });

  final String id;
  final String name;
  final String period;
  final String currency;
  final num limit;
  final String? categoryId;
  final bool archived;
}

class BudgetProgress {
  const BudgetProgress({
    required this.spec,
    required this.spent,
    required this.previousSpent,
  });

  final BudgetSpec spec;
  final num spent;
  final num previousSpent;

  num get remaining => spec.limit - spent;

  double get ratio {
    if (spec.limit <= 0) return 0;
    return spent / spec.limit;
  }

  int get percent => (ratio * 100).round();

  List<int> get crossedThresholds => [
        for (final threshold in budgetThresholds)
          if (percent >= threshold) threshold,
      ];
}

BudgetProgress progressFor(
  BudgetSpec spec,
  Iterable<SpendEvent> events,
  DateTime now,
) {
  return BudgetProgress(
    spec: spec,
    spent: sumSpending(
      events,
      window: periodWindow(spec.period, now),
      currency: spec.currency,
      categoryId: spec.categoryId,
    ),
    previousSpent: sumSpending(
      events,
      window: previousWindow(spec.period, now),
      currency: spec.currency,
      categoryId: spec.categoryId,
    ),
  );
}

/// Overall budgets and category budgets are reported separately.
/// Adding them together would count the same expense twice.
class BudgetRollup {
  const BudgetRollup({required this.overall, required this.categories});

  final List<BudgetProgress> overall;
  final List<BudgetProgress> categories;
}

BudgetRollup rollupBudgets(
  Iterable<BudgetSpec> specs,
  Iterable<SpendEvent> events,
  DateTime now,
) {
  final active = specs.where((spec) => !spec.archived);
  return BudgetRollup(
    overall: [
      for (final spec in active)
        if (spec.categoryId == null) progressFor(spec, events, now),
    ],
    categories: [
      for (final spec in active)
        if (spec.categoryId != null) progressFor(spec, events, now),
    ],
  );
}

Map<String, num> spendingByCategory(
  Iterable<SpendEvent> events, {
  required PeriodWindow window,
  required String currency,
}) {
  final totals = <String, num>{};
  for (final event in events) {
    if (!countsAsSpending(event)) continue;
    if (event.currency != currency || !window.contains(event.date)) continue;
    final key = event.categoryName ?? event.categoryId ?? 'other';
    totals[key] = (totals[key] ?? 0) + event.amount;
  }
  return totals;
}
