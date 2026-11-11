import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/session/session_scope.dart';

final receiptUserIdPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Storage object key owned by the authenticated user. The operation id is
/// stable across retries, so a second upload replaces the same object.
String receiptStoragePath({
  required String userId,
  required String operationId,
}) {
  if (!receiptUserIdPattern.hasMatch(userId) ||
      !receiptUserIdPattern.hasMatch(operationId)) {
    throw const AppException('Invalid receipt path');
  }
  return '$userId/$operationId.jpg';
}

bool receiptPathBelongsToUser(String path, String userId) {
  if (!receiptUserIdPattern.hasMatch(userId)) return false;
  if (path.contains('..') || path.contains('\\')) return false;
  return path.startsWith('$userId/');
}

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(ref.watch(supabaseProvider));
});

class ReceiptRepository {
  ReceiptRepository(this._client);
  final SupabaseClient _client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (!belongsToActiveUser(loadedFor: userId, active: userId)) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    return userId!;
  }

  Future<String> uploadImage(
    Uint8List bytes, {
    required String operationId,
  }) async {
    final userId = _requireUserId();
    final path = receiptStoragePath(userId: userId, operationId: operationId);
    try {
      await _client.storage.from('receipts').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return path;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> insert({
    required String transactionId,
    required String imagePath,
    String? merchant,
    DateTime? receiptDate,
    required num total,
    required String currency,
    Map<String, dynamic>? extractedData,
  }) async {
    final userId = _requireUserId();
    if (!receiptPathBelongsToUser(imagePath, userId)) {
      throw const AppException('Receipt image path does not belong to this account.');
    }
    try {
      final existing = await _client
          .from('receipts')
          .select('id')
          .eq('transaction_id', transactionId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing != null) return;
      await _client.from('receipts').insert({
        'user_id': userId,
        'transaction_id': transactionId,
        'image_path': imagePath,
        'merchant': merchant,
        'receipt_date': receiptDate?.toIso8601String().split('T').first,
        'total': total,
        'currency': currency,
        'extracted_data': extractedData,
      });
    } catch (error) {
      final text = error.toString().toLowerCase();
      if (text.contains('duplicate') || text.contains('23505')) return;
      throw AppException.from(error);
    }
  }
}
