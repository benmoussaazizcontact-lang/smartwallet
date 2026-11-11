import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../domain/investment_math.dart';
import '../repositories/investment_repository.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final portfolios = ref.watch(portfoliosProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.portfolioTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/portfolio/new'),
        child: const Icon(Icons.add),
      ),
      body: portfolios.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(portfoliosForUserProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: l10n.noPlanData,
              message: l10n.notAdvice,
              actionLabel: l10n.newPortfolio,
              onAction: () => context.push('/plan/portfolio/new'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(l10n.notAdvice),
              for (final portfolio in items) ...[
                const SizedBox(height: 12),
                Text(portfolio.name, style: Theme.of(context).textTheme.titleMedium),
                _AllocationBlock(portfolio: portfolio),
                for (final asset in portfolio.assets)
                  ListTile(
                    title: Text('${asset.symbol} · ${asset.name}'),
                    subtitle: Text(
                      asset.currentPrice == null
                          ? l10n.priceMissing
                          : '${l10n.manualPrice} · ${asset.priceUpdatedAt?.toLocal().toString().split('.').first ?? ''}',
                    ),
                    trailing: Text(asset.position.quantity.toString()),
                    onTap: () => context.push('/plan/assets/${asset.id}'),
                  ),
                TextButton(
                  onPressed: () => context.push('/plan/assets/new?portfolio=${portfolio.id}'),
                  child: Text(l10n.newAsset),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AllocationBlock extends StatelessWidget {
  const _AllocationBlock({required this.portfolio});

  final PortfolioView portfolio;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allocation = allocate(
      currency: portfolio.currency,
      holdings: [
        for (final asset in portfolio.assets)
          if (asset.currency == portfolio.currency)
            (label: asset.symbol, value: asset.marketValue),
      ],
    );
    if (allocation.slices.isEmpty) return Text(l10n.priceMissing);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.allocation),
        for (final slice in allocation.slices)
          Text('${slice.label}: ${(slice.share * 100).toStringAsFixed(0)}%'),
        if (allocation.concentrated) Text(l10n.concentration),
      ],
    );
  }
}

class PortfolioFormScreen extends ConsumerStatefulWidget {
  const PortfolioFormScreen({super.key});

  @override
  ConsumerState<PortfolioFormScreen> createState() => _PortfolioFormScreenState();
}

