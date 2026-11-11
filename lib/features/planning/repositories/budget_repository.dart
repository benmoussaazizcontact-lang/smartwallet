import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/budget_math.dart';
import '../domain/forecast_math.dart';
import '../domain/spend_rules.dart';

class BudgetRecord {
  const BudgetRecord({
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

  factory BudgetRecord.fromMap(Map<String, dynamic> map) {
    return BudgetRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      period: map['period'] as String,
      currency: map['currency'] as String,
      limit: num.parse(map['limit_amount'].toString()),
      categoryId: map['category_id'] as String?,
      archived: map['archived'] as bool? ?? false,
    );
  }

  BudgetSpec get spec => BudgetSpec(
        id: id,
        name: name,
        period: period,
        currency: currency,
        limit: limit,
        categoryId: categoryId,
        archived: archived,
      );
}

class BudgetHome {
  const BudgetHome({
    required this.rollup,
    required this.events,
    required this.alerts,
  });

  final BudgetRollup rollup;
  final List<SpendEvent> events;
  final List<Map<String, dynamic>> alerts;
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(supabaseProvider));
});

final budgetsForUserProvider = FutureProvider.family<BudgetHome, String>((ref, userId) async {
  final home = await ref.watch(budgetRepositoryProvider).load(now: DateTime.now());
  if (ref.read(currentUserIdProvider) != userId) {
    return const BudgetHome(rollup: BudgetRollup(overall: [], categories: []), events: [], alerts: []);
  }
  return home;
});

final budgetsProvider = Provider<AsyncValue<BudgetHome>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const AsyncData(BudgetHome(rollup: BudgetRollup(overall: [], categories: []), events: [], alerts: []));
  }
  return ref.watch(budgetsForUserProvider(userId));
});

class BudgetRepository {
  BudgetRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<BudgetHome> load({required DateTime now}) async {
    final userId = _userId;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    final from = DateTime(now.year, now.month - 2);
    final budgets = await _client.from('budgets').select().eq('user_id', userId).order('created_at');
    final tx = await _client
        .from('transactions')
        .select('transaction_type, amount, currency, status, category_id, transaction_date, merchant, categories(name)')
        .eq('user_id', userId)
        .gte('transaction_date', from.toUtc().toIso8601String())
        .limit(2000);
    final alerts = await _client.from('budget_alerts').select().eq('user_id', userId).order('created_at');
    final events = [
      for (final row in tx)
        SpendEvent(
          date: DateTime.parse(row['transaction_date'] as String).toLocal(),
          type: (row['transaction_type'] as String?) ?? 'EXPENSE',
          status: (row['status'] as String?) ?? 'POSTED',
          amount: num.parse(row['amount'].toString()),
          currency: row['currency'] as String,
          categoryId: row['category_id'] as String?,
          categoryName: row['categories'] is Map ? (row['categories'] as Map)['name'] as String? : null,
          merchant: row['merchant'] as String?,
        ),
    ];
    final specs = [for (final row in budgets) BudgetRecord.fromMap(row).spec];
    final rollup = rollupBudgets(specs, events, now);
    await _recordNewAlerts(userId, rollup, now);
    return BudgetHome(rollup: rollup, events: events, alerts: alerts);
  }

  Future<void> _recordNewAlerts(String userId, BudgetRollup rollup, DateTime now) async {
    final items = [...rollup.overall, ...rollup.categories];
    for (final item in items) {
      final key = item.spec.period == 'weekly'
          ? '${now.year}-W${periodWindow(item.spec.period, now).start.toIso8601String().substring(0, 10)}'
          : '${now.year}-${now.month.toString().padLeft(2, '0')}';
      for (final threshold in item.crossedThresholds) {
        try {
          await _client.from('budget_alerts').insert({
            'user_id': userId,
            'budget_id': item.spec.id,
            'threshold': threshold,
            'period_key': key,
          });
        } catch (_) {
          // A repeated threshold for this period is already stored.
        }
      }
    }
  }

  Future<void> save({
    String? id,
    required String name,
    required String period,
    required String currency,
    required num limit,
    String? categoryId,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    final row = {
      'user_id': userId,
      'name': name.trim(),
      'period': period,
      'currency': currency,
      'limit_amount': limit,
      'category_id': categoryId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      await _client.from('budgets').insert(row);
    } else {
      await _client.from('budgets').update(row).eq('id', id).eq('user_id', userId);
    }
  }

  Future<void> archive(String id, {bool archived = true}) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    await _client.from('budgets').update({'archived': archived}).eq('id', id).eq('user_id', userId);
  }

  Future<void> delete(String id) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    await _client.from('budgets').delete().eq('id', id).eq('user_id', userId);
  }
}

String periodKeyFor(String period, DateTime now) {
  final window = periodWindow(period, now);
  return period == 'weekly'
      ? window.start.toIso8601String().substring(0, 10)
      : '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

SpendForecast forecastFor(BudgetProgress progress, List<SpendEvent> events, DateTime now) {
  final window = periodWindow(progress.spec.period, now);
  final samples = events.where((event) {
    return countsAsSpending(event) &&
        event.currency == progress.spec.currency &&
        window.contains(event.date) &&
        (progress.spec.categoryId == null || event.categoryId == progress.spec.categoryId);
  }).length;
  if (progress.spec.period != 'monthly') {
    return SpendForecast(sufficient: false, sampleCount: samples);
  }
  return forecastMonth(
    spentSoFar: progress.spent,
    now: now,
    limit: progress.spec.limit,
    sampleCount: samples,
  );
}
