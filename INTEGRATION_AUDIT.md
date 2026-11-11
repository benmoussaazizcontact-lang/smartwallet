# Integration audit

Phase 2 update (2026-10-22): the critical receipt, logout, parser, and Edge Function issues below were implemented in the app. See `INTEGRATION_FIX_REPORT.md` for what was executed. The original findings stay in this file as the inspection record.

Verified after the fixes: `flutter analyze` reported no issues, `flutter test --reporter expanded` passed (58 tests), and `flutter build apk --release` produced `build\app\outputs\flutter-apk\app-release.apk`. The packaged `.env` asset does not contain demo credentials. Live Supabase, a two-account device login, and an on-device camera scan were not run.

Status of the original inspection: **code inspection only** at the time it was written. Nothing in the sections below was, by itself, a device or database execution.

Date: 2026-10-22  
Workspace: `wallet_app` (`pubspec.yaml` version `1.0.0+1`)

## What already fits together

The two modules are already in one feature-first Flutter app. There is no second `pubspec.yaml` and no duplicate wallet or auth package.

| Area | Current state | Evidence |
| --- | --- | --- |
| Entry | `lib/main.dart` → `BootstrapApp` | Demo auto-login was removed in phase 2 |
| Auth | Register, login, password reset, profile, 2FA, biometrics, devices, support | `lib/features/auth/` |
| Routing | GoRouter, public routes, session redirect, bottom-nav shell | `lib/app/router.dart` |
| Finance | Wallets, transactions, transfers, categories, tags, recurring, receipts, classification | `lib/features/` |
| User id on writes | Most repositories use `supabase.auth.currentUser?.id` | Wallet, category, tag, recurring, classification repositories |
| Money movement | `create_transaction`, `transfer_money`, `void_transaction` take `auth.uid()` inside SQL | `supabase/migrations/20261012120000_harden_finance_schema.sql`, re-wrapped in `20261022100000_admin_user_management.sql` |
| RLS | Owner policies exist for wallets, transactions, transfers, receipts, categories, tags, corrections, storage paths | Migrations plus `supabase/wallet_project_complete_setup.sql` |
| i18n | `en`, `fr`, `ar` ARB files; Arabic font hook in typography | `lib/l10n/`, `l10n.yaml` |
| Design tokens | Navy / electric blue theme, shared buttons, cards, motion | `lib/core/theme/`, `lib/core/constants/app_colors.dart` |
| Extra modules to keep | Admin, support, low-balance push | `lib/features/admin/`, `lib/features/notifications/` |

`WalletApp` in `lib/app/app.dart` is not referenced by `main.dart`. The running tree is `BootstrapApp`.

## Issue index

Severity: **Critical** blocks a real user or can duplicate money. **High** is a security or correctness gap. **Medium** is incomplete behavior or drift. **Low** is cleanup.

### 1. Receipts still belong only to the demo user

- **Severity:** Critical
- **Status:** Verified in source. Not tested against Supabase.
- **Files:** `lib/features/receipts/repositories/receipt_repository.dart`, `lib/core/config/demo_user.dart`
- **What is wrong:** Upload and insert both reject any session whose id is not `7d2f1a6e-9c4b-4e8a-b3d1-2f6a8c0e5b91`. A registered user can pass the confirmation screen and create a transaction, then fail on the receipt with “Receipt upload is limited to the demo account.”
- **Correction:** Authorize `supabase.auth.currentUser?.id` only. Keep the path `receipts/{userId}/{uuid}.jpg`. Remove the demo-id comparison. Leave Storage RLS as the server check.
- **Verify:** Two real accounts. User A uploads a receipt. User B’s storage list and `receipts` select stay empty. User A’s upload succeeds.

### 2. A failed receipt upload can create a second transaction

- **Severity:** Critical
- **Status:** Verified in source. Not executed.
- **Files:** `lib/features/receipts/screens/confirm_receipt_screen.dart`, `lib/features/transactions/repositories/transaction_repository.dart`
- **What is wrong:** Save order is `create_transaction`, then storage upload, then `receipts` insert, then classification. On any error, `_submitted` is set back to false. The next tap calls `create()` again. `p_client_request_id` is a new UUID inside the repository, so the database idempotency index does not see a retry.
- **Correction:** Generate one client request id for the confirmation attempt and reuse it. If the transaction id is already known, only retry upload and metadata. Show a recoverable state. Do not claim PostgreSQL and Storage are one atomic transaction.
- **Verify:** Unit-test the retry branch with a fake repository. Manually fail storage (offline or denied policy) and confirm the wallet balance moves once.

