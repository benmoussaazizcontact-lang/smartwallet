import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/security_repository.dart';

/// Recharge profil / utilisateur / sécurité après login, logout ou mise à jour.
void refreshUserModuleProviders(Ref ref) {
  ref.invalidate(authUserForSessionProvider);
  ref.invalidate(securityHistoryForUserProvider);
  ref.invalidate(riskScoreForUserProvider);
  ref.invalidate(mfaFactorsProvider);
}
