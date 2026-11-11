import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/l10n_ext.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _done = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final success = await ref
        .read(authFormProvider.notifier)
        .signUp(
          email: _email.text,
          password: _password.text,
          firstName: _firstName.text,
          lastName: _lastName.text,
        );
    if (success && mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFormProvider);
    final loading = state is AsyncLoading;
    final error = state is AsyncError ? state.error.toString() : null;
    final l10n = context.l10n;

    if (_done) return _ConfirmationView(email: _email.text);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                AuthHeader(
                  icon: Icons.person_add_rounded,
                  title: l10n.signUp,
                  subtitle: l10n.welcomeSubtitle,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        controller: _firstName,
                        label: l10n.firstName,
                        prefixIcon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? l10n.required
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: _lastName,
                        label: l10n.lastName,
                        prefixIcon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? l10n.required
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _email,
                  label: l10n.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  validator: (value) =>
                      localizeValidator(l10n, Validators.email(value)),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _password,
                  label: l10n.password,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) =>
                      localizeValidator(l10n, Validators.password(value)),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _confirm,
                  label: l10n.confirmPassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => localizeValidator(
                    l10n,
                    Validators.confirmPassword(value, _password.text),
                  ),
                ),
                const SizedBox(height: 8),
                // Indicateur de force du mot de passe
                _PasswordStrength(password: _password),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: error),
                ],
                const SizedBox(height: 20),
                AuthButton(
                  label: l10n.createMyAccount,
                  icon: Icons.check_circle_outline_rounded,
                  loading: loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => context.pushReplacement('/login'),
                      child: Text(l10n.signIn),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatefulWidget {
  const _PasswordStrength({required this.password});
  final TextEditingController password;

  @override
  State<_PasswordStrength> createState() => _PasswordStrengthState();
}

class _PasswordStrengthState extends State<_PasswordStrength> {
  @override
  void initState() {
    super.initState();
    widget.password.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.password.removeListener(_rebuild);
    super.dispose();
  }

  int get _strength {
    final p = widget.password.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.password.text.isEmpty) return const SizedBox.shrink();
    final s = _strength;
    final color = s <= 1
        ? AppColors.danger
        : s == 2
        ? AppColors.warning
        : s == 3
        ? Colors.orange
        : AppColors.success;
    final label = s <= 1
        ? context.l10n.passwordWeak
        : s == 2
        ? context.l10n.passwordFair
        : s == 3
        ? context.l10n.passwordGood
        : context.l10n.passwordExcellent;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < s ? color : color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.passwordStrength(label),
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.checkEmail,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.checkEmailBody(email),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.goToSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
