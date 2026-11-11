/// Modèle utilisateur enrichi (données Supabase Auth + profil).
/// Nommé [AppUser] pour éviter le conflit de nom avec [AuthUser]
/// du package supabase/gotrue qui est exporté par supabase_flutter.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.preferredCurrency = 'TND',
    this.themeMode = 'system',
    this.emailConfirmedAt,
    this.lastSignInAt,
    this.mfaEnabled = false,
    this.biometricEnabled = false,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String preferredCurrency;
  final String themeMode;
  final DateTime? emailConfirmedAt;
  final DateTime? lastSignInAt;
  final bool mfaEnabled;
  final bool biometricEnabled;

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.join(' ');
  }

  String get displayName {
    final name = firstName;
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  bool get isEmailVerified => emailConfirmedAt != null;

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? preferredCurrency,
    String? themeMode,
    bool? mfaEnabled,
    bool? biometricEnabled,
  }) {
    return AppUser(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      themeMode: themeMode ?? this.themeMode,
      emailConfirmedAt: emailConfirmedAt,
      lastSignInAt: lastSignInAt,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  factory AppUser.fromMap({
    required Map<String, dynamic> profile,
    required String email,
    DateTime? emailConfirmedAt,
    DateTime? lastSignInAt,
    bool mfaEnabled = false,
    bool biometricEnabled = false,
  }) {
    return AppUser(
      id: profile['id'] as String,
      email: email,
      firstName: profile['first_name'] as String?,
      lastName: profile['last_name'] as String?,
      phone: profile['phone'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      bio: profile['bio'] as String?,
      preferredCurrency: (profile['preferred_currency'] as String?) ?? 'TND',
      themeMode: (profile['theme_mode'] as String?) ?? 'system',
      emailConfirmedAt: emailConfirmedAt,
      lastSignInAt: lastSignInAt,
      mfaEnabled: mfaEnabled,
      biometricEnabled: biometricEnabled,
    );
  }
}
