class SpendForecast {
  const SpendForecast({
    required this.sufficient,
    this.projected,
    this.overBy,
    this.sampleCount = 0,
  });

  final bool sufficient;
  final num? projected;
  final num? overBy;
  final int sampleCount;

  bool get mayExceed => sufficient && (overBy ?? 0) > 0;
}

int daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

/// Spending velocity for the current month. Fewer than three elapsed days
/// or fewer than two real expenses is not enough to forecast.
SpendForecast forecastMonth({
  required num spentSoFar,
  required DateTime now,
  required num limit,
  required int sampleCount,
}) {
  final elapsed = now.day;
  if (sampleCount < 2 || elapsed < 3) {
    return SpendForecast(sufficient: false, sampleCount: sampleCount);
  }
  final projected = spentSoFar / elapsed * daysInMonth(now);
  final gap = projected - limit;
  return SpendForecast(
    sufficient: true,
    projected: projected,
    overBy: gap > 0 ? gap : 0,
    sampleCount: sampleCount,
  );
}

int spendingSamples(
  Iterable<DateTime> dates, {
  required DateTime month,
  required bool Function(DateTime date) include,
}) {
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  var count = 0;
  for (final date in dates) {
    if (!include(date)) continue;
    if (!date.isBefore(start) && date.isBefore(end)) count++;
  }
  return count;
}

class WeekdaySplit {
  const WeekdaySplit({required this.weekday, required this.weekend});

  final num weekday;
  final num weekend;
}

WeekdaySplit weekdaySplit(Iterable<({DateTime date, num amount})> rows) {
  num weekday = 0;
  num weekend = 0;
  for (final row in rows) {
    final day = row.date.weekday;
    if (day == DateTime.saturday || day == DateTime.sunday) {
      weekend += row.amount;
    } else {
      weekday += row.amount;
    }
  }
  return WeekdaySplit(weekday: weekday, weekend: weekend);
}
