import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../tags/models/tag.dart';
import '../../tags/repositories/tag_repository.dart';
import '../../planning/repositories/budget_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  const TransactionDetailsScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen> {
  late final Future<MoneyTransaction> _transactionFuture;
  late final Future<List<TagItem>> _tagsFuture;
  final Map<(double, double), Future<String?>> _addressFutures = {};

  @override
  void initState() {
    super.initState();
    _transactionFuture = ref
        .read(transactionRepositoryProvider)
        .getById(widget.transactionId);
    _tagsFuture = ref
        .read(tagRepositoryProvider)
        .forTransaction(widget.transactionId);
  }

  Future<String?> _addressFuture(double latitude, double longitude) {
    final key = (latitude, longitude);
    return _addressFutures.putIfAbsent(
      key,
      () => const LocationService().addressFor(latitude, longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _transactionFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: ErrorView(message: '${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: LoadingSkeleton(count: 2));
        }
        final tx = snapshot.data!;
        final debit = tx.isDebit;
        final color = debit ? AppColors.danger : AppColors.success;
        final wallets = ref.watch(walletsProvider).asData?.value ?? [];
        final wallet = wallets.where((w) => w.walletId == tx.walletId);
        final l10n = context.l10n;
        final locale = Localizations.localeOf(context).toLanguageTag();
        return Scaffold(
          appBar: AppBar(title: Text(l10n.transaction)),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${debit ? '-' : '+'}${Money.format(tx.amount, tx.currency)}',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: color),
              ),
              const SizedBox(height: 8),
              Text(localizedTransactionType(l10n, tx.type)),
              Text(tx.merchant ?? '—'),
              Text(tx.description ?? l10n.noDescription),
              Text(DateFormat.yMMMd(locale).add_Hm().format(tx.date.toLocal())),
              Text(
                l10n.walletLabel(
                  wallet.isEmpty ? tx.walletId : wallet.first.name,
                ),
              ),
              Text(
                l10n.categoryLabel(
                  tx.categoryName == null
                      ? '—'
                      : localizedCategoryName(l10n, tx.categoryName!),
                ),
              ),
              Text(l10n.statusLabel(tx.status)),
              FutureBuilder(
                future: _tagsFuture,
                builder: (context, tagSnap) {
                  final tags = tagSnap.data ?? [];
                  if (tags.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      children: tags
                          .map((t) => Chip(label: Text(t.name)))
                          .toList(),
                    ),
                  );
                },
              ),
              if (tx.hasLocation) ...[
                const SizedBox(height: 16),
                FutureBuilder(
                  future: _addressFuture(
                    tx.latitude!.toDouble(),
                    tx.longitude!.toDouble(),
                  ),
                  builder: (context, addr) =>
                      Text(addr.data ?? '${tx.latitude}, ${tx.longitude}'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          tx.latitude!.toDouble(),
                          tx.longitude!.toDouble(),
                        ),
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.wallet_app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                tx.latitude!.toDouble(),
                                tx.longitude!.toDouble(),
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.place,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!tx.isVoided && !tx.type.startsWith('TRANSFER'))
                OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.voidAction),
                        content: Text(l10n.voidHint),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.voidAction),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref
                          .read(transactionRepositoryProvider)
                          .voidTransaction(tx.id, reason: 'User void');
                      ref.invalidate(recentTransactionsForUserProvider);
                      ref.invalidate(walletsForUserProvider);
                      ref.invalidate(dashboardActivityForUserProvider);
                      ref.invalidate(budgetsForUserProvider);
                      if (context.mounted) context.go('/transactions');
                    }
                  },
                  child: Text(l10n.voidAction),
                ),
            ],
          ),
        );
      },
    );
  }
}
