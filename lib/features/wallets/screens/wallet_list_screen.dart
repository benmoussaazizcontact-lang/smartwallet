import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/wallet_visual_card.dart';
import '../repositories/wallet_repository.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wallets-add-fab',
        onPressed: () => context.go('/wallets/new'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(walletsForUserProvider),
        child: wallets.when(
          loading: () => const LoadingSkeleton(),
          error: (e, _) => ErrorView(
            message: '$e',
            onRetry: () => ref.invalidate(walletsForUserProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  EmptyState(
                    title: l10n.firstWalletTitle,
                    message: l10n.firstWalletHint,
                    actionLabel: l10n.addWallet,
                    onAction: () => context.go('/wallets/new'),
                  ),
                ],
              );
            }
            final totals = <String, num>{};
            for (final w in items) {
              totals.update(
                w.currency,
                (v) => v + w.currentBalance,
                ifAbsent: () => w.currentBalance,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                Text(l10n.totalsByCurrency, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: totals.entries
                      .map(
                        (e) => Chip(
                          label: Text(
                            Money.format(e.value, e.key),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...items.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WalletVisualCard(
                      wallet: w,
                      onTap: () => context.go('/wallets/${w.walletId}'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WalletListScreen extends WalletsScreen {
  const WalletListScreen({super.key});
}
