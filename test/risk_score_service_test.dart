import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/auth/models/security_event.dart';
import 'package:wallet_app/features/auth/services/risk_score_service.dart';

void main() {
  group('RiskScoreService', () {
    final now = DateTime.utc(2026, 10, 17, 12);

    SecurityEvent event(String type, DateTime createdAt) => SecurityEvent(
      id: type,
      userId: 'user-1',
      eventType: type,
      createdAt: createdAt,
    );

    test('scores missing verified MFA without claiming certainty', () {
      final assessment = RiskScoreService.assess(
        const [],
        mfaEnabled: false,
        now: now,
      );

      expect(assessment.score, 20);
      expect(assessment.reasons.single, contains('MFA'));
    });

    test('uses only the documented recent Wallet-reported signals', () {
      final assessment = RiskScoreService.assess(
        [
          event('password_reset', now.subtract(const Duration(hours: 1))),
          event('password_reset', now.subtract(const Duration(hours: 2))),
          event('mfa_disable', now.subtract(const Duration(days: 2))),
          event('sign_in', now.subtract(const Duration(minutes: 1))),
        ],
        mfaEnabled: true,
        now: now,
      );

      expect(assessment.score, 50);
      expect(assessment.reasons, hasLength(2));
      expect(assessment.reasons.join(' '), contains('réinitialisation'));
      expect(assessment.reasons.join(' '), contains('désactivation'));
    });

    test('does not count old client events as current risk signals', () {
      final assessment = RiskScoreService.assess(
        [
          event('password_reset', now.subtract(const Duration(days: 31))),
          event('mfa_disable', now.subtract(const Duration(days: 31))),
        ],
        mfaEnabled: true,
        now: now,
      );

      expect(assessment.score, 0);
      expect(assessment.reasons.single, contains('ne garantit pas'));
    });
  });
}
