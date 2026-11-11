import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../planning/domain/goal_math.dart';
import '../../planning/repositories/goal_repository.dart';
import '../../planning/repositories/investment_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../domain/advanced_finance.dart';
import '../domain/insight_snapshot.dart';
import '../domain/model_status.dart';
import '../domain/studio.dart';
import '../repositories/insight_store.dart';
import 'insights_screen.dart';

class _PersistSnapshot extends ConsumerStatefulWidget {
  const _PersistSnapshot({required this.rows});

  final List<TxnObs> rows;

  @override
  ConsumerState<_PersistSnapshot> createState() => _PersistSnapshotState();
}

class _PersistSnapshotState extends ConsumerState<_PersistSnapshot> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      final snapshot = buildInsightSnapshot(
        userId: userId,
        rows: widget.rows,
        now: DateTime.now(),
        currency: 'TND',
      );
      try {
        await ref.read(insightStoreProvider).replaceOwn(snapshot);
      } catch (_) {
        // The screen already shows the calculated figures if storage is unavailable.
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

const modelTasks = ['expense', 'overrun', 'anomaly', 'cashflow'];

Future<ModelServiceReport> _invokeModelTask(SupabaseClient client, String task) async {
  try {
    final response = await client.functions.invoke('smartwallet-ml', body: {'task': task});
    return modelServiceReport(task, response.data);
  } on FunctionException catch (error) {
    return modelServiceFailure(task, status: error.status);
  } catch (_) {
    return modelServiceFailure(task, status: null);
  }
}

final modelServiceProvider = FutureProvider<List<ModelServiceReport>>((ref) async {
  final client = ref.watch(supabaseProvider);
  final reports = <ModelServiceReport>[];
  for (final task in modelTasks) {
    reports.add(await _invokeModelTask(client, task));
  }
  // The first call often hits a sleeping Render instance. Retry only the
  // calls that failed once the later calls have had a chance to wake it.
  for (var i = 0; i < reports.length; i++) {
    final reason = reports[i].reason;
    if (reason == 'network_error' || reason == 'model_service_unavailable') {
      reports[i] = await _invokeModelTask(client, reports[i].task);
    }
  }
  return reports;
});

class _ModelServicePanel extends StatelessWidget {
  const _ModelServicePanel({required this.reports});

  final AsyncValue<List<ModelServiceReport>> reports;

  @override
  Widget build(BuildContext context) {
    final lines = reports.when(
      data: (items) => items.map((item) => item.summary).join('\n\n'),
      loading: () {
        final code = Localizations.localeOf(context).languageCode;
        if (code == 'ar') return 'خدمة النماذج تجيب…';
        if (code == 'en') return 'The model service is responding…';
        return 'Le service de modèles répond…';
      },
      error: (error, stack) => modelServiceFailure('expense', status: null).summary,
    );
    return GlassPanel(
      child: Text(lines, key: const Key('model-service-metadata')),
    );
  }
}

class StudioScreen extends ConsumerWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = ref.watch(localeControllerProvider).languageCode;
    final tx = ref.watch(insightTransactionsProvider);
    final goals = ref.watch(goalsProvider).asData?.value ?? const <GoalRecord>[];
    final portfolios = ref.watch(portfoliosProvider).asData?.value ?? const <PortfolioView>[];
    final wallets = ref.watch(walletsProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.studioTitle)),
      body: tx.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.noPlanData)),
        data: (rows) {
          final now = DateTime.now();
          final cash = wallets
              .where((wallet) => wallet.currency == 'TND' && wallet.walletType != 'CREDIT_CARD')
              .fold<num>(0, (sum, wallet) => sum + wallet.currentBalance);
          final results = buildStudio(
            rows: rows,
            now: now,
            currency: 'TND',
            cashBalance: cash < 0 ? 0 : cash,
            goals: [
              for (final goal in goals.where((goal) => goal.status == 'active'))
                StudioGoal(
                  name: goal.name,
                  gap: goal.snapshot(now).gap,
                  months: goal.targetDate == null ? 6 : monthsRemaining(now, goal.targetDate!),
                  priority: goal.priority,
                ),
            ],
            holdings: [
              for (final portfolio in portfolios)
                for (final asset in portfolio.assets)
                  StudioHolding(
                    label: asset.symbol,
                    assetClass: asset.assetClass,
                    value: asset.marketValue ?? 0,
                    gain: asset.marketValue == null ? 0 : asset.marketValue! - asset.position.costBasis,
                    prices: asset.currentPrice == null ? const [] : [asset.currentPrice!],
                  ),
            ],
          );
          final report = results.where((result) => result.code == 'reports').firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PersistSnapshot(rows: rows),
              _ModelServicePanel(reports: ref.watch(modelServiceProvider)),
              const SizedBox(height: 12),
              Text(l10n.studioBaseline),
              const SizedBox(height: 12),
              if (report != null) _chart(context, report),
              for (final result in results) _card(context, language, result),
            ],
          );
        },
      ),
    );
  }

  Widget _chart(BuildContext context, FeatureResult report) {
    final income = (report.metrics['income'] ?? 0).toDouble();
    final expense = (report.metrics['expense'] ?? 0).toDouble();
    final maxY = (income > expense ? income : expense) * 1.2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: maxY <= 0 ? 1 : maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, width: 18)]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: expense, width: 18)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String language, FeatureResult result) {
    final metrics = result.metrics.entries.take(4).map((entry) {
      final value = entry.value.abs() >= 1 && entry.key != 'reach_rate' && entry.key != 'weekend_share' && entry.key != 'largest_share'
          ? Money.format(entry.value, 'TND')
          : entry.value.toStringAsFixed(3);
      return '${entry.key}: $value';
    }).join('\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.id}. ${studioTitle(language, result.code)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(result.operational ? result.method : 'insufficient_data'),
            if (metrics.isNotEmpty) ...[const SizedBox(height: 8), Text(metrics)],
            const SizedBox(height: 8),
            Text(result.drivers.take(2).join(' ')),
          ],
        ),
      ),
    );
  }
}
