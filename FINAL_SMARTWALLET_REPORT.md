# SmartWallet advanced modules

The four modules were extended inside the existing Flutter app. The five-tab navigation, authentication, and User & Security screens were left in place. French, English, and Arabic strings were added for the new screens. Dark and light themes still come from the existing theme controller.

## Where to open the new work

Plan → Insights, Split expense, and Savings plan. The assistant microphone uses the phone speech engine and still requires the confirmation screen before a transaction is saved.

## Feature status

| Feature | Status |
| --- | --- |
| Multi-wallet, transfers, credit, archive | Implemented before. Consistency checks added and unit-tested. |
| Transaction types, recurring, categories, tags, search | Implemented before. |
| Split expenses | Implemented. Two idempotent `create_transaction` calls. Unit-tested sum check. |
| Trained transaction classifier | Blocked. No training set and no trained model. |
| Receipt OCR, confirmation, idempotent retry | Implemented before. Tax and items added. Arabic OCR blocked on ML Kit Latin, with a visible warning. |
| Reconciliation | Implemented as deterministic matching and unit-tested. Duplicate expenses are listed in Insights. |
| Subscriptions | Implemented and unit-tested from repeated merchants. |
| Anomaly alerts | Implemented and unit-tested. They do not block payments. |
| Budgets create, edit, archive, delete, monthly, weekly, category, overall | Implemented before. |
| Wallet-specific budget column | Prepared in the unapplied migration. Not available remotely. |
| 7/30-day and end-of-month forecast | Implemented statistical baseline. Unit-tested. Not a trained forecaster. |
| Early overspending | Implemented and unit-tested. |
| Allocation | Implemented. Savings cannot exceed surplus. |
| Behavior | Implemented from the transaction history. |
| What-if | Implemented before. |
| Goals and virtual contributions | Implemented before. |
| Feasibility scenarios | Implemented and unit-tested. Assumptions are shown. |
| Saving planner | Implemented. `movesMoney` is false. Creating a goal is a separate confirmed screen. |
| Portfolio and manual prices | Implemented before. No invented live prices. |
| Risk shocks | Implemented. Volatility waits for five prices. |
| Goal comparison | Implemented and unit-tested. Not regulated advice. |
| Assistant answers and natural-language drafts | Implemented before. |
| Voice questions | Implemented with device speech and TTS. Not device-tested here. |
| Monthly report | Implemented from transactions in Insights. |
| Planning steps | Implemented. No autonomous transfer and no free SQL. |

## Database

On 10 November 2026 the file `supabase/migrations/20261110120000_advanced_intelligence.sql` was applied alone. `supabase db push` was not used, so the other pending local migrations were not run.

Checked before execution: the file has no `DROP`, `DELETE`, or `TRUNCATE`. It only creates seven new tables. `ON DELETE CASCADE` applies only if that auth user is deleted later. It did not remove existing rows. None of the new names already existed.

Verified backup, gitignored:

| File | Size |
| --- | --- |
| `.backups/schema_20261110.sql` | 71 789 bytes |
| `.backups/data_20261110.sql` | 72 171 bytes |

The data dump contains the public financial tables and the known account and wallet ids. The auth schema is not included. Categories have a circular foreign key, so a data-only restore needs `--disable-triggers`.

After the migration, RLS is on for all seven tables. Each policy is `user_id = auth.uid()` for both read and write. The new tables are empty. Existing counts are unchanged: 4 users, 11 wallets, 40 transactions, 6 transfers, 53 movements, 32 categories, 5 budgets, 3 goals, 3 contributions, 1 portfolio, 3 assets, 3 investment trades. Wallets `n` and `tt` were not modified.

The Flutter screens calculate forecasts, alerts, goals, and investments from the existing tables. They do not yet write these new persistence tables.

## Verification

`flutter analyze` reported no issues. `flutter test` passed 79 tests. `flutter build apk --release` produced `build\app\outputs\flutter-apk\app-release.apk` (94.1 MB).

After the migration, `adb devices` showed no phone, including after an ADB restart. The APK was not installed and none of the four modules, the scanner, or the assistant was opened on the Samsung.
