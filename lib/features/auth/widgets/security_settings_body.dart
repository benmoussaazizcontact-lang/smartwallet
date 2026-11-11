import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../models/auth_user.dart';
import '../providers/auth_providers.dart';
import '../repositories/auth_repository.dart';
import '../services/risk_score_service.dart';
import 'auth_widgets.dart';

/// Contenu principal de l'écran Sécurité (réutilisable avec profil ou session).
class SecuritySettingsBody extends ConsumerWidget {
  const SecuritySettingsBody({
    super.key,
    required this.user,
    required this.riskAsync,
    required this.mfaEnabled,
    required this.onRetryMfa,
  });

  final AppUser user;
  final AsyncValue<RiskAssessment?> riskAsync;
  final AsyncValue<bool> mfaEnabled;
  final VoidCallback onRetryMfa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SecurityStatusCard(mfaEnabled: mfaEnabled, onRetry: onRetryMfa),
        const SizedBox(height: 16),
        riskAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text('Estimation de risque indisponible : $error'),
            ),
          ),
          data: (assessment) => _RiskCard(assessment: assessment),
        ),
        const SizedBox(height: 16),
        _SectionTitle('Authentification'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SecurityTile(
                icon: Icons.phonelink_lock_rounded,
                title: 'Authentification à deux facteurs',
                subtitle: mfaEnabled.when(
                  loading: () => 'Vérification du statut…',
                  error: (_, _) => 'Statut indisponible · Réessayer',
                  data: (enabled) => enabled ? 'Activé — TOTP' : 'Non activé',
                ),
                iconColor: mfaEnabled.when(
                  loading: () => AppColors.primary,
                  error: (_, _) => AppColors.warning,
                  data: (enabled) =>
                      enabled ? AppColors.success : AppColors.warning,
                ),
                trailing: mfaEnabled.hasError
                    ? IconButton(
                        tooltip: 'Réessayer',
                        onPressed: onRetryMfa,
                        icon: const Icon(Icons.refresh_rounded),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/security/2fa'),
              ),
              const Divider(height: 1, indent: 74),
              SecurityTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biométrie',
                subtitle: 'Empreinte digitale ou Face ID',
                iconColor: AppColors.primary,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/security/biometric'),
              ),
              const Divider(height: 1, indent: 74),
              SecurityTile(
                icon: Icons.lock_reset_rounded,
                title: 'Changer le mot de passe',
                subtitle: 'Envoyer un lien de réinitialisation',
                iconColor: AppColors.secondary,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _sendReset(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle('Sessions & Appareils'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SecurityTile(
                icon: Icons.devices_rounded,
                title: 'Appareils',
                subtitle: 'Session courante',
                iconColor: AppColors.primary,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/security/devices'),
              ),
              const Divider(height: 1, indent: 74),
              SecurityTile(
                icon: Icons.history_rounded,
                title: 'Historique de connexion',
                subtitle: 'Activités récentes sur votre compte',
                iconColor: AppColors.secondary,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/security/history'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _sendReset(BuildContext context, WidgetRef ref) async {
    final email =
        ref.read(authRepositoryProvider).currentUser?.email ?? user.email;
    if (email.isEmpty) return;
    final sent = await ref
        .read(authFormProvider.notifier)
        .sendPasswordReset(email);
    if (context.mounted) {
      final error = ref.read(authFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Lien de réinitialisation envoyé ✓'
                : error?.toString() ??
                      'Impossible d’envoyer le lien. Réessayez plus tard.',
          ),
        ),
      );
    }
  }
}

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard({required this.mfaEnabled, required this.onRetry});

  final AsyncValue<bool> mfaEnabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = mfaEnabled.when(
      loading: () => 'Vérification du second facteur…',
      error: (_, _) => 'Statut MFA temporairement indisponible',
      data: (enabled) =>
          enabled ? 'Compte protégé par TOTP' : 'TOTP non configuré',
    );
    final color = mfaEnabled.when(
      loading: () => AppColors.primary,
      error: (_, _) => AppColors.warning,
      data: (enabled) => enabled ? AppColors.success : AppColors.warning,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.shield_outlined, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sécurité du compte',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(status, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (mfaEnabled.isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (mfaEnabled.hasError)
              IconButton(
                tooltip: 'Réessayer',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              )
            else
              Icon(
                mfaEnabled.asData?.value == true
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.assessment});
  final RiskAssessment? assessment;

  Color _colorFor(int score) => score < 30
      ? AppColors.success
      : score < 60
      ? AppColors.warning
      : score < 80
      ? Colors.orange
      : AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final assessment = this.assessment;
    if (assessment == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Estimation du risque indisponible sans session active.'),
        ),
      );
    }
    final score = assessment.score;
    final color = _colorFor(score);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 6,
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score de risque',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                RiskBadge(score: score),
                const SizedBox(height: 6),
                Text(
                  score < 30
                      ? 'Peu de signaux dans les données disponibles.'
                      : score < 60
                      ? 'Estimation modérée; vérifiez les raisons ci-dessous.'
                      : 'Estimation élevée; vérifiez les raisons ci-dessous.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ...assessment.reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '• $reason',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estimation indicative fondée sur le MFA Supabase et les événements déclarés par Wallet. Ce score ne vérifie pas les connexions côté serveur.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
