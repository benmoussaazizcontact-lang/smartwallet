import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 16)),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0B1220).withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> glow() => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.32),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> nav(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(color: Color(0x88000000), blurRadius: 24, offset: Offset(0, 10)),
      ];
    }
    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.12),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
