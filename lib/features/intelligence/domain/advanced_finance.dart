// Deterministic finance calculations. These are statistical baselines.
// They are not trained CatBoost, XGBoost, LightGBM, SARIMAX, or Isolation Forest models.

class TxnObs {
  const TxnObs({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.currency,
    this.merchant,
    this.category,
    this.description,
  });

  final String id;
  final DateTime date;
  final String type;
  final num amount;
  final String currency;
  final String? merchant;
  final String? category;
  final String? description;

  bool get isSpend => type == 'EXPENSE' || type == 'PAYMENT';
  bool get isIncome => type == 'INCOME';

  String get label {
    final merchantName = merchant?.trim();
    if (merchantName != null && merchantName.isNotEmpty) return merchantName;
    final text = description?.trim();
    if (text != null && text.isNotEmpty) return text;
    return category ?? 'expense';
  }
}

class Claim {
  const Claim({
    required this.id,
    required this.amount,
    required this.currency,
    this.merchant,
    this.date,
    this.description,
  });

  final String id;
  final num amount;
  final String currency;
  final String? merchant;
  final DateTime? date;
  final String? description;
}

num medianOf(List<num> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

num sampleStdev(List<num> values) {
  if (values.length < 2) return 0;
  num mean = 0;
  for (final value in values) {
    mean += value;
  }
  mean /= values.length;
  num square = 0;
  for (final value in values) {
    final delta = value - mean;
    square += delta * delta;
  }
  return _sqrt(square / (values.length - 1));
}

double _sqrt(num value) {
  if (value <= 0) return 0;
  var guess = value.toDouble();
  for (var i = 0; i < 12; i++) {
    guess = (guess + value / guess) / 2;
  }
  return guess;
}

String normalizeMerchant(String input) {
  final folded = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  return folded;
}

class AnomalyAlert {
  const AnomalyAlert({
    required this.code,
    required this.transactionId,
    required this.severity,
    required this.detail,
  });

  final String code;
  final String? transactionId;
  final String severity;
  final String detail;

  /// Predictions never block a legitimate payment.
  bool get blocksTransaction => false;
}

class AnomalyReport {
  const AnomalyReport({required this.sufficient, required this.alerts});

  final bool sufficient;
  final List<AnomalyAlert> alerts;
}

AnomalyReport detectAnomalies(List<TxnObs> rows, {DateTime? now}) {
  final spends = rows.where((row) => row.isSpend && row.amount > 0).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  if (spends.length < 8) {
    return const AnomalyReport(sufficient: false, alerts: []);
  }
  final clock = now ?? spends.last.date;
  final amounts = [for (final row in spends) row.amount];
  final mid = medianOf(amounts);
  final mad = medianOf([for (final amount in amounts) (amount - mid).abs()]);
  final scale = mad == 0 ? (mid * 0.15) : mad;
  final alerts = <AnomalyAlert>[];
  for (final row in spends) {
    if (scale > 0 && row.amount > mid + 3 * scale) {
      alerts.add(AnomalyAlert(
        code: 'high_expense',
        transactionId: row.id,
        severity: 'high',
        detail: '${row.label} ${row.amount} vs median $mid',
      ));
    }
  }
  final seen = <String, TxnObs>{};
  for (final row in spends) {
    final key = '${row.currency}|${normalizeMerchant(row.label)}|${row.amount.toStringAsFixed(3)}';
    final previous = seen[key];
    if (previous != null && row.date.difference(previous.date).inDays.abs() <= 2 && previous.id != row.id) {
      alerts.add(AnomalyAlert(
        code: 'duplicate_payment',
        transactionId: row.id,
        severity: 'medium',
        detail: row.label,
      ));
    }
    seen[key] = row;
  }
  final recent = spends.where((row) => clock.difference(row.date).inDays <= 1).length;
  final days = spends.last.date.difference(spends.first.date).inDays.clamp(1, 3650);
  final daily = spends.length / days;
  if (recent >= 4 && recent > daily * 3) {
    alerts.add(AnomalyAlert(
      code: 'frequency_spike',
      transactionId: null,
      severity: 'medium',
      detail: '$recent payments in one day',
    ));
  }
  final tiny = spends.where((row) => row.amount <= mid * 0.25 && clock.difference(row.date).inDays <= 2).length;
  if (tiny >= 5) {
    alerts.add(const AnomalyAlert(
      code: 'many_small',
      transactionId: null,
      severity: 'low',
      detail: 'Several small payments in a short window',
    ));
  }
  return AnomalyReport(sufficient: true, alerts: alerts);
}

class SubscriptionHit {
  const SubscriptionHit({
    required this.name,
    required this.currency,
    required this.cadence,
    required this.typicalAmount,
    required this.lastAmount,
    required this.lastDate,
    required this.nextDate,
    required this.inactive,
    required this.priceIncreased,
    required this.duplicate,
  });

  final String name;
  final String currency;
  final String cadence;
  final num typicalAmount;
  final num lastAmount;
  final DateTime lastDate;
  final DateTime? nextDate;
  final bool inactive;
  final bool priceIncreased;
  final bool duplicate;
}

List<SubscriptionHit> detectSubscriptions(List<TxnObs> rows, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final groups = <String, List<TxnObs>>{};
  for (final row in rows.where((row) => row.isSpend)) {
    final key = '${row.currency}|${normalizeMerchant(row.label)}';
    if (key.endsWith('|')) continue;
    groups.putIfAbsent(key, () => []).add(row);
  }
  final hits = <SubscriptionHit>[];
  for (final entry in groups.entries) {
    final items = [...entry.value]..sort((a, b) => a.date.compareTo(b.date));
    if (items.length < 2) continue;
    final gaps = <num>[];
    for (var i = 1; i < items.length; i++) {
      gaps.add(items[i].date.difference(items[i - 1].date).inDays.toDouble());
    }
    final gap = medianOf(gaps);
    final cadence = gap >= 6 && gap <= 9
        ? 'weekly'
        : gap >= 25 && gap <= 40
            ? 'monthly'
            : gap >= 80 && gap <= 100
                ? 'quarterly'
                : null;
    if (cadence == null) continue;
    final amounts = [for (final item in items) item.amount];
    final typical = medianOf(amounts);
    final last = items.last;
    final previous = amounts.length > 1 ? medianOf(amounts.sublist(0, amounts.length - 1)) : typical;
    final increased = previous > 0 && last.amount > previous * 1.05;
    final staleDays = cadence == 'weekly' ? 21 : cadence == 'monthly' ? 70 : 200;
    final inactive = clock.difference(last.date).inDays > staleDays;
    final modes = amounts.map((amount) => (amount * 10).round()).toSet();
    hits.add(SubscriptionHit(
      name: last.label,
      currency: last.currency,
      cadence: cadence,
      typicalAmount: typical,
      lastAmount: last.amount,
      lastDate: last.date,
      nextDate: inactive ? null : last.date.add(Duration(days: gap.round())),
      inactive: inactive,
      priceIncreased: increased,
      duplicate: modes.length > 1 && (amounts.reduce((a, b) => a > b ? a : b) > typical * 1.2),
    ));
  }
  hits.sort((a, b) => a.name.compareTo(b.name));
  return hits;
}

class MatchScore {
  const MatchScore({required this.receiptId, required this.transactionId, required this.score});

  final String receiptId;
  final String transactionId;
  final double score;
}

class Reconciliation {
  const Reconciliation({
    required this.matches,
    required this.duplicateReceipts,
    required this.unmatchedReceipts,
    required this.unmatchedTransactions,
  });

  final List<MatchScore> matches;
  final List<String> duplicateReceipts;
  final List<String> unmatchedReceipts;
  final List<String> unmatchedTransactions;
}

double _tokens(String? left, String? right) {
  final a = (left ?? '').toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((part) => part.length > 2).toSet();
  final b = (right ?? '').toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((part) => part.length > 2).toSet();
  if (a.isEmpty || b.isEmpty) return 0;
  final overlap = a.intersection(b).length;
  return overlap / a.union(b).length;
}

Reconciliation reconcile(List<Claim> receipts, List<Claim> transactions) {
  final matches = <MatchScore>[];
  final used = <String>{};
  for (final receipt in receipts) {
    MatchScore? best;
    for (final txn in transactions) {
      if (used.contains(txn.id) || receipt.currency != txn.currency) continue;
      if ((receipt.amount - txn.amount).abs() > 0.05) continue;
      var score = 0.55;
      if (receipt.date != null && txn.date != null && receipt.date!.difference(txn.date!).inDays.abs() <= 2) {
        score += 0.25;
      }
      score += 0.20 * _tokens('${receipt.merchant} ${receipt.description}', '${txn.merchant} ${txn.description}');
      if (best == null || score > best.score) {
        best = MatchScore(receiptId: receipt.id, transactionId: txn.id, score: score);
      }
    }
    if (best != null && best.score >= 0.7) {
      matches.add(best);
      used.add(best.transactionId);
    }
  }
  final matchedReceipts = matches.map((match) => match.receiptId).toSet();
  final duplicates = <String>[];
  for (var i = 0; i < receipts.length; i++) {
    for (var j = i + 1; j < receipts.length; j++) {
      final a = receipts[i];
      final b = receipts[j];
      if (a.currency == b.currency &&
          (a.amount - b.amount).abs() <= 0.05 &&
          _tokens(a.merchant, b.merchant) >= 0.5) {
        duplicates.add(b.id);
      }
    }
  }
  return Reconciliation(
    matches: matches,
    duplicateReceipts: duplicates.toSet().toList(),
    unmatchedReceipts: [for (final receipt in receipts) if (!matchedReceipts.contains(receipt.id)) receipt.id],
    unmatchedTransactions: [for (final txn in transactions) if (!used.contains(txn.id)) txn.id],
  );
}

class HorizonForecast {
  const HorizonForecast({
    required this.sufficient,
    required this.dailyAverage,
    required this.next7,
    required this.next30,
    required this.endOfMonth,
    required this.uncertainty30,
    required this.sampleCount,
  });

  final bool sufficient;
  final num dailyAverage;
  final num next7;
  final num next30;
  final num endOfMonth;
  final num uncertainty30;
  final int sampleCount;
}

HorizonForecast forecastSpending(List<TxnObs> rows, {required DateTime now, String? category}) {
  final start = now.subtract(const Duration(days: 28));
  final sample = rows.where((row) {
    if (!row.isSpend || row.date.isBefore(start) || row.date.isAfter(now)) return false;
    if (category != null && row.category != category) return false;
    return true;
  }).toList();
  if (sample.length < 4) {
    return const HorizonForecast(
      sufficient: false,
      dailyAverage: 0,
      next7: 0,
      next30: 0,
      endOfMonth: 0,
      uncertainty30: 0,
      sampleCount: 0,
    );
  }
  final byDay = <DateTime, num>{};
  for (final row in sample) {
    final day = DateTime(row.date.year, row.date.month, row.date.day);
    byDay[day] = (byDay[day] ?? 0) + row.amount;
  }
  final dailyValues = byDay.values.toList();
  num total = 0;
  for (final value in dailyValues) {
    total += value;
  }
  final average = total / 28;
  final spread = sampleStdev(dailyValues);
  final monthEnd = DateTime(now.year, now.month + 1, 0).day;
  final left = monthEnd - now.day;
  num spentMonth = 0;
  for (final row in rows) {
    if (!row.isSpend) continue;
    if (category != null && row.category != category) continue;
    if (row.date.year == now.year && row.date.month == now.month && !row.date.isAfter(now)) {
      spentMonth += row.amount;
    }
  }
  return HorizonForecast(
    sufficient: true,
    dailyAverage: average,
    next7: average * 7,
    next30: average * 30,
    endOfMonth: spentMonth + average * (left < 0 ? 0 : left),
    uncertainty30: spread * _sqrt(30),
    sampleCount: sample.length,
  );
}

class OverspendRisk {
  const OverspendRisk({
    required this.sufficient,
    required this.name,
    required this.expected,
    required this.limit,
    required this.overBy,
    required this.daysLeft,
    required this.dailyLimit,
    required this.level,
  });

  final bool sufficient;
  final String name;
  final num expected;
  final num limit;
  final num overBy;
  final int daysLeft;
  final num dailyLimit;
  final String level;
}

List<OverspendRisk> overspendRisks({
  required List<({String name, num spent, num limit})> budgets,
  required DateTime now,
  required int sampleCount,
}) {
  final days = DateTime(now.year, now.month + 1, 0).day;
  final left = days - now.day;
  if (sampleCount < 4 || now.day < 3) return const [];
  return [
    for (final budget in budgets)
      if (budget.limit > 0)
        () {
          final expected = budget.spent / now.day * days;
          final over = expected - budget.limit;
          final remaining = budget.limit - budget.spent;
          final level = expected <= budget.limit * 0.8
              ? 'low'
              : expected <= budget.limit
                  ? 'medium'
                  : 'high';
          return OverspendRisk(
            sufficient: true,
            name: budget.name,
            expected: expected,
            limit: budget.limit,
            overBy: over > 0 ? over : 0,
            daysLeft: left < 0 ? 0 : left,
            dailyLimit: remaining <= 0 || left <= 0 ? 0 : remaining / left,
            level: level,
          );
        }(),
  ];
}

class AllocationLine {
  const AllocationLine({required this.name, required this.amount, required this.note});

  final String name;
  final num amount;
  final String note;
}

class AllocationPlan {
  const AllocationPlan({
    required this.sufficient,
    required this.income,
    required this.essentials,
    required this.surplus,
    required this.lines,
  });

  final bool sufficient;
  final num income;
  final num essentials;
  final num surplus;
  final List<AllocationLine> lines;
}

const essentialNames = {'housing', 'food', 'transport', 'bills'};

AllocationPlan suggestAllocation(List<TxnObs> rows, {required DateTime now, required String currency}) {
  final month = DateTime(now.year, now.month - 1);
  num income = 0;
  final categories = <String, num>{};
  for (final row in rows) {
    if (row.currency != currency || row.date.year != month.year || row.date.month != month.month) continue;
    if (row.isIncome) income += row.amount;
    if (row.isSpend) {
      final key = (row.category ?? 'other').toLowerCase();
      categories[key] = (categories[key] ?? 0) + row.amount;
    }
  }
  if (income <= 0) {
    return const AllocationPlan(sufficient: false, income: 0, essentials: 0, surplus: 0, lines: []);
  }
  num essentials = 0;
  for (final entry in categories.entries) {
    if (essentialNames.contains(entry.key)) essentials += entry.value;
  }
  final surplus = income - essentials;
  final safeSurplus = surplus < 0 ? 0 : surplus;
  final lines = <AllocationLine>[
    for (final name in ['Housing', 'Food', 'Transport'])
      AllocationLine(
        name: name,
        amount: categories[name.toLowerCase()] ?? 0,
        note: 'observed essential',
      ),
    AllocationLine(name: 'Savings', amount: safeSurplus * 0.4, note: 'share of surplus'),
    AllocationLine(name: 'Shopping', amount: safeSurplus * 0.2, note: 'share of surplus'),
    AllocationLine(name: 'Entertainment', amount: safeSurplus * 0.15, note: 'share of surplus'),
    AllocationLine(name: 'Buffer', amount: safeSurplus * 0.25, note: 'unallocated surplus'),
  ];
  return AllocationPlan(
    sufficient: true,
    income: income,
    essentials: essentials,
    surplus: surplus,
    lines: lines,
  );
}

class BehaviorReport {
  const BehaviorReport({
    required this.sufficient,
    required this.weekendShare,
    required this.monthChange,
    required this.categoryChanges,
  });

  final bool sufficient;
  final double weekendShare;
  final num monthChange;
  final List<({String category, num delta})> categoryChanges;
}

BehaviorReport analyzeBehavior(List<TxnObs> rows, {required DateTime now, required String currency}) {
  final spends = rows.where((row) => row.isSpend && row.currency == currency).toList();
  if (spends.length < 6) {
    return const BehaviorReport(sufficient: false, weekendShare: 0, monthChange: 0, categoryChanges: []);
  }
  num weekend = 0;
  num all = 0;
  for (final row in spends) {
    all += row.amount;
    if (row.date.weekday == DateTime.saturday || row.date.weekday == DateTime.sunday) {
      weekend += row.amount;
    }
  }
  num current = 0;
  num previous = 0;
  final currentCats = <String, num>{};
  final previousCats = <String, num>{};
  final prev = DateTime(now.year, now.month - 1);
  for (final row in spends) {
    final name = row.category ?? 'other';
    if (row.date.year == now.year && row.date.month == now.month) {
      current += row.amount;
      currentCats[name] = (currentCats[name] ?? 0) + row.amount;
    } else if (row.date.year == prev.year && row.date.month == prev.month) {
      previous += row.amount;
      previousCats[name] = (previousCats[name] ?? 0) + row.amount;
    }
  }
  final names = {...currentCats.keys, ...previousCats.keys};
  final changes = [
    for (final name in names)
      (category: name, delta: (currentCats[name] ?? 0) - (previousCats[name] ?? 0)),
  ]..sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
  return BehaviorReport(
    sufficient: true,
    weekendShare: all == 0 ? 0 : (weekend / all).toDouble(),
    monthChange: current - previous,
    categoryChanges: changes.take(5).toList(),
  );
}

class GoalScenario {
  const GoalScenario({
    required this.sufficient,
    required this.requiredMonthly,
    required this.optimistic,
    required this.expected,
    required this.pessimistic,
    required this.reachRate,
    required this.assumption,
  });

  final bool sufficient;
  final num requiredMonthly;
  final bool optimistic;
  final bool expected;
  final bool pessimistic;
  final double reachRate;
  final String assumption;
}

class _Lcg {
  _Lcg(this.state);
  int state;
  double next() {
    state = (1664525 * state + 1013904223) & 0x7fffffff;
    return state / 0x7fffffff;
  }
}

GoalScenario goalFeasibility({
  required num gap,
  required int months,
  required num monthlySurplus,
  int paths = 200,
}) {
  if (months < 1 || monthlySurplus <= 0 || gap <= 0) {
    return const GoalScenario(
      sufficient: false,
      requiredMonthly: 0,
      optimistic: false,
      expected: false,
      pessimistic: false,
      reachRate: 0,
      assumption: 'need a positive surplus, a gap, and at least one month',
    );
  }
  final required = gap / months;
  bool reaches(num factor) => monthlySurplus * factor * months >= gap;
  final random = _Lcg(42);
  var hits = 0;
  for (var i = 0; i < paths; i++) {
    num saved = 0;
    for (var month = 0; month < months; month++) {
      final factor = 0.4 + random.next() * 0.8;
      saved += monthlySurplus * factor;
    }
    if (saved >= gap) hits++;
  }
  return GoalScenario(
    sufficient: true,
    requiredMonthly: required,
    optimistic: reaches(1.1),
    expected: reaches(1),
    pessimistic: reaches(0.7),
    reachRate: hits / paths,
    assumption: 'each simulated month saves 40% to 120% of the observed surplus',
  );
}

class PlanStep {
  const PlanStep({required this.title, required this.detail});

  final String title;
  final String detail;
}

class SavingPlan {
  const SavingPlan({
    required this.recommended,
    required this.achievable,
    required this.movesMoney,
    required this.steps,
  });

  final num recommended;
  final bool achievable;
  final bool movesMoney;
  final List<PlanStep> steps;
}

SavingPlan planSavings({
  required num gap,
  required int months,
  required num monthlySurplus,
  required num cashBalance,
  required String currency,
}) {
  final scenario = goalFeasibility(gap: gap, months: months, monthlySurplus: monthlySurplus);
  final required = months < 1 ? gap : gap / months;
  final recommended = monthlySurplus <= 0 ? 0 : (required < monthlySurplus ? required : monthlySurplus);
  final reserve = cashBalance * 0.2;
  return SavingPlan(
    recommended: recommended,
    achievable: scenario.expected,
    movesMoney: false,
    steps: [
      PlanStep(title: 'Required', detail: '${required.toStringAsFixed(3)} $currency / month for $months months'),
      PlanStep(title: 'Available surplus', detail: '${monthlySurplus.toStringAsFixed(3)} $currency'),
      PlanStep(title: 'Keep a reserve', detail: '${reserve.toStringAsFixed(3)} $currency stays in the wallet'),
      const PlanStep(title: 'Approval', detail: 'No wallet is debited until you confirm a contribution or transfer'),
    ],
  );
}

class GoalCompareRow {
  const GoalCompareRow({
    required this.name,
    required this.assigned,
    required this.feasible,
    required this.priority,
  });

  final String name;
  final num assigned;
  final bool feasible;
  final int priority;
}

List<GoalCompareRow> compareGoals({
  required num monthlySurplus,
  required List<({String name, num gap, int months, int priority})> goals,
}) {
  final ordered = [...goals]..sort((a, b) => a.priority.compareTo(b.priority));
  var left = monthlySurplus < 0 ? 0 : monthlySurplus;
  return [
    for (final goal in ordered)
      () {
        final need = goal.months < 1 ? goal.gap : goal.gap / goal.months;
        final assigned = need < left ? need : left;
        left -= assigned;
        return GoalCompareRow(
          name: goal.name,
          assigned: assigned,
          feasible: assigned + 0.001 >= need && need > 0,
          priority: goal.priority,
        );
      }(),
  ];
}

class RiskView {
  const RiskView({
    required this.volatility,
    required this.volatilityKnown,
    required this.loss10,
    required this.loss30,
    required this.concentrated,
    required this.limitation,
  });

  final num? volatility;
  final bool volatilityKnown;
  final num loss10;
  final num loss30;
  final bool concentrated;
  final String limitation;
}

RiskView portfolioRisk({
  required num value,
  required double largestShare,
  required List<num> prices,
}) {
  final concentrated = largestShare > 0.4;
  if (prices.length < 5 || value <= 0) {
    return RiskView(
      volatility: null,
      volatilityKnown: false,
      loss10: value * 0.1,
      loss30: value * 0.3,
      concentrated: concentrated,
      limitation: 'Shock figures are hypothetical percentages, not a market forecast. Volatility needs at least five recorded prices.',
    );
  }
  final returns = <num>[];
  for (var i = 1; i < prices.length; i++) {
    if (prices[i - 1] == 0) continue;
    returns.add((prices[i] - prices[i - 1]) / prices[i - 1]);
  }
  return RiskView(
    volatility: sampleStdev(returns),
    volatilityKnown: returns.length >= 4,
    loss10: value * 0.1,
    loss30: value * 0.3,
    concentrated: concentrated,
    limitation: 'Sample standard deviation of recorded price changes. Not a prediction and not investment advice.',
  );
}

class PeriodReport {
  const PeriodReport({
    required this.income,
    required this.expense,
    required this.net,
    required this.byCategory,
  });

  final num income;
  final num expense;
  final num net;
  final Map<String, num> byCategory;
}

PeriodReport reportFor(
  List<TxnObs> rows, {
  required DateTime start,
  required DateTime end,
  required String currency,
}) {
  num income = 0;
  num expense = 0;
  final categories = <String, num>{};
  for (final row in rows) {
    if (row.currency != currency || row.date.isBefore(start) || !row.date.isBefore(end)) continue;
    if (row.isIncome) income += row.amount;
    if (row.isSpend) {
      expense += row.amount;
      final name = row.category ?? 'other';
      categories[name] = (categories[name] ?? 0) + row.amount;
    }
  }
  return PeriodReport(income: income, expense: expense, net: income - expense, byCategory: categories);
}

class SplitCheck {
  const SplitCheck({required this.valid, required this.remainder});

  final bool valid;
  final num remainder;
}

SplitCheck checkSplit({required num total, required List<num> parts}) {
  if (total <= 0 || parts.isEmpty || parts.any((part) => part <= 0)) {
    return SplitCheck(valid: false, remainder: total);
  }
  num sum = 0;
  for (final part in parts) {
    sum += part;
  }
  final remainder = total - sum;
  return SplitCheck(valid: remainder.abs() <= 0.001, remainder: remainder);
}

class BalanceCheck {
  const BalanceCheck({
    required this.name,
    required this.consistent,
    required this.unusual,
    required this.detail,
  });

  final String name;
  final bool consistent;
  final bool unusual;
  final String detail;
}

List<BalanceCheck> checkBalances({
  required List<({String name, String type, num initial, num current, num creditLimit, num? available})> wallets,
  required List<num> movementSizes,
}) {
  final mid = movementSizes.length < 5 ? null : medianOf(movementSizes.map((value) => value.abs()).toList());
  return [
    for (final wallet in wallets)
      BalanceCheck(
        name: wallet.name,
        consistent: wallet.type != 'CREDIT_CARD' ||
            wallet.available == null ||
            (wallet.available! - (wallet.creditLimit + wallet.current)).abs() <= 0.001,
        unusual: mid != null && (wallet.current - wallet.initial).abs() > mid * 8 && mid > 0,
        detail: wallet.type == 'CREDIT_CARD'
            ? 'available credit should equal limit plus balance'
            : 'balance is initial balance plus movements',
      ),
  ];
}
