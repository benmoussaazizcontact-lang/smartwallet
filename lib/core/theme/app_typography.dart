import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Inter for Latin (OFL). Cairo for Arabic (OFL via Google Fonts).
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Locale locale, Brightness brightness) {
    final ink = AppColors.textPrimary(brightness);
    final muted = AppColors.textSecondary(brightness);
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final themed = locale.languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(base)
        : GoogleFonts.interTextTheme(base);
    return themed.apply(bodyColor: ink, displayColor: ink).copyWith(
          headlineLarge: themed.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: ink,
          ),
          headlineMedium: themed.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: ink,
          ),
          titleLarge: themed.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          bodyMedium: themed.bodyMedium?.copyWith(color: ink, height: 1.4),
          bodySmall: themed.bodySmall?.copyWith(color: muted, height: 1.35),
        );
  }
}
