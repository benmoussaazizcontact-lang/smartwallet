import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface(brightness).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: brightness == Brightness.dark ? 0.06 : 0.7,
          ),
        ),
        boxShadow: AppShadows.card(brightness),
      ),
      child: child,
    );
  }
}
