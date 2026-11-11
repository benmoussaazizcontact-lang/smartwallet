import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_redirect.dart';
import '../core/providers/supabase_provider.dart';
import '../core/session/clear_user_state.dart';
import '../features/auth/screens/auth_callback_screen.dart';
import '../features/auth/screens/biometric_screen.dart';
import '../features/auth/screens/devices_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_history_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/security_settings_screen.dart';
import '../features/auth/screens/support_request_screen.dart';
import '../features/auth/screens/two_factor_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/widgets/biometric_gate.dart';
import '../features/admin/screens/admin_users_dashboard_screen.dart';
import '../features/categories/screens/categories_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/receipts/models/receipt_draft.dart';
import '../features/receipts/screens/confirm_receipt_screen.dart';
import '../features/receipts/screens/scan_receipt_screen.dart';
import '../features/recurring/screens/recurring_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/transactions/screens/add_transaction_screen.dart';
import '../features/transactions/screens/transaction_details_screen.dart';
import '../features/transactions/screens/transaction_list_screen.dart';
import '../features/transfers/screens/transfer_screen.dart';
import '../features/wallets/screens/wallet_details_screen.dart';
import '../features/wallets/screens/wallet_form_screen.dart';
import '../features/wallets/screens/wallet_list_screen.dart';
import '../features/planning/domain/nl_transaction.dart';
import '../features/planning/screens/assistant_screen.dart';
import '../features/planning/screens/budget_screens.dart';
import '../features/planning/screens/goal_screens.dart';
import '../features/planning/screens/investment_screens.dart';
import '../features/intelligence/screens/insights_screen.dart';
import '../features/intelligence/screens/studio_screen.dart';
import '../features/intelligence/screens/planner_screen.dart';
import '../features/intelligence/screens/split_screen.dart';
import '../features/planning/screens/plan_hub_screen.dart';
import 'shell.dart';

// ─── AppNotifier ─────────────────────────────────────────────────────────────
// Singleton qui notifie GoRouter quand :
//   1. Le bootstrap (init Supabase) est terminé
//   2. La session Supabase change (login / logout)
// GoRouter re-évalue le redirect à chaque notification.

class AppNotifier extends ChangeNotifier {
  bool _ready = false;
  bool _hasSession = false;

  bool get ready => _ready;
  bool get hasSession => _hasSession;

  /// Appelé par BootstrapApp après Supabase.initialize().
  void setReady() {
    if (_ready) return;
    _ready = true;
    _hasSession = Supabase.instance.client.auth.currentSession != null;
    notifyListeners();
  }

  /// L'état provient de l'unique abonnement Supabase tenu par
  /// [currentSessionProvider]. Une session nulle n'est donc publiée que lors
  /// d'un véritable événement signedOut ou au premier bootstrap.
  void updateSession(Session? session) {
    final nextHasSession = session != null;
    if (_hasSession == nextHasSession) return;
    _hasSession = nextHasSession;
    notifyListeners();
  }
}

/// Singleton global — créé une seule fois, accessible depuis bootstrap.dart.
final appNotifier = AppNotifier();

// ─── GoRouter singleton ───────────────────────────────────────────────────────

final _rootKey = GlobalKey<NavigatorState>();

GoRouter? _routerSingleton;

