import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/core/i18n/l10n_ext.dart';
import 'package:wallet_app/core/i18n/locale_controller.dart';
import 'package:wallet_app/core/utils/money.dart';
import 'package:wallet_app/shared/widgets/empty_state.dart';

Widget _app(Locale locale, Widget home) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

void main() {
  testWidgets('english to french labels', (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), const Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();
    var l10n = tester.element(find.byType(SizedBox)).l10n;
    expect(l10n.navHome, 'Home');
    expect(l10n.addExpense, 'Add Expense');

    await tester.pumpWidget(_app(const Locale('fr'), const Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();
    l10n = tester.element(find.byType(SizedBox)).l10n;
    expect(l10n.navHome, 'Accueil');
    expect(l10n.addExpense, 'Ajouter une dépense');
  });

  testWidgets('french to arabic and RTL', (tester) async {
    await tester.pumpWidget(_app(const Locale('fr'), const Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(SizedBox)).l10n.navWallets, 'Portefeuilles');

    await tester.pumpWidget(_app(const Locale('ar'), const Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SizedBox));
    expect(context.l10n.navWallets, 'المحافظ');
    expect(Directionality.of(context), TextDirection.rtl);
  });

  test('persists language in shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(resolveStartupLocale(prefs, const Locale('de')), const Locale('en'));
    await prefs.setString(prefsLocaleKey, 'ar');
    expect(resolveStartupLocale(prefs, const Locale('fr')), const Locale('ar'));
    await prefs.setString(prefsLocaleKey, 'fr');
    expect(resolveStartupLocale(prefs, const Locale('en')), const Locale('fr'));
  });

  test('TND formatting uses three decimals independently of stored value', () {
    const stored = 12.5;
    expect(Money.format(stored, 'TND', locale: 'en'), contains('12.500'));
    expect(Money.format(stored, 'TND', locale: 'en'), contains('TND'));
    expect(Money.format(stored, 'EUR', locale: 'en'), contains('12.50'));
    expect(stored, 12.5);
  });

  testWidgets('arabic empty state does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    await tester.pumpWidget(
      _app(
        const Locale('ar'),
        const EmptyState(
          title: 'لا توجد محافظ بعد',
          message: 'أنشئ محفظة لبدء تسجيل نشاط حقيقي على هذا الجهاز الصغير.',
          actionLabel: 'إضافة محفظة',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('navigation destinations render in french', (tester) async {
    await tester.pumpWidget(
      _app(
        const Locale('fr'),
        Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: Builder(
            builder: (context) {
              final l10n = context.l10n;
              return NavigationBar(
                selectedIndex: 0,
                destinations: [
                  NavigationDestination(icon: const Icon(Icons.home), label: l10n.navHome),
                  NavigationDestination(
                    icon: const Icon(Icons.account_balance_wallet),
                    label: l10n.navWallets,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.receipt_long),
                    label: l10n.navActivity,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.document_scanner),
                    label: l10n.navScan,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings),
                    label: l10n.navSettings,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Portefeuilles'), findsWidgets);
    expect(find.text('Paramètres'), findsWidgets);
  });

  testWidgets('financial amount form uses translated validation', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        const Locale('fr'),
        Scaffold(
          body: Builder(
            builder: (context) {
              return Form(
                key: formKey,
                child: TextFormField(
                  key: const Key('amount-field'),
                  validator: (v) => Money.validate(v ?? '', l10n: context.l10n),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Montant requis'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('amount-field')), '12.500');
    expect(formKey.currentState!.validate(), isTrue);
  });
}
