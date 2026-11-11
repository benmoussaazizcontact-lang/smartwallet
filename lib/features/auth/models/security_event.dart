/// Représente un événement de sécurité stocké localement ou dans Supabase
class SecurityEvent {
  const SecurityEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.createdAt,
    this.ipAddress,
    this.userAgent,
    this.location,
    this.success = true,
    this.riskScore = 0,
    this.metadata,
  });

  final String id;
  final String userId;
  final String eventType; // 'sign_in', 'sign_up', 'mfa_verify', 'biometric', 'password_reset', 'sign_out'
  final DateTime createdAt;
  final String? ipAddress;
  final String? userAgent;
  final String? location;
  final bool success;
  final int riskScore; // 0-100
  final Map<String, dynamic>? metadata;

  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      eventType: map['event_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      ipAddress: map['ip_address'] as String?,
      userAgent: map['user_agent'] as String?,
      location: map['location'] as String?,
      success: (map['success'] as bool?) ?? true,
      riskScore: (map['risk_score'] as int?) ?? 0,
      metadata: _metadataFromJson(map['metadata']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'event_type': eventType,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'location': location,
      'success': success,
      'risk_score': riskScore,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static Map<String, dynamic>? _metadataFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String get eventLabel => switch (eventType) {
        'sign_in' => 'Connexion',
        'sign_up' => 'Inscription',
        'sign_out' => 'Déconnexion',
        'mfa_verify' => 'Vérification 2FA',
        'mfa_enroll' => 'Activation 2FA',
        'mfa_disable' => 'Désactivation 2FA',
        'biometric' => 'Biométrie',
        'password_reset' => 'Réinitialisation mot de passe',
        'password_change' => 'Changement mot de passe',
        'profile_update' => 'Mise à jour profil',
        _ => eventType,
      };

  RiskLevel get riskLevel => switch (riskScore) {
        < 30 => RiskLevel.low,
        < 60 => RiskLevel.medium,
        < 80 => RiskLevel.high,
        _ => RiskLevel.critical,
      };
}

enum RiskLevel {
  low,    // 0-29
  medium, // 30-59
  high,   // 60-79
  critical; // 80-100

  String get label => switch (this) {
        RiskLevel.low => 'Faible',
        RiskLevel.medium => 'Modéré',
        RiskLevel.high => 'Élevé',
        RiskLevel.critical => 'Critique',
      };
}
