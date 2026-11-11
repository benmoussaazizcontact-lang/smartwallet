import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/intelligence/domain/advanced_finance.dart';
import 'package:wallet_app/features/intelligence/domain/model_status.dart';
import 'package:wallet_app/features/intelligence/domain/insight_snapshot.dart';
import 'package:wallet_app/features/intelligence/domain/studio.dart';
import 'package:wallet_app/features/receipts/services/ocr_parser.dart';

TxnObs row(String id, DateTime date, num amount, {String type = 'EXPENSE', String category = 'Food', String merchant = 'Shop'}) {
  return TxnObs(id: id, date: date, type: type, amount: amount, currency: 'TND', category: category, merchant: merchant);
}

void main() {
  test('studio returns 30 labeled baselines and never a trained model', () {
    final now = DateTime(2026, 11, 10);
    final rows = [
      for (var day = 1; day <= 12; day++) row('e$day', DateTime(2026, 10, day), 40, category: day.isEven ? 'Food' : 'Transport'),
      row('in', DateTime(2026, 10, 1), 2000, type: 'INCOME', category: 'Income', merchant: 'Employeur'),
      row('net1', DateTime(2026, 8, 5), 30, merchant: 'Netflix', category: 'Entertainment'),
      row('net2', DateTime(2026, 9, 5), 30, merchant: 'Netflix', category: 'Entertainment'),
      row('net3', DateTime(2026, 10, 5), 36, merchant: 'Netflix', category: 'Entertainment'),
    ];
    final results = buildStudio(
      rows: rows,
      now: now,
      currency: 'TND',
      cashBalance: 800,
      goals: const [StudioGoal(name: 'Laptop', gap: 1500, months: 6, priority: 1)],
      holdings: const [StudioHolding(label: 'DEMO', assetClass: 'etf', value: 300, gain: 20, prices: [10, 11, 9, 12, 10, 13, 12, 14, 13])],
    );
    expect(results, hasLength(30));
    expect(results.map((result) => result.id).toSet(), hasLength(30));
    expect(results.every((result) => result.method != 'trained_model'), isTrue);
    expect(results.every((result) => result.drivers.any((line) => line.contains('not trained'))), isTrue);
    final reduction = results.firstWhere((result) => result.code == 'reduction_plan');
    expect(reduction.metrics['monthly_freed']!, lessThan(2000));
    final wealth = results.firstWhere((result) => result.code == 'wealth_projection');
    expect(wealth.metrics['low_10y']!, lessThan(wealth.metrics['high_10y']!));
    final loop = results.firstWhere((result) => result.code == 'human_loop');
    expect(loop.metrics['auto_execute'], 0);
    expect(studioTitle('fr', 'cash_flow'), contains('Trésorerie'));
    expect(studioTitle('ar', 'voice'), 'الصوت');
  });

  test('dbscan and k-means are deterministic groupings', () {
    expect(dbscan1d([1, 1.2, 1.1, 20], eps: 0.5).first.length, 3);
    expect(kMeans1d([1, 1, 1, 1, 9, 9, 9, 9]).toSet(), {0, 1});
  });

  test('intents prepare actions and do not execute them', () {
    final budget = parseFinancialIntent('Set a budget of 400 TND');
    expect(budget.kind, 'budget_draft');
    expect(budget.action!.executesImmediately, isFalse);
    expect(budget.action!.requiresConfirmation, isTrue);
    final scenario = parseFinancialIntent('What if my salary drops');
    expect(scenario.kind, 'scenario');
    expect(scenario.scenario, 'income_loss');
    expect(parseFinancialIntent('How much did I spend').kind, 'question');
  });

  test('insight snapshot stays on the supplied account and never blocks', () {
    final now = DateTime(2026, 11, 10);
    final rows = [
      for (var day = 1; day <= 8; day++) row('e$day', DateTime(2026, 11, day), 25),
      row('in', DateTime(2026, 10, 2), 900, type: 'INCOME', category: 'Income', merchant: 'Employeur'),
      row('net1', DateTime(2026, 9, 5), 30, merchant: 'Netflix', category: 'Entertainment'),
      row('net2', DateTime(2026, 10, 5), 30, merchant: 'Netflix', category: 'Entertainment'),
      row('net3', DateTime(2026, 11, 5), 36, merchant: 'Netflix', category: 'Entertainment'),
    ];
    final snapshot = buildInsightSnapshot(userId: 'account-a', rows: rows, now: now, currency: 'TND');
    expect(snapshot.ownsEveryRow, isTrue);
    expect(snapshot.forecasts.map((item) => item['horizon_days']), [7, 30]);
    expect(snapshot.anomalies.every((item) => item['blocks_transaction'] == false), isTrue);
    expect(snapshot.subscriptions.every((item) => item['user_id'] == 'account-a'), isTrue);
    expect(snapshot.report!['user_id'], 'account-a');
    expect(snapshot.report!['expense'], greaterThan(0));
  });

  test('a missing or unsafe model response stays off the trained path', () {
    expect(modelServiceLabel(null), 'awaiting_deployment');
    expect(modelServiceLabel({'status': 'experimental', 'executed': false}), 'experimental');
    expect(modelServiceLabel({'status': 'experimental', 'executed': true}), 'refused');
    expect(modelServiceLabel({'blocks_transaction': true}), 'refused');
    expect(modelServiceLabel({'status': 'made_up'}), 'statistical_baseline');
    final trained = modelServiceReport('expense', {
      'status': 'experimental',
      'model': 'lightgbm',
      'version': '0.1.0-synthetic',
      'real_world_validated': false,
      'executed': false,
    });
    expect(trained.status, 'experimental');
    expect(trained.model, 'lightgbm');
    expect(trained.version, '0.1.0-synthetic');
    expect(trained.realWorldValidated, isFalse);
    expect(trained.summary, contains('real_world_validated: false'));
    final shortHistory = modelServiceReport('cashflow', {
      'status': 'statistical_baseline',
      'reason': 'insufficient_history',
      'real_world_validated': false,
    });
    expect(shortHistory.reason, 'insufficient_history');
    expect(shortHistory.model, 'none');
    expect(modelServiceFailure('anomaly', status: 401).reason, 'authentication_required');
    expect(modelServiceFailure('anomaly', status: 503).reason, 'model_service_unavailable');
    expect(modelServiceFailure('anomaly', status: null).reason, 'network_error');
    expect(modelServiceReport('overrun', {'executed': true, 'status': 'experimental'}).status, 'refused');
  });

  test('ocr distinguishes invoice and statement without saving', () {
    expect(documentKindOf('FACTURE Carrefour\nTotal 20'), 'invoice');
    expect(documentKindOf('Relevé bancaire BIAT'), 'statement');
    expect(documentKindOf('Ticket de caisse'), 'receipt');
    expect(const OcrParser().parse('FACTURE\nTotal 20.000 TND').documentKind, 'invoice');
  });
}
