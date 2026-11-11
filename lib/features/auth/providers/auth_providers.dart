import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/session/clear_user_state.dart';
import 'auth_session_refresh.dart';
import '../repositories/auth_repository.dart';
import '../utils/session_user.dart';
import '../repositories/security_repository.dart';
import '../services/biometric_service.dart';

// ─── Services ────────────────────────────────────────────────────────────────

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

// ─── Biométrie disponible ─────────────────────────────────────────────────────

final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(biometricServiceProvider).isAvailable();
});

// ─── Biométrie activée pour l'utilisateur courant ────────────────────────────

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  ref.watch(currentSessionProvider);
  final user =
      ref.watch(authUserProvider).asData?.value ??
      appUserFromSession(ref.read(currentSessionProvider));
  if (user == null) return false;
  return ref.watch(biometricServiceProvider).isEnabledForUser(user.id);
});

// ─── Notifier : état du formulaire de connexion ──────────────────────────────
// Riverpod 3.x : Notifier<T> remplace StateNotifier<T>

class AuthFormNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      unawaited(
        ref
            .read(securityRepositoryProvider)
            .logEvent(eventType: 'sign_in', success: true),
      );
      refreshUserModuleProviders(ref);
      ref.invalidate(mfaFactorsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      // Failed Auth attempts cannot be attributed to an authenticated user
      // from the mobile client. Supabase Auth logs remain the authoritative
      // source; do not create a misleading client audit row here.
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
          );
      unawaited(
        ref
            .read(securityRepositoryProvider)
            .logEvent(eventType: 'sign_up', success: true),
      );
      refreshUserModuleProviders(ref);
      ref.invalidate(mfaFactorsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    // Drop cached finance and profile data before the network call returns,
    // then again after the session is gone.
    clearUserScopedProviders(ref);
    await ref.read(authRepositoryProvider).signOut();
    ref.read(biometricServiceProvider).clearRecentAuthentication();
    refreshUserModuleProviders(ref);
    clearUserScopedProviders(ref);
    state = const AsyncValue.data(null);
  }

  /// Revokes all other sessions while keeping this device signed in.
  Future<void> signOutOtherSessions() async {
    await ref.read(authRepositoryProvider).signOut(scope: SignOutScope.others);
    refreshUserModuleProviders(ref);
    ref.invalidate(mfaFactorsProvider);
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      unawaited(
        ref
            .read(securityRepositoryProvider)
            .logEvent(eventType: 'password_reset'),
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void clearError() => state = const AsyncValue.data(null);
}

final authFormProvider = NotifierProvider<AuthFormNotifier, AsyncValue<void>>(
  AuthFormNotifier.new,
);

// ─── Notifier : MFA ──────────────────────────────────────────────────────────

class MfaNotifier extends Notifier<AsyncValue<void>> {
  String? _pendingFactorId;
  String? _pendingTotpSecret;
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Retourne l'URI otpauth:// du QR code, ou null en cas d'erreur
  Future<String?> enrollTotp() async {
    state = const AsyncValue.loading();
    try {
      final response = await ref.read(authRepositoryProvider).enrollTotp();
      _pendingFactorId = response.id;
      _pendingTotpSecret = response.totp?.secret;
      state = const AsyncValue.data(null);
      return response.totp?.uri;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> getPendingFactorId() async {
    return _pendingFactorId;
  }

  String? getPendingTotpSecret() => _pendingTotpSecret;

  Future<bool> verifyAndActivate({
    required String factorId,
    required String code,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyTotpEnrollment(factorId: factorId, code: code);
      unawaited(
        ref
            .read(securityRepositoryProvider)
            .logEvent(eventType: 'mfa_enroll', success: true),
      );
      state = const AsyncValue.data(null);
      _pendingFactorId = null;
      _pendingTotpSecret = null;
      ref.invalidate(mfaFactorsProvider);
      return true;
    } catch (e, st) {
      unawaited(
        ref
            .read(securityRepositoryProvider)
            .logEvent(eventType: 'mfa_enroll', success: false),
      );
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> disable(String factorId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).unenrollMfa(factorId);
      unawaited(
        ref.read(securityRepositoryProvider).logEvent(eventType: 'mfa_disable'),
      );
      state = const AsyncValue.data(null);
      ref.invalidate(mfaFactorsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void clearError() => state = const AsyncValue.data(null);
}

final mfaNotifierProvider = NotifierProvider<MfaNotifier, AsyncValue<void>>(
  MfaNotifier.new,
);
