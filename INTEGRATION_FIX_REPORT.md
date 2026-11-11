# Integration fix report

Date: 2026-10-22

This report covers the critical and high-priority items from `INTEGRATION_AUDIT.md`. It does not claim a live two-user Supabase session, a deployed Edge Function, or a camera scan on a device.

## Commands actually run

| Command | Result |
| --- | --- |
| `flutter gen-l10n` | Completed |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | 58 tests passed |
| `flutter build apk --release` | Built `build\app\outputs\flutter-apk\app-release.apk` (93.1 MB) |

The release APK was inspected only to confirm `assets/flutter_assets/.env` does not contain `DEMO_EMAIL`, `DEMO_PASSWORD`, `service_role`, or `OPENAI_API_KEY`. It was not installed on a phone.

## 1. Demo user removed from active flows

- **Root cause:** Receipt upload and insert compared the session id with `DemoUser.id`. Startup still contained `DemoSession`, which signs out any other user. `DEMO_EMAIL` and `DEMO_PASSWORD` were read from `.env`, and `.env` is a Flutter asset.
- **Files changed:** Deleted `lib/core/config/demo_user.dart`, `lib/core/services/demo_session.dart`, and `test/demo_user_test.dart`. Updated `lib/features/receipts/repositories/receipt_repository.dart`, `lib/core/config/env.dart`, `lib/app/bootstrap.dart`, wallet/category/tag/recurring/classification error text, `README.md`, and `.env`.
- **Fix:** Receipt paths are `{authenticatedUserId}/{operationId}.jpg`. A missing session throws `Not signed in`. Demo getters and the auto-login call are gone. Demo keys were removed from `.env`.
- **Tests:** `test/receipt_confirmation_test.dart` checks that user A’s path is rejected for user B, including the old demo uuid. Packaged release `.env` has no demo keys (`secret_markers_present=False`).
- **Limitation:** The public Supabase URL and publishable key remain in the asset, which is required for the client. This was not a live upload by a real account.

## 2. Receipt confirmation no longer creates a second transaction

- **Root cause:** Each save called `create()` with a new `p_client_request_id`. A storage failure cleared the in-memory “submitted” flag and the next tap posted another movement.
- **Files changed:** `lib/features/receipts/services/receipt_confirmation.dart`, `lib/features/receipts/providers/receipt_providers.dart`, `lib/features/receipts/screens/confirm_receipt_screen.dart`, `lib/features/receipts/models/receipt_draft.dart`, `lib/features/receipts/screens/scan_receipt_screen.dart`, `lib/features/dashboard/screens/dashboard_screen.dart`, `supabase/migrations/20261025120000_receipt_idempotency.sql`.
- **Fix:** One operation id is generated per confirmation and reused as `client_request_id`. The id is stored before the financial call. After a transaction id exists, retry skips creation and continues with upload, receipt row, then classification. The same storage object key is reused. Double taps are ignored while `_busy` is true. A dashboard reminder can resume or be dismissed without deleting the expense. PostgreSQL already returns an existing row for the same user and `client_request_id`. The new migration also catches a concurrent unique violation and adds `receipts_user_transaction_uidx`.
- **Tests:** Fake gateway: upload fails once, `createTransaction` is called once, retry keeps `tx-1`. A completed operation does not call create again. The migration source contains the unique-violation return and the receipt unique index.
- **Limitation:** The migration was not applied to the remote database. Restart recovery keeps the operation id in SharedPreferences, not the image bytes. After a process kill the user attaches the image again; the same operation id is reused only from the Scan screen opened with `resume=1`. Storage and Postgres are still two steps, not one atomic transaction.

## 3. Logout no longer keeps the previous account’s lists

- **Root cause:** Financial `FutureProvider`s kept the previous `AsyncData` while the next session loaded. Logout invalidated profile providers only. The transaction list also kept its own rows.
- **Files changed:** Wallet, transaction, category, tag, recurring, classification, auth, security, and support providers; `lib/core/session/clear_user_state.dart`; `lib/core/session/session_scope.dart`; `lib/features/auth/providers/auth_providers.dart`; `lib/app/router.dart`; `lib/features/transactions/screens/transaction_list_screen.dart`; `lib/features/receipts/screens/scan_receipt_screen.dart`.
- **Fix:** Each user-scoped query is a Riverpod family. The public provider returns an empty value when `currentUserId` is null, and watches only that user’s family. Sign-out and a user-id change invalidate those families, including receipts, classifications, profile, security history, and support. The transaction list and scan preview clear when the user id changes. Pending receipt records are stored per user id.
- **Tests:** `test/session_scope_test.dart` and the pending-store test that user B cannot read user A’s operation. No two-account UI session was executed.
- **Limitation:** Requires a manual login as user A, logout, then user B on a device to confirm the screen never paints A’s balances. Global categories (`user_id` null) remain visible to every account by existing RLS.

