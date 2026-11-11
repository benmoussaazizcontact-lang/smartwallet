import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:wallet_app/features/planning/screens/plan_hub_screen.dart';
import 'package:wallet_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('home shortcuts open Plan and the existing assistant', (tester) async {
    final router = _router(const _HomeEntries());
    await tester.pumpWidget(_app(router, const Locale('fr')));
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Gérer mes finances'), findsOneWidget);
    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('SmartWallet AI'));
    await tester.pumpAndSettle();
    expect(find.text('assistant-page'), findsOneWidget);
  });

  testWidgets('plan hub keeps every module and hides the studio entry', (tester) async {
    final router = _router(const PlanHubScreen(), start: '/plan');
    await tester.pumpWidget(_app(router, const Locale('fr')));
    expect(find.text('Gérer mes finances'), findsOneWidget);
    expect(find.text('Intelligence financière'), findsOneWidget);
    expect(find.text('Atelier financier'), findsNothing);
    expect(find.text('Analyses et prévisions'), findsOneWidget);
    await tester.tap(find.text('Budget et dépenses'));
    await tester.pumpAndSettle();
    expect(find.text('budgets-page'), findsOneWidget);
    router.go('/plan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objectifs'));
    await tester.pumpAndSettle();
    expect(find.text('goals-page'), findsOneWidget);
    router.go('/plan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Investissements'));
    await tester.pumpAndSettle();
    expect(find.text('invest-page'), findsOneWidget);
    router.go('/plan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyses et prévisions'));
    await tester.pumpAndSettle();
    expect(find.text('insights-page'), findsOneWidget);
    router.go('/plan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulation'));
    await tester.pumpAndSettle();
    expect(find.text('simulation-page'), findsOneWidget);
  });

  testWidgets('plan hub stays readable in dark mode, english, and arabic', (tester) async {
    final router = _router(const PlanHubScreen(), start: '/plan');
    await tester.pumpWidget(_app(router, const Locale('en'), dark: true));
    expect(find.text('Manage my money'), findsOneWidget);
    expect(tester.getSize(find.text('Manage my money')).width, greaterThan(0));

    await tester.pumpWidget(_app(router, const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('إدارة أموالي'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('إدارة أموالي'))), TextDirection.rtl);
  });

  testWidgets('the plan list does not overflow a short screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = _router(const PlanHubScreen(), start: '/plan');
    await tester.pumpWidget(_app(router, const Locale('fr')));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Simulation'), 200);
    expect(find.text('Simulation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _HomeEntries extends StatelessWidget {
  const _HomeEntries();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          HomePlanEntry(),
          HomeAssistantEntry(),
        ],
      ),
    );
  }
}

Widget _app(GoRouter router, Locale locale, {bool dark = false}) {
  return MaterialApp.router(
    locale: locale,
    theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light, useMaterial3: true),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

GoRouter _router(Widget home, {String start = '/'}) {
  return GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/plan',
        builder: (_, _) => const PlanHubScreen(),
        routes: [
          GoRoute(path: 'budgets', builder: (_, _) => const Text('budgets-page')),
          GoRoute(path: 'goals', builder: (_, _) => const Text('goals-page')),
          GoRoute(path: 'portfolio', builder: (_, _) => const Text('invest-page')),
          GoRoute(path: 'assistant', builder: (_, _) => const Text('assistant-page')),
          GoRoute(path: 'insights', builder: (_, _) => const Scaffold(body: Text('insights-page'))),
          GoRoute(path: 'what-if', builder: (_, _) => const Text('simulation-page')),
        ],
      ),
    ],
  );
}
