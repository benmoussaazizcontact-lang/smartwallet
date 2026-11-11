import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/i18n/l10n_ext.dart';
import '../core/i18n/locale_controller.dart';
import '../core/providers/supabase_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/splash/screens/splash_screen.dart';
import 'router.dart';

/// Point d'entrée de l'application.
///
/// Utilise [MaterialApp.router] dès le premier build (jamais remplacé).
/// La SplashScreen est rendue en overlay via le paramètre [builder] de
/// MaterialApp — elle disparaît après son animation de sortie.
///
/// [appNotifier.setReady()] est appelé après l'initialisation Supabase.
/// GoRouter re-évalue automatiquement le redirect et navigue vers /welcome
/// ou /home selon la session.
class BootstrapApp extends ConsumerStatefulWidget {
  const BootstrapApp({super.key});

  @override
  ConsumerState<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends ConsumerState<BootstrapApp> {
  Object? _error;
  bool _ready = false; // Supabase initialisé
  bool _showSplash = true; // Splash overlay visible

  @override
  void initState() {
    super.initState();
    // Riverpod : utiliser ref après le premier frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      await dotenv.load(fileName: '.env');

      // Timeout de 15s pour éviter l'écran blanc infini si Supabase est inaccessible.
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Impossible de joindre Supabase (timeout 15s). Vérifiez votre connexion internet.',
        ),
      );

      // Notifier Riverpod + GoRouter que l'init est terminée.
      ref.read(supabaseBootstrapReadyProvider.notifier).markReady();
      appNotifier.setReady();

      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onSplashFinished() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);
    ref.listen(authUserProvider, (previous, next) {
      final user = next.asData?.value;
      if (user == null) return;
      unawaited(
        ref
            .read(themeControllerProvider.notifier)
            .applyAccountTheme(user.id, user.themeMode),
      );
      unawaited(
        ref.read(localeControllerProvider.notifier).applyAccountLocale(user.id),
      );
    });

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(locale),
        darkTheme: AppTheme.dark(locale),
        themeMode: themeMode,
        home: Builder(
          builder: (context) {
            final l10n = context.l10n;
            final scheme = Theme.of(context).colorScheme;
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: scheme.error,
                        size: 56,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.startupError,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_error',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _error = null);
                          _start();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => ctx.l10n.appTitle,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            if (_ready)
              child ?? const SizedBox.expand()
            else
              const SizedBox.expand(),
            if (_showSplash)
              SplashScreen(ready: _ready, onFinished: _onSplashFinished),
          ],
        );
      },
    );
  }
}