## 4. classify-transaction requires a user

- **Root cause:** The function called OpenAI whenever `OPENAI_API_KEY` was set. It never called `auth.getUser()`. Gateway JWT checks can still accept the anon key.
- **Files changed:** `supabase/functions/classify-transaction/index.ts`, `supabase/config.toml`, `lib/features/ai_classification/services/transaction_classification_service.dart`, `lib/features/ai_classification/services/classification_result.dart`, `lib/features/ai_classification/widgets/classification_banner.dart`.
- **Fix:** The function rejects missing or invalid user tokens with 401 before any model call. It limits body size, text length, and category count, and applies a per-isolate rate limit of 12 requests per minute. It does not read `classification_corrections` or `ai_classifications`. A missing model confidence is returned as null, and the app does not invent a percentage. `verify_jwt = true` is set for this function. The key stays in the function environment.
- **Tests:** `test/classify_function_guard_test.dart` reads the function source and checks that `auth.getUser` appears before `api.openai.com`, with 401 and 429, and without `service_role` or classification-history queries.
- **Limitation:** The function was not deployed and was not called over HTTP. The rate limit is per isolate, not a global quota. Corrections remain isolated by the existing `user_id = auth.uid()` policies, which were not re-executed here.

## 5. Receipt totals skip subtotals

- **Root cause:** The first match of `total|montant|amount` won. `sous-total` contains `total`.
- **Files changed:** `lib/features/receipts/services/ocr_parser.dart`, `lib/features/receipts/services/receipt_amounts.dart`, `lib/features/receipts/screens/confirm_receipt_screen.dart`, English/French/Arabic ARB files.
- **Fix:** Labels are ranked: net à payer, total TTC, then total. Sous-total, TVA, remise, montant payé, and monnaie rendue do not override a final total. TND three-digit fractions stay millimes (`48,500` and `1 250,000`). EUR `48,50` is 48.50 and `1.250` is a thousands group. If no final label parses, the amount stays empty and the confirmation screen asks for it.
- **Tests:** Passed in `test/ocr_classification_test.dart`: TTC versus sous-total/TVA/remise/monnaie, net à payer, English subtotal versus total, grouped TND, euro cents, and subtotal-only review.
- **Limitation:** Parser tests use text fixtures, not photographed receipts. Line items, invoice numbers, and tax amounts are still not extracted as separate saved fields.

## 6. OCR failures stay user-readable

- **Root cause:** The Latin engine and the old `InputImage.fromFilePath` path could surface a Java `NullPointerException`. ProGuard rules existed while R8 was off, so they had no effect.
- **Files changed:** `lib/features/receipts/services/ocr_service.dart`, `android/app/build.gradle.kts`, `android/app/proguard-rules.pro` (unchanged rules, now applied), `docs/ARABIC_OCR_PLAN.md`, scan screen copy.
- **Fix:** OCR still decodes the image in Dart and passes a bitmap, avoiding `fromFilePath`. Engine failures stay `OcrFailure` and the existing localization test rejects a Java stack in the message. Release R8 is enabled (`isMinifyEnabled = true`) with resource shrinking left off. Core library desugaring is enabled because `flutter_local_notifications` requires it for the release metadata check. The scan screen states that Arabic is not recognized on device.
- **Tests:** `test/ocr_error_test.dart` passed. The release APK built with R8 enabled.
- **Limitation:** The APK was not installed. The previous ML Kit `NullPointerException` was not reproduced or cleared on a device. Arabic OCR is not implemented; the plan is in `docs/ARABIC_OCR_PLAN.md`. Release signing is still the debug keystore.

## Remaining manual work

1. Apply `supabase/migrations/20261025120000_receipt_idempotency.sql` in the Supabase SQL editor or CLI. Do not disable RLS.
2. Deploy `classify-transaction` and confirm an anonymous call returns 401.
3. On a device, sign in as two users and confirm wallets, transactions, and the scan preview do not cross.
4. Scan a sharp receipt and a blurry one from the release APK and check logcat for `NullPointerException`.
5. Do not describe the Latin scanner as Arabic support until the plan in `docs/ARABIC_OCR_PLAN.md` is implemented and photographed.
