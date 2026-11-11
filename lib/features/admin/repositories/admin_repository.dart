import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../models/admin_audit_event.dart';
import '../models/admin_support_request.dart';
import '../models/admin_user.dart';
import '../models/admin_user_metrics.dart';

class AdminRepository {
  const AdminRepository(this._client);
  final SupabaseClient _client;

  Future<AdminUserMetrics> overview() async {
    final result = await _client.rpc('admin_user_overview');
    if (result is! List || result.isEmpty || result.first is! Map) {
      throw const FormatException('Statistiques administrateur invalides.');
    }
    return AdminUserMetrics.fromMap(
      Map<String, dynamic>.from(result.first as Map),
    );
  }

  Future<List<AdminUser>> searchUsers({
    String? query,
    DateTime? from,
    DateTime? to,
    String? role,
    String? status,
    int page = 0,
  }) async {
    final result = await _client.rpc(
      'admin_search_users',
      params: {
        'p_query': query,
        'p_created_from': from?.toUtc().toIso8601String(),
        'p_created_to': to?.toUtc().toIso8601String(),
        'p_role': role,
        'p_status': status,
        'p_page': page,
        'p_page_size': 50,
      },
    );
    if (result is! List) throw const FormatException('Liste invalide.');
    return result
        .whereType<Map>()
        .map((row) => AdminUser.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<AdminSupportRequest>> supportRequests({String? status}) async {
    final result = await _client.rpc(
      'admin_list_support_requests',
      params: {'p_status': status},
    );
    if (result is! List) throw const FormatException('Demandes invalides.');
    return result
        .whereType<Map>()
        .map(
          (row) => AdminSupportRequest.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<List<AdminSupportRequest>> mySupportRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Session utilisateur absente.');
    final result = await _client
        .from('support_requests')
        .select(
          'id,user_id,subject,message,request_type,status,admin_response,created_at',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);
    return result
        .map(
          (row) => AdminSupportRequest.fromMap({...row, 'email': user.email}),
        )
        .toList(growable: false);
  }

  Future<List<AdminAuditEvent>> auditLog() async {
    final result = await _client.rpc('admin_list_audit_log');
    if (result is! List) throw const FormatException('Journal invalide.');
    return result
        .whereType<Map>()
        .map((row) => AdminAuditEvent.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<void> updateSupportRequest({
    required String requestId,
    required String status,
    String? response,
  }) async {
    await _client.rpc(
      'admin_update_support_request',
      params: {
        'p_request_id': requestId,
        'p_status': status,
        'p_response': response,
      },
    );
  }

  Future<void> submitSupportRequest({
    required String subject,
    required String message,
    required String requestType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Session utilisateur absente.');
    }
    await _client.from('support_requests').insert({
      'user_id': userId,
      'request_type': requestType,
      'subject': subject.trim(),
      'message': message.trim(),
    });
  }

  Future<void> performUserAction({
    required String action,
    required String userId,
    String? role,
    String? confirmEmail,
    String? reason,
    int? durationDays,
  }) async {
    final response = await _client.functions.invoke(
      'admin-users',
      body: {
        'action': action,
        'user_id': userId,
        'role': role,
        'confirm_email': confirmEmail,
        'reason': reason,
        'duration_days': durationDays,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(
        message ?? 'Action administrateur refusée (${response.status}).',
      );
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(supabaseProvider)),
);

class AdminUserSearch {
  const AdminUserSearch({
    this.query = '',
    this.from,
    this.to,
    this.role,
    this.status,
    this.page = 0,
  });
  final String query;
  final DateTime? from;
  final DateTime? to;
  final String? role;
  final String? status;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is AdminUserSearch &&
      query == other.query &&
      from == other.from &&
      to == other.to &&
      role == other.role &&
      status == other.status &&
      page == other.page;

  @override
  int get hashCode => Object.hash(query, from, to, role, status, page);
}

final adminUserListProvider =
    FutureProvider.family<List<AdminUser>, AdminUserSearch>(
      (ref, filters) => ref
          .watch(adminRepositoryProvider)
          .searchUsers(
            query: filters.query,
            from: filters.from,
            to: filters.to,
            role: filters.role,
            status: filters.status,
            page: filters.page,
          ),
    );

final adminUserMetricsProvider = FutureProvider<AdminUserMetrics>(
  (ref) => ref.watch(adminRepositoryProvider).overview(),
);

final adminSupportRequestsProvider =
    FutureProvider.family<List<AdminSupportRequest>, String?>(
      (ref, status) =>
          ref.watch(adminRepositoryProvider).supportRequests(status: status),
    );

final mySupportRequestsForUserProvider =
    FutureProvider.family<List<AdminSupportRequest>, String>((ref, userId) async {
  final rows = await ref.watch(adminRepositoryProvider).mySupportRequests();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final mySupportRequestsProvider =
    Provider<AsyncValue<List<AdminSupportRequest>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(mySupportRequestsForUserProvider(userId));
});

final adminAuditLogProvider = FutureProvider<List<AdminAuditEvent>>(
  (ref) => ref.watch(adminRepositoryProvider).auditLog(),
);