### 3. Demo session can still sign a real user out

- **Severity:** High
- **Status:** Verified in source. The call is currently disabled.
- **Files:** `lib/core/services/demo_session.dart`, `lib/app/bootstrap.dart`, `lib/core/config/env.dart`, `README.md`, `test/demo_user_test.dart`
- **What is wrong:** `DemoSession.ensure()` signs out any session that is not the hardcoded demo user, then signs in with `DEMO_EMAIL` / `DEMO_PASSWORD`. Bootstrap comments say to turn it back on after auth testing. `.env` is a Flutter asset (`pubspec.yaml`), so those credentials are packaged into the APK if they are present. `.env` is gitignored; this audit did not open it.
- **Correction:** Delete demo login from the production startup path. Stop shipping demo credentials in the asset bundle. Keep `test/demo_user_test.dart` from requiring that UUID once the constant is gone.
- **Verify:** Cold start with a saved session stays on that user. Release APK asset listing does not contain `DEMO_PASSWORD`.

### 4. Logout does not clear financial state explicitly

- **Severity:** High
- **Status:** Verified in source. Cross-account UI not tested.
- **Files:** `lib/features/auth/providers/auth_session_refresh.dart`, `lib/features/auth/providers/auth_providers.dart`, `lib/app/router.dart`, `lib/features/wallets/repositories/wallet_repository.dart`, `lib/features/transactions/repositories/transaction_repository.dart`, `lib/features/dashboard/screens/dashboard_screen.dart`
- **What is wrong:** `refreshUserModuleProviders` reloads profile and security only. Wallet, transaction, category, tag, recurring, and correction providers watch `currentSessionProvider`, so they should recompute, but the shell is an `IndexedStack` and several screens read `asData?.value`. Previous balances can remain visible while the next user’s future is in flight. Logout does not cancel an in-progress OCR or classification call.
- **Correction:** On sign-out, invalidate every user-scoped provider and drop in-memory receipt bytes before navigating to welcome. Do not keep financial `AsyncData` across user ids.
- **Verify:** User A data on screen, logout, login as user B before the network returns. Dashboard, wallets, transactions, categories, and scan preview must be empty or loading, never A’s rows.

### 5. Remote classification does not check the caller

- **Severity:** High
- **Status:** Verified in source. Live function config was not queried.
- **Files:** `supabase/functions/classify-transaction/index.ts`, `supabase/config.toml`
- **What is wrong:** The function reads `OPENAI_API_KEY` and calls OpenAI. It never calls `auth.getUser()`. Only `wallet-low-balance-push` sets `verify_jwt = false`. Supabase’s default JWT check still accepts a valid anon JWT on many projects, which is the publishable key already in the app. The function also trusts the category catalog sent by the client and returns the model’s own confidence number.
- **Correction:** Require a user JWT inside the function. Ignore client confidence. If the key is missing, return `available: false` and let the app keep the local classifier. Do not put `OPENAI_API_KEY` or `service_role` in Flutter.
- **Verify:** Call the function with the publishable key and no user session; expect 401. Call it as user A; expect a category id that exists in the supplied catalog or null. With the secret unset, the app still shows the local suggestion.

### 6. OCR can treat a subtotal as the amount to pay

- **Severity:** High
- **Status:** Verified by reading `OcrParser`. Not run against photos.
- **Files:** `lib/features/receipts/services/ocr_parser.dart`, `test/ocr_classification_test.dart`
- **What is wrong:** The first match of `total|montant|amount` wins. `sous-total` contains `total`, so a subtotal earlier in the text beats `TOTAL TTC` or `NET À PAYER`. There is no tax, discount, paid, or change split. Invoice number, time, and line items are not extracted. Currency falls back to `TND` when no code is found. Amounts with a thousands space (`1 250,000 TND`) do not match the OCR regex. `Money.tryParse` can read a spaced amount later, on the confirmation field, but the scanner never fills it. `48.500` becomes `48.5` through `num.tryParse`, which is the same value but hides 3-decimal TND precision in the draft string.
- **Correction:** Rank labels: net à payer, montant TTC, amount due, total, then reject sous-total, subtotal, HT, tax, TVA, discount, remise, paid, change, monnaie. Parse by currency (TND millimes vs EUR cents). Leave amount empty when no winning label exists.
- **Verify:** Parser tests for French TTC vs HT, English subtotal vs total, `48,500 TND`, `48.500 TND`, `48,50 EUR`, `1 250,000 TND`, and a receipt with no total.

