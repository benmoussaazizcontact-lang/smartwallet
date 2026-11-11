import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF4776FF);
  static const secondary = Color(0xFF7C5CFC);
  static const accent = Color(0xFF8AB4FF);
  static const success = Color(0xFF34D399);
  static const danger = Color(0xFFFB7185);
  static const warning = Color(0xFFFBBF24);

  static const darkBackground = Color(0xFF070B14);
  static const surfaceDark = Color(0xFF111827);
  static const elevatedDark = Color(0xFF192235);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);

  static const lightBackground = Color(0xFFF3F5FB);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const elevatedLight = Color(0xFFE8EEF9);
  static const textPrimaryLight = Color(0xFF0B1220);
  static const textSecondaryLight = Color(0xFF4A5870);

  static const cardDark = elevatedDark;
  static const ink = textPrimaryLight;
  static const muted = textSecondaryLight;

  static Color background(Brightness b) =>
      b == Brightness.dark ? darkBackground : lightBackground;

  static Color surface(Brightness b) =>
      b == Brightness.dark ? surfaceDark : surfaceLight;

  static Color elevated(Brightness b) =>
      b == Brightness.dark ? elevatedDark : elevatedLight;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? textSecondaryDark : textSecondaryLight;
}
