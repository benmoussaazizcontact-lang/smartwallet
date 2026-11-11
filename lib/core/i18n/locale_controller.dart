import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const prefsLocaleKey = 'app_locale';
const prefsLocaleUserPrefix = 'app_locale_user_';

const supportedLanguageCodes = ['en', 'fr', 'ar'];

Locale resolveStartupLocale(SharedPreferences prefs, Locale device) {
  final stored = prefs.getString(prefsLocaleKey);
  if (stored != null && supportedLanguageCodes.contains(stored)) {
    return Locale(stored);
  }
  if (supportedLanguageCodes.contains(device.languageCode)) {
    return Locale(device.languageCode);
  }
  return const Locale('en');
}

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    final locale = resolveStartupLocale(prefs, device);
    Intl.defaultLocale = locale.toLanguageTag();
    return locale;
  }

  Future<void> setLocale(Locale locale, {String? userId}) async {
    state = locale;
    Intl.defaultLocale = locale.toLanguageTag();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(prefsLocaleKey, locale.languageCode);
    if (userId != null) {
      await prefs.setString(
        '$prefsLocaleUserPrefix$userId',
        locale.languageCode,
      );
    }
  }

  /// Restores the language saved for this account. A new account keeps the
  /// language already chosen on the device and stores it for next time.
  Future<void> applyAccountLocale(String userId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString('$prefsLocaleUserPrefix$userId');
    if (stored != null && supportedLanguageCodes.contains(stored)) {
      if (state.languageCode != stored) {
        await setLocale(Locale(stored), userId: userId);
      }
      return;
    }
    await prefs.setString(
      '$prefsLocaleUserPrefix$userId',
      state.languageCode,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden in main');
});

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
