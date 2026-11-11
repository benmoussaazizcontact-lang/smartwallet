# Advanced modules audit

Date: 10 November 2026. The existing app was kept. New work extends it.

## Already in place before this pass

- Wallets: cash, bank, credit, savings, crypto, several currencies, transfers through `transfer_money`, credit limit and available credit, archive.
- Transactions: income, expense, payment, refund, transfers in `activity_feed`, categories, tags, filters, recurring and scheduled rows.
- Receipts: ML Kit Latin OCR, editable confirmation, `client_request_id` so a failed upload does not create a second movement.
- Budgets: monthly and weekly, category and overall, create, edit, archive, delete, utilization, a simple month forecast, what-if.
- Goals: several goals, virtual contributions, progress, required monthly amount. No automatic wallet debit.
- Investments: stocks, ETF, crypto, other, buy/sell, average cost, realized and unrealized gain, allocation, manual prices.
- Assistant: verified local answers, natural-language draft, wallet confirmation, remote narrative only when the total matches.

## Feature matrix

| # | Feature | Before | After this pass |
| --- | --- | --- | --- |
| 1.1 | Multi-wallet management | Implemented | Balance consistency and unusual-movement checks added. Still uses existing RPCs. |
| 1.2 | Smart transaction engine | Implemented except split and trained classifiers | Split expenses added. CatBoost / XGBoost not trained. Existing merchant rules remain. |
| 1.3 | AI receipt scanner | Partial | Tax, line items, and an Arabic-script warning added. ML Kit does not read Arabic. Structured LLM extraction stays the existing classify function when configured. |
| 1.4 | Reconciliation | Missing | Deterministic amount, date, and token match, with duplicate detection. Sentence Transformers not added. |
| 1.5 | Subscription manager | Missing | Cadence, price increase, next date, inactive, and duplicate amount modes. |
| 1.6 | Fraud and anomaly alerts | Missing | Median/MAD alerts. They never block a payment. Isolation Forest not trained. |
| 2.1 | Adaptive budgets | Mostly implemented | Wallet-specific and project budget columns are in the unapplied migration only. Named budgets already cover a project-style limit. |
| 2.2 | Forecasting | Partial month forecast | 7-day, 30-day, and end-of-month baseline with a spread. SARIMAX, Prophet, and LightGBM not trained. |
| 2.3 | Early overspending | Partial | Expected spend, limit, days left, overspend, risk, and daily limit. XGBoost and logistic regression not trained. |
| 2.4 | Smart allocation | Missing | Last-month income and essentials, surplus split. Savings never exceed the surplus. |
| 2.5 | Behavioral analysis | Weekend split only | Weekend share, month change, category deltas. No clustering model. |
| 2.6 | What-if simulator | Implemented | Kept. Planner adds goal and cash-flow context. |
| 3.1 | Savings goals | Implemented | Unchanged contract: virtual contributions do not move wallets. |
| 3.2 | Goal feasibility | Required monthly only | Optimistic, expected, pessimistic, and a seeded simulation. Assumptions are shown. |
| 3.3 | Saving planner | Missing | Recommends an amount and does not move money. |
| 3.4 | Portfolio tracking | Implemented | Manual prices kept. No live market feed. |
| 3.5 | Risk | Concentration only | Hypothetical −10% and −30% shocks. Volatility only with five or more prices. |
| 3.6 | Goal comparison | Missing | Priority allocation of one surplus across goals. Educational, not regulated advice. |
| 4.1 | Conversational assistant | Implemented | Kept. Amounts still come from recorded facts. |
| 4.2 | Natural-language transactions | Implemented | Kept, with confirmation and idempotent RPC. |
| 4.3 | Financial coach | Partial answers | Insights screen adds the numerical coach views from the same data. |
| 4.4 | Voice | Missing | Device speech-to-text and text-to-speech. Unavailable engines are reported. Voice still opens a draft, it does not save. |
| 4.5 | Reports | Dashboard charts | Monthly income, expense, net, and category breakdown from transactions. |
| 4.6 | Planning agent | Missing | Step list from surplus, required saving, reserve, and an explicit link to create a goal. No free SQL and no transfer. |

## External services

| Need | Status |
| --- | --- |
| CatBoost, XGBoost, LightGBM, SARIMAX, Prophet, Isolation Forest | Not trained. The demo account is too small. |
| Sentence Transformers | Not added. Token overlap is the similarity used. |
| Arabic OCR | Blocked on ML Kit Latin. The screen says so. |
| Arabic / French / English speech | Depends on the Android speech and TTS engines installed on the phone. |
| Live market prices | Not connected. Manual prices stay. |
| Remote insight tables | Migration prepared, not applied. |

Screens are under Plan: Insights, Split expense, and Savings plan. The five-tab bar is unchanged.
