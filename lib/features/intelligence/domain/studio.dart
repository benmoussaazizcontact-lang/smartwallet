import 'advanced_finance.dart';

/// On-device calculations for the 30 studio features.
/// `method` is `statistical_baseline` or `educational_simulation`.
/// No result uses a trained LightGBM, XGBoost, SARIMAX, Prophet, Isolation Forest, or SHAP model.

class StudioGoal {
  const StudioGoal({required this.name, required this.gap, required this.months, required this.priority});

  final String name;
  final num gap;
  final int months;
  final int priority;
}

class StudioHolding {
  const StudioHolding({
    required this.label,
    required this.assetClass,
    required this.value,
    required this.gain,
    this.prices = const [],
  });

  final String label;
  final String assetClass;
  final num value;
  final num gain;
  final List<num> prices;
}

class FeatureResult {
  const FeatureResult({
    required this.id,
    required this.code,
    required this.method,
    required this.operational,
    required this.metrics,
    required this.drivers,
  });

  final int id;
  final String code;
  final String method;
  final bool operational;
  final Map<String, num> metrics;
  final List<String> drivers;
}

class PreparedAction {
  const PreparedAction({
    required this.kind,
    required this.summary,
    required this.requiresConfirmation,
    required this.executesImmediately,
  });

  final String kind;
  final String summary;
  final bool requiresConfirmation;
  final bool executesImmediately;
}

class FinancialIntent {
  const FinancialIntent({
    required this.kind,
    this.draftAmount,
    this.draftCurrency = 'TND',
    this.scenario,
    this.action,
  });

  final String kind;
  final num? draftAmount;
  final String draftCurrency;
  final String? scenario;
  final PreparedAction? action;
}

List<List<int>> dbscan1d(List<num> values, {required num eps, int minPts = 2}) {
  if (values.isEmpty || eps < 0) return const [];
  final clusters = <List<int>>[];
  final seen = <int>{};
  for (var i = 0; i < values.length; i++) {
    if (seen.contains(i)) continue;
    final neighbors = [
      for (var j = 0; j < values.length; j++)
        if ((values[i] - values[j]).abs() <= eps) j,
    ];
    if (neighbors.length < minPts) continue;
    final cluster = <int>[];
    final queue = [...neighbors];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!seen.add(current)) continue;
      cluster.add(current);
      final more = [
        for (var j = 0; j < values.length; j++)
          if ((values[current] - values[j]).abs() <= eps) j,
      ];
      if (more.length >= minPts) queue.addAll(more);
    }
    clusters.add(cluster);
  }
  return clusters;
}

List<int> kMeans1d(List<num> values, {int k = 2, int iterations = 8}) {
  if (values.length < k * 3) return const [];
  final sorted = [...values]..sort();
  var centers = [for (var i = 0; i < k; i++) sorted[(sorted.length * (i + 1) / (k + 1)).floor()]];
  var labels = List<int>.filled(values.length, 0);
  for (var step = 0; step < iterations; step++) {
    for (var i = 0; i < values.length; i++) {
      var best = 0;
      num bestDist = (values[i] - centers[0]).abs();
      for (var c = 1; c < k; c++) {
        final dist = (values[i] - centers[c]).abs();
        if (dist < bestDist) {
          best = c;
          bestDist = dist;
        }
      }
      labels[i] = best;
    }
    final sums = List<num>.filled(k, 0);
    final counts = List<int>.filled(k, 0);
    for (var i = 0; i < values.length; i++) {
      sums[labels[i]] += values[i];
      counts[labels[i]] += 1;
    }
    for (var c = 0; c < k; c++) {
      if (counts[c] > 0) centers[c] = sums[c] / counts[c];
    }
  }
  return labels;
}

num _percentile(List<num> values, double p) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * p).round().clamp(0, sorted.length - 1);
  return sorted[index];
}

class _Seed {
  _Seed(this.state);
  int state;
  double next() {
    state = (1664525 * state + 1013904223) & 0x7fffffff;
    return state / 0x7fffffff;
  }
}

