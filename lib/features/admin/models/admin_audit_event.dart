class AdminAuditEvent {
  const AdminAuditEvent({
    required this.id,
    required this.action,
    required this.createdAt,
    this.actorEmail,
    this.targetUserId,
    this.metadata = const {},
  });

  final String id;
  final String action;
  final DateTime createdAt;
  final String? actorEmail;
  final String? targetUserId;
  final Map<String, dynamic> metadata;

  factory AdminAuditEvent.fromMap(Map<String, dynamic> map) => AdminAuditEvent(
    id: map['id'] as String,
    action: map['action'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    actorEmail: map['actor_email'] as String?,
    targetUserId: map['target_user_id'] as String?,
    metadata: map['metadata'] is Map
        ? Map<String, dynamic>.from(map['metadata'] as Map)
        : const {},
  );
}
