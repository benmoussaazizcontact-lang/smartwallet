# Wallet & Transactions

Personal finance manager for Android and iOS. Flutter talks to PostgreSQL **only** through Supabase (Auth, Data API / RPC, Storage). There is no Spring/Express backend and no direct Postgres connection from the phone.

## What is already live on Supabase

Project: `jjfqpfxhgositfaglrzr` (eu-west-1, Postgres 17)

Inspected remotely (not assumed):

- Tables: `profiles`, `wallets`, `categories`, `transactions`, `transfers`, `wallet_movements`, `tags`, `transaction_tags`, `recurring_transactions`, `receipts`, `ai_classifications`
- Added: `recurring_executions`, `wallet_balances` (security-invoker view)
- RPCs: `create_transaction`, `transfer_money`, `void_transaction`
- Trigger: `on_auth_user_created` → `handle_new_user`
- Private bucket: `receipts`
- Hourly `pg_cron` job: `app_private.process_due_recurring_transactions()`
- 31 global categories (parents + children)

Financial writes go through SECURITY DEFINER functions in `app_private`. Clients cannot insert into `wallet_movements`. Initial wallet balances cannot be edited after creation.

## Local setup

1. Copy `.env.example` to `.env` if needed. Do **not** put a `service_role` key in the app.
2. `flutter pub get`
3. `flutter run`

Default display currency is **TND** (3 decimal places). EUR and USD use 2 decimals. Different currencies are never summed together.

## Sign-in

The app opens on the welcome screen until a real Supabase Auth session exists. Wallets, transactions, receipts, and categories are loaded for `auth.uid()` only. Do not put a demo password or the `service_role` key in `.env`. The file is packaged as a Flutter asset, so it may contain only the public project URL and publishable key, plus optional public Firebase app ids.

## Recurring jobs

Executions happen on the server (`pg_cron`), not only when Flutter is open. Duplicate dates are blocked by `UNIQUE (recurring_id, executed_on)`.

## Manual SQL

If you need to re-check the database, run `supabase/diagnostics.sql` in **Supabase Dashboard → SQL Editor**.

Two-user RLS check: `supabase/tests/rls_two_users.sql`.

## Tests

```bash
flutter analyze
flutter test
```

## Android APK

```bash
flutter build apk --release
```

Release currently uses the debug signing config so a local APK can be produced. Replace it before a store release.
