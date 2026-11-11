import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/biometric_lock.dart';
import '../providers/auth_providers.dart';

/// Locks authenticated finance/security screens locally when the user opted in.
/// No biometric template or secret leaves the device; Supabase auth is unchanged.
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate>
    with WidgetsBindingObserver {
  bool _checking = false;
  String? _error;
  String? _authorizedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final signal = switch (state) {
      AppLifecycleState.paused => LockSignal.paused,
      AppLifecycleState.hidden => LockSignal.hidden,
      AppLifecycleState.resumed => LockSignal.resumed,
      _ => LockSignal.inactive,
    };
    ref.read(biometricServiceProvider).onLifecycle(signal);
    if (signal == LockSignal.paused || signal == LockSignal.hidden) {
      _checking = false;
      _error = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _authenticate() async {
    if (_checking || !mounted) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final service = ref.read(biometricServiceProvider);
      if (!await service.isAvailable()) {
        if (!mounted) return;
        setState(() => _error = 'Authentification indisponible sur cet appareil.');
        return;
      }
      final ok = await service.authenticate();
      if (!mounted) return;
      setState(() {
        _error = ok ? null : 'Authentification annulée. Réessayez pour continuer.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Authentification indisponible : $error');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOutForRecovery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.signOutWalletTitle),
        content: Text(dialogContext.l10n.signOutWalletBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(authFormProvider.notifier).signOut();
      await ref.read(biometricServiceProvider).clearPreferenceAfterSignOut();
      if (mounted) context.go('/welcome');
    } catch (error) {
      if (ref.read(currentSessionProvider) == null) {
        await ref.read(biometricServiceProvider).clearPreferenceAfterSignOut();
      }
      if (mounted) {
        setState(
          () => _error =
              'La déconnexion locale a été effectuée, mais la requête distante a échoué : $error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentSessionProvider)?.user.id;
    if (_authorizedUserId != userId) {
      _authorizedUserId = userId;
      _error = null;
    }
    final enabled = ref.watch(biometricEnabledProvider);
    return enabled.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 40),
                const SizedBox(height: 12),
                Text(context.l10n.localLockFailed),
                Text('$error', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(biometricEnabledProvider),
                  child: Text(context.l10n.retry),
                ),
                TextButton(
                  onPressed: _signOutForRecovery,
                  child: const Text(
                    'Se déconnecter et réinitialiser ce verrou',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (isEnabled) {
        final service = ref.read(biometricServiceProvider);
        if (!service.lock.blocksFinancialContent(enabled: isEnabled, userId: userId)) {
          return widget.child;
        }
        if (userId == null) return const SizedBox.shrink();
        if (service.lock.phase == LockSignal.resumed && !_checking && _error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 52),
                  const SizedBox(height: 16),
                  Text(
                    'Confirmez votre identité',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La session Wallet reste active. Cette vérification protège localement l’accès à vos données sur cet appareil. Si le capteur est indisponible, vérifiez les réglages biométriques du téléphone ou déconnectez-vous pour vous réauthentifier.',
                    textAlign: TextAlign.center,
                  ),
                  if (_checking) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.l10n.retry),
                    ),
                    TextButton(
                      onPressed: _signOutForRecovery,
                      child: const Text(
                        'Se déconnecter et réinitialiser ce verrou',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
