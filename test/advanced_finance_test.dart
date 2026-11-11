import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/intelligence/domain/advanced_finance.dart';

TxnObs spend({
  required String id,
  required DateTime date,
  required num amount,
  String merchant = 'Carrefour',
  String category = 'Food',
  String type = 'EXPENSE',
}) {
  return TxnObs(
    id: id,
    date: date,
    type: type,
    amount: amount,
    currency: 'TND',
    merchant: merchant,
    category: category,
  );
}

void main() {
  test('anomaly detection stays explainable and never blocks', () {
    final rows = [
      for (var i = 0; i < 10; i++)
        spend(id: 'n$i', date: DateTime(2026, 9, i + 1), amount: 20),
      spend(id: 'big', date: DateTime(2026, 9, 20), amount: 900),
      spend(id: 'dup1', date: DateTime(2026, 9, 21), amount: 30, merchant: 'Netflix'),
      spend(id: 'dup2', date: DateTime(2026, 9, 21), amount: 30, merchant: 'Netflix'),
    ];
    final report = detectAnomalies(rows, now: DateTime(2026, 9, 22));
    expect(report.sufficient, isTrue);
    expect(report.alerts.any((alert) => alert.code == 'high_expense'), isTrue);
    expect(report.alerts.any((alert) => alert.code == 'duplicate_payment'), isTrue);
    expect(report.alerts.every((alert) => alert.blocksTransaction == false), isTrue);
  });

  test('subscriptions detect a monthly price increase and ignore one-off merchants', () {
    final rows = [
      spend(id: '1', date: DateTime(2026, 8, 5), amount: 29.9, merchant: 'Netflix', category: 'Entertainment'),
      spend(id: '2', date: DateTime(2026, 9, 5), amount: 29.9, merchant: 'Netflix', category: 'Entertainment'),
      spend(id: '3', date: DateTime(2026, 10, 5), amount: 34.9, merchant: 'Netflix', category: 'Entertainment'),
      spend(id: 'once', date: DateTime(2026, 10, 2), amount: 80, merchant: 'Shell', category: 'Transport'),
    ];
    final hits = detectSubscriptions(rows, now: DateTime(2026, 10, 6));
    expect(hits, hasLength(1));
    expect(hits.single.cadence, 'monthly');
    expect(hits.single.priceIncreased, isTrue);
    expect(hits.single.inactive, isFalse);
    expect(hits.single.nextDate, isNotNull);
  });

  test('reconciliation matches amount, date, and merchant and flags a duplicate receipt', () {
    final result = reconcile(
      [
        Claim(id: 'r1', amount: 42, currency: 'TND', merchant: 'Carrefour market', date: DateTime(2026, 11, 2)),
        Claim(id: 'r2', amount: 42, currency: 'TND', merchant: 'Carrefour market', date: DateTime(2026, 11, 2)),
      ],
      [
        Claim(id: 't1', amount: 42, currency: 'TND', merchant: 'Carrefour', date: DateTime(2026, 11, 2)),
      ],
    );
    expect(result.matches, hasLength(1));
    expect(result.matches.single.transactionId, 't1');
    expect(result.duplicateReceipts, isNotEmpty);
    expect(result.unmatchedReceipts, isNotEmpty);
  });

  test('forecast and overspend use a transparent daily baseline', () {
    final now = DateTime(2026, 11, 10);
    final rows = [
      for (var day = 1; day <= 10; day++)
        spend(id: 'd$day', date: DateTime(2026, 11, day), amount: 10, category: 'Food'),
    ];
    final forecast = forecastSpending(rows, now: now, category: 'Food');
    expect(forecast.sufficient, isTrue);
    expect(forecast.next7, greaterThan(0));
    final risks = overspendRisks(
      budgets: [(name: 'Food', spent: 100, limit: 120)],
      now: now,
      sampleCount: 10,
    );
    expect(risks.single.level, 'high');
    expect(risks.single.overBy, greaterThan(0));
    expect(risks.single.dailyLimit, greaterThanOrEqualTo(0));
  });

  test('allocation never assigns savings beyond the surplus', () {
    final rows = [
      spend(id: 'in', date: DateTime(2026, 10, 1), amount: 1000, type: 'INCOME', merchant: 'Employeur', category: 'Income'),
      spend(id: 'food', date: DateTime(2026, 10, 2), amount: 200, category: 'Food'),
      spend(id: 'home', date: DateTime(2026, 10, 3), amount: 300, category: 'Housing'),
    ];
    final plan = suggestAllocation(rows, now: DateTime(2026, 11, 10), currency: 'TND');
    expect(plan.sufficient, isTrue);
    expect(plan.surplus, 500);
    final savings = plan.lines.firstWhere((line) => line.name == 'Savings').amount;
    expect(savings, lessThanOrEqualTo(plan.surplus));
  });

  test('goal scenarios and comparison stay inside the available surplus', () {
    final scenario = goalFeasibility(gap: 3000, months: 6, monthlySurplus: 400);
    expect(scenario.sufficient, isTrue);
    expect(scenario.requiredMonthly, closeTo(500, 0.001));
    expect(scenario.expected, isFalse);
    expect(scenario.assumption, contains('surplus'));
    final plan = planSavings(gap: 3000, months: 6, monthlySurplus: 400, cashBalance: 1000, currency: 'TND');
    expect(plan.movesMoney, isFalse);
    expect(plan.recommended, 400);
    final compared = compareGoals(
      monthlySurplus: 400,
      goals: [
        (name: 'Laptop', gap: 1200, months: 6, priority: 1),
        (name: 'Car', gap: 40000, months: 24, priority: 2),
      ],
    );
    expect(compared.first.feasible, isTrue);
    expect(compared.last.assigned, lessThanOrEqualTo(400));
  });

  test('risk shocks are labeled and volatility waits for a price series', () {
    final thin = portfolioRisk(value: 885, largestShare: 0.36, prices: [9, 9.2]);
    expect(thin.volatilityKnown, isFalse);
    expect(thin.loss10, closeTo(88.5, 0.001));
    final series = portfolioRisk(value: 1000, largestShare: 0.5, prices: [10, 11, 9, 12, 10, 13]);
    expect(series.volatilityKnown, isTrue);
    expect(series.concentrated, isTrue);
    expect(series.limitation, contains('advice'));
  });

  test('split and balance checks reject inconsistent money', () {
    expect(checkSplit(total: 30, parts: [10, 20]).valid, isTrue);
    expect(checkSplit(total: 30, parts: [10, 15]).valid, isFalse);
    final checks = checkBalances(
      wallets: [
        (name: 'Card', type: 'CREDIT_CARD', initial: 0, current: -100, creditLimit: 2000, available: 1900),
        (name: 'Broken', type: 'CREDIT_CARD', initial: 0, current: -100, creditLimit: 2000, available: 500),
      ],
      movementSizes: const [10, 12, 11, 9, 13],
    );
    expect(checks.first.consistent, isTrue);
    expect(checks.last.consistent, isFalse);
  });

  test('a short history refuses a forecast instead of inventing one', () {
    final forecast = forecastSpending(
      [spend(id: '1', date: DateTime(2026, 11, 1), amount: 10)],
      now: DateTime(2026, 11, 10),
    );
    expect(forecast.sufficient, isFalse);
    final anomalies = detectAnomalies([spend(id: '1', date: DateTime(2026, 11, 1), amount: 10)]);
    expect(anomalies.sufficient, isFalse);
  });
}
