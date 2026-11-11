import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../categories/models/category.dart';
import '../services/classification_result.dart';

class MerchantCorrection {
  const MerchantCorrection({required this.merchantKey, required this.categoryId});

  final String merchantKey;
  final String categoryId;
}

final classificationRepositoryProvider = Provider<ClassificationRepository>((ref) {
  return ClassificationRepository(ref.watch(supabaseProvider));
});

class ClassificationRepository {
  ClassificationRepository(this._client);
  final SupabaseClient _client;

  Future<List<MerchantCorrection>> listCorrections() async {
    try {
      final rows = await _client.from('classification_corrections').select();
      return rows
          .map(
            (row) => MerchantCorrection(
              merchantKey: row['merchant_key'] as String,
              categoryId: row['category_id'] as String,
            ),
          )
          .toList();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> record({
    required String transactionId,
    required String? merchantKey,
    required String? predictedCategoryId,
    required String? actualCategoryId,
    required double? confidence,
    required String modelName,
    required bool wasCorrected,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    try {
      final existing = await _client
          .from('ai_classifications')
          .select('id')
          .eq('user_id', userId)
          .eq('transaction_id', transactionId)
          .maybeSingle();
      if (existing == null) {
        await _client.from('ai_classifications').insert({
          'user_id': userId,
          'transaction_id': transactionId,
          'predicted_category_id': predictedCategoryId,
          'actual_category_id': actualCategoryId,
          'merchant_key': merchantKey,
          'confidence': confidence,
          'model_name': modelName,
          'was_corrected': wasCorrected,
        });
      }
      if (wasCorrected &&
          merchantKey != null &&
          merchantKey.isNotEmpty &&
          actualCategoryId != null) {
        await _client.from('classification_corrections').upsert({
          'user_id': userId,
          'merchant_key': merchantKey,
          'category_id': actualCategoryId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id,merchant_key');
      }
    } catch (error) {
      throw AppException.from(error);
    }
  }
}

final merchantCorrectionsForUserProvider =
    FutureProvider.family<List<MerchantCorrection>, String>((ref, userId) async {
  final rows = await ref.watch(classificationRepositoryProvider).listCorrections();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final merchantCorrectionsProvider =
    Provider<AsyncValue<List<MerchantCorrection>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(merchantCorrectionsForUserProvider(userId));
});

ClassificationResult? resultFromCorrection({
  required MerchantCorrection correction,
  required List<CategoryItem> categories,
}) {
  CategoryItem? match;
  for (final item in categories) {
    if (item.id == correction.categoryId) {
      match = item;
      break;
    }
  }
  if (match == null) return null;
  CategoryItem? parent;
  for (final item in categories) {
    if (item.id == match.parentId) {
      parent = item;
      break;
    }
  }
  return ClassificationResult(
    categoryId: parent?.id ?? match.id,
    categoryName: parent?.name ?? match.name,
    subcategoryId: match.parentId == null ? null : match.id,
    subcategoryName: match.parentId == null ? null : match.name,
    confidence: ClassificationResult.userCorrectionScore,
    reason:
        'Previous correction for this merchant (${ClassificationResult.userCorrectionScore})',
    source: ClassificationSource.userCorrection,
  );
}
