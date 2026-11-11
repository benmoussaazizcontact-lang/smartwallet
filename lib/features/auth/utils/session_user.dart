import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';

/// Construit un [AppUser] minimal depuis la session Auth (sans table profiles).
AppUser? appUserFromSession(Session? session) {
  final authUser = session?.user;
  if (authUser == null) return null;

  return AppUser(
    id: authUser.id,
    email: authUser.email ?? '',
    firstName: authUser.userMetadata?['first_name'] as String?,
    lastName: authUser.userMetadata?['last_name'] as String?,
    emailConfirmedAt: authUser.emailConfirmedAt != null
        ? DateTime.tryParse(authUser.emailConfirmedAt!)
        : null,
    lastSignInAt: authUser.lastSignInAt != null
        ? DateTime.tryParse(authUser.lastSignInAt!)
        : null,
  );
}
