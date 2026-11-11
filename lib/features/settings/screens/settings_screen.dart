import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/fade_slide_in.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/widgets/profile_avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider).asData?.value;
    final locale = ref.watch(localeControllerProvider);
    final themeMode = themeModeToStorage(ref.watch(themeControllerProvider));
    final userId = ref.watch(currentUserIdProvider);
    final userAsync = ref.watch(authUserProvider);
    final sessionEmail = ref.watch(currentSessionProvider)?.user.email;
    final isAdmin =
        ref.watch(currentSessionProvider)?.user.appMetadata['role'] == 'admin';

    Future<void> savePreference({String? themeMode, String? currency}) async {
      try {
        await ref
            .read(authRepositoryProvider)
            .updateModulePreferences(
              themeMode: themeMode,
              preferredCurrency: currency,
            );
        ref.invalidate(authUserForSessionProvider);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.preferenceNotSaved)),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ─── Section Compte ──────────────────────────────────────────────
          FadeSlideIn(
            child: _AccountCard(
              userAsync: userAsync,
              sessionEmail: sessionEmail,
              onLogout: () => _logout(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Apparence ───────────────────────────────────────────────────
          FadeSlideIn(
            child: _Section(
              title: l10n.appearance,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'system',
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(value: 'light', label: Text(l10n.themeLight)),
                    ButtonSegment(value: 'dark', label: Text(l10n.themeDark)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (v) async {
                    final mode = themeModeFromStorage(v.first);
                    await ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(mode, userId: userId);
                    await savePreference(themeMode: v.first);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Langue ──────────────────────────────────────────────────────
          FadeSlideIn(
            child: _Section(
              title: l10n.language,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'fr', label: Text(l10n.langFrench)),
                    ButtonSegment(value: 'ar', label: Text(l10n.langArabic)),
                    ButtonSegment(value: 'en', label: Text(l10n.langEnglish)),
                  ],
                  selected: {locale.languageCode},
                  onSelectionChanged: (v) {
                    ref.read(localeControllerProvider.notifier).setLocale(
                          Locale(v.first),
                          userId: userId,
                        );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Devise ──────────────────────────────────────────────────────
          FadeSlideIn(
            child: _Section(
              title: l10n.currency,
              child: DropdownButton<String>(
                value: profile?.preferredCurrency ?? 'TND',
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: Currencies.all
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.code,
                        child: Text('${c.code} · ${c.label}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  savePreference(currency: v);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Préférences financières ──────────────────────────────────────
          FadeSlideIn(
            child: _Section(
              title: l10n.financialPreferences,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.planTitle),
                    subtitle: Text(l10n.planSubtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/plan'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.categories),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/settings/categories'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.recurringTransactions),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/settings/recurring'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (isAdmin) ...[
            FadeSlideIn(
              child: _Section(
                title: l10n.administration,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: Text(l10n.userManagement),
                  subtitle: Text(l10n.userManagementHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/users'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          FadeSlideIn(
            child: _Section(
              title: l10n.help,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.support_agent_outlined),
                title: Text(l10n.contactSupport),
                subtitle: Text(l10n.contactSupportHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/support'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── À propos ────────────────────────────────────────────────────
          FadeSlideIn(
            child: _Section(
              title: l10n.about,
              child: Text(
                l10n.aboutBody,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.signOutTitle),
        content: Text(ctx.l10n.signOutBody),
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
}

// ─── Carte compte utilisateur ─────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.userAsync,
    required this.sessionEmail,
    required this.onLogout,
  });

  final AsyncValue<AppUser?> userAsync;
  final String? sessionEmail;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlassPanel(
      child: Column(
        children: [
          // En-tête utilisateur
          userAsync.when(
            loading: () {
              if (sessionEmail != null) {
                final initial = sessionEmail!.substring(0, 1).toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sessionEmail!.split('@').first,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              sessionEmail!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                );
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              );
            },
            error: (_, _) {
              final email = sessionEmail;
              if (email != null) {
                final initial = email.substring(0, 1).toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email.split('@').first,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _GuestTile();
            },
            data: (user) {
              if (user == null) return _GuestTile();
              final displayName = (user.firstName?.isNotEmpty == true)
                  ? '${user.firstName} ${user.lastName ?? ''}'.trim()
                  : user.email;
              final initial = displayName.isEmpty
                  ? '?'
                  : displayName.substring(0, 1).toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Avatar
                    ProfileAvatar(
                      radius: 28,
                      storedPath: user.avatarUrl,
                      fallbackText: initial,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (user.isEmailVerified)
                                _MiniChip(
                                  label: l10n.emailVerified,
                                  color: AppColors.success,
                                  icon: Icons.verified_rounded,
                                )
                              else
                                _MiniChip(
                                  label: l10n.emailUnverified,
                                  color: AppColors.warning,
                                  icon: Icons.warning_amber_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Actions
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            title: l10n.myProfile,
            subtitle: l10n.myProfileHint,
            onTap: () => GoRouter.of(context).push('/profile'),
          ),
          _SettingsTile(
            icon: Icons.security_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: l10n.security,
            subtitle: l10n.securityHint,
            onTap: () => GoRouter.of(context).push('/settings/security'),
          ),
          _SettingsTile(
            icon: Icons.history_rounded,
            iconColor: AppColors.secondary,
            title: l10n.loginHistory,
            subtitle: l10n.loginHistoryHint,
            onTap: () =>
                GoRouter.of(context).push('/settings/security/history'),
          ),
          _SettingsTile(
            icon: Icons.person_add_rounded,
            iconColor: AppColors.success,
            title: l10n.createAnotherAccount,
            subtitle: l10n.createAnotherAccountHint,
            onTap: () => GoRouter.of(context).push('/register'),
          ),

          const Divider(height: 1),

          // Déconnexion
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            title: Text(
              l10n.signOut,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(l10n.signOutHint),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            child: const Icon(Icons.person_outline_rounded, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.guest,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => GoRouter.of(context).go('/login'),
                child: Text(l10n.signIn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
