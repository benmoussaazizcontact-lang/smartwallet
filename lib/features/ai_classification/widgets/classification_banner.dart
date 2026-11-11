import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_radius.dart';
import '../services/classification_result.dart';

class ClassificationBanner extends StatelessWidget {
  const ClassificationBanner({
    super.key,
    required this.suggestion,
    this.advancedUnavailableReason,
    this.onAccept,
  });

  final ClassificationResult? suggestion;
  final String? advancedUnavailableReason;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label = '';
    if (suggestion != null && suggestion!.categoryId.isNotEmpty) {
      final raw = suggestion!.label;
      final parts = raw.split(' / ');
      label = parts.map((p) => localizedCategoryName(l10n, p.trim())).join(' → ');
    }
    final sourceLabel = switch (suggestion?.source) {
      ClassificationSource.remoteAi => l10n.classificationRemote,
      ClassificationSource.userCorrection => l10n.classificationMemory,
      ClassificationSource.localRules => l10n.classificationRules,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggestion != null && suggestion!.categoryId.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: suggestion!.isLowConfidence
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      suggestion!.isLowConfidence
                          ? Icons.help_outline
                          : Icons.auto_awesome,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.suggestedCategory(label),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if (sourceLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(sourceLabel, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (suggestion!.confidenceMeasured) ...[
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: suggestion!.confidence.clamp(0, 1)),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                      color: suggestion!.isLowConfidence
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.confidence(suggestion!.confidencePercent)),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(l10n.confidenceNotMeasured),
                ],
                Text(suggestion!.reason, style: Theme.of(context).textTheme.bodySmall),
                if (onAccept != null && !suggestion!.isLowConfidence)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: onAccept,
                      child: Text(l10n.acceptSuggestion),
                    ),
                  ),
              ],
            ),
          ),
        if (suggestion?.isLowConfidence == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.lowConfidenceHint),
          ),
        if (advancedUnavailableReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              advancedUnavailableReason!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
