import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/money.dart';
import '../../features/wallets/models/wallet.dart';
import 'pressable.dart';

class WalletVisualCard extends StatelessWidget {
  const WalletVisualCard({
    super.key,
    required this.wallet,
    this.onTap,
    this.compact = false,
    this.hideBalance = false,
  });

  final WalletBalance wallet;
  final VoidCallback? onTap;
  final bool compact;
  final bool hideBalance;

  List<Color> get _gradient {
    return switch (wallet.walletType) {
      'CASH' => const [Color(0xFF064E3B), Color(0xFF10B981)],
      'BANK_ACCOUNT' => const [Color(0xFF0B1B3A), Color(0xFF2563EB)],
      'CREDIT_CARD' => const [Color(0xFF1A1325), Color(0xFF7C5CFC)],
      'CRYPTO' => const [Color(0xFF2E1064), Color(0xFF7C3AED)],
      'SAVINGS' => const [Color(0xFF0F3D4C), Color(0xFF2DD4BF)],
      _ => const [AppColors.primary, AppColors.secondary],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = compact ? 118.0 : 168.0;
    final amount = hideBalance
        ? '••••  ${wallet.currency}'
        : Money.format(wallet.currentBalance, wallet.currency);
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            gradient: LinearGradient(
              colors: _gradient,
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            boxShadow: AppShadows.glow(),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -40,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -30,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: compact ? 22 : 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        child: Icon(wallet.style.icon, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              wallet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              '${localizedWalletType(l10n, wallet.walletType)} · ${wallet.currency}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            amount,
                            key: ValueKey(amount),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