### 7. Arabic OCR is not implemented

- **Severity:** High for the Arabic scanning requirement. Latin path is present.
- **Status:** Verified in source. Not tested on a device.
- **Files:** `lib/features/receipts/services/ocr_service.dart`
- **What is wrong:** The only engine is `TextRecognitionScript.latin`. Google ML Kit’s Latin recognizer does not provide a supported Arabic model in this integration. No server OCR path exists.
- **Correction:** Keep Latin on-device. Add a separate Arabic path only after a real engine is chosen and tested. Until then, the UI must say Arabic script is not recognized locally. Do not mark Arabic OCR as working.
- **Verify:** Device photos of Arabic receipts. Record recognized text. A blank or Latin-only result means the claim stays false.

### 8. The previous ML Kit release crash is not proven fixed

- **Severity:** High
- **Status:** Mitigations exist in source. Release behavior was not built or run.
- **Files:** `lib/features/receipts/services/ocr_service.dart`, `android/app/proguard-rules.pro`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- **What is wrong:** OCR no longer calls `InputImage.fromFilePath`. It decodes RGBA in Dart and calls `InputImage.fromBitmap`. That avoids the old `file://` null stream, but ML Kit’s Android bitmap path is sensitive to pixel format and rotation. ProGuard keep rules for ML Kit registrars exist, yet `build.gradle.kts` never sets `isMinifyEnabled` or `isShrinkResources`. Those rules do nothing until R8 is actually on. Release signing is still the debug keystore. `applicationId` is `com.example.wallet_app`.
- **Correction:** Confirm `fromBitmap` format against `google_mlkit_commons` 0.15 on an API 35/36 release build. Enable minify only together with the existing keep rules, then run a release scan. Do not treat `flutter analyze` as proof.
- **Verify:** `flutter build apk --release`, install that APK, scan a sharp Latin receipt and a blurry one. Capture logcat if a `NullPointerException` returns.

### 9. Scanner UI is incomplete for the requested capture flow

- **Severity:** Medium
- **Status:** Verified in source.
- **Files:** `lib/features/receipts/screens/scan_receipt_screen.dart`, `lib/features/receipts/screens/confirm_receipt_screen.dart`, `lib/features/receipts/models/receipt_draft.dart`
- **What is present:** Camera and gallery through `image_picker`, preview, animated frame, scan line that stops when reduced motion is on, loading flag, localized OCR errors, editable confirmation, original image via `Image.memory`.
- **What is missing:** In-app crop and rotate, perspective correction, blur/resolution checks, document-edge guidance beyond a painted frame, explicit “amount missing” review state, confidence on each extracted field. Preprocessing is only a decode to width 1600. The scan line keeps running during OCR unless the user prefers reduced motion.
- **Correction:** Add quality checks and crop/rotate with a light dependency or Flutter’s image APIs. Keep the original bytes for review. Do not block the OCR isolate on decorative animation.
- **Verify:** Denied camera permission, gallery import, blurry image, missing total, retake. Device required for camera.

### 10. Classification is local-first, but remote confidence is untrusted-by-policy and still displayed

- **Severity:** Medium
- **Status:** Local rules verified by reading tests and `RuleClassifier`. Remote path not called.
- **Files:** `lib/features/ai_classification/services/rule_classifier.dart`, `lib/features/ai_classification/services/transaction_classification_service.dart`, `lib/features/ai_classification/repositories/classification_repository.dart`
- **What works:** Exact merchant tokens score 0.95, contained keywords 0.82, weak parent hints 0.45. User corrections score the documented constant 0.99 and are loaded from `classification_corrections`. Corrections are written with the session user id. Low confidence does not auto-select on the receipt screen. Unknown merchants return null locally.
- **Gaps:** Rules are Latin keywords only (no Arabic merchant names). Remote errors are English strings, not ARB. The model’s confidence is shown as if it were measured. Category matching is by English catalog names (`Groceries`, `Fuel`), so a renamed or French-only category silently gets no suggestion.
- **Correction:** Keep the three levels. Display remote failure as a limitation. Do not invent a score when the model omits one. Match categories by stable ids seeded in SQL, not only by English display names.
- **Verify:** Existing `test/ocr_classification_test.dart`, plus cases for unknown merchant, user correction override, and a thrown functions error.

### 11. Database scripts are strong on paper and unverified in this workspace

