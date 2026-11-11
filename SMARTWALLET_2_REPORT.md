# SmartWallet 2.0 — Budget, Goals, and AI Assistant

The three new modules live inside the existing Flutter app. Authentication, wallets, transactions, the five-tab shell, theme, and French / English / Arabic localization were kept. New screens open from the home dashboard and Settings under `/plan`.

## Features implemented

### Budget & Expenses

- Create, archive, and delete monthly or weekly budgets, overall or for one category, in a wallet currency.
- Spending is calculated from posted `EXPENSE` and `PAYMENT` rows in the same currency. Transfers, refunds, income, voided rows, and recurring templates are excluded.
- Overall budgets and category budgets are shown separately so the same expense is not added into both totals.
- Each card shows spent, remaining, utilization, the previous period, and a statistical month-end forecast when at least two spending days exist and the month is at least three days old.
- Crossing 50%, 80%, 90%, or 100% writes one `budget_alerts` row per budget, threshold, and period.
- The what-if screen turns a monthly reduction into a period total and suggests cuts from the user’s actual same-currency categories (15% of the largest, 10% of the next).

### Goals & Investment

- Goals for laptop, car, travel, house, education, emergency fund, phone, investments, or a custom name, with target, currency, date, priority, icon, and color.
- Saved amount and progress come from `goal_contributions`. These rows are virtual: creating a goal or a contribution does not change a wallet balance.
- Each contribution uses a unique `client_request_id`. Repeating the same id does not insert a second row.
- Required monthly savings is the remaining gap divided by the months left (at least one). Feasibility and category-cut suggestions use the same actual expenses as the budget module.
- Portfolios hold stocks, ETFs, crypto, and other assets. Buys and sells use average cost. A sell larger than the held quantity is rejected. Unrealized gain uses the last manual price. Realized gain comes from recorded sells.
- Allocation is by market value inside one currency. A holding above 40% is flagged. Prices are manual and store `price_updated_at`. No live price is invented.
- The portfolio screen states that the figures are not buy or sell advice.

### SmartWallet AI

- Chat with localized suggestions, loading, errors, and a local answer computed from the signed-in user’s transactions, budgets, and goals.
- Deterministic questions (this month’s spend, largest category, week-over-week change, goal gap) use those calculations. If history is missing, the reply says so.
- A remote narrative from `smartwallet-ai` replaces the local month-spend sentence only when the function’s total matches the local total and the text contains that verified amount.
- If the function or `OPENAI_API_KEY` is missing, the app keeps the on-device answer and says the remote assistant is not configured.
- A sentence such as “I paid 45 dinars at a restaurant yesterday” becomes an editable draft. It is saved only after the user picks a wallet and confirms. Saving calls the existing `create_transaction` RPC with one request id.

## Navigation

The bottom bar is still Home, Wallets, Activity, Scan, and Settings. `/plan` is a separate shell route behind the biometric gate:

- `/plan`, `/plan/budgets`, `/plan/budgets/new`, `/plan/budgets/:id`, `/plan/what-if`
- `/plan/goals`, `/plan/goals/new`, `/plan/goals/:id`
- `/plan/portfolio`, `/plan/portfolio/new`, `/plan/assets/new`, `/plan/assets/:id`
- `/plan/assistant`, `/plan/assistant/confirm`

Sign-out invalidates `budgetsForUserProvider`, `goalsForUserProvider`, and `portfoliosForUserProvider`.

## Files

Created:

- `lib/features/planning/domain/` — `spend_rules.dart`, `budget_math.dart`, `forecast_math.dart`, `what_if.dart`, `goal_math.dart`, `investment_math.dart`, `nl_transaction.dart`, `finance_answers.dart`
- `lib/features/planning/repositories/` — `budget_repository.dart`, `goal_repository.dart`, `investment_repository.dart`
- `lib/features/planning/screens/` — `plan_hub_screen.dart`, `budget_screens.dart`, `goal_screens.dart`, `investment_screens.dart`, `assistant_screen.dart`
- `supabase/migrations/20261106120000_smartwallet_modules.sql`
- `supabase/functions/smartwallet-ai/index.ts`
- `test/planning_modules_test.dart`

Modified:

- `lib/app/router.dart`
- `lib/core/session/clear_user_state.dart`
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`
- `lib/l10n/app_en.arb`, `app_fr.arb`, `app_ar.arb`, and generated localizations
- `supabase/config.toml` (`[functions.smartwallet-ai] verify_jwt = true`)

## Database

`20261106120000_smartwallet_modules.sql` is additive. It creates `budgets`, `budget_alerts`, `financial_goals`, `goal_contributions`, `goal_schedules`, `investment_portfolios`, `investment_assets`, `investment_transactions`, `investment_price_history`, `ai_conversations`, and `ai_messages`. Money columns are `numeric`. RLS is enabled, `anon` is revoked, and policies use `auth.uid()` plus parent-row ownership.

This migration was **not** applied to the remote Supabase project. Until it is applied, the new screens will fail when they query these tables.

## AI configuration

Deploy the function, then set the key only on the server:

```bash
supabase db push
supabase functions deploy smartwallet-ai
supabase secrets set OPENAI_API_KEY=...
```

The Flutter app does not contain `OPENAI_API_KEY` or the service role key. The function checks the caller JWT, limits the body to 12 KB and the caller to 10 requests per minute, re-reads that user’s transactions under RLS, and refuses a model narrative that does not contain the computed total. Without the key it returns `available: false` and `fallback: true`. The function was **not** deployed in this session.

## Verification

| Command | Result |
| --- | --- |
| `flutter pub get` | Completed |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | 68 tests passed, 0 failed |
| `flutter build apk --release` | Succeeded |

APK: `build\app\outputs\flutter-apk\app-release.apk` (93.7 MB)

No live database test and no device install were run.

## Known limitations

- Budgets can be created, archived, and deleted. There is no edit form that reloads an existing limit.
- What-if category rates are the fixed 15% and 10% suggestions plus one monthly reduction field.
- Goal schedules can be stored by the repository. The detail screen does not expose a schedule form, and a schedule does not move wallet money.
- Alerts and goal completion are in-app records, not push notifications.
- Chat history is written when the new tables exist. It is not reloaded into a history screen.
- The assistant returns a full reply. Token streaming is not implemented.
- Forecasts are spending-velocity estimates for the current month only. They are labeled separately from actual spend.
- Investment prices stay at the last manual update. There is no market-data provider.
- Release APK signing is still the project’s existing debug signing.
