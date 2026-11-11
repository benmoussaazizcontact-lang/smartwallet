import '../../../core/utils/money.dart';
import 'advanced_finance.dart';

/// Rows ready for the signed-in user's insight tables.
/// The caller supplies [userId]; this never reads another account.
class InsightSnapshot {
  const InsightSnapshot({
    required this.userId,
    required this.forecasts,
    required this.anomalies,
    required this.subscriptions,
    required this.allocations,
    required this.report,
  });

  final String userId;
  final List<Map<String, dynamic>> forecasts;
  final List<Map<String, dynamic>> anomalies;
  final List<Map<String, dynamic>> subscriptions;
  final List<Map<String, dynamic>> allocations;
  final Map<String, dynamic>? report;

  bool get ownsEveryRow {
    final rows = [...forecasts, ...anomalies, ...subscriptions, ...allocations, ?report];
    return rows.every((row) => row['user_id'] == userId);
  }
}

InsightSnapshot buildInsightSnapshot({
  required String userId,
  required List<TxnObs> rows,
  required DateTime now,
  required String currency,
}) {
  final forecast = forecastSpending(rows, now: now);
  final anomalies = detectAnomalies(rows, now: now);
  final subscriptions = detectSubscriptions(rows, now: now);
  final allocation = suggestAllocation(rows, now: now, currency: currency);
  final monthStart = DateTime(now.year, now.month);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  final report = reportFor(rows, start: monthStart, end: DateTime(now.year, now.month + 1), currency: currency);
  String day(DateTime value) => value.toIso8601String().substring(0, 10);

  return InsightSnapshot(
    userId: userId,
    forecasts: forecast.sufficient
        ? [
            {
              'user_id': userId,
              'currency': currency,
              'horizon_days': 7,
              'amount': Money.round3(forecast.next7),
              'uncertainty': Money.round3(forecast.uncertainty30),
              'sample_count': forecast.sampleCount,
            },
            {
              'user_id': userId,
              'currency': currency,
              'horizon_days': 30,
              'amount': Money.round3(forecast.next30),
              'uncertainty': Money.round3(forecast.uncertainty30),
              'sample_count': forecast.sampleCount,
            },
          ]
        : const [],
    anomalies: [
      for (final alert in anomalies.alerts)
        {
          'user_id': userId,
          'transaction_id': alert.transactionId,
          'code': alert.code,
          'severity': alert.severity,
          'detail': alert.detail,
          'blocks_transaction': false,
        },
    ],
    subscriptions: [
      for (final hit in subscriptions)
        if (hit.typicalAmount > 0 && hit.lastAmount > 0)
          {
            'user_id': userId,
            'merchant': hit.name,
            'currency': hit.currency,
            'cadence': hit.cadence,
            'typical_amount': Money.round3(hit.typicalAmount),
            'last_amount': Money.round3(hit.lastAmount),
            'last_paid_on': day(hit.lastDate),
            'inactive': hit.inactive,
            'price_increased': hit.priceIncreased,
          },
    ],
    allocations: [
      for (final line in allocation.lines)
        if (line.amount >= 0)
          {
            'user_id': userId,
            'category_name': line.name,
            'currency': currency,
            'amount': Money.round3(line.amount),
            'note': line.note,
          },
    ],
    report: {
      'user_id': userId,
      'period_start': day(monthStart),
      'period_end': day(monthEnd),
      'currency': currency,
      'income': Money.round3(report.income),
      'expense': Money.round3(report.expense),
    },
  );
}
