import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseProvider));
});

class CategoryRepository {
  CategoryRepository(this._client);
  final SupabaseClient _client;

  Future<List<CategoryItem>> list() async {
    final rows = await _client.from('categories').select().order('name');
    return rows.map(CategoryItem.fromMap).toList();
  }

  Future<void> create({
    required String name,
    String? parentId,
    String? icon,
    String? color,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    await _client.from('categories').insert({
      'user_id': userId,
      'name': name.trim(),
      'parent_id': parentId,
      'icon': icon,
      'color': color,
    });
  }

  Future<void> update(CategoryItem item) async {
    if (item.isGlobal) {
      throw const AppException('Les catégories globales ne sont pas modifiables.');
    }
    await _client.from('categories').update({
      'name': item.name,
      'icon': item.icon,
      'color': item.color,
    }).eq('id', item.id);
  }

  Future<void> delete(CategoryItem item) async {
    if (item.isGlobal) {
      throw const AppException('Les catégories globales ne peuvent pas être supprimées.');
    }
    await _client.from('categories').delete().eq('id', item.id);
  }
}

final categoriesForUserProvider =
    FutureProvider.family<List<CategoryItem>, String>((ref, userId) async {
  final rows = await ref.watch(categoryRepositoryProvider).list();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final categoriesProvider = Provider<AsyncValue<List<CategoryItem>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(categoriesForUserProvider(userId));
});
