import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/tag.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.watch(supabaseProvider));
});

class TagRepository {
  TagRepository(this._client);
  final SupabaseClient _client;

  Future<List<TagItem>> list() async {
    final rows = await _client.from('tags').select().order('name');
    return rows.map(TagItem.fromMap).toList();
  }

  Future<TagItem> create(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    final row = await _client
        .from('tags')
        .insert({'user_id': userId, 'name': name.trim()})
        .select()
        .single();
    return TagItem.fromMap(row);
  }

  Future<List<TagItem>> forTransaction(String transactionId) async {
    final rows = await _client
        .from('transaction_tags')
        .select('tags(id, name)')
        .eq('transaction_id', transactionId);
    return rows
        .map((row) => row['tags'])
        .whereType<Map<String, dynamic>>()
        .map(TagItem.fromMap)
        .toList();
  }
}

final tagsForUserProvider =
    FutureProvider.family<List<TagItem>, String>((ref, userId) async {
  final rows = await ref.watch(tagRepositoryProvider).list();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final tagsProvider = Provider<AsyncValue<List<TagItem>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(tagsForUserProvider(userId));
});
