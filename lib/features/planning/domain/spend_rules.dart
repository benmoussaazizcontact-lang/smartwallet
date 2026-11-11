class SpendEvent {
  const SpendEvent({
    required this.date,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.categoryName,
    this.merchant,
    this.template = false,
  });

  final DateTime date;
  final String type;
  final String status;
  final num amount;
  final String currency;
  final String? categoryId;
  final String? categoryName;
  final String? merchant;
  final bool template;
}

/// Expenses that consume a budget. Transfers, refunds, income, voided rows,
/// and recurring templates are excluded so they are not double-counted.
bool countsAsSpending(SpendEvent event) {
  if (event.template || event.status == 'VOIDED') return false;
  return event.type == 'EXPENSE' || event.type == 'PAYMENT';
}

/// Money received. Incoming transfers and refunds are not income.
bool countsAsIncome(SpendEvent event) {
  if (event.template || event.status == 'VOIDED') return false;
  return event.type == 'INCOME';
}

class PeriodWindow {
  const PeriodWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

PeriodWindow periodWindow(String period, DateTime now) {
  if (period == 'weekly') {
    final day = _dateOnly(now);
    final start = day.subtract(Duration(days: day.weekday - 1));
    return PeriodWindow(start, start.add(const Duration(days: 7)));
  }
  final start = DateTime(now.year, now.month);
  return PeriodWindow(start, DateTime(now.year, now.month + 1));
}

PeriodWindow previousWindow(String period, DateTime now) {
  final current = periodWindow(period, now);
  if (period == 'weekly') {
    return PeriodWindow(
      current.start.subtract(const Duration(days: 7)),
      current.start,
    );
  }
  final start = DateTime(current.start.year, current.start.month - 1);
  return PeriodWindow(start, current.start);
}

num _sum(
  Iterable<SpendEvent> events, {
  required PeriodWindow window,
  required String currency,
  required bool Function(SpendEvent event) include,
  String? categoryId,
}) {
  num total = 0;
  for (final event in events) {
    if (!include(event)) continue;
    if (event.currency != currency) continue;
    if (!window.contains(event.date.toLocal())) continue;
    if (categoryId != null && event.categoryId != categoryId) continue;
    total += event.amount;
  }
  return (total * 1000).round() / 1000;
}

num sumSpending(
  Iterable<SpendEvent> events, {
  required PeriodWindow window,
  required String currency,
  String? categoryId,
}) {
  return _sum(
    events,
    window: window,
    currency: currency,
    include: countsAsSpending,
    categoryId: categoryId,
  );
}

num sumIncome(
  Iterable<SpendEvent> events, {
  required PeriodWindow window,
  required String currency,
}) {
  return _sum(events, window: window, currency: currency, include: countsAsIncome);
}

/// One currency, one half-open month, the same rows on every screen.
class MonthCashflow {
  const MonthCashflow({
    required this.currency,
    required this.window,
    required this.income,
    required this.expense,
  });

  final String currency;
  final PeriodWindow window;
  final num income;
  final num expense;
}

MonthCashflow monthCashflow(
  Iterable<SpendEvent> events, {
  required DateTime now,
  required String currency,
}) {
  final window = periodWindow('monthly', now);
  return MonthCashflow(
    currency: currency,
    window: window,
    income: sumIncome(events, window: window, currency: currency),
    expense: sumSpending(events, window: window, currency: currency),
  );
}