- **Severity:** High until the live database is compared. Schema design in the migrations is mostly sound.
- **Status:** Read from SQL. Not applied or executed here. `supabase/tests/rls_two_users.sql` is comments, not a test.
- **Files:** `supabase/migrations/*.sql`, `supabase/wallet_project_complete_setup.sql`, `supabase/diagnostics.sql`
- **What looks correct in migrations:** RLS on financial tables; `wallet_balances` and `activity_feed` use `security_invoker = true`; movements, transactions, and transfers are not client-writable; `initial_balance`, `user_id`, and `currency` are trigger-protected; client request ids are unique per user; receipt storage policies use the first folder segment as `auth.uid()`; admin RPCs check `app_metadata.role = admin`; push webhook uses a shared secret and keeps `service_role` on the server.
- **Conflicts and gaps:**
  1. `wallet_project_complete_setup.sql` is a concatenated manual script. Running it on a database that already has the migration history can recreate policies and functions out of order. Migrations should stay the source of truth.
  2. This workspace cannot see whether those migrations were applied to the linked project.
  3. `recurring_executions` is granted insert/update/delete to `authenticated` with an owner policy, so a user can insert their own execution rows and interfere with the scheduler’s uniqueness.
  4. Transaction search builds a PostgREST `or` filter by string interpolation (`description.ilike.%$q%`). A comma or parenthesis in the search box can change the filter. It is not raw SQL execution, and RLS still applies.
  5. No Flutter test proves user A cannot read user B. The SQL file only tells a human which selects to run.
- **Correction:** Add an additive migration only for gaps that inspection confirms on the live database. Do not disable RLS. Do not run destructive SQL from the app. Generate diagnostics for manual execution if the project is not linked.
- **Verify:** `supabase/diagnostics.sql` plus the two-user selects, after the UUIDs are real. Confirm `CREATE POLICY` names match the latest migration, not an older copy inside the setup script.

### 12. Auth routing is real, with a few holes

- **Severity:** Medium
- **Status:** Verified in source. Not widget-tested.
- **Files:** `lib/app/router.dart`, `lib/core/providers/supabase_provider.dart`, `lib/features/auth/widgets/biometric_gate.dart`
- **What works:** Unauthenticated users are sent to `/welcome`. Authenticated users are sent away from login and register. Session updates come from one `onAuthStateChange` subscription. Null sessions are applied on `signedOut`, not on every transient event. Biometric gate wraps the shell and profile.
- **Holes:** `/admin/users` is not role-gated in the router. The SQL functions refuse non-admins, but the screen still opens. Settings logout copy is hardcoded French. `signOut()` defaults to `SignOutScope.local`, so other devices stay signed in until the devices screen revokes them. That is acceptable if the UI says so.
- **Correction:** Gate the admin route on the same role the SQL checks. Move logout strings into ARB. Keep local sign-out, and keep the separate “other sessions” action.
- **Verify:** Widget tests with a fake session: protected route redirects, public route redirects when signed in, admin route hidden for a normal user.

### 13. Theme preference does not drive the running app

- **Severity:** Medium
- **Status:** Verified in source.
- **Files:** `lib/app/bootstrap.dart`, `lib/app/app.dart`, `lib/features/settings/screens/settings_screen.dart`, `lib/features/receipts/screens/scan_receipt_screen.dart`
- **What is wrong:** Settings write `theme_mode` on the profile. `WalletApp` reads it, but `main.dart` never builds `WalletApp`. `BootstrapApp` forces `ThemeMode.system`. The scanner hardcodes `AppColors.darkBackground` and white foreground, so light mode still shows a dark scan page. Admin screens use raw French titles.
- **Correction:** One theme controller used by `BootstrapApp`. Scan, auth, and admin screens consume the same color, type, and spacing tokens. Preserve reduced motion.
- **Verify:** Light, dark, and system on login, dashboard, wallets, transfer, scan, and settings. Arabic locale flips direction.

### 14. Localization is generated, but new failures are still raw strings

- **Severity:** Medium
- **Status:** `lib/l10n/untranslated.txt` is `{}`. Hardcoded strings remain outside ARB.
- **Files:** `lib/core/errors/app_exception.dart`, repositories (`Session démo absente`, `Non authentifié`), `lib/features/settings/screens/settings_screen.dart`, `lib/features/admin/`, classification unavailable messages
- **Correction:** Translate auth, wallet, OCR, classification, receipt, storage, and success messages in `app_en.arb`, `app_fr.arb`, and `app_ar.arb`. Do not translate merchant names the user typed.
- **Verify:** `test/i18n_test.dart` plus a widget that pumps `ar` and expects RTL.

