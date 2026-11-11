import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/l10n_ext.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/error_view.dart';
import '../providers/auth_providers.dart';
import '../repositories/auth_repository.dart';
import '../repositories/security_repository.dart';
import '../widgets/auth_widgets.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  String? _totpSecret;
  String? _factorId;
  String? _codeError;
  final _codeCtrl = TextEditingController();
  var _step = _Step.overview;
  var _cancelingEnrollment = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startEnroll() async {
    final provisioningUri = await ref
        .read(mfaNotifierProvider.notifier)
        .enrollTotp();
    if (!mounted) return;
    final factorId = await ref
        .read(mfaNotifierProvider.notifier)
        .getPendingFactorId();
    final secret = ref
        .read(mfaNotifierProvider.notifier)
        .getPendingTotpSecret();
    if (!mounted ||
        provisioningUri == null ||
        factorId == null ||
        secret == null) {
      return;
    }
    setState(() {
      _totpSecret = secret;
      _factorId = factorId;
      _step = _Step.qr;
    });
  }

  Future<void> _verify() async {
    final factorId = _factorId;
    if (factorId == null) return;
    final code = _codeCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(
        () => _codeError = 'Saisissez les 6 chiffres affichés par votre application d’authentification.',
      );
      return;
    }
    setState(() => _codeError = null);
    final ok = await ref
        .read(mfaNotifierProvider.notifier)
        .verifyAndActivate(factorId: factorId, code: code);
    if (ok && mounted) {
      ref.invalidate(authUserForSessionProvider);
      setState(() => _step = _Step.success);
    }
  }

  Future<void> _cancelEnrollment() async {
    final factorId = _factorId;
    if (factorId == null) {
      setState(() => _step = _Step.overview);
      return;
    }
    setState(() => _cancelingEnrollment = true);
    try {
      await ref.read(authRepositoryProvider).unenrollMfa(factorId);
      if (!mounted) return;
      ref.invalidate(mfaFactorsProvider);
      setState(() {
        _factorId = null;
        _totpSecret = null;
        _codeCtrl.clear();
        _codeError = null;
        _step = _Step.overview;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible d’annuler cet enrôlement. Supprimez le facteur en attente dans les paramètres Auth de Supabase. $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelingEnrollment = false);
    }
  }

  Future<void> _disable(String factorId) async {
    final codeController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.disableTwoFactorTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirmez avec le code actuel de votre application d’authentification. Supabase exige une session de niveau AAL2 avant de retirer le facteur.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code à 6 chiffres',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.disable),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      codeController.dispose();
      return;
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyMfaChallenge(
            factorId: factorId,
            code: codeController.text.trim(),
          );
      unawaited(
        ref
            .read(securityRepositoryProvider)
            .logEvent(
              eventType: 'mfa_verify',
              metadata: {'action': 'factor_removal_confirmation'},
            ),
      );
      final ok = await ref.read(mfaNotifierProvider.notifier).disable(factorId);
      if (!ok) {
        final state = ref.read(mfaNotifierProvider);
        throw state is AsyncError
            ? state.error
            : Exception('Supabase n’a pas autorisé le retrait du facteur.');
      }
      if (!mounted) return;
      ref.invalidate(authUserForSessionProvider);
      ref.invalidate(mfaFactorsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentification 2FA désactivée.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de désactiver le 2FA : $error')),
        );
      }
    } finally {
      codeController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    if (session == null) {
      // Supabase may still be restoring the persisted session. The router
      // handles an actual signedOut event; don't redirect on a transient null.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mfaState = ref.watch(mfaNotifierProvider);
    final loading = mfaState is AsyncLoading;
    final error = mfaState is AsyncError ? mfaState.error.toString() : null;
    final factors = ref.watch(mfaFactorsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.twoFactor)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: switch (_step) {
          _Step.overview => _buildOverview(factors, loading, error),
          _Step.qr => _buildQr(loading, error),
          _Step.success => _buildSuccess(),
        },
      ),
    );
  }

  Widget _buildOverview(
    AsyncValue<AuthMFAListFactorsResponse> factors,
    bool loading,
    String? error,
  ) {
    return factors.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(mfaFactorsProvider),
      ),
      data: (data) {
        // Utilise .name pour comparer le statut sans risquer un type manquant
        final verified = data.totp
            .where((f) => f.status.name == 'verified')
            .toList();
        final hasActive = verified.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              icon: Icons.phonelink_lock_rounded,
              title: 'Double authentification',
              subtitle: hasActive
                  ? 'Le 2FA est activé sur votre compte'
                  : 'Protégez votre compte avec une app d\'authentification',
            ),
            const SizedBox(height: 28),
            if (hasActive) ...[
              ...verified.map(
                (f) => Card(
                  child: SecurityTile(
                    icon: Icons.shield_rounded,
                    title: 'TOTP — ${f.friendlyName ?? 'Authenticator'}',
                    subtitle: 'Actif · Enrôlé le ${_formatDate(f.createdAt)}',
                    iconColor: AppColors.success,
                    trailing: TextButton(
                      onPressed: () => _disable(f.id),
                      child: const Text(
                        'Désactiver',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(context.l10n.addAnotherFactor),
                onPressed: _startEnroll,
              ),
            ] else ...[
              _InfoCard(
                icon: Icons.info_outline_rounded,
                text: 'Le 2FA ajoute un code temporaire depuis une app (Google Authenticator, Authy…) à chaque connexion.',
              ),
              const SizedBox(height: 20),
              AuthButton(
                label: 'Activer le 2FA',
                icon: Icons.security_rounded,
                loading: loading,
                onPressed: _startEnroll,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQr(bool loading, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeader(
          icon: Icons.qr_code_rounded,
          title: 'Configurez votre application',
          subtitle: 'Dans Google Authenticator, Microsoft Authenticator ou Authy, ajoutez un compte avec une clé de configuration.',
        ),
        const SizedBox(height: 28),
        const _InfoCard(
          icon: Icons.warning_amber_rounded,
          text: 'Cette clé équivaut au second facteur de votre compte. Saisissez-la uniquement dans votre application d’authentification et ne la partagez pas.',
        ),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(minHeight: 130),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Clé secrète TOTP',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _totpSecret ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Entrez le code actuel à 6 chiffres généré par cette application. 123456 est un exemple et ne fonctionnera pas.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codeCtrl,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
          onChanged: (_) {
            if (_codeError != null) setState(() => _codeError = null);
            ref.read(mfaNotifierProvider.notifier).clearError();
          },
        ),
        if (_codeError != null) ...[
          const SizedBox(height: 8),
          Text(
            _codeError ?? '',
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        AuthButton(
          label: 'Vérifier et activer',
          loading: loading,
          onPressed: _verify,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _cancelingEnrollment ? null : _cancelEnrollment,
          child: _cancelingEnrollment
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.cancelTwoFactorSetup),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 44,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '2FA activé !',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Votre compte est maintenant protégé par une double authentification.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.done),
        ),
      ],
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }
}

enum _Step { overview, qr, success }

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