GoRouter _buildRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    // GoRouter re-évalue le redirect à chaque notification de appNotifier.
    refreshListenable: appNotifier,
    redirect: (context, state) {
      // 1. Si Supabase n'est pas encore initialisé, rester sur la splash.
      if (!appNotifier.ready) return null;

      // 2. Vérifier la session.
      final isAuthenticated = appNotifier.hasSession;

      final loc = state.matchedLocation;
      if (isAuthCallbackLocation(loc)) return null;
      if (loc == '/auth/recovery') {
        return isAuthenticated ? null : '/forgot-password';
      }

      // Routes publiques (accessibles sans compte)
      const publicRoutes = [
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
      ];
      final isPublic = publicRoutes.any((r) => loc.startsWith(r));

      // Non connecté + route protégée → welcome
      if (!isAuthenticated && !isPublic) return '/welcome';

      // Connecté + route publique → dashboard
      if (isAuthenticated && isPublic) return '/home';

      // Racine '/' → dashboard ou welcome
      if (loc == '/') return isAuthenticated ? '/home' : '/welcome';

      return null;
    },
    routes: [
      // ── Shell (bottom nav) ─────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BiometricGate(child: AppShell(navigationShell: navigationShell)),
        branches: [
          // Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Wallets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallets',
                builder: (context, state) => const WalletsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const AddWalletScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => WalletDetailsScreen(
                      walletId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => EditWalletScreen(
                          walletId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => TransactionDetailsScreen(
                      transactionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Scan reçu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                builder: (context, state) => const ScanReceiptScreen(),
                routes: [
                  GoRoute(
                    path: 'confirm',
                    builder: (context, state) {
                      final draft = state.extra;
                      if (draft is! ReceiptDraft) {
                        return const ScanReceiptScreen();
                      }
                      return ConfirmReceiptScreen(draft: draft);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Paramètres
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) =>
                        const CategoryManagementScreen(),
                  ),
                  GoRoute(
                    path: 'recurring',
                    builder: (context, state) =>
                        const RecurringTransactionsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Routes hors shell ──────────────────────────────────────────────
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => AddTransactionScreen(
          initialType: state.uri.queryParameters['type'] ?? 'EXPENSE',
        ),
      ),
      GoRoute(
        path: '/transfer',
        builder: (context, state) => const TransferScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => BiometricGate(child: child),
        routes: [
          GoRoute(
            path: '/plan',
            builder: (context, state) => const PlanHubScreen(),
            routes: [
              GoRoute(
                path: 'budgets',
                builder: (context, state) => const BudgetDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const BudgetFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => BudgetDetailScreen(
                      budgetId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'what-if',
                builder: (context, state) => const WhatIfScreen(),
              ),
              GoRoute(
                path: 'goals',
                builder: (context, state) => const GoalsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const GoalFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => GoalDetailScreen(
                      goalId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'portfolio',
                builder: (context, state) => const PortfolioScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PortfolioFormScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'assets/new',
                builder: (context, state) => AssetFormScreen(
                  portfolioId: state.uri.queryParameters['portfolio'] ?? '',
                ),
              ),
              GoRoute(
                path: 'assets/:id',
                builder: (context, state) => AssetDetailScreen(
                  assetId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'insights',
                builder: (context, state) => const InsightsScreen(),
              ),
              GoRoute(
                path: 'studio',
                builder: (context, state) => const StudioScreen(),
              ),
              GoRoute(
                path: 'split',
                builder: (context, state) => const SplitExpenseScreen(),
              ),
              GoRoute(
                path: 'planner',
                builder: (context, state) => const PlannerScreen(),
              ),
              GoRoute(
                path: 'assistant',
                builder: (context, state) => const AssistantScreen(),
                routes: [
                  GoRoute(
                    path: 'confirm',
                    builder: (context, state) {
                      final draft = state.extra;
                      if (draft is! TransactionDraft) return const AssistantScreen();
                      return DraftTransactionScreen(draft: draft);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Module User & Security ─────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/auth/recovery',
        builder: (context, state) => const RecoveryPasswordScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const BiometricGate(child: ProfileScreen()),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) =>
            const BiometricGate(child: SupportRequestScreen()),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) =>
            const BiometricGate(child: AdminUsersDashboardScreen()),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) =>
            const BiometricGate(child: SecuritySettingsScreen()),
        routes: [
          GoRoute(
            path: '2fa',
            builder: (context, state) =>
                const BiometricGate(child: TwoFactorScreen()),
          ),
          GoRoute(
            path: 'biometric',
            builder: (context, state) =>
                const BiometricGate(child: BiometricScreen()),
          ),
          GoRoute(
            path: 'devices',
            builder: (context, state) =>
                const BiometricGate(child: DevicesScreen()),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) =>
                const BiometricGate(child: LoginHistoryScreen()),
          ),
        ],
      ),
    ],
  );
}

/// Provider qui retourne le GoRouter singleton.
/// Le GoRouter est créé une seule fois et réutilisé — jamais recréé.
final routerProvider = Provider<GoRouter>((ref) {
  ref.listen(currentSessionProvider, (_, session) {
    appNotifier.updateSession(session);
  });
  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    if (previous != null && previous != next) {
      clearUserScopedProviders(ref);
    }
  });
  _routerSingleton ??= _buildRouter();
  return _routerSingleton!;
});
