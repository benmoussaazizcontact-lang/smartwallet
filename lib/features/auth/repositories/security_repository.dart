import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import 'auth_repository.dart';
import '../models/security_event.dart';
import '../services/risk_score_service.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepository(ref.watch(supabaseProvider));
});

final mfaFactorsProvider = FutureProvider<AuthMFAListFactorsResponse>((
  ref,
) async {
  if (ref.watch(currentSessionProvider) == null) {
    throw const AppException('Session absente; statut MFA indisponible.');
  }
  return ref
      .read(authRepositoryProvider)
      .listMfaFactors()
      .timeout(const Duration(seconds: 8));
});

class SecurityRepository {
  SecurityRepository(this._client);

  final SupabaseClient _client;

  /// Enregistre un événement de sécurité dans la table `security_events`.
  Future<void> logEvent({
    required String eventType,
    bool success = true,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentSession?.user.id;
    if (userId == null) return;

    try {
      await _client
          .from('security_events')
          .insert({
            'user_id': userId,
            'event_type': eventType,
            'success': success,
            'metadata': {
              'source': 'wallet_client',
              'platform': defaultTargetPlatform.name,
              ...?metadata,
            },
          })
          .timeout(const Duration(seconds: 4));
    } catch (error, stackTrace) {
      debugPrint('Échec de journalisation sécurité ($eventType): $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Récupère l'historique des événements de sécurité (100 derniers).
  Future<List<SecurityEvent>> fetchHistory() async {
    final userId = _client.auth.currentSession?.user.id;
    if (userId == null) return [];
    try {
      final rows = await _client
          .from('security_events')
          .select(
            'id,user_id,event_type,success,risk_score,metadata,created_at',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 12));
      return rows.map((r) => SecurityEvent.fromMap(r)).toList();
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST205') {
        throw const AppException(
          'L’historique de sécurité n’est pas encore configuré sur Supabase. '
          'Appliquez les migrations de sécurité du projet puis réessayez.',
          code: 'security_events_not_migrated',
        );
      }
      throw AppException.from(error);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Calcule le score de risque global basé sur l'historique.
  Future<RiskAssessment> computeRiskScore({required bool mfaEnabled}) async {
    final events = await fetchHistory();
    return RiskScoreService.assess(events, mfaEnabled: mfaEnabled);
  }

  /// ─── Sessions (appareil courant uniquement) ───────────────────────────
  /// ⚠️ Supabase ne fournit pas de liste multi-appareils via le SDK client.
  /// Seule la session courante est accessible. Une Edge Function serait
  /// nécessaire pour lister toutes les sessions (optionnel & non implémenté).

  /// Retourne les infos de la session courante
  Session? get currentSession => _client.auth.currentSession;

  /// Déconnecte la session courante
  Future<void> revokeCurrentSession() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}

/// Provider de l'historique de sécurité
final securityHistoryForUserProvider =
    FutureProvider.family<List<SecurityEvent>, String>((ref, userId) async {
  final events = await ref.watch(securityRepositoryProvider).fetchHistory();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return events;
});

final securityHistoryProvider = Provider<AsyncValue<List<SecurityEvent>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(securityHistoryForUserProvider(userId));
});

/// Provider du score de risque
final riskScoreForUserProvider =
    FutureProvider.family<RiskAssessment?, String>((ref, userId) async {
  if (ref.read(currentUserIdProvider) != userId) return null;
  final events = await ref.watch(securityHistoryForUserProvider(userId).future);
  final factors = await ref.watch(mfaFactorsProvider.future);
  if (ref.read(currentUserIdProvider) != userId) return null;
  final mfaEnabled = factors.totp.any(
    (factor) => factor.status.name == 'verified',
  );
  return RiskScoreService.assess(events, mfaEnabled: mfaEnabled);
});

final riskScoreProvider = Provider<AsyncValue<RiskAssessment?>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData(null);
  return ref.watch(riskScoreForUserProvider(userId));
});
