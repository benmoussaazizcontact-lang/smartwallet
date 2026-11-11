class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.preferredCurrency = 'TND',
    this.themeMode = 'system',
  });

  final String id;
  final String? fullName;
  final String preferredCurrency;
  final String themeMode;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      preferredCurrency: (map['preferred_currency'] as String?) ?? 'TND',
      themeMode: (map['theme_mode'] as String?) ?? 'system',
    );
  }

  String get displayName {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return 'there';
    return name.split(' ').first;
  }
}
