import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/i18n/l10n_ext.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/providers/supabase_provider.dart';
import '../features/notifications/services/push_notification_service.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final client = ref.read(supabaseProvider);
    if (session != null) {
      unawaited(
        PushNotificationService.instance.syncUser(client, session.user.id),
      );
    }
    ref.listen(currentSessionProvider, (previous, next) {
      if (next == null && previous != null) {
        unawaited(
          PushNotificationService.instance.removeSignedInDevice(
            client,
            previous.user.id,
          ),
        );
      }
    });
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      body: navigationShell,
      extendBody: false,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface(brightness).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: brightness == Brightness.dark ? 0.08 : 0.9,
              ),
            ),
            boxShadow: AppShadows.nav(brightness),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
                label: l10n.navWallets,
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long_rounded),
                label: l10n.navActivity,
              ),
              NavigationDestination(
                icon: const Icon(Icons.document_scanner_outlined),
                selectedIcon: const Icon(Icons.document_scanner_rounded),
                label: l10n.navScan,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: l10n.navSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
