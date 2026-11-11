# Database

Remote project `jjfqpfxhgositfaglrzr`, Postgres 17, region eu-west-1. Row-level security applies to user-owned tables with `user_id = auth.uid()`.

The app does not store a balance column. A wallet balance is the initial balance plus the sum of its movements. Credit-card debt is the negative balance, capped at zero for the displayed debt. Available credit is the limit plus the balance.

## Core records

- `wallets`, `transactions`, `transfers`
- `categories`
- `budgets`, `budget_alerts`
- `financial_goals`, `goal_contributions`
- portfolios, assets, and investment transactions with manual prices
- `profiles`
- `activity_feed`, which unions transactions and transfers for the activity list

Writers for money movement are `app_private.create_transaction` and `app_private.transfer_money`, exposed through the public RPCs. Both are idempotent on `(user_id, client_request_id)`.

Voided rows stay in history and are excluded from income and expense totals. Transfers are visible in activity and excluded from those totals. Refunds are neither income nor expenses.

## Insight tables

Applied with `20261110120000_advanced_intelligence.sql`:

- `subscriptions`
- `transaction_reconciliations`
- `anomaly_events` (`blocks_transaction` must stay false)
- `expense_forecasts` (horizons 7 and 30 only)
- `budget_allocations`
- `financial_reports`
- `ai_action_requests` (draft transaction, create goal, virtual contribution)

Studio replaces only the signed-in user's insight rows. It does not change wallets or transactions.

## Not applied

`supabase/pending/delete_own_account.sql` is reviewed and not installed. It deletes only `auth.users` where `id = auth.uid()`. Wallet movements reference wallets with `ON DELETE RESTRICT`, so this single delete can abort and roll back for an account that still has movements. It does not partially delete. Do not apply it, and do not run `supabase db push`, without an explicit approval, a fresh backup, and a deletion order that respects those restrictions.
