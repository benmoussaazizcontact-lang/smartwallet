import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_redirect.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../shared/models/profile.dart';
import '../../notifications/services/push_notification_service.dart';
import '../models/auth_user.dart'; // AppUser

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;
  final Set<String> _removedMfaFactorIds = <String>{};

  // ─── Session courante ────────────────────────────────────────────────────

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentSession != null;

  // ─── Authentification ────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        emailRedirectTo: authCallbackUrl,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'full_name': '${firstName.trim()} ${lastName.trim()}',
        },
      );
      final user = response.user;
      if (user == null) {
        throw const AppException('Inscription échouée. Réessayez.');
      }
      _removedMfaFactorIds.clear();
      await ensureProfile(user);
      return response;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = response.user;
      if (response.session == null || user == null) {
        throw const AppException('Connexion échouée. Réessayez.');
      }
      _removedMfaFactorIds.clear();
      return response;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    try {
      final userId = currentUser?.id;
      if (userId != null) {
        await PushNotificationService.instance.removeSignedInDevice(
          _client,
          userId,
        );
      }
      await _client.auth.signOut(scope: scope);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: authCallbackUrl,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
        emailRedirectTo: authCallbackUrl,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ─── Profil (rétro-compatibilité avec settings_screen) ──────────────────

  Future<Profile?> fetchProfile() async {
    final userId = currentSession?.user.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return Profile.fromMap(row);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Crée la ligne `profiles` si le trigger Supabase ne l'a pas encore fait.
  Future<void> ensureProfile(User user) async {
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) return;

      final meta = user.userMetadata ?? {};
      final firstName = meta['first_name'] as String?;
      final lastName = meta['last_name'] as String?;
      final fullName =
          (meta['full_name'] as String?) ??
          '${firstName ?? ''} ${lastName ?? ''}'.trim();

      await _client.from('profiles').insert({
        'id': user.id,
        'first_name': ?firstName,
        'last_name': ?lastName,
        if (fullName.isNotEmpty) 'full_name': fullName,
      });
    } catch (error, stackTrace) {
      // Non bloquant — le profil peut être reconstruit depuis les métadonnées Auth.
      debugPrint('Profil non initialisé après inscription : $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> updateModulePreferences({
    String? preferredCurrency,
    String? themeMode,
  }) async {
    final userId = currentSession?.user.id;
    if (userId == null) throw const AppException('Session expirée');
    try {
      await _client
          .from('profiles')
          .update({
            'preferred_currency': ?preferredCurrency,
            'theme_mode': ?themeMode,
          })
          .eq('id', userId);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ─── MFA TOTP — API supabase_flutter 2.x (paramètres directs) ───────────

  /// Enrôle un facteur TOTP. Retourne la réponse contenant le QR code URI.
  Future<AuthMFAEnrollResponse> enrollTotp() async {
    try {
      if (currentSession == null || currentUser == null) {
        throw const AppException(
          'Votre session a expiré. Reconnectez-vous avant de configurer le 2FA.',
        );
      }

      // A page refresh can lose the in-memory pending factor ID. Remove only
      // unverified TOTP enrollments before starting another one; never touch
      // verified factors. Supabase requires AAL2 to remove verified factors.
      final response = await _client.auth.getUser();
      final factors = response.user?.factors ?? const <Factor>[];
      for (final factor in factors) {
        if (factor.factorType == FactorType.totp &&
            factor.status != FactorStatus.verified) {
          try {
            await _client.auth.mfa.unenroll(factor.id);
            _removedMfaFactorIds.add(factor.id);
          } catch (error) {
            // Still start a distinct enrollment name if Supabase refuses to
            // remove an abandoned pending factor. The failure is observable
            // for diagnosis and does not alter session state.
            debugPrint('Could not remove pending TOTP factor: $error');
          }
        }
      }

      final label =
          'Wallet App ${DateTime.now().toUtc().millisecondsSinceEpoch}';
      return await _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'Wallet App',
        friendlyName: label,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Vérifie un code TOTP pour finaliser l'enrôlement.
  Future<void> verifyTotpEnrollment({
    required String factorId,
    required String code,
  }) async {
    try {
      final challenge = await _client.auth.mfa.challenge(factorId: factorId);
      await _client.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Liste les facteurs MFA enrôlés.
  Future<AuthMFAListFactorsResponse> listMfaFactors() async {
    try {
      // gotrue 2.27's listFactors() calls refreshSession() unconditionally.
      // That adds a network round-trip (and can make a temporary refresh
      // failure look like a logout) whenever Security is opened. Prefer the
      // user/factors snapshot already attached to the persisted session.
      final currentUser = currentSession?.user;
      if (currentUser == null) {
        throw const AppException('Session absente. Reconnectez-vous.');
      }
      var factors = currentUser.factors;
      // Older persisted sessions may not include factors. Fetch the user
      // once with the current JWT; getUser does not refresh or sign out.
      if (factors == null) {
        // A successful /user response with `factors: null` means that the
        // account has no enrolled factors (the same empty-state semantics
        // used by gotrue's listFactors implementation). Only an actual fetch
        // failure is an unavailable status; never refresh or sign out here.
        final response = await _client.auth.getUser();
        final user = response.user;
        if (user == null) {
          throw const AppException(
            'Impossible de vérifier le statut MFA pour cette session.',
          );
        }
        factors = user.factors ?? <Factor>[];
      }
      final verified = factors
          .where((factor) => !_removedMfaFactorIds.contains(factor.id))
          .where((factor) => factor.status == FactorStatus.verified)
          .toList(growable: false);
      return AuthMFAListFactorsResponse(
        all: factors
            .where((factor) => !_removedMfaFactorIds.contains(factor.id))
            .toList(growable: false),
        totp: verified
            .where((factor) => factor.factorType == FactorType.totp)
            .toList(growable: false),
        phone: verified
            .where((factor) => factor.factorType == FactorType.phone)
            .toList(growable: false),
        webauthn: verified
            .where((factor) => factor.factorType == FactorType.webauthn)
            .toList(growable: false),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Désactive un facteur MFA.
  Future<void> unenrollMfa(String factorId) async {
    try {
      await _client.auth.mfa.unenroll(factorId);
      // If the optional refresh below fails offline, do not keep rendering
      // the factor as active in this process after Supabase accepted removal.
      _removedMfaFactorIds.add(factorId);
      // Supabase may leave the old AAL2 claim in the current JWT until the
      // next refresh. Refresh best-effort; never sign out on a network error.
      try {
        await _client.auth.refreshSession();
      } catch (error) {
        // The factor is already removed. Keep the valid local session and
        // allow normal token refresh to reconcile the assurance claim.
        debugPrint('Session AAL refresh after MFA removal failed: $error');
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Vérifie un code TOTP lors de la connexion MFA (challenge flow).
  Future<void> verifyMfaChallenge({
    required String factorId,
    required String code,
  }) async {
    try {
      final challenge = await _client.auth.mfa.challenge(factorId: factorId);
      await _client.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code,
      );
      // Caller invokes this only for an explicit, identity-sensitive action.
      // The local audit entry is best-effort and never changes auth state.
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Niveau d'authentification actuel (aal1 / aal2).
  Future<AuthMFAGetAuthenticatorAssuranceLevelResponse> getAuthLevel() async {
    return _client.auth.mfa.getAuthenticatorAssuranceLevel();
  }

  /// Deletes the signed-in auth user through the pending server function.
  /// A missing function deletes nothing.
  Future<void> deleteOwnAccount() async {
    if (_client.auth.currentUser == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    try {
      await _client.rpc('delete_own_account');
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('delete_own_account') ||
          text.contains('could not find') ||
          text.contains('pgrst202') ||
          text.contains('404')) {
        throw const AppException(
          'Account deletion is not enabled on the server. No data was deleted.',
          code: 'delete_unavailable',
        );
      }
      throw AppException.from(error);
    }
  }
}

// ─── Rétro-compatibilité : profileProvider (utilisé par settings_screen) ─────

final profileProvider = Provider<AsyncValue<Profile?>>((ref) {
  return ref.watch(authUserProvider).when(
    data: (user) => AsyncData(
      user == null
          ? null
          : Profile(
              id: user.id,
              fullName: user.fullName,
              preferredCurrency: user.preferredCurrency,
              themeMode: user.themeMode,
            ),
    ),
    error: (error, stackTrace) => AsyncError(error, stackTrace),
    loading: () => const AsyncLoading(),
  );
});

// ─── Provider AuthUser enrichi (utilisé par les écrans auth) ─────────────────

AppUser _appUserFromAuthUser(User user, {bool mfaEnabled = false}) {
  return AppUser(
    id: user.id,
    email: user.email ?? '',
    firstName: user.userMetadata?['first_name'] as String?,
    lastName: user.userMetadata?['last_name'] as String?,
    emailConfirmedAt: DateTime.tryParse(user.emailConfirmedAt ?? ''),
    lastSignInAt: DateTime.tryParse(user.lastSignInAt ?? ''),
    mfaEnabled: mfaEnabled,
  );
}

Future<AppUser?> _loadAppUser(SupabaseClient client, User user) async {
  Map<String, dynamic>? row;
  try {
    row = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  } catch (error) {
    // The session-backed identity remains usable while profile data is
    // unavailable; keep the failure visible for permissions/network diagnosis.
    debugPrint('Lecture du profil indisponible : $error');
  }

  if (row == null) {
    return _appUserFromAuthUser(user);
  }

  return AppUser.fromMap(
    profile: row,
    email: user.email ?? '',
    emailConfirmedAt: DateTime.tryParse(user.emailConfirmedAt ?? ''),
    lastSignInAt: DateTime.tryParse(user.lastSignInAt ?? ''),
  );
}

final authUserForSessionProvider = FutureProvider.family<AppUser?, String>((
  ref,
  userId,
) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null || session.user.id != userId) return null;
  final client = ref.watch(supabaseProvider);
  try {
    return await _loadAppUser(client, session.user);
  } catch (_) {
    return _appUserFromAuthUser(session.user);
  }
});

final authUserProvider = Provider<AsyncValue<AppUser?>>((ref) {
  if (!ref.watch(supabaseBootstrapReadyProvider)) return const AsyncData(null);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData(null);
  return ref.watch(authUserForSessionProvider(userId));
});

/// Chargé uniquement sur l'écran Sécurité : ce contrôle réseau ne bloque plus
/// l'ouverture de Settings ni le chargement des informations du profil.