List<FeatureResult> buildStudio({
  required List<TxnObs> rows,
  required DateTime now,
  required String currency,
  required List<StudioGoal> goals,
  required List<StudioHolding> holdings,
  required num cashBalance,
  int paths = 200,
}) {
  final same = rows.where((row) => row.currency == currency).toList();
  final spends = same.where((row) => row.isSpend).toList();
  final incomes = same.where((row) => row.isIncome).toList();
  num income = 0;
  num expense = 0;
  final byCategory = <String, num>{};
  final byWeekday = List<num>.filled(7, 0);
  for (final row in spends) {
    expense += row.amount;
    final name = row.category ?? 'other';
    byCategory[name] = (byCategory[name] ?? 0) + row.amount;
    byWeekday[row.date.weekday - 1] += row.amount;
  }
  for (final row in incomes) {
    income += row.amount;
  }
  final months = same.map((row) => '${row.date.year}-${row.date.month}').toSet().length.clamp(1, 36);
  final monthlyIncome = income / months;
  final monthlyExpense = expense / months;
  final surplus = monthlyIncome - monthlyExpense;
  final forecast = forecastSpending(same, now: now);
  final anomalies = detectAnomalies(same, now: now);
  final subscriptions = detectSubscriptions(same, now: now);
  final behavior = analyzeBehavior(same, now: now, currency: currency);
  final allocation = suggestAllocation(same, now: now, currency: currency);
  final daily = forecast.sufficient ? forecast.dailyAverage : (spends.isEmpty ? 0 : monthlyExpense / 30);
  final enough = spends.length >= 8;

  num fixedCosts = 0;
  for (final entry in byCategory.entries) {
    if (essentialNames.contains(entry.key.toLowerCase())) fixedCosts += entry.value / months;
  }
  final goalNeed = goals.fold<num>(0, (sum, goal) {
    final monthsLeft = goal.months < 1 ? 1 : goal.months;
    return sum + goal.gap / monthsLeft;
  });
  final adjustable = monthlyIncome - fixedCosts - (goalNeed < 0 ? 0 : goalNeed);
  final proposedCut = adjustable < 0 ? 0 : adjustable * 0.1;

  FeatureResult baseline({
    required int id,
    required String code,
    required bool operational,
    required Map<String, num> metrics,
    required List<String> drivers,
    String method = 'statistical_baseline',
  }) {
    return FeatureResult(
      id: id,
      code: code,
      method: method,
      operational: operational,
      metrics: metrics,
      drivers: [
        ...drivers,
        'LightGBM, XGBoost, SARIMAX, Prophet, Isolation Forest, and SHAP are not trained on this account.',
      ],
    );
  }

  final categoryRisks = <String, num>{};
  for (final entry in byCategory.entries) {
    final monthly = entry.value / months;
    final limit = allocation.lines.where((line) => line.name.toLowerCase() == entry.key.toLowerCase()).fold<num>(0, (sum, line) => sum + line.amount);
    final guard = limit > 0 ? limit : monthly * 1.1;
    categoryRisks[entry.key] = guard == 0 ? 0 : monthly / guard;
  }

  final clusters = kMeans1d([for (final row in spends) row.amount]);
  final gaps = <num>[];
  final ordered = [...spends]..sort((a, b) => a.date.compareTo(b.date));
  for (var i = 1; i < ordered.length; i++) {
    gaps.add(ordered[i].date.difference(ordered[i - 1].date).inDays.toDouble());
  }
  final density = gaps.length < 4 ? 0 : dbscan1d(gaps, eps: 3).length;

  final random = _Seed(42);
  final lossSims = <num>[];
  final rentSims = <num>[];
  for (var i = 0; i < paths; i++) {
    final shock = 0.5 + random.next() * 0.5;
    lossSims.add(monthlyIncome * shock - monthlyExpense);
    rentSims.add(monthlyIncome - monthlyExpense - fixedCosts * 0.2 * random.next());
  }

  final prices = [for (final holding in holdings) ...holding.prices];
  num portfolio = 0;
  num gain = 0;
  var largest = 0.0;
  final byClass = <String, num>{};
  for (final holding in holdings) {
    if (holding.value <= 0) continue;
    portfolio += holding.value;
    gain += holding.gain;
    byClass[holding.assetClass] = (byClass[holding.assetClass] ?? 0) + holding.value;
  }
  if (portfolio > 0) {
    for (final holding in holdings) {
      final share = holding.value / portfolio;
      if (share > largest) largest = share.toDouble();
    }
  }
  final risk = portfolioRisk(value: portfolio, largestShare: largest, prices: prices);
  final returns = <num>[];
  for (var i = 1; i < prices.length; i++) {
    if (prices[i - 1] == 0) continue;
    returns.add((prices[i] - prices[i - 1]) / prices[i - 1]);
  }
  num ewma = 0;
  if (returns.length >= 8) {
    ewma = returns.first.abs().toDouble();
    for (final value in returns.skip(1)) {
      ewma = 0.94 * ewma + 0.06 * value.abs();
    }
  }

  final primary = goals.isEmpty ? null : goals.reduce((a, b) => a.priority <= b.priority ? a : b);
  final feasibility = primary == null
      ? null
      : goalFeasibility(gap: primary.gap, months: primary.months < 1 ? 1 : primary.months, monthlySurplus: surplus < 0 ? 0 : surplus, paths: paths);
  final compared = compareGoals(
    monthlySurplus: surplus < 0 ? 0 : surplus,
    goals: [for (final goal in goals) (name: goal.name, gap: goal.gap, months: goal.months, priority: goal.priority)],
  );
  final plan = planSavings(
    gap: primary?.gap ?? 0,
    months: primary?.months ?? 1,
    monthlySurplus: surplus < 0 ? 0 : surplus,
    cashBalance: cashBalance < 0 ? 0 : cashBalance,
    currency: currency,
  );
  final reserve = cashBalance * 0.2;
  final weekly = plan.recommended / 4;

  num lowWealth = cashBalance;
  num midWealth = cashBalance;
  num highWealth = cashBalance;
  final save = plan.recommended < 0 ? 0 : plan.recommended;
  for (var month = 0; month < 120; month++) {
    lowWealth = lowWealth + save - monthlyExpense * 0.2;
    midWealth = (midWealth + save) * 1.002;
    highWealth = (highWealth + save) * 1.005;
  }

  final reduction = <String, num>{};
  num freed = 0;
  final ranked = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in ranked.take(3)) {
    final cut = entry.value / months * 0.1;
    if (cut <= 0) continue;
    reduction[entry.key] = cut;
    freed += cut;
  }

  return [
    baseline(
      id: 1,
      code: 'budget_optimization',
      operational: monthlyIncome > 0,
      metrics: {'income': monthlyIncome, 'fixed': fixedCosts, 'goal_need': goalNeed, 'proposed_adjustment': proposedCut},
      drivers: ['Adjustment is 10% of income left after observed essentials and the sum of required goal contributions.'],
    ),
    baseline(
      id: 2,
      code: 'cash_flow',
      operational: enough && forecast.sufficient,
      metrics: {'d7': daily * 7, 'd30': daily * 30, 'd90': daily * 90, 'uncertainty30': forecast.uncertainty30},
      drivers: ['7, 30, and 90 day figures extend the 28-day daily average. This is not a fitted SARIMAX or Prophet model.'],
    ),
    baseline(
      id: 3,
      code: 'overrun_risk',
      operational: categoryRisks.isNotEmpty,
      metrics: {for (final entry in categoryRisks.entries.take(6)) entry.key: entry.value},
      drivers: ['Risk is current monthly pace divided by the suggested or observed category limit. Above 1 means the pace exceeds that limit.'],
    ),
    baseline(
      id: 4,
      code: 'anomaly',
      operational: anomalies.sufficient,
      metrics: {'alerts': anomalies.alerts.length},
      drivers: [
        if (anomalies.alerts.isEmpty) 'No amount is beyond three median absolute deviations.',
        for (final alert in anomalies.alerts.take(5)) '${alert.code}: ${alert.detail}',
      ],
    ),
    baseline(
      id: 5,
      code: 'subscriptions',
      operational: true,
      metrics: {
        'count': subscriptions.length,
        'yearly_increase': subscriptions.where((item) => item.priceIncreased).fold<num>(0, (sum, item) => sum + (item.lastAmount - item.typicalAmount) * 12),
        'interval_clusters': density,
      },
      drivers: ['Cadence is the median gap. A price increase is the latest charge above 105% of the earlier median. Interval clusters use one-dimensional DBSCAN.'],
    ),
    baseline(
      id: 6,
      code: 'behavior',
      operational: behavior.sufficient,
      metrics: {
        'weekend_share': behavior.weekendShare,
        'month_change': behavior.monthChange,
        'clusters': clusters.toSet().length,
        for (var i = 0; i < 7; i++) 'weekday_$i': byWeekday[i],
      },
      drivers: ['Weekday totals are sums of expenses. Two amount clusters are one-dimensional k-means when at least six expenses exist.'],
    ),
    baseline(
      id: 7,
      code: 'scenarios',
      operational: monthlyIncome > 0 || monthlyExpense > 0,
      method: 'educational_simulation',
      metrics: {
        'income_loss_p10': _percentile(lossSims, 0.1),
        'income_loss_p50': _percentile(lossSims, 0.5),
        'rent_increase_p50': _percentile(rentSims, 0.5),
        'emergency_gap': 1000 - (surplus < 0 ? 0 : surplus),
        'cut_15': monthlyExpense * 0.15,
      },
      drivers: ['Income-loss paths keep 50% to 100% of observed income. Rent paths add up to 20% of essentials. A 1,000 emergency and a 15% spending cut are arithmetic.'],
    ),
    baseline(
      id: 8,
      code: 'budget_recommendation',
      operational: byCategory.isNotEmpty && monthlyIncome > 0,
      metrics: {
        for (final entry in byCategory.entries.take(6)) entry.key: (entry.value / months) * (surplus < 0 ? 0.9 : 1.0),
      },
      drivers: ['A category limit starts from its observed monthly average and is reduced 10% when surplus is negative.'],
    ),
    baseline(
      id: 9,
      code: 'reduction_plan',
      operational: freed > 0,
      metrics: {'monthly_freed': freed, ...reduction},
      drivers: ['Each of the three largest categories is reduced by 10% of its own observed spend. The plan never cuts more than that spend.'],
    ),
    baseline(
      id: 10,
      code: 'stress_warning',
      operational: true,
      metrics: {
        'surplus': surplus,
        'fixed_ratio': monthlyIncome == 0 ? 1 : fixedCosts / monthlyIncome,
        'thirty_day_net': monthlyIncome - daily * 30,
      },
      drivers: [
        if (surplus < 0) 'Spending exceeds income.',
        if (monthlyIncome > 0 && fixedCosts / monthlyIncome > 0.7) 'Essentials are more than 70% of income.',
        if (monthlyIncome - daily * 30 < 0) 'The 30-day spending pace exceeds monthly income.',
      ],
    ),
    baseline(
      id: 11,
      code: 'goal_feasibility',
      operational: feasibility?.sufficient ?? false,
      method: 'educational_simulation',
      metrics: {
        'required': feasibility?.requiredMonthly ?? 0,
        'reach_rate': feasibility?.reachRate ?? 0,
        'expected': (feasibility?.expected ?? false) ? 1 : 0,
      },
      drivers: [feasibility?.assumption ?? 'A goal needs a positive gap, a deadline, and a positive surplus.'],
    ),
    baseline(
      id: 12,
      code: 'multi_goal',
      operational: compared.isNotEmpty,
      metrics: {for (final row in compared) row.name: row.assigned},
      drivers: ['Higher priority receives its required monthly amount first. Later goals receive only the surplus that remains.'],
    ),
    baseline(
      id: 13,
      code: 'contribution_schedule',
      operational: plan.recommended > 0 && cashBalance > reserve,
      metrics: {'weekly': weekly, 'monthly': plan.recommended, 'reserve': reserve},
      drivers: ['Weekly amount is the recommended month divided by four. Nothing is scheduled when cash is below a 20% reserve. No wallet is debited.'],
    ),
    baseline(
      id: 14,
      code: 'portfolio_risk',
      operational: portfolio > 0,
      method: 'educational_simulation',
      metrics: {
        'value': portfolio,
        'largest_share': largest,
        'volatility': risk.volatility ?? 0,
        ...byClass,
      },
      drivers: [risk.limitation],
    ),
    baseline(
      id: 15,
      code: 'risk_monitoring',
      operational: returns.length >= 8,
      metrics: {'ewma': ewma, 'observations': returns.length},
      drivers: ['The operational estimate is EWMA of absolute returns with lambda 0.94. GARCH is not fitted.'],
    ),
    baseline(
      id: 16,
      code: 'diversification',
      operational: portfolio > 0,
      method: 'educational_simulation',
      metrics: {'largest_share': largest, 'equal_weight': holdings.isEmpty ? 0 : 1 / holdings.length},
      drivers: ['A holding above 40% is concentrated. Equal weight is a hypothetical comparison, not an instruction to trade.'],
    ),
    baseline(
      id: 17,
      code: 'stress_test',
      operational: portfolio > 0 || cashBalance > 0,
      method: 'educational_simulation',
      metrics: {
        'market_drop_20': portfolio * 0.2,
        'inflation_5_on_cash': cashBalance * 0.05,
        'currency_drop_10': portfolio * 0.1,
      },
      drivers: ['These are stated shocks. They are not forecasts and not guaranteed losses.'],
    ),
    baseline(
      id: 18,
      code: 'replan',
      operational: primary != null,
      metrics: {
        'required_now': primary == null || primary.months < 1 ? 0 : primary.gap / primary.months,
        'covered': surplus <= 0 || primary == null ? 0 : surplus / (primary.gap / (primary.months < 1 ? 1 : primary.months)),
      },
      drivers: ['Required saving is the remaining gap divided by the months still left. It changes when the gap or the deadline changes.'],
    ),
    baseline(
      id: 19,
      code: 'attribution',
      operational: holdings.isNotEmpty,
      metrics: {for (final holding in holdings) holding.label: holding.gain, 'total_gain': gain},
      drivers: ['Each figure is the asset gain stored from manual prices and trades. SHAP is not applied because no predictive model is loaded.'],
    ),
    baseline(
      id: 20,
      code: 'wealth_projection',
      operational: true,
      method: 'educational_simulation',
      metrics: {'low_10y': lowWealth, 'mid_10y': midWealth, 'high_10y': highWealth},
      drivers: ['Ten-year paths use 0%, 2.4%, and about 6% compounded hypothetical yearly returns. They are not guaranteed.'],
    ),
    baseline(id: 21, code: 'orchestration', operational: true, metrics: {'tools': 4}, drivers: ['Allowlisted tools: cash flow, overrun, goal plan, scenario. No free SQL.']),
    baseline(id: 22, code: 'nl_operations', operational: true, metrics: {'drafts': 1}, drivers: ['A sentence with an amount becomes a draft. It is not saved.']),
    baseline(id: 23, code: 'reasoning', operational: enough, metrics: {'income': monthlyIncome, 'expense': monthlyExpense, 'surplus': surplus}, drivers: ['Answers use these recorded totals only.']),
    baseline(id: 24, code: 'explainable', operational: true, metrics: {'drivers': 30}, drivers: ['Every card lists the arithmetic that produced its numbers.']),
    baseline(
      id: 25,
      code: 'proactive',
      operational: anomalies.alerts.isNotEmpty || surplus < 0,
      metrics: {'alerts': anomalies.alerts.length + (surplus < 0 ? 1 : 0)},
      drivers: ['Alerts appear only when the anomaly rule or the negative surplus rule matches.'],
    ),
    baseline(id: 26, code: 'scenario_chat', operational: true, method: 'educational_simulation', metrics: {'scenarios': 4}, drivers: ['Salary, rent, emergency, and spending-cut questions call the same scenario numbers.']),
    baseline(id: 27, code: 'documents', operational: true, metrics: {'kinds': 3}, drivers: ['OCR labels receipt, invoice, or statement, then opens the existing confirmation screen.']),
    baseline(
      id: 28,
      code: 'reports',
      operational: spends.isNotEmpty,
      metrics: {'income': income, 'expense': expense, 'net': income - expense},
      drivers: ['Weekly and monthly totals are sums of recorded income and expenses. Narrative text must repeat these numbers.'],
    ),
    baseline(id: 29, code: 'voice', operational: true, metrics: {'languages': 3}, drivers: ['French, English, and Arabic use the device speech engines. A missing engine is reported and nothing is saved from voice.']),
    baseline(id: 30, code: 'human_loop', operational: true, metrics: {'auto_execute': 0}, drivers: ['Prepared actions stay unexecuted until the confirmation button. Retries reuse the same client request id.']),
  ];
}

