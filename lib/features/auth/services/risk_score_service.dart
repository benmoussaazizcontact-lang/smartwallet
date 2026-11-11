import '../models/security_event.dart';

/// Informational, client-side estimate. It is never an authorization signal.
class RiskAssessment {
  const RiskAssessment({required this.score, required this.reasons});

  final int score;
  final List<String> reasons;
}

class RiskScoreService {
  /// Initial, documented weights (not universal security thresholds):
  /// * no currently verified Supabase MFA factor: +20;
  /// * a Wallet-recorded password reset in the last 24h: +15 each, capped +30;
  /// * a Wallet-recorded MFA removal in the last 30 days: +20.
  ///
  /// Wallet events are client-reported and can be incomplete or manipulated.
  /// Supabase Auth audit logs and server policy remain authoritative. We do not
  /// infer failed logins, IP/location, unfamiliar devices, or safe account state.
  static RiskAssessment assess(
    List<SecurityEvent> events, {
    required bool mfaEnabled,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final reasons = <String>[];
    var score = 0;

    if (!mfaEnabled) {
      score += 20;
      reasons.add('Aucun facteur MFA vérifié n’est actif sur ce compte (+20).');
    }

    final recentResets = events.where((event) {
      final age = clock.difference(event.createdAt);
      return event.eventType == 'password_reset' &&
          event.success &&
          !age.isNegative &&
          age <= const Duration(hours: 24);
    }).length;
    if (recentResets > 0) {
      final points = (recentResets * 15).clamp(0, 30);
      score += points;
      reasons.add(
        '$recentResets réinitialisation(s) de mot de passe déclarée(s) par Wallet dans les dernières 24 h (+$points).',
      );
    }

    final recentMfaRemovals = events.where((event) {
      final age = clock.difference(event.createdAt);
      return event.eventType == 'mfa_disable' &&
          event.success &&
          !age.isNegative &&
          age <= const Duration(days: 30);
    }).length;
    if (recentMfaRemovals > 0) {
      score += 20;
      reasons.add(
        'Wallet a enregistré une désactivation du MFA dans les 30 derniers jours (+20).',
      );
    }

    if (reasons.isEmpty) {
      reasons.add(
        'Aucun signal de risque disponible dans les données Wallet récentes; cela ne garantit pas la sécurité du compte.',
      );
    }
    return RiskAssessment(score: score.clamp(0, 100), reasons: reasons);
  }

  static List<String> recommendations(
    int score,
    bool? hasMfa,
    bool? hasBiometric,
  ) {
    final rec = <String>[];
    if (hasMfa == false) {
      rec.add('Activez l’authentification multifacteur (MFA).');
    }
    if (hasBiometric == false) {
      rec.add('Le verrouillage biométrique local peut protéger cet appareil.');
    }
    if (score >= 60) {
      rec.add('Vérifiez les événements récents de votre compte.');
    }
    if (rec.isEmpty && hasMfa != null && hasBiometric != null) {
      rec.add(
        'Aucune action recommandée selon les signaux Wallet disponibles.',
      );
    } else if (rec.isEmpty) {
      rec.add('Statut MFA ou biométrique encore indisponible.');
    }
    return rec;
  }
}
