import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/money.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(ref.watch(supabaseProvider));
});

class TransferRepository {
  TransferRepository(this._client);
  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<String> transfer({
    required String fromWalletId,
    required String toWalletId,
    required num amount,
    String? description,
    String? clientRequestId,
  }) async {
    if (fromWalletId == toWalletId) {
      throw const AppException('Choisissez deux wallets différents.');
    }
    try {
      final result = await _client.rpc(
        'transfer_money',
        params: {
          'p_from_wallet': fromWalletId,
          'p_to_wallet': toWalletId,
          'p_amount': Money.round3(amount),
          'p_description': description,
          'p_client_request_id': clientRequestId ?? _uuid.v4(),
        },
      );
      return result as String;
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
