import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/repositories/admin_repository.dart';
import '../../features/ai_classification/repositories/classification_repository.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/repositories/security_repository.dart';
import '../../features/categories/repositories/category_repository.dart';
import '../../features/receipts/providers/receipt_providers.dart';
import '../../features/recurring/repositories/recurring_repository.dart';
import '../../features/tags/repositories/tag_repository.dart';
import '../../features/transactions/repositories/transaction_repository.dart';
import '../../features/planning/repositories/budget_repository.dart';
import '../../features/planning/repositories/goal_repository.dart';
import '../../features/planning/repositories/investment_repository.dart';
import '../../features/wallets/repositories/wallet_repository.dart';

/// Drops cached rows that belong to a signed-in account.
/// Watching the public providers then yields an empty value until the new
/// account's family loads.
void clearUserScopedProviders(Ref ref) {
  ref.invalidate(walletsForUserProvider);
  ref.invalidate(budgetsForUserProvider);
  ref.invalidate(goalsForUserProvider);
  ref.invalidate(portfoliosForUserProvider);
  ref.invalidate(recentTransactionsForUserProvider);
  ref.invalidate(dashboardActivityForUserProvider);
  ref.invalidate(categoriesForUserProvider);
  ref.invalidate(tagsForUserProvider);
  ref.invalidate(recurringForUserProvider);
  ref.invalidate(merchantCorrectionsForUserProvider);
  ref.invalidate(pendingReceiptsForUserProvider);
  ref.invalidate(authUserForSessionProvider);
  ref.invalidate(securityHistoryForUserProvider);
  ref.invalidate(riskScoreForUserProvider);
  ref.invalidate(mfaFactorsProvider);
  ref.invalidate(mySupportRequestsForUserProvider);
  ref.invalidate(adminUserMetricsProvider);
  ref.invalidate(adminUserListProvider);
  ref.invalidate(adminSupportRequestsProvider);
  ref.invalidate(adminAuditLogProvider);
}
