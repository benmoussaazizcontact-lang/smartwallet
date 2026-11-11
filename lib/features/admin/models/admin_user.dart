class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.role,
    this.firstName,
    this.lastName,
    this.lastSignInAt,
    this.emailConfirmedAt,
    this.bannedUntil,
    this.suspensionReason,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final DateTime? emailConfirmedAt;
  final DateTime? bannedUntil;
  final String? suspensionReason;
  final String role;

  String get name => [
    firstName,
    lastName,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  bool get isSuspended {
    final until = bannedUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) => AdminUser(
    id: map['id'] as String,
    email: (map['email'] as String?) ?? '',
    firstName: map['first_name'] as String?,
    lastName: map['last_name'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
    lastSignInAt: _date(map['last_sign_in_at']),
    emailConfirmedAt: _date(map['email_confirmed_at']),
    bannedUntil: _date(map['banned_until']),
    suspensionReason: map['suspension_reason'] as String?,
    role: (map['account_role'] as String?) ?? 'user',
  );
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
