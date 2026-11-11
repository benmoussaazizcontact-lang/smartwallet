enum ClassificationSource { localRules, userCorrection, remoteAi }

class ClassificationOutcome {
  const ClassificationOutcome({
    this.suggestion,
    this.advancedUnavailableReason,
  });

  final ClassificationResult? suggestion;
  final String? advancedUnavailableReason;

  bool get advancedUnavailable => advancedUnavailableReason != null;
}

class ClassificationResult {
  const ClassificationResult({
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    required this.confidence,
    required this.reason,
    required this.source,
    this.confidenceMeasured = true,
    this.advancedUnavailable = false,
    this.advancedUnavailableReason,
  });

  /// Suggestions at or above this score may be pre-selected.
  /// Below it, the user must confirm or pick a category.
  static const autoApplyThreshold = 0.70;

  /// Previous user correction for the same normalized merchant.
  static const userCorrectionScore = 0.99;

  final String categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final double confidence;
  final String reason;
  final ClassificationSource source;

  /// False when a remote model omitted a score. The app does not invent one.
  final bool confidenceMeasured;
  final bool advancedUnavailable;
  final String? advancedUnavailableReason;

  bool get isLowConfidence =>
      !confidenceMeasured || confidence < autoApplyThreshold;

  String get label {
    if (subcategoryName == null || subcategoryName == categoryName) {
      return categoryName;
    }
    return '$categoryName / $subcategoryName';
  }

  int get confidencePercent => (confidence * 100).round();

  String get chosenCategoryId => subcategoryId ?? categoryId;
}
