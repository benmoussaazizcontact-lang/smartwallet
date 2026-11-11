import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/i18n/l10n_ext.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../core/theme/app_radius.dart';
import '../models/security_event.dart';
import '../repositories/security_repository.dart';
import '../services/risk_score_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_widgets.dart';

class LoginHistoryScreen extends ConsumerWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final historyAsync = ref.watch(securityHistoryProvider);
    final riskAsync = ref.watch(riskScoreProvider);
    final factorsAsync = ref.watch(mfaFactorsProvider);
    final biometricAsync = ref.watch(biometricEnabledProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.loginHistory)),
        body: Center(
          child: Text(context.l10n.signInToSeeHistory),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.loginHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(securityHistoryForUserProvider);
              ref.invalidate(riskScoreForUserProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const _HistoryDisclosure(),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(securityHistoryForUserProvider),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 56,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Aucun événement enregistré',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final assessment = riskAsync.asData?.value;
                final score = assessment?.score ?? 0;
                final hasMfa = factorsAsync.asData?.value.totp.any(
                  (factor) => factor.status.name == 'verified',
                );
                final hasBio = biometricAsync.asData?.value;
                final recommendations = RiskScoreService.recommendations(
                  score,
                  hasMfa,
                  hasBio,
                );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Score de risque
                    riskAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (assessment) => assessment == null
                          ? const SizedBox.shrink()
                          : _RiskSummary(
                              score: assessment.score,
                              recommendations: recommendations,
                            ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      '${events.length} événements',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...events.map((e) => _EventTile(event: e)),
                  ],
                );
              },
              skipLoadingOnRefresh: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDisclosure extends StatelessWidget {
  const _HistoryDisclosure();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Text(
        'Activités consignées par Wallet. Supabase Auth ne fournit pas au client mobile l’historique complet des connexions, les tentatives échouées, l’adresse IP ou la localisation ; aucune donnée de ce type n’est inventée ici.',
        style: TextStyle(fontSize: 11, height: 1.4),
      ),
    );
  }
}

class _RiskSummary extends StatelessWidget {
  const _RiskSummary({required this.score, required this.recommendations});
  final int score;
  final List<String> recommendations;

  Color get _color => score < 30
      ? AppColors.success
      : score < 60
      ? AppColors.warning
      : score < 80
      ? Colors.orange
      : AppColors.danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _color.withValues(alpha: 0.12),
            _color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Score de risque',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              RiskBadge(score: score),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: _color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Recommandations',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...recommendations.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_right_rounded, color: _color, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final SecurityEvent event;

  Color get _iconColor => event.success
      ? switch (event.eventType) {
          'sign_in' => AppColors.success,
          'mfa_enroll' => AppColors.primary,
          'biometric' => AppColors.secondary,
          'mfa_disable' => AppColors.warning,
          _ => AppColors.primary,
        }
      : AppColors.danger;

  IconData get _icon => switch (event.eventType) {
    'sign_in' => Icons.login_rounded,
    'sign_up' => Icons.person_add_rounded,
    'sign_out' => Icons.logout_rounded,
    'mfa_enroll' => Icons.phonelink_lock_rounded,
    'mfa_verify' => Icons.verified_user_rounded,
    'mfa_disable' => Icons.no_encryption_rounded,
    'biometric' => Icons.fingerprint_rounded,
    'password_reset' => Icons.lock_reset_rounded,
    'password_change' => Icons.lock_outlined,
    'profile_update' => Icons.edit_rounded,
    _ => Icons.history_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final brightness = Theme.of(context).brightness;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.eventLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (!event.success)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Échoué',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(
                        fmt.format(event.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                      if (event.metadata?['platform'] is String)
                        Text(
                          '· ${event.metadata!['platform']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary(brightness),
                          ),
                        ),
                      Text(
                        event.success ? '· Réussi' : '· Échoué',
                        style: TextStyle(
                          fontSize: 11,
                          color: event.success
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  if (event.riskScore > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Risque : +${event.riskScore} pts',
                      style: TextStyle(
                        fontSize: 11,
                        color: event.riskScore >= 20
                            ? AppColors.danger
                            : AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
