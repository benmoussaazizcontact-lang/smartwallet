import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../categories/models/category.dart';
import '../repositories/classification_repository.dart';
import 'classification_result.dart';
import 'rule_classifier.dart';

class TransactionClassificationService {
  TransactionClassificationService(this._client);

  final SupabaseClient _client;

  static String merchantKey(String? merchant) {
    final raw = (merchant ?? '').toLowerCase().trim();
    return raw.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static ClassificationResult? classifyLocal({
    required String text,
    String? merchant,
    required List<CategoryItem> categories,
    List<MerchantCorrection> corrections = const [],
  }) {
    final key = merchantKey(merchant?.isNotEmpty == true ? merchant : text);
    if (key.isNotEmpty) {
      for (final correction in corrections) {
        if (correction.merchantKey == key) {
          final fromUser = resultFromCorrection(
            correction: correction,
            categories: categories,
          );
          if (fromUser != null) return fromUser;
        }
      }
    }
    return const RuleClassifier().classify(
      text: '$merchant $text',
      categories: categories,
    );
  }

  Future<ClassificationOutcome> classify({
    required String text,
    String? merchant,
    num? amount,
    required List<CategoryItem> categories,
    List<MerchantCorrection> corrections = const [],
    bool allowRemote = true,
  }) async {
    final local = TransactionClassificationService.classifyLocal(
      text: text,
      merchant: merchant,
      categories: categories,
      corrections: corrections,
    );
    if (local != null && !local.isLowConfidence) {
      return ClassificationOutcome(suggestion: local);
    }
    if (!allowRemote) {
      return ClassificationOutcome(suggestion: local);
    }

    final remote = await _classifyRemote(
      text: text,
      merchant: merchant,
      amount: amount,
      categories: categories,
    );
    if (remote.$1 != null) {
      return ClassificationOutcome(suggestion: remote.$1);
    }
    return ClassificationOutcome(
      suggestion: local,
      advancedUnavailableReason: remote.$2,
    );
  }

  /// Returns (result, unavailableReason).
  Future<(ClassificationResult?, String?)> _classifyRemote({
    required String text,
    String? merchant,
    num? amount,
    required List<CategoryItem> categories,
  }) async {
    try {
      final payload = categories
          .map(
            (c) {
              String? parentName;
              for (final p in categories) {
                if (p.id == c.parentId) {
                  parentName = p.name;
                  break;
                }
              }
              return {
                'id': c.id,
                'name': c.name,
                'parentName': parentName,
              };
            },
          )
          .toList();
      final response = await _client.functions.invoke(
        'classify-transaction',
        body: {
          'text': text,
          'merchant': merchant,
          'amount': amount,
          'categories': payload,
        },
      );
      final data = response.data;
      if (data is! Map) {
        return (
          null,
          'Advanced AI classification is unavailable (unexpected response).',
        );
      }
      final map = Map<String, dynamic>.from(data);
      if (map['available'] == false) {
        return (
          null,
          (map['reason'] as String?) ??
              'Advanced AI classification is not configured.',
        );
      }
      final id = map['category_id'] as String?;
      if (id == null || id.isEmpty) {
        return (null, null);
      }
      CategoryItem? match;
      for (final item in categories) {
        if (item.id == id) {
          match = item;
          break;
        }
      }
      if (match == null) {
        return (null, 'The AI model returned an unknown category. Ignored.');
      }
      CategoryItem? parent;
      for (final item in categories) {
        if (item.id == match.parentId) {
          parent = item;
          break;
        }
      }
      final rawConfidence = map['confidence'];
      final measured = rawConfidence is num;
      return (
        ClassificationResult(
          categoryId: parent?.id ?? match.id,
          categoryName: parent?.name ?? match.name,
          subcategoryId: match.parentId == null ? null : match.id,
          subcategoryName: match.parentId == null ? null : match.name,
          confidence: measured
              ? (rawConfidence).toDouble().clamp(0, 1).toDouble()
              : 0,
          confidenceMeasured: measured,
          reason: measured
              ? ((map['reason'] as String?) ?? 'Edge Function model score')
              : 'The model did not return a confidence score. Confirm the category.',
          source: ClassificationSource.remoteAi,
        ),
        null,
      );
    } catch (error) {
      return (
        null,
        'Advanced AI classification is unavailable: $error',
      );
    }
  }
}

final transactionClassificationServiceProvider =
    Provider<TransactionClassificationService>((ref) {
  return TransactionClassificationService(ref.watch(supabaseProvider));
});