class _PortfolioFormScreenState extends ConsumerState<PortfolioFormScreen> {
  final _name = TextEditingController();
  String _currency = 'TND';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPortfolio)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppTextField(controller: _name, label: l10n.name),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            items: [
              for (final currency in Currencies.all)
                DropdownMenuItem(value: currency.code, child: Text(currency.code)),
            ],
            onChanged: (value) => setState(() => _currency = value ?? _currency),
            decoration: InputDecoration(labelText: l10n.currency),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.save,
            loading: _saving,
            onPressed: () async {
              if (_name.text.trim().isEmpty) return;
              setState(() => _saving = true);
              try {
                await ref.read(investmentRepositoryProvider).createPortfolio(
                      name: _name.text,
                      currency: _currency,
                    );
                ref.invalidate(portfoliosForUserProvider);
                if (context.mounted) context.pop();
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class AssetFormScreen extends ConsumerStatefulWidget {
  const AssetFormScreen({super.key, required this.portfolioId});

  final String portfolioId;

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _symbol = TextEditingController();
  final _name = TextEditingController();
  String _class = 'stock';
  String _currency = 'TND';
  bool _saving = false;

  @override
  void dispose() {
    _symbol.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newAsset)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppTextField(controller: _symbol, label: l10n.symbol),
          const SizedBox(height: 12),
          AppTextField(controller: _name, label: l10n.name),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _class,
            items: [
              DropdownMenuItem(value: 'stock', child: Text(l10n.assetStocks)),
              DropdownMenuItem(value: 'etf', child: Text(l10n.assetEtf)),
              DropdownMenuItem(value: 'crypto', child: Text(l10n.assetCrypto)),
              DropdownMenuItem(value: 'other', child: Text(l10n.assetOther)),
            ],
            onChanged: (value) => setState(() => _class = value ?? _class),
            decoration: InputDecoration(labelText: l10n.planInvest),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            items: [
              for (final currency in Currencies.all)
                DropdownMenuItem(value: currency.code, child: Text(currency.code)),
            ],
            onChanged: (value) => setState(() => _currency = value ?? _currency),
            decoration: InputDecoration(labelText: l10n.currency),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.save,
            loading: _saving,
            onPressed: () async {
              if (_symbol.text.trim().isEmpty || _name.text.trim().isEmpty) return;
              setState(() => _saving = true);
              try {
                await ref.read(investmentRepositoryProvider).createAsset(
                      portfolioId: widget.portfolioId,
                      symbol: _symbol.text,
                      name: _name.text,
                      assetClass: _class,
                      currency: _currency,
                    );
                ref.invalidate(portfoliosForUserProvider);
                if (context.mounted) context.pop();
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class AssetDetailScreen extends ConsumerStatefulWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _mark = TextEditingController();
  final _requestIds = <String, String>{};
  bool _saving = false;

  String _idFor(String side) => _requestIds.putIfAbsent(side, () => const Uuid().v4());

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _mark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final portfolios = ref.watch(portfoliosProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.planInvest)),
      body: portfolios.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(message: '$error'),
        data: (items) {
          AssetView? asset;
          for (final portfolio in items) {
            for (final item in portfolio.assets) {
              if (item.id == widget.assetId) asset = item;
            }
          }
          if (asset == null) return Center(child: Text(l10n.noPlanData));
          final current = asset;
          final gain = unrealizedGain(current.position, current.currentPrice);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${current.symbol} · ${current.name}', style: Theme.of(context).textTheme.titleLarge),
              Text('${l10n.quantity}: ${current.position.quantity}'),
              Text('${l10n.realized}: ${Money.format(current.position.realized, current.currency)}'),
              Text(
                gain == null
                    ? l10n.priceMissing
                    : '${l10n.unrealized}: ${Money.format(gain, current.currency)}',
              ),
              if (current.priceUpdatedAt != null)
                Text('${l10n.manualPrice}: ${current.priceUpdatedAt!.toLocal()}'),
              Text(l10n.notAdvice),
              const SizedBox(height: 12),
              AppTextField(controller: _quantity, label: l10n.quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              AppTextField(controller: _price, label: l10n.unitPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              Row(
                children: [
                  Expanded(child: _tradeButton(context, current, 'buy', l10n.buy)),
                  const SizedBox(width: 8),
                  Expanded(child: _tradeButton(context, current, 'sell', l10n.sell)),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _mark, label: l10n.currentPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              AppButton(
                label: l10n.manualPrice,
                loading: _saving,
                onPressed: () async {
                  final price = Money.tryParse(_mark.text);
                  if (price == null) return;
                  setState(() => _saving = true);
                  try {
                    await ref.read(investmentRepositoryProvider).updatePrice(assetId: current.id, price: price);
                    ref.invalidate(portfoliosForUserProvider);
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tradeButton(BuildContext context, AssetView asset, String side, String label) {
    return OutlinedButton(
      onPressed: _saving
          ? null
          : () async {
              final quantity = Money.tryParse(_quantity.text);
              final price = Money.tryParse(_price.text);
              if (quantity == null || price == null) return;
              setState(() => _saving = true);
              try {
                await ref.read(investmentRepositoryProvider).trade(
                      assetId: asset.id,
                      side: side,
                      quantity: quantity,
                      unitPrice: price,
                      clientRequestId: _idFor(side),
                    );
                _requestIds[side] = const Uuid().v4();
                ref.invalidate(portfoliosForUserProvider);
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
      child: Text(label),
    );
  }
}