FinancialIntent parseFinancialIntent(String raw) {
  final text = raw.trim();
  final lower = text.toLowerCase();
  final amountMatch = RegExp(r'(\d+(?:[.,]\d{1,3})?)').firstMatch(lower);
  final amount = amountMatch == null ? null : num.tryParse(amountMatch.group(1)!.replaceAll(',', '.'));
  if (RegExp(r'what if|si je|ماذا لو|salary|salaire|loyer|rent|urgence|emergency').hasMatch(lower)) {
    final scenario = RegExp(r'rent|loyer').hasMatch(lower)
        ? 'rent'
        : RegExp(r'emergency|urgence').hasMatch(lower)
            ? 'emergency'
            : RegExp(r'rédui|redui|cut|baisse').hasMatch(lower)
                ? 'cut'
                : 'income_loss';
    return FinancialIntent(kind: 'scenario', scenario: scenario, draftAmount: amount, action: PreparedAction(kind: 'scenario', summary: scenario, requiresConfirmation: true, executesImmediately: false));
  }
  if (RegExp(r'budget').hasMatch(lower) && amount != null) {
    return FinancialIntent(
      kind: 'budget_draft',
      draftAmount: amount,
      action: PreparedAction(kind: 'create_budget', summary: 'Monthly budget $amount', requiresConfirmation: true, executesImmediately: false),
    );
  }
  if (RegExp(r'objectif|goal|هدف').hasMatch(lower) && amount != null) {
    return FinancialIntent(
      kind: 'goal_draft',
      draftAmount: amount,
      action: PreparedAction(kind: 'create_goal', summary: 'Goal $amount', requiresConfirmation: true, executesImmediately: false),
    );
  }
  if (amount != null && RegExp(r'paid|payé|paye|spent|dépens|دفعت|bought').hasMatch(lower)) {
    return FinancialIntent(
      kind: 'transaction_draft',
      draftAmount: amount,
      action: PreparedAction(kind: 'create_transaction', summary: text, requiresConfirmation: true, executesImmediately: false),
    );
  }
  return const FinancialIntent(kind: 'question');
}

