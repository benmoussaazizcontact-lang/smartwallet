import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/l10n_ext.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/auth_providers.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);

    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.devices)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avertissement limitation
          _LimitationBanner(),
          const SizedBox(height: 20),

          Text(
            l10n.currentSession,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          if (session == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucune session active'),
              ),
            )
          else
            _SessionCard(session: session, ref: ref),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.ref});
  final Session session;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expiresAt = session.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appareil actuel',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '● Session active',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.vpn_key_outlined,
              label: 'Token type',
              value: session.tokenType,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Expiration',
              value: expiresAt != null
                  ? '${expiresAt.day}/${expiresAt.month}/${expiresAt.year} à ${expiresAt.hour}:${expiresAt.minute.toString().padLeft(2, '0')}'
                  : '—',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Utilisateur',
              value: session.user.email ?? session.user.id,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(l10n.signOutThisDevice),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                onPressed: () => _revoke(context, ref),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phonelink_erase_outlined, size: 18),
                label: Text(l10n.signOutOtherSessions),
                onPressed: () => _revokeOtherSessions(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.signOutThisDeviceTitle),
        content: Text(ctx.l10n.signOutWalletBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authFormProvider.notifier).signOut();
      if (context.mounted) context.go('/welcome');
    }
  }

  Future<void> _revokeOtherSessions(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.signOutOtherSessionsTitle),
        content: Text(ctx.l10n.signOutWalletBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.revoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(authFormProvider.notifier).signOutOtherSessions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les autres sessions ont été révoquées.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de révoquer les sessions : $error'),
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LimitationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le SDK Supabase ne fournit pas les détails d’une liste d’appareils. Il permet toutefois de fermer cette session ou de révoquer les autres sessions du compte.',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
