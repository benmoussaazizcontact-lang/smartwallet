import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/core/i18n/locale_controller.dart';
import 'package:wallet_app/core/theme/theme_controller.dart';
import 'package:wallet_app/features/wallets/models/wallet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wallet rows belong to the signed-in user and keep every type', () {
    final rows = [
      for (final type in walletTypeValues)
        walletInsertRow(
          userId: 'account-1',
          name: type,
          walletType: type,
          currency: 'TND',
          initialBalance: 0,
          creditLimit: type == 'CREDIT_CARD' ? 500 : 0,
          cryptoSymbol: type == 'CRYPTO' ? 'BTC' : null,
          icon: type,
          color: '#2563EB',
        ),
    ];
    expect(walletTypeValues, [
      'CASH',
      'BANK_ACCOUNT',
      'CREDIT_CARD',
      'CRYPTO',
      'SAVINGS',
    ]);
    expect(rows.map((row) => row['user_id']), everyElement('account-1'));
    expect(rows.map((row) => row['wallet_type']), walletTypeValues);
    expect(rows.first.containsKey('user_id'), isTrue);
  });

  test('theme choice is restored and follows the signed-in account', () async {
    SharedPreferences.setMockInitialValues({
      prefsThemeKey: 'dark',
      prefsThemeUserKey: 'user-a',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider), ThemeMode.dark);
    await container
        .read(themeControllerProvider.notifier)
        .applyAccountTheme('user-b', 'light');
    expect(container.read(themeControllerProvider), ThemeMode.light);
    expect(prefs.getString(prefsThemeUserKey), 'user-b');

    await container
        .read(themeControllerProvider.notifier)
        .setThemeMode(ThemeMode.dark, userId: 'user-b');
    await container
        .read(themeControllerProvider.notifier)
        .applyAccountTheme('user-b', 'light');
    expect(container.read(themeControllerProvider), ThemeMode.dark);

    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(themeControllerProvider), ThemeMode.dark);
  });

  test('language choice is saved per account', () async {
    SharedPreferences.setMockInitialValues({prefsLocaleKey: 'fr'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(localeControllerProvider), const Locale('fr'));
    await container
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('ar'), userId: 'user-a');
    expect(prefs.getString('${prefsLocaleUserPrefix}user-a'), 'ar');

    await container
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('en'), userId: 'user-b');
    await container
        .read(localeControllerProvider.notifier)
        .applyAccountLocale('user-a');
    expect(container.read(localeControllerProvider), const Locale('ar'));
  });
}
