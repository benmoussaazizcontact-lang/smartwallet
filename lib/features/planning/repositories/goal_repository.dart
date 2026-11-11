import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/goal_math.dart';

class GoalRecord {
  const GoalRecord({
    required this.id,
    required this.name,
    required this.kind,
    required this.target,
    required this.currency,
    required this.priority,
    required this.status,
    this.targetDate,
    this.icon,
    this.color,
    this.saved = 0,
  });

  final String id;
  final String name;
  final String kind;
  final num target;
  final String currency;
  final int priority;
  final String status;
  final DateTime? targetDate;
  final String? icon;
  final String? color;
  final num saved;

  GoalSnapshot snapshot(DateTime now) => GoalSnapshot(
        target: target,
        saved: saved,
        now: now,
        targetDate: targetDate,
      );

  factory GoalRecord.fromMap(Map<String, dynamic> map, {num saved = 0}) {
    return GoalRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: map['kind'] as String,
      target: num.parse(map['target_amount'].toString()),
      currency: map['currency'] as String,
      priority: map['priority'] as int? ?? 2,
      status: map['status'] as String? ?? 'active',
      targetDate: map['target_date'] == null ? null : DateTime.parse(map['target_date'] as String),
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      saved: saved,
    );
  }
}

class ContributionRecord {
  const ContributionRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.date,
    this.note,
  });

  final String id;
  final num amount;
  final String currency;
  final DateTime date;
  final String? note;
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(supabaseProvider));
});

final goalsForUserProvider = FutureProvider.family<List<GoalRecord>, String>((ref, userId) async {
  final rows = await ref.watch(goalRepositoryProvider).list();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final goalsProvider = Provider<AsyncValue<List<GoalRecord>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(goalsForUserProvider(userId));
});

class GoalRepository {
  GoalRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<GoalRecord>> list() async {
    final userId = _userId;
    if (userId == null) return const [];
    final goals = await _client.from('financial_goals').select().eq('user_id', userId).order('created_at');
    final contributions = await _client
        .from('goal_contributions')
        .select('goal_id, amount, currency')
        .eq('user_id', userId);
    final saved = <String, num>{};
    for (final row in contributions) {
      final id = row['goal_id'] as String;
      saved[id] = (saved[id] ?? 0) + num.parse(row['amount'].toString());
    }
    return [
      for (final row in goals) GoalRecord.fromMap(row, saved: saved[row['id']] ?? 0),
    ];
  }

  Future<List<ContributionRecord>> contributions(String goalId) async {
    final userId = _userId;
    if (userId == null) return const [];
    final rows = await _client
        .from('goal_contributions')
        .select()
        .eq('user_id', userId)
        .eq('goal_id', goalId)
        .order('contributed_on', ascending: false);
    return [
      for (final row in rows)
        ContributionRecord(
          id: row['id'] as String,
          amount: num.parse(row['amount'].toString()),
          currency: row['currency'] as String,
          date: DateTime.parse(row['contributed_on'] as String),
          note: row['note'] as String?,
        ),
    ];
  }

  Future<void> save({
    String? id,
    required String name,
    required String kind,
    required num target,
    required String currency,
    DateTime? targetDate,
    required int priority,
    String? color,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    final row = {
      'user_id': userId,
      'name': name.trim(),
      'kind': kind,
      'target_amount': target,
      'currency': currency,
      'target_date': targetDate == null
          ? null
          : '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
      'priority': priority,
      'color': color,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      await _client.from('financial_goals').insert(row);
    } else {
      await _client.from('financial_goals').update(row).eq('id', id).eq('user_id', userId);
    }
  }

  Future<void> setStatus(String id, String status) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    await _client.from('financial_goals').update({'status': status}).eq('id', id).eq('user_id', userId);
  }

  /// Records a virtual contribution. Wallet balances are not changed.
  Future<void> contribute({
    required String goalId,
    required num amount,
    required String currency,
    required String clientRequestId,
    String? note,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    final existing = await _client
        .from('goal_contributions')
        .select('id')
        .eq('user_id', userId)
        .eq('client_request_id', clientRequestId)
        .maybeSingle();
    if (existing != null) return;
    await _client.from('goal_contributions').insert({
      'user_id': userId,
      'goal_id': goalId,
      'amount': amount,
      'currency': currency,
      'note': note,
      'client_request_id': clientRequestId,
    });
  }

  Future<void> schedule({
    required String goalId,
    required num amount,
    required String frequency,
    required DateTime nextOn,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    await _client.from('goal_schedules').insert({
      'user_id': userId,
      'goal_id': goalId,
      'amount': amount,
      'frequency': frequency,
      'next_on':
          '${nextOn.year.toString().padLeft(4, '0')}-${nextOn.month.toString().padLeft(2, '0')}-${nextOn.day.toString().padLeft(2, '0')}',
    });
  }
}
