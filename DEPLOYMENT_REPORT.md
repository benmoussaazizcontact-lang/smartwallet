# SmartWallet deployment report

Date: 2026-11-07. Remote database was not changed. `supabase db push` was not run.

## Supabase CLI

- Installed with Scoop: CLI 3.0.0 at `C:\Users\USER\scoop\shims\supabase.exe`.
- Not authenticated. `supabase projects list` returned `AccessTokenRequiredError`.
- `supabase login` cannot run in this agent shell because it is not a TTY. A separate PowerShell window was opened with `supabase login`.
- The project was not linked. `supabase link --project-ref jjfqpfxhgositfaglrzr` needs that login first.

## Project identity

- Requested project `jjfqpfxhgositfaglrzr` resolves and answers. `GET /auth/v1/health` returned 401 without a key, which means the host is up.
- `POST /functions/v1/classify-transaction` returned 401. That function is deployed and rejects a request without credentials.
- `POST /functions/v1/smartwallet-ai` returned 404. The new assistant function is not deployed.
- The app `.env` points at `https://pmfgrzhgropgorzbhcec.supabase.co`. That hostname does not resolve. The packaged APK still uses that URL, so this build cannot reach the live project. The publishable key was not printed and was not changed. It must be replaced with the key from project `jjfqpfxhgositfaglrzr` before the phone app can log in.

## Migration review

Local file `supabase/migrations/20261106120000_smartwallet_modules.sql` was reviewed. It only creates new tables and indexes with `IF NOT EXISTS`:

- `budgets`, `budget_alerts`
- `financial_goals`, `goal_contributions`, `goal_schedules`
- `investment_portfolios`, `investment_assets`, `investment_transactions`, `investment_price_history`
- `ai_conversations`, `ai_messages`

Money columns are `numeric`. RLS is enabled, `anon` is revoked, and policies require `auth.uid()` plus ownership of the parent row. `ON DELETE CASCADE` applies only if a parent user or row is deleted later. The SQL does not `DROP`, `TRUNCATE`, or `DELETE` existing accounts, wallets, or transactions.

`CREATE POLICY` is not idempotent. A second apply fails if those policies already exist.

Remote migration history could not be read. Older local files replace views, functions, and policies. They must be compared with `supabase migration list` after login before any push. They were not applied.

## Database backup

Not created. A dump needs an authenticated, linked CLI and the database password. Because the backup cannot be verified, the remote database was left unchanged.

## Edge Function

`supabase/functions/smartwallet-ai/index.ts` was inspected, not deployed:

- POST only. Missing or invalid bearer token returns 401 after `auth.getUser`.
- Body limited to 12 KB. Invalid JSON returns 400. Currency must match `^[A-Z]{3,10}$` or it falls back to TND.
- In-memory limit of 10 requests per user per minute. This resets when the function instance restarts.
- Transactions are read with the caller JWT, so RLS applies. The model receives only the computed total.
- `OPENAI_API_KEY` is read from the function environment. If it is missing, the response is `available: false`, `fallback: true`, and a local sentence. The key is not in Flutter or `.env`.
- Whether `OPENAI_API_KEY` is set in Supabase is unknown until `supabase secrets list` can run. Its value was not requested.

Unauthenticated call result: HTTP 404 because the function is not deployed, so the JWT rejection path was not reached on the server. The local assistant still answers from on-device calculations.

## Flutter

| Command | Result |
| --- | --- |
| `flutter pub get` | Completed |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | 68 passed, 0 failed |
| `flutter build apk --release` | Succeeded |

These tests cover validators, localization, theme preferences, wallet rules, OCR, and planning calculations. They do not sign in, load live wallets, or exercise the phone UI. Login, wallets, transactions, budgets, goals, investments, and the assistant were not tested on a device.

## APK

- Path: `C:\Users\USER\Desktop\wallet_app_selim\build\app\outputs\flutter-apk\app-release.apk`
- Size: 98,283,408 bytes (93.7 MB)
- Built: 2026-11-07 00:25:43 local time

## Android installation

ADB: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`. The daemon started. `adb devices -l` listed no phones, authorized or otherwise. `adb install -r` was not run. Nothing was uninstalled.

## Remaining issues

1. Finish `supabase login` in the PowerShell window. Do not paste the access token into chat.
2. Approve a database backup, then `supabase link` and `supabase db dump`, before any `supabase db push`.
3. Approve `supabase db push` only after the remote migration list is shown.
4. Deploy `smartwallet-ai` after login, then set `OPENAI_API_KEY` with `supabase secrets set` if it is missing.
5. Point `.env` at `https://jjfqpfxhgositfaglrzr.supabase.co` and that project's publishable key, then rebuild. The current APK targets a hostname that does not resolve.
6. Connect the phone, accept the USB debugging prompt, and rerun `adb install -r`.
