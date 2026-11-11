class AdminSupportRequest {
  const AdminSupportRequest({
    required this.id,
    required this.userId,
    required this.email,
    required this.subject,
    required this.message,
    required this.requestType,
    required this.status,
    required this.createdAt,
    this.response,
  });

  final String id;
  final String userId;
  final String email;
  final String subject;
  final String message;
  final String requestType;
  final String status;
  final DateTime createdAt;
  final String? response;

  factory AdminSupportRequest.fromMap(Map<String, dynamic> map) =>
      AdminSupportRequest(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        email: (map['email'] as String?) ?? '(mon compte)',
        subject: map['subject'] as String,
        message: map['message'] as String,
        requestType: map['request_type'] as String? ?? 'question',
        status: map['status'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        response: map['admin_response'] as String?,
      );
}