String studioTitle(String language, String code) {
  final ar = language.startsWith('ar');
  final fr = language.startsWith('fr');
  const en = {
    'budget_optimization': 'Budget optimization',
    'cash_flow': 'Cash flow, 7 / 30 / 90 days',
    'overrun_risk': 'Overrun risk',
    'anomaly': 'Spending anomalies',
    'subscriptions': 'Subscription costs',
    'behavior': 'Spending patterns',
    'scenarios': 'Financial scenarios',
    'budget_recommendation': 'Budget recommendations',
    'reduction_plan': 'Expense reduction',
    'stress_warning': 'Financial stress',
    'goal_feasibility': 'Goal feasibility',
    'multi_goal': 'Several goals',
    'contribution_schedule': 'Savings schedule',
    'portfolio_risk': 'Portfolio risk',
    'risk_monitoring': 'Risk monitoring',
    'diversification': 'Diversification',
    'stress_test': 'Stress test',
    'replan': 'Goal replan',
    'attribution': 'Performance attribution',
    'wealth_projection': 'Wealth projection',
    'orchestration': 'Task orchestration',
    'nl_operations': 'Natural language drafts',
    'reasoning': 'Financial reasoning',
    'explainable': 'Explainable figures',
    'proactive': 'Proactive alerts',
    'scenario_chat': 'Scenario conversation',
    'documents': 'Documents',
    'reports': 'Financial report',
    'voice': 'Voice',
    'human_loop': 'Confirmation before action',
  };
  const frMap = {
    'budget_optimization': 'Optimisation du budget',
    'cash_flow': 'Trésorerie, 7 / 30 / 90 jours',
    'overrun_risk': 'Risque de dépassement',
    'anomaly': 'Dépenses inhabituelles',
    'subscriptions': 'Coût des abonnements',
    'behavior': 'Habitudes de dépense',
    'scenarios': 'Scénarios financiers',
    'budget_recommendation': 'Budgets recommandés',
    'reduction_plan': 'Plan de réduction',
    'stress_warning': 'Tension financière',
    'goal_feasibility': 'Faisabilité des objectifs',
    'multi_goal': 'Plusieurs objectifs',
    'contribution_schedule': 'Calendrier d’épargne',
    'portfolio_risk': 'Risque du portefeuille',
    'risk_monitoring': 'Suivi du risque',
    'diversification': 'Diversification',
    'stress_test': 'Test de résistance',
    'replan': 'Recalcul de l’objectif',
    'attribution': 'Attribution de performance',
    'wealth_projection': 'Projection de patrimoine',
    'orchestration': 'Orchestration des tâches',
    'nl_operations': 'Brouillons en langage naturel',
    'reasoning': 'Raisonnement financier',
    'explainable': 'Chiffres expliqués',
    'proactive': 'Alertes proactives',
    'scenario_chat': 'Conversation de scénario',
    'documents': 'Documents',
    'reports': 'Rapport financier',
    'voice': 'Voix',
    'human_loop': 'Confirmation avant action',
  };
  const arMap = {
    'budget_optimization': 'تحسين الميزانية',
    'cash_flow': 'التدفق النقدي، 7 / 30 / 90 يومًا',
    'overrun_risk': 'خطر تجاوز الميزانية',
    'anomaly': 'مصروفات غير معتادة',
    'subscriptions': 'تكلفة الاشتراكات',
    'behavior': 'أنماط الإنفاق',
    'scenarios': 'سيناريوهات مالية',
    'budget_recommendation': 'ميزانيات مقترحة',
    'reduction_plan': 'خطة خفض المصروفات',
    'stress_warning': 'ضغط مالي',
    'goal_feasibility': 'إمكانية تحقيق الهدف',
    'multi_goal': 'عدة أهداف',
    'contribution_schedule': 'جدول الادخار',
    'portfolio_risk': 'مخاطر المحفظة',
    'risk_monitoring': 'مراقبة المخاطر',
    'diversification': 'التنويع',
    'stress_test': 'اختبار الضغط',
    'replan': 'إعادة تخطيط الهدف',
    'attribution': 'عزو الأداء',
    'wealth_projection': 'توقع الثروة',
    'orchestration': 'تنسيق المهام',
    'nl_operations': 'مسودات باللغة الطبيعية',
    'reasoning': 'استدلال مالي',
    'explainable': 'أرقام مفسرة',
    'proactive': 'تنبيهات استباقية',
    'scenario_chat': 'محادثة السيناريو',
    'documents': 'المستندات',
    'reports': 'تقرير مالي',
    'voice': 'الصوت',
    'human_loop': 'تأكيد قبل التنفيذ',
  };
  final map = ar ? arMap : fr ? frMap : en;
  return map[code] ?? code;
}

String scenarioNarrative(List<FeatureResult> results, String scenario, String currency) {
  final card = results.where((result) => result.code == 'scenarios').firstOrNull;
  if (card == null || !card.operational) return 'Not enough recorded cash flow for this scenario.';
  final key = switch (scenario) {
    'rent' => 'rent_increase_p50',
    'emergency' => 'emergency_gap',
    'cut' => 'cut_15',
    _ => 'income_loss_p50',
  };
  final value = card.metrics[key] ?? 0;
  return '$scenario: ${value.toStringAsFixed(3)} $currency. ${card.drivers.first}';
}