### 15. Performance hotspots

- **Severity:** Medium
- **Status:** Verified in source. Not profiled.
- **Files:** `lib/features/transactions/repositories/transaction_repository.dart`, `lib/features/dashboard/screens/dashboard_screen.dart`, `lib/features/receipts/services/ocr_service.dart`
- **Findings:** The transaction list pages with `range` (good). The dashboard asks for up to 400 activity rows on every open (heavy). Wallet balances recompute a movement sum per wallet inside the SQL view (correct, can get slow without a covering index). OCR decodes on the UI isolate. Full receipt bytes are held for the confirmation route. Google Fonts are fetched for Inter and Cairo.
- **Correction:** Cache dashboard aggregates per user id, paginate activity, run decode off the UI isolate, and evict receipt bytes on logout. Do not share that cache across accounts.
- **Verify:** Flutter DevTools timeline on dashboard refresh and a scan. SQL `EXPLAIN` on `wallet_balances` for a user with many movements.

### 16. Tests do not cover the integration

- **Severity:** Medium
- **Status:** Files listed. Suite was not executed in this audit.
- **Files:** `test/widget_test.dart`, `test/auth_validation_test.dart`, `test/demo_user_test.dart`, `test/wallet_module_test.dart`, `test/money_test.dart`, `test/ocr_classification_test.dart`, `test/ocr_error_test.dart`, `test/i18n_test.dart`, `test/validation_error_cases_test.dart`, `test/risk_score_service_test.dart`
- **Gaps:** No login/logout widget test, no route guard test, no two-user repository test, no OCR fixture for multiple totals, no Arabic case, no upload-failure retry test, no release ML Kit test.
- **Correction:** Add those tests without deleting passing ones. Mark camera, release R8, and live RLS as manual.
- **Verify:** `flutter test --reporter expanded` after the fixes, with failures quoted rather than summarized as success.

### 17. Duplicate and leftover symbols

- **Severity:** Low
- **Status:** Verified by search. No second copy of the repositories was found.
- **Files:** `lib/app/app.dart` (`WalletApp` unused), `lib/features/wallets/screens/wallet_list_screen.dart` (`WalletListScreen` alias), `lib/features/transactions/screens/transaction_list_screen.dart` (`TransactionListScreen` alias), `lib/features/categories/screens/categories_screen.dart`, `lib/features/recurring/screens/recurring_screen.dart`
- **Correction:** Remove aliases only after confirming no import uses them. Do not delete admin, notifications, or working finance screens to “clean architecture.”

## Dependency and platform notes

- Flutter SDK constraint: `>=3.13.3 <4.0.0`
- State: `flutter_riverpod` 3.4.x, navigation: `go_router` 18, backend: `supabase_flutter` 2.18
- OCR: `google_mlkit_text_recognition` 0.15, `image_picker` 1.2
- No second HTTP backend. Edge Functions are the remote AI and admin boundary.
- Android permissions for internet, camera, images, location, biometric, and notifications are declared.
- `minSdk` is at least 24. Release minify is off. Release signing is debug.

## What this audit did not do

| Item | Why it is open |
| --- | --- |
| `flutter analyze` / `flutter test` / `flutter build apk --release` | Phase 1 is inspection only |
| Camera, gallery, and ML Kit on a device | No device run |
| Arabic recognition quality | No Arabic model in the code, and no photo test |
| Live RLS and storage policies | SQL was read, not executed |
| Whether migrations are applied on the Supabase project | No linked remote query in this pass |
| Contents of `.env` | Treated as secret; not printed |

## Recommended order after this audit

1. Remove the demo-user receipt lock and the demo auto-login path. Clear financial providers on logout.
2. Make receipt confirmation idempotent when storage fails.
3. Confirm live RLS with the two-user diagnostic. Add an additive migration only if a listed gap is actually missing.
4. Fix total-vs-subtotal parsing and empty-amount confirmation. State clearly that Arabic OCR is unsupported until a tested engine exists.
5. Require a user session inside `classify-transaction`.
6. Build a release APK and scan on a device before calling the ML Kit crash fixed.
7. Unify theme and ARB strings, then run analyze, tests, and the release build.

Do not drop RLS, do not put `service_role` in the app, and do not delete financial rows to make a test pass.
