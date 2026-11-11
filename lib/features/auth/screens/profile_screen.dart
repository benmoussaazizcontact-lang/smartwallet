import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/i18n/l10n_ext.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/error_view.dart';
import '../domain/account_deletion.dart';
import '../models/auth_user.dart';
import '../providers/auth_providers.dart';
import '../utils/session_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/security_repository.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  var _editing = false;
  var _saving = false;
  AppUser? _user;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _populate(AppUser u) {
    _firstName.text = u.firstName ?? '';
    _lastName.text = u.lastName ?? '';
    _phone.text = u.phone ?? '';
    _bio.text = u.bio ?? '';
    _user = u;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            firstName: _firstName.text,
            lastName: _lastName.text,
            phone: _phone.text,
            bio: _bio.text,
          );
      ref.invalidate(authUserForSessionProvider);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil mis à jour ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeAvatar() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image == null || !mounted) return;
      final extension = image.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        throw const FormatException('Choisissez une image JPG, PNG ou WebP.');
      }
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const FormatException('L’image doit faire au maximum 5 Mo.');
      }
      setState(() => _saving = true);
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(bytes: bytes, extension: extension);
      await ref.read(profileRepositoryProvider).updateProfile(avatarUrl: url);
      ref.invalidate(profileAvatarUrlProvider(url));
      ref.invalidate(authUserForSessionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour ✓')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de modifier la photo : $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authFormProvider.notifier).signOut();
    if (mounted) context.go('/welcome');
  }

  Future<void> _deleteAccount() async {
    final l10n = context.l10n;
    final typed = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteAccountBody),
            const SizedBox(height: 12),
            TextField(
              controller: typed,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.deleteAccountConfirmWord),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              accountDeletionConfirmed(typed.text, l10n.deleteAccountConfirmWord),
            ),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    typed.dispose();
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(authRepositoryProvider).deleteOwnAccount();
      await ref.read(biometricServiceProvider).clearPreferenceAfterSignOut();
      await ref.read(authFormProvider.notifier).signOut();
      if (mounted) context.go('/welcome');
    } catch (error) {
      if (!mounted) return;
      final unavailable = error is AppException && error.code == 'delete_unavailable';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(unavailable ? l10n.deleteAccountUnavailable : '$error')),
      );
    }
  }

  AppUser? _userFromSession() =>
      appUserFromSession(ref.read(currentSessionProvider));

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);
    final mfaFactors = ref.watch(mfaFactorsProvider);
    final session = ref.watch(currentSessionProvider);
    final brightness = Theme.of(context).brightness;

    return userAsync.when(
      loading: () {
        final fallback = _userFromSession();
        if (fallback == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildProfileScaffold(fallback, brightness);
      },
      error: (e, _) => Scaffold(
        body: ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(authUserForSessionProvider),
        ),
      ),
      data: (user) {
        final resolved = user ?? _userFromSession();
        if (resolved == null) {
          if (session != null) {
            return Scaffold(
              body: ErrorView(
                message: 'Impossible de charger le profil.',
                onRetry: () => ref.invalidate(authUserForSessionProvider),
              ),
            );
          }
          // Session state is owned by the app router/auth stream. It can be
          // temporarily unavailable while Supabase restores it; never turn
          // that transient state into a local login redirect.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final u = resolved.copyWith(
          mfaEnabled:
              mfaFactors.asData?.value.totp.any(
                (factor) => factor.status.name == 'verified',
              ) ??
              resolved.mfaEnabled,
        );
        if (_user?.id != u.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _populate(u));
        }
        return _buildProfileScaffold(u, brightness);
      },
    );
  }

  Widget _buildProfileScaffold(AppUser u, Brightness brightness) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myProfile),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
          if (_editing)
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: Text(context.l10n.cancel),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(
              user: u,
              brightness: brightness,
              editing: _editing,
              changingAvatar: _saving,
              onChangeAvatar: _changeAvatar,
            ),
            if (!u.isEmailVerified) _EmailWarning(email: u.email),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle('Informations personnelles'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _firstName,
                            label: 'Prénom',
                            prefixIcon: Icons.person_outline_rounded,
                            enabled: _editing,
                            validator: (v) =>
                                (v?.trim().isEmpty ?? true) ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AuthTextField(
                            controller: _lastName,
                            label: 'Nom',
                            prefixIcon: Icons.person_outline_rounded,
                            enabled: _editing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _phone,
                      label: 'Téléphone',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      enabled: _editing,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _bio,
                      label: 'Bio',
                      prefixIcon: Icons.notes_rounded,
                      enabled: _editing,
                      maxLines: 3,
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 20),
                      AuthButton(
                        label: 'Enregistrer',
                        icon: Icons.check_rounded,
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SectionTitle('Compte'),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          SecurityTile(
                            icon: Icons.security_rounded,
                            title: 'Sécurité',
                            subtitle: 'MFA, biométrie, sessions',
                            iconColor: AppColors.primary,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push('/settings/security'),
                          ),
                          const Divider(height: 1, indent: 74),
                          SecurityTile(
                            icon: Icons.logout_rounded,
                            title: 'Se déconnecter',
                            subtitle: 'Fermer la session en cours',
                            iconColor: AppColors.danger,
                            onTap: _signOut,
                          ),
                          const Divider(height: 1, indent: 74),
                          SecurityTile(
                            icon: Icons.delete_forever_rounded,
                            title: context.l10n.deleteAccount,
                            subtitle: context.l10n.deleteAccountBody,
                            iconColor: AppColors.danger,
                            onTap: _deleteAccount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.user,
    required this.brightness,
    required this.editing,
    required this.changingAvatar,
    required this.onChangeAvatar,
  });
  final AppUser user;
  final Brightness brightness;
  final bool editing;
  final bool changingAvatar;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = user.displayName;
    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ProfileAvatar(
                radius: 44,
                storedPath: user.avatarUrl,
                fallbackText: initial,
              ),
              if (editing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Modifier la photo',
                      onPressed: changingAvatar ? null : onChangeAvatar,
                      icon: changingAvatar
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName.isEmpty ? user.displayName : user.fullName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.isEmailVerified)
                _Badge(
                  label: 'Email vérifié',
                  color: AppColors.success,
                  icon: Icons.verified_rounded,
                )
              else
                _Badge(
                  label: 'Email non vérifié',
                  color: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                ),
              if (user.mfaEnabled) ...[
                const SizedBox(width: 8),
                _Badge(
                  label: '2FA actif',
                  color: AppColors.primary,
                  icon: Icons.shield_rounded,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailWarning extends StatelessWidget {
  const _EmailWarning({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Email non vérifié. Vérifiez votre boîte $email.',
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
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
