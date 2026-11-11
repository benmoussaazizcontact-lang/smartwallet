import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/investment_math.dart';

class AssetView {
  const AssetView({
    required this.id,
    required this.portfolioId,
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.currency,
    required this.position,
    this.currentPrice,
    this.priceUpdatedAt,
    this.manualPrice = true,
  });

  final String id;
  final String portfolioId;
  final String symbol;
  final String name;
  final String assetClass;
  final String currency;
  final Position position;
  final num? currentPrice;
  final DateTime? priceUpdatedAt;
  final bool manualPrice;

  num? get marketValue => currentPrice == null ? null : position.quantity * currentPrice!;
}

class PortfolioView {
  const PortfolioView({required this.id, required this.name, required this.currency, required this.assets});

  final String id;
  final String name;
  final String currency;
  final List<AssetView> assets;
}

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository(ref.watch(supabaseProvider));
});

final portfoliosForUserProvider = FutureProvider.family<List<PortfolioView>, String>((ref, userId) async {
  final rows = await ref.watch(investmentRepositoryProvider).list();
  if (ref.read(currentUserIdProvider) != userId) return const [];
  return rows;
});

final portfoliosProvider = Provider<AsyncValue<List<PortfolioView>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(portfoliosForUserProvider(userId));
});

class InvestmentRepository {
  InvestmentRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<PortfolioView>> list() async {
    final userId = _userId;
    if (userId == null) return const [];
    final portfolios = await _client.from('investment_portfolios').select().eq('user_id', userId).order('created_at');
    final assets = await _client.from('investment_assets').select().eq('user_id', userId);
    final trades = await _client.from('investment_transactions').select().eq('user_id', userId).order('traded_on');
    final byAsset = <String, List<Trade>>{};
    for (final row in trades) {
      final id = row['asset_id'] as String;
      byAsset.putIfAbsent(id, () => []).add(
            Trade(
              side: row['side'] as String,
              quantity: num.parse(row['quantity'].toString()),
              unitPrice: num.parse(row['unit_price'].toString()),
              date: DateTime.parse(row['traded_on'] as String),
            ),
          );
    }
    return [
      for (final portfolio in portfolios)
        PortfolioView(
          id: portfolio['id'] as String,
          name: portfolio['name'] as String,
          currency: portfolio['base_currency'] as String,
          assets: [
            for (final asset in assets)
              if (asset['portfolio_id'] == portfolio['id'])
                AssetView(
                  id: asset['id'] as String,
                  portfolioId: asset['portfolio_id'] as String,
                  symbol: asset['symbol'] as String,
                  name: asset['name'] as String,
                  assetClass: asset['asset_class'] as String,
                  currency: asset['currency'] as String,
                  position: applyTrades(byAsset[asset['id']] ?? const []),
                  currentPrice: asset['current_price'] == null ? null : num.parse(asset['current_price'].toString()),
                  priceUpdatedAt: asset['price_updated_at'] == null
                      ? null
                      : DateTime.parse(asset['price_updated_at'] as String),
                  manualPrice: asset['manual_price'] as bool? ?? true,
                ),
          ],
        ),
    ];
  }

  Future<String> createPortfolio({required String name, required String currency}) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    final row = await _client
        .from('investment_portfolios')
        .insert({'user_id': userId, 'name': name.trim(), 'base_currency': currency})
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<String> createAsset({
    required String portfolioId,
    required String symbol,
    required String name,
    required String assetClass,
    required String currency,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    final row = await _client.from('investment_assets').insert({
      'user_id': userId,
      'portfolio_id': portfolioId,
      'symbol': symbol.trim().toUpperCase(),
      'name': name.trim(),
      'asset_class': assetClass,
      'currency': currency,
    }).select('id').single();
    return row['id'] as String;
  }

  Future<void> trade({
    required String assetId,
    required String side,
    required num quantity,
    required num unitPrice,
    required String clientRequestId,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    final existing = await _client
        .from('investment_transactions')
        .select('id')
        .eq('user_id', userId)
        .eq('client_request_id', clientRequestId)
        .maybeSingle();
    if (existing != null) return;
    final current = await list();
    AssetView? asset;
    for (final portfolio in current) {
      for (final item in portfolio.assets) {
        if (item.id == assetId) asset = item;
      }
    }
    if (asset == null) throw const AppException('Asset not found.', code: 'not_found');
    if (side == 'sell' && quantity > asset.position.quantity + 0.0000001) {
      throw const AppException('This trade would exceed the holding.', code: 'invalid');
    }
    await _client.from('investment_transactions').insert({
      'user_id': userId,
      'asset_id': assetId,
      'side': side,
      'quantity': quantity,
      'unit_price': unitPrice,
      'client_request_id': clientRequestId,
    });
  }

  Future<void> updatePrice({required String assetId, required num price}) async {
    final userId = _userId;
    if (userId == null) throw const AppException('Not signed in', code: 'unauthenticated');
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('investment_assets').update({
      'current_price': price,
      'price_updated_at': now,
      'manual_price': true,
    }).eq('id', assetId).eq('user_id', userId);
    await _client.from('investment_price_history').insert({
      'user_id': userId,
      'asset_id': assetId,
      'price': price,
      'recorded_at': now,
    });
  }
}
