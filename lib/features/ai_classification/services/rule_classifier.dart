import '../../categories/models/category.dart';
import 'classification_result.dart';

/// Local keyword classifier.
///
/// Documented confidence (never arbitrary):
/// - 0.95 — exact merchant/token alias (e.g. "Carrefour", "Shell")
/// - 0.82 — keyword contained in a longer OCR blob
/// - 0.45 — weak parent-category hint only
class RuleClassifier {
  const RuleClassifier();

  static const exactTokenScore = 0.95;
  static const containedKeywordScore = 0.82;
  static const weakParentScore = 0.45;

  static const autoApplyThreshold = ClassificationResult.autoApplyThreshold;

  static const _rules = <String, List<String>>{
    'Groceries': [
      'carrefour',
      'monoprix',
      'geant',
      'magasin general',
      'aziza',
      'groceries',
      'supermarket',
      'supermarche',
    ],
    'Restaurants': [
      'restaurant',
      'restaurants',
      'resto',
      'pizzeria',
      'mcdonald',
      'kfc',
      'burger',
    ],
    'Coffee': ['coffee', 'cafe', 'starbucks', 'costa'],
    'Fuel': ['shell', 'totalenergies', 'agil', 'esso', 'station', 'fuel', 'carburant', 'essence'],
    'Taxi': ['taxi', 'bolt', 'uber', 'indrive'],
    'Parking': ['parking', 'stationnement'],
    'Transport': ['transport', 'bus', 'metro', 'tramway', 'tram'],
    'Shopping': ['shopping'],
    'Bills': ['facture', 'factures', 'invoice', 'bill', 'bills'],
    'Subscriptions': ['netflix', 'spotify', 'youtube', 'disney', 'canal', 'abonnement', 'subscription'],
    'Games': ['steam', 'playstation', 'xbox', 'game'],
    'Gaming': ['steam', 'playstation', 'xbox', 'game'],
    'Cinema': ['cinema', 'pathe', 'imax'],
    'Pharmacy': ['pharmacie', 'pharmacy'],
    'Doctor': ['clinique', 'doctor', 'hopital', 'hôpital'],
    'Salary': ['salaire', 'salary', 'payroll'],
    'Freelance': ['freelance', 'honoraires', 'invoice'],
    'Internet': ['orange', 'ooredoo', 'telecom', 'internet'],
    'Electricity': ['sted', 'electric', 'steg'],
    'Clothes': ['zara', 'h&m', 'pull&bear'],
    'Electronics': ['fnac', 'tunisianet', 'mytek'],
  };

  ClassificationResult? classify({
    required String text,
    required List<CategoryItem> categories,
  }) {
    final haystack = text.toLowerCase().trim();
    if (haystack.isEmpty) return null;

    final tokens = haystack
        .split(RegExp(r'[^a-z0-9&]+'))
        .where((t) => t.isNotEmpty)
        .toSet();

    ClassificationResult? best;
    for (final entry in _rules.entries) {
      var score = 0.0;
      String? matchedKeyword;
      for (final keyword in entry.value) {
        final parts = keyword.split(' ');
        final tokenHit = parts.length == 1
            ? tokens.contains(keyword)
            : haystack.contains(keyword);
        if (tokenHit) {
          if (exactTokenScore > score) {
            score = exactTokenScore;
            matchedKeyword = keyword;
          }
        } else if (keyword.length >= 4 && haystack.contains(keyword)) {
          if (containedKeywordScore > score) {
            score = containedKeywordScore;
            matchedKeyword = keyword;
          }
        }
      }
      if (score == 0) continue;
      final direct = _findByName(categories, entry.key);
      final resolved = direct ?? _fallbackCategory(categories, entry.key);
      if (resolved == null) continue;
      final parent = direct == null
          ? null
          : categories.cast<CategoryItem?>().firstWhere(
                (c) => c?.id == direct.parentId,
                orElse: () => null,
              );
      final category = direct == null ? resolved : (parent ?? direct);
      final subcategory = direct == null || parent == null ? null : direct;
      final chosenName = subcategory == null
          ? category.name
          : '${category.name} / ${subcategory.name}';
      if (best == null || score > best.confidence) {
        best = ClassificationResult(
          categoryId: category.id,
          categoryName: category.name,
          subcategoryId: subcategory?.id,
          subcategoryName: subcategory?.name,
          confidence: score,
          reason: score == exactTokenScore
              ? 'Exact token "${matchedKeyword!}" → $chosenName ($score)'
              : 'Keyword "${matchedKeyword!}" in text → $chosenName ($score)',
          source: ClassificationSource.localRules,
        );
      }
    }
    if (best != null) return best;

    final food = _findByName(categories, 'Food');
    if (food != null && (haystack.contains('food') || haystack.contains('eat'))) {
      return ClassificationResult(
        categoryId: food.id,
        categoryName: food.name,
        confidence: weakParentScore,
        reason: 'Weak parent hint "food/eat" ($weakParentScore). Select a category.',
        source: ClassificationSource.localRules,
      );
    }
    return null;
  }

  static const _parentFallback = {
    'Parking': ['Transport'],
    'Fuel': ['Transport'],
    'Taxi': ['Transport'],
    'Restaurants': ['Food'],
    'Groceries': ['Shopping'],
    'Pharmacy': ['Health'],
    'Subscriptions': ['Entertainment'],
  };

  CategoryItem? _fallbackCategory(List<CategoryItem> categories, String name) {
    for (final fallback in _parentFallback[name] ?? const <String>[]) {
      final item = _findByName(categories, fallback);
      if (item != null) return item;
    }
    return null;
  }

  CategoryItem? _findByName(List<CategoryItem> categories, String name) {
    for (final item in categories) {
      if (item.name.toLowerCase() == name.toLowerCase()) return item;
    }
    return null;
  }
}
