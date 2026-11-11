import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/locale_controller.dart';

const prefsThemeKey = 'theme_mode';
const prefsThemeUserKey = 'theme_mode_user';

ThemeMode themeModeFromStorage(String? raw) {
  return switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

String themeModeToStorage(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(prefsThemeKey);
    return themeModeFromStorage(raw);
  }

  Future<void> setThemeMode(ThemeMode mode, {String? userId}) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(prefsThemeKey, themeModeToStorage(mode));
    if (userId != null) {
      await prefs.setString(prefsThemeUserKey, userId);
    }
  }

  /// Applies the signed-in account theme once. Later changes on this device
  /// stay in [setThemeMode] and are not overwritten by a profile refresh.
  Future<void> applyAccountTheme(String userId, String? profileTheme) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getString(prefsThemeUserKey) == userId) return;
    await setThemeMode(themeModeFromStorage(profileTheme), userId: userId);
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
