import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_redirect.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';
import '../widgets/auth_widgets.dart';

class AuthCallbackScreen extends ConsumerWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final event = ref.watch(lastAuthEventProvider);
    final recovery = event == AuthChangeEvent.passwordRecovery ||
        isRecoveryLink(GoRouterState.of(context).uri);
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(recovery ? '/auth/recovery' : '/home');
      });
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.l10n.authCallbackWaiting, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class RecoveryPasswordScreen extends ConsumerStatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  ConsumerState<RecoveryPasswordScreen> createState() =>
      _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends ConsumerState<RecoveryPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppException.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setNewPassword)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AuthTextField(
                controller: _password,
                label: l10n.password,
                obscureText: true,
                validator: (value) =>
                    localizeValidator(l10n, Validators.password(value)),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirm,
                label: l10n.confirmPassword,
                obscureText: true,
                validator: (value) => localizeValidator(
                  l10n,
                  Validators.confirmPassword(value, _password.text),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              AuthButton(
                label: l10n.setNewPassword,
                icon: Icons.lock_reset_rounded,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
