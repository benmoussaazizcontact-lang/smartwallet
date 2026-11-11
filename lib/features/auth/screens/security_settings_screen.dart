import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../../shared/widgets/error_view.dart';
import '../repositories/auth_repository.dart';
import '../repositories/security_repository.dart';
import '../utils/auth_user_resolve.dart';
import '../widgets/security_settings_body.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);
    final session = ref.watch(currentSessionProvider);
    final riskAsync = ref.watch(riskScoreProvider);
    final mfaFactors = ref.watch(mfaFactorsProvider);
    final resolvedUser = resolveAppUser(userAsync, session);
    final mfaEnabled = mfaFactors.whenData(
      (factors) =>
          factors.totp.any((factor) => factor.status.name == 'verified'),
    );
    final user = resolvedUser?.copyWith(
      mfaEnabled: mfaEnabled.asData?.value ?? resolvedUser.mfaEnabled,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.security)),
      body: Builder(
        builder: (context) {
          if (user != null) {
            return SecuritySettingsBody(
              user: user,
              riskAsync: riskAsync,
              mfaEnabled: mfaEnabled,
              onRetryMfa: () => ref.invalidate(mfaFactorsProvider),
            );
          }
          if (userAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userAsync.hasError && session != null) {
            return ErrorView(
              message: '${userAsync.error}',
              onRetry: () => ref.invalidate(authUserForSessionProvider),
            );
          }
          // Auth restoration is asynchronous. Let the app-level auth guard
          // handle a confirmed sign-out; a missing snapshot here is not proof
          // that the user's session has ended.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
