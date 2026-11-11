import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/planning/domain/budget_math.dart';
import 'package:wallet_app/features/planning/domain/finance_answers.dart';
import 'package:wallet_app/features/planning/domain/forecast_math.dart';
import 'package:wallet_app/features/planning/domain/goal_math.dart';
import 'package:wallet_app/features/planning/domain/investment_math.dart';
import 'package:wallet_app/features/planning/domain/nl_transaction.dart';
import 'package:wallet_app/features/planning/domain/spend_rules.dart';
import 'package:wallet_app/features/planning/domain/what_if.dart';

void main() {
  final now = DateTime(2026, 10, 15);

  SpendEvent expense({
    required num amount,
    String type = 'EXPENSE',
    String status = 'POSTED',
    String currency = 'TND',
    String? categoryId,
    DateTime? date,
  }) {
    return SpendEvent(
      date: date ?? now,
      type: type,
      status: status,
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      categoryName: categoryId,
    );
  }

  test('budget spending ignores transfers, refunds, voids, and other currencies', () {
    final events = [
      expense(amount: 780),
      expense(amount: 50, type: 'TRANSFER'),
      expense(amount: 20, type: 'REFUND'),
      expense(amount: 30, status: 'VOIDED'),
      expense(amount: 100, currency: 'EUR'),
      expense(amount: 10, type: 'PAYMENT', categoryId: 'food'),
    ];
    final rollup = rollupBudgets(
      [
        const BudgetSpec(id: 'overall', name: 'Month', period: 'monthly', currency: 'TND', limit: 1000),
        const BudgetSpec(
          id: 'food',
          name: 'Food',
          period: 'monthly',
          currency: 'TND',
          limit: 250,
          categoryId: 'food',
        ),
      ],
      events,
      now,
    );
    expect(rollup.overall.single.spent, 790);
    expect(rollup.overall.single.remaining, 210);
    expect(rollup.categories.single.spent, 10);
    expect(rollup.overall.single.crossedThresholds, containsAll([50]));
    expect(rollup.overall.single.crossedThresholds, isNot(contains(80)));
  });

  test('forecast needs history and projects the month', () {
    expect(
      forecastMonth(spentSoFar: 100, now: DateTime(2026, 10, 2), limit: 1000, sampleCount: 4).sufficient,
      isFalse,
    );
    final forecast = forecastMonth(
      spentSoFar: 300,
      now: DateTime(2026, 10, 10),
      limit: 500,
      sampleCount: 4,
    );
    expect(forecast.sufficient, isTrue);
    expect(forecast.projected, 930);
    expect(forecast.mayExceed, isTrue);
  });

  test('what-if savings and category cuts use actual amounts', () {
    final result = simulateSavings(monthlyReduction: 100, months: 12, currency: 'TND');
    expect(result.savings, 1200);
    final cuts = suggestCuts(
      currency: 'TND',
      spends: const [
        CategorySpend(name: 'Shopping', amount: 200, currency: 'TND'),
        CategorySpend(name: 'Restaurants', amount: 100, currency: 'EUR'),
      ],
      rates: const {'Shopping': 0.15, 'Restaurants': 0.10},
    );
    expect(cuts.monthlyFreed, 30);
  });

  test('goal progress and required monthly savings', () {
    final goal = GoalSnapshot(
      target: 40000,
      saved: 0,
      now: DateTime(2026, 1, 1),
      targetDate: DateTime(2028, 1, 1),
    );
    expect(goal.percent, 0);
    expect(requiredMonthly(goal), closeTo(40000 / 24, 0.01));
    final started = GoalSnapshot(
      target: 3500,
      saved: 2100,
      now: DateTime(2026, 6, 1),
      targetDate: DateTime(2026, 12, 1),
    );
    expect(started.percent, 60);
    expect(requiredMonthly(started), closeTo(1400 / 6, 0.01));
  });

  test('investment cost basis, sell guard, and allocation', () {
    final bought = Trade(side: 'buy', quantity: 2, unitPrice: 100, date: DateTime(2026, 1, 1));
    final position = applyTrades([bought]);
    expect(position.costBasis, 200);
    expect(unrealizedGain(position, 130), 60);
    final sold = applyTrades([
      bought,
      Trade(side: 'sell', quantity: 1, unitPrice: 150, date: DateTime(2026, 2, 1)),
    ]);
    expect(sold.realized, 50);
    expect(sold.quantity, 1);
    final rejected = applyTrades([
      Trade(side: 'buy', quantity: 1, unitPrice: 10, date: DateTime(2026, 1, 1)),
      Trade(side: 'sell', quantity: 2, unitPrice: 10, date: DateTime(2026, 2, 1)),
    ]);
    expect(rejected.rejected, isTrue);
    final allocation = allocate(
      currency: 'TND',
      holdings: const [
        (label: 'A', value: 80),
        (label: 'B', value: 20),
      ],
    );
    expect(allocation.concentrated, isTrue);
    expect(allocation.slices.first.share, 0.8);
  });

  test('natural language draft is not a saved transaction', () {
    final draft = parseNaturalTransaction(
      'I paid 45 dinars at a restaurant yesterday',
      now: DateTime(2026, 10, 15),
    );
    expect(draft, isNotNull);
    expect(draft!.amount, 45);
    expect(draft.currency, 'TND');
    expect(draft.type, 'EXPENSE');
    expect(draft.categoryHint, 'Restaurants');
    expect(draft.date, DateTime(2026, 10, 14));
  });

  test('assistant answers only from supplied facts', () {
    const empty = FinanceFacts(
      spentThisMonth: null,
      largestCategory: null,
      largestCategoryAmount: null,
      currency: 'TND',
      previousWeekSpent: null,
      thisWeekSpent: null,
      weekComparable: false,
    );
    final missing = answerQuestion('How much did I spend this month?', empty, language: 'en');
    expect(missing.answered, isFalse);
    expect(missing.text.contains('780'), isFalse);

    const facts = FinanceFacts(
      spentThisMonth: 780,
      largestCategory: 'Food',
      largestCategoryAmount: 250,
      currency: 'TND',
      previousWeekSpent: 100,
      thisWeekSpent: 92,
      weekComparable: true,
    );
    final answer = answerQuestion('How much did I spend this month?', facts, language: 'en');
    expect(answer.text, contains('780.000 TND'));
    expect(answer.text, contains('Food'));
    expect(narrativeMatchesFacts('You spent 999.000 TND', facts), isFalse);
    expect(narrativeMatchesFacts(answer.text, facts), isTrue);
  });
}
