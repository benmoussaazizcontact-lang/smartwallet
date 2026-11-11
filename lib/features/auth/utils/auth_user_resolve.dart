import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';
import 'session_user.dart';

/// Profil enrichi si disponible, sinon utilisateur minimal depuis la session Auth.
AppUser? resolveAppUser(AsyncValue<AppUser?> userAsync, Session? session) {
  final fromProfile = userAsync.asData?.value;
  if (fromProfile != null) return fromProfile;
  return appUserFromSession(session);
}
