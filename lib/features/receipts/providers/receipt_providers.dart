import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/providers/supabase_provider.dart';
import '../services/receipt_confirmation.dart';

final receiptOperationStoreProvider = Provider<ReceiptOperationStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsReceiptOperationStore(
    () => prefs.getString(SharedPrefsReceiptOperationStore.storageKey),
    (value) => prefs.setString(SharedPrefsReceiptOperationStore.storageKey, value),
  );
});

final pendingReceiptsForUserProvider =
    FutureProvider.family<List<ReceiptOperation>, String>((ref, userId) {
  return ref.watch(receiptOperationStoreProvider).pendingFor(userId);
});

final pendingReceiptsProvider = Provider<AsyncValue<List<ReceiptOperation>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AsyncData([]);
  return ref.watch(pendingReceiptsForUserProvider(userId));
});

/// Test hook. Production uses [sharedPreferencesProvider].
ReceiptOperationStore receiptStoreFromPrefs(SharedPreferences prefs) {
  return SharedPrefsReceiptOperationStore(
    () => prefs.getString(SharedPrefsReceiptOperationStore.storageKey),
    (value) => prefs.setString(SharedPrefsReceiptOperationStore.storageKey, value),
  );
}
