import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/money.dart';
import '../../features/transactions/models/transaction.dart';
import 'pressable.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.walletName,
    this.onTap,
  });

  final MoneyTransaction transaction;
  final String? walletName;
  final VoidCallback? onTap;

  Color get _amountColor {
    if (transaction.type.startsWith('TRANSFER')) return AppColors.primary;
    return transaction.isDebit ? AppColors.danger : AppColors.success;
  }

  IconData get _icon {
    if (transaction.type.startsWith('TRANSFER')) return Icons.swap_horiz_rounded;
    return transaction.isDebit ? Icons.south_west_rounded : Icons.north_east_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = transaction.isVoided
        ? Theme.of(context).disabledColor
        : _amountColor;
    final title = transaction.merchant?.isNotEmpty == true
        ? transaction.merchant!
        : (transaction.description ?? localizedTransactionType(l10n, transaction.type));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final category = transaction.categoryName == null
        ? null
        : localizedCategoryName(l10n, transaction.categoryName!);
    final debit = transaction.isDebit && !transaction.type.startsWith('TRANSFER');
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(_icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration:
                          transaction.isVoided ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    [
                      localizedTransactionType(l10n, transaction.type),
                      ?walletName,
                      ?category,
                      DateFormat.MMMd(locale).add_Hm().format(transaction.date.toLocal()),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Text(
                '${debit ? '-' : (transaction.type.startsWith('TRANSFER') ? '' : '+')}${Money.format(transaction.amount, transaction.currency)}',
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary(Theme.of(context).brightness),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevated(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}
