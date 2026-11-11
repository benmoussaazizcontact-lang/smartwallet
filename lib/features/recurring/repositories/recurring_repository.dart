import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/recurring.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(supabaseProvider));
});

class RecurringRepository {
  RecurringRepository(this._client);
  final SupabaseClient _client;

  Future<List<RecurringItem>> list() async {
    final rows = await _client
        .from('recurring_transactions')
        .select()
        .order('next_execution_date');
    return rows.map(RecurringItem.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> executions(String recurringId) async {
    return _client
        .from('recurring_executions')
        .select()
        .eq('recurring_id', recurringId)
        .order('executed_on', ascending: false);
  }

  Future<void> create({
    required String walletId,
    required String type,
    required num amount,
    required String frequency,
    required DateTime nextExecutionDate,
    String? categoryId,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    await _client.from('recurring_transactions').insert({
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'transaction_type': type,
      'amount': amount,
      'frequency': frequency,
      'next_execution_date': nextExecutionDate.toIso8601String().split('T').first,
      'description': description,
      'is_active': true,
    });
  }

  Future<void> update({
    required String id,
    required String frequency,
    required DateTime nextExecutionDate,
    required num amount,
    String? description,
    bool? isActive,
  }) async {
    await _client.from('recurring_transactions').update({
      'frequency': frequency,
      'next_execution_date': nextExecutionDate.toIso8601String().split('T').first,
      'amount': amount,
      'description': description,
      'is_active': ?isActive,
    }).eq('id', id);
  }

  Future<void> setActive(String id, bool active) async {
    await _client
        .from('recurring_transactions')
        .update({'is_active': active}).eq('id', id);
  }
}

final recurringForUserProvider =
    FutureProvider.family<List<RecurringItem>, String>((ref, userId) async {
  final rows = await ref.watch(recurringRepositoryProvider).list();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final recurringProvider = Provider<AsyncValue<List<RecurringItem>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(recurringForUserProvider(userId));
});
