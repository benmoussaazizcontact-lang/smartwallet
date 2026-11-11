import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/wallet_visual_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../models/wallet.dart';
import '../repositories/wallet_repository.dart';

class WalletDetailsScreen extends ConsumerStatefulWidget {
  const WalletDetailsScreen({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<WalletDetailsScreen> createState() =>
      _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends ConsumerState<WalletDetailsScreen> {
  late final Future<WalletBalance> _walletFuture;
  late final Future<List<MoneyTransaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = ref.read(walletRepositoryProvider).getById(widget.walletId);
    _transactionsFuture = ref
        .read(transactionRepositoryProvider)
        .list(filters: TransactionFilters(walletId: widget.walletId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _walletFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: ErrorView(message: '${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: LoadingSkeleton(count: 3));
        }
        final wallet = snapshot.data!;
        final l10n = context.l10n;
        final locale = Localizations.localeOf(context).toLanguageTag();
        return Scaffold(
          appBar: AppBar(
            title: Text(wallet.name),
            actions: [
              IconButton(
                tooltip: l10n.addWallet,
                onPressed: () => context.push('/wallets/new'),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: l10n.edit,
                onPressed: () => context.go('/wallets/${widget.walletId}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              WalletVisualCard(wallet: wallet),
              const SizedBox(height: 12),
              Text(
                l10n.currentBalance,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                Money.format(wallet.currentBalance, wallet.currency),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                l10n.initial(
                  Money.format(wallet.initialBalance, wallet.currency),
                ),
              ),
              Text(
                '${l10n.created} ${DateFormat.yMMMd(locale).add_Hm().format(wallet.createdAt.toLocal())}',
              ),
              if (wallet.walletType == 'CREDIT_CARD') ...[
                Text(
                  '${l10n.debt} ${Money.format(wallet.debt, wallet.currency)}',
                ),
                Text(
                  '${l10n.limit} ${Money.format(wallet.creditLimit, wallet.currency)}',
                ),
                Text(
                  '${l10n.available} ${Money.format(wallet.availableCredit ?? 0, wallet.currency)}',
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.archiveWalletTitle),
                      content: Text(l10n.archiveWalletBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.archiveWallet),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref
                        .read(walletRepositoryProvider)
                        .archive(widget.walletId);
                    ref.invalidate(walletsForUserProvider);
                    if (context.mounted) context.go('/wallets');
                  }
                },
                child: Text(l10n.archiveWallet),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.walletTransactions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FutureBuilder(
                future: _transactionsFuture,
                builder: (context, txSnap) {
                  final txs = txSnap.data ?? [];
                  if (txs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noWalletTransactions),
                    );
                  }
                  return Column(
                    children: txs
                        .map(
                          (t) => TransactionTile(
                            transaction: t,
                            walletName: wallet.name,
                            onTap: () => context.go('/transactions/${t.id}'),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
