import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/l10n_ext.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../providers/auth_providers.dart';
import '../utils/session_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/security_repository.dart';
import '../widgets/auth_widgets.dart';

class BiometricScreen extends ConsumerWidget {
  const BiometricScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(biometricAvailableProvider);
    final enabledAsync = ref.watch(biometricEnabledProvider);
    final typesAsync = ref.watch(_biometricTypesProvider);

    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.biometrics)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              icon: Icons.fingerprint_rounded,
              title: l10n.biometrics,
              subtitle: l10n.biometricSubtitle,
            ),
            const SizedBox(height: 12),
            // Avertissement important
            _InfoBanner(
              icon: Icons.info_outline_rounded,
              color: AppColors.primary,
              text: 'La biométrie est un verrou LOCAL. Elle protège l\'accès à l\'app sur cet appareil mais ne remplace pas votre session Supabase.',
            ),
            const SizedBox(height: 24),

            availableAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur : $e'),
              data: (available) {
                if (!available) {
                  return _InfoBanner(
                    icon: Icons.phone_android_rounded,
                    color: AppColors.warning,
                    text: 'Aucune biométrie compatible n’est configurée sur cet appareil. Activez Face ID ou une empreinte dans les réglages système, puis réessayez.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Types disponibles
                    typesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (types) => _TypesChips(types: types),
                    ),
                    const SizedBox(height: 20),
                    // Toggle biométrie
                    enabledAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text(e.toString()),
                      data: (enabled) => _BiometricToggle(enabled: enabled),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricToggle extends ConsumerStatefulWidget {
  const _BiometricToggle({required this.enabled});
  final bool enabled;

  @override
  ConsumerState<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends ConsumerState<_BiometricToggle> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final widgetRef = ref;
    return Card(
      child: SecurityTile(
        icon: enabled ? Icons.fingerprint_rounded : Icons.no_encryption_rounded,
        title: 'Biométrie',
        subtitle: enabled ? 'Activée sur cet appareil' : 'Désactivée',
        iconColor: enabled ? AppColors.success : AppColors.warning,
        trailing: _busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: enabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  setState(() => _busy = true);
                  try {
                    final bio = widgetRef.read(biometricServiceProvider);
                    final session = widgetRef.read(currentSessionProvider);
                    final user =
                        widgetRef.read(authUserProvider).asData?.value ??
                        appUserFromSession(session);
                    if (user == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Votre session est en cours de restauration. Réessayez dans un instant.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    if (val) {
                      final ok = await bio.enable(user.id);
                      if (ok && context.mounted) {
                        unawaited(
                          widgetRef
                              .read(securityRepositoryProvider)
                              .logEvent(
                                eventType: 'biometric',
                                metadata: {'action': 'enable'},
                              ),
                        );
                        if (!context.mounted) return;
                        widgetRef.invalidate(biometricEnabledProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biométrie activée ✓')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vérification biométrique annulée. La biométrie reste désactivée.',
                            ),
                          ),
                        );
                      }
                    } else {
                      final ok = await bio.disable(user.id);
                      if (ok && context.mounted) {
                        unawaited(
                          widgetRef
                              .read(securityRepositoryProvider)
                              .logEvent(
                                eventType: 'biometric',
                                metadata: {'action': 'disable'},
                              ),
                        );
                        if (!context.mounted) return;
                        widgetRef.invalidate(biometricEnabledProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biométrie désactivée')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vérification biométrique annulée. La biométrie reste activée.',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Impossible de modifier la biométrie : $error',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
              ),
      ),
    );
  }
}

class _TypesChips extends StatelessWidget {
  const _TypesChips({required this.types});
  final List<BiometricType> types;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: types.map((t) {
        final label = switch (t) {
          BiometricType.fingerprint => '☞ Empreinte digitale',
          BiometricType.face => '◉ Reconnaissance faciale',
          BiometricType.iris => '◎ Iris',
          BiometricType.strong => '★ Biométrie forte',
          BiometricType.weak => '☆ Biométrie standard',
        };
        return Chip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        );
      }).toList(),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

final _biometricTypesProvider = FutureProvider<List<BiometricType>>((ref) {
  return ref.watch(biometricServiceProvider).getAvailableTypes();
});
