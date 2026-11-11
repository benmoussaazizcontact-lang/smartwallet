import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/money.dart';
import '../models/transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(supabaseProvider));
});

class TransactionRepository {
  TransactionRepository(this._client);
  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<List<MoneyTransaction>> list({
    TransactionFilters filters = const TransactionFilters(),
    int offset = 0,
    int limit = 30,
  }) async {
    try {
      var query = _client.from('activity_feed').select();
      if (filters.type == 'TRANSFER' || filters.type == 'TRANSFER_OUT') {
        query = query.inFilter('transaction_type', ['TRANSFER', 'TRANSFER_OUT']);
      } else if (filters.type != null) {
        query = query.eq('transaction_type', filters.type!);
      }
      if (filters.walletId != null) query = query.eq('wallet_id', filters.walletId!);
      if (filters.categoryId != null) {
        query = query.eq('category_id', filters.categoryId!);
      }
      if (filters.minAmount != null) query = query.gte('amount', filters.minAmount!);
      if (filters.maxAmount != null) query = query.lte('amount', filters.maxAmount!);
      if (filters.from != null) {
        query = query.gte('transaction_date', filters.from!.toIso8601String());
      }
      if (filters.to != null) {
        query = query.lte('transaction_date', filters.to!.toIso8601String());
      }
      if (filters.query != null && filters.query!.trim().isNotEmpty) {
        final q = filters.query!.trim();
        query = query.or('description.ilike.%$q%,merchant.ilike.%$q%');
      }
      final rows = await query
          .order('transaction_date', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map(MoneyTransaction.fromMap).toList();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<MoneyTransaction> getById(String id) async {
    try {
      final row = await _client
          .from('transactions')
          .select('*, categories(name)')
          .eq('id', id)
          .maybeSingle();
      if (row != null) return MoneyTransaction.fromMap(row);
      final transfer = await _client.from('transfers').select().eq('id', id).single();
      return MoneyTransaction.fromTransfer(transfer, outgoing: true);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<String> create({
    required String walletId,
    required String type,
    required num amount,
    String? description,
    String? categoryId,
    String? merchant,
    DateTime? date,
    List<String>? tagIds,
    String? clientRequestId,
    num? latitude,
    num? longitude,
  }) async {
    try {
      final result = await _client.rpc(
        'create_transaction',
        params: {
          'p_wallet_id': walletId,
          'p_type': type,
          'p_amount': Money.round3(amount),
          'p_description': description,
          'p_category_id': categoryId,
          'p_merchant': merchant,
          'p_transaction_date': (date ?? DateTime.now()).toUtc().toIso8601String(),
          'p_latitude': latitude,
          'p_longitude': longitude,
          'p_tag_ids': tagIds,
          'p_client_request_id': clientRequestId ?? _uuid.v4(),
        },
      );
      return result as String;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> voidTransaction(String id, {String? reason}) async {
    try {
      await _client.rpc(
        'void_transaction',
        params: {'p_transaction_id': id, 'p_reason': reason},
      );
    } catch (error) {
      throw AppException.from(error);
    }
  }
}

final recentTransactionsForUserProvider =
    FutureProvider.family<List<MoneyTransaction>, String>((ref, userId) async {
  final rows = await ref.watch(transactionRepositoryProvider).list(limit: 8);
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final recentTransactionsProvider =
    Provider<AsyncValue<List<MoneyTransaction>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(recentTransactionsForUserProvider(userId));
});

final dashboardActivityForUserProvider =
    FutureProvider.family<List<MoneyTransaction>, String>((ref, userId) async {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month - 1, 1);
  final rows = await ref.watch(transactionRepositoryProvider).list(
        filters: TransactionFilters(from: from),
        limit: 400,
      );
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final dashboardActivityProvider =
    Provider<AsyncValue<List<MoneyTransaction>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(dashboardActivityForUserProvider(userId));
});
