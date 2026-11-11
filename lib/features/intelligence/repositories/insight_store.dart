import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../domain/insight_snapshot.dart';

final insightStoreProvider = Provider<InsightStore>((ref) {
  return InsightStore(ref.watch(supabaseProvider));
});

/// Writes derived insight rows for the signed-in user only.
/// Wallets, transactions, budgets, goals, and other accounts are not touched.
class InsightStore {
  InsightStore(this._client);

  final SupabaseClient _client;

  static const cacheTables = [
    'subscriptions',
    'anomaly_events',
    'expense_forecasts',
    'budget_allocations',
    'financial_reports',
  ];

  Future<void> replaceOwn(InsightSnapshot snapshot) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId != snapshot.userId || !snapshot.ownsEveryRow) {
      throw StateError('Refusing to store insights for another account');
    }
    for (final table in cacheTables) {
      await _client.from(table).delete().eq('user_id', userId);
    }
    if (snapshot.forecasts.isNotEmpty) {
      await _client.from('expense_forecasts').insert(snapshot.forecasts);
    }
    if (snapshot.anomalies.isNotEmpty) {
      await _client.from('anomaly_events').insert(snapshot.anomalies);
    }
    if (snapshot.subscriptions.isNotEmpty) {
      await _client.from('subscriptions').insert(snapshot.subscriptions);
    }
    if (snapshot.allocations.isNotEmpty) {
      await _client.from('budget_allocations').insert(snapshot.allocations);
    }
    if (snapshot.report != null) {
      await _client.from('financial_reports').insert(snapshot.report!);
    }
  }

  Future<void> recordPending({required String action, required Map<String, dynamic> payload}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    if (action != 'draft_transaction' && action != 'create_goal' && action != 'virtual_contribution') {
      return;
    }
    await _client.from('ai_action_requests').insert({
      'user_id': userId,
      'action': action,
      'payload': payload,
      'status': 'pending',
    });
  }

  /// Marks the newest pending request approved after the user confirmed it.
  Future<void> approveLatest(String action) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final rows = await _client
        .from('ai_action_requests')
        .select('id')
        .eq('user_id', userId)
        .eq('action', action)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return;
    await _client
        .from('ai_action_requests')
        .update({'status': 'approved'})
        .eq('id', rows.first['id'] as String)
        .eq('user_id', userId)
        .eq('status', 'pending');
  }
}
