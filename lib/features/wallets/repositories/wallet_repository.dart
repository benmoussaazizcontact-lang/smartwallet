import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/wallet.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(supabaseProvider));
});

class WalletRepository {
  WalletRepository(this._client);
  final SupabaseClient _client;

  Future<List<WalletBalance>> listBalances({bool includeArchived = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      var query = _client.from('wallet_balances').select().eq('user_id', userId);
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }
      final rows = await query.order('created_at');
      return rows.map(WalletBalance.fromMap).toList();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<WalletBalance> getById(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    final row = await _client
        .from('wallet_balances')
        .select()
        .eq('wallet_id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) {
      throw const AppException(
        'Wallet not found or not allowed.',
        code: 'not_found',
      );
    }
    return WalletBalance.fromMap(row);
  }

  Future<String> create({
    required String name,
    required String walletType,
    required String currency,
    required num initialBalance,
    num creditLimit = 0,
    String? cryptoSymbol,
    String? icon,
    String? color,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    try {
      final inserted = await _client
          .from('wallets')
          .insert(
            walletInsertRow(
              userId: userId,
              name: name,
              walletType: walletType,
              currency: currency,
              initialBalance: initialBalance,
              creditLimit: creditLimit,
              cryptoSymbol: cryptoSymbol,
              icon: icon,
              color: color,
            ),
          )
          .select('id')
          .single();
      return inserted['id'] as String;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> update({
    required String id,
    required String name,
    num? creditLimit,
    String? cryptoSymbol,
    String? icon,
    String? color,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    try {
      await _client.from('wallets').update({
        'name': name.trim(),
        'credit_limit': ?creditLimit,
        'crypto_symbol': cryptoSymbol,
        'icon': icon,
        'color': color,
      }).eq('id', id).eq('user_id', userId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> archive(String id, {bool archived = true}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Not signed in', code: 'unauthenticated');
    }
    await _client
        .from('wallets')
        .update({'is_archived': archived})
        .eq('id', id)
        .eq('user_id', userId);
  }
}

final walletsForUserProvider =
    FutureProvider.family<List<WalletBalance>, String>((ref, userId) async {
  final rows = await ref.watch(walletRepositoryProvider).listBalances();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final walletsProvider = Provider<AsyncValue<List<WalletBalance>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(walletsForUserProvider(userId));
});
