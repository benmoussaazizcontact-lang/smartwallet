# Tests

Latest local run for the final delivery:

- `flutter analyze`: no issues.
- `flutter test`: 96 passed, 0 failed. This includes the month reconciliation, the assistant understanding tests, the biometric lock, and the account-deletion word.
- Python `pytest` in `ml/`: 19 passed.

The assistant tests cover misspellings, French, English, Arabic, Tunisian Latin, category synonyms, follow-ups, a savings plan that cannot cut more than the observed category, an empty history, a loading state, an ambiguous question, and a network failure.

Samsung SM_S938B, 10 Nov 2026, signed-in account, no data erased:

- Home: total 18 181,300 TND, November income 2 200,000 TND, expenses 703,900 TND, transfers excluded.
- Wallets: the same 18 181,300 TND total. Cash, credit, crypto, and the next cards were visible.
- Transactions: search and filters are on screen. A transfer is listed separately from an expense.
- Settings: the signed-in email is verified. Theme choices are visible. Sign-out was not used.
- Assistant, on the account records: Food this month 274,000 TND; Transport 95,000 TND against 90,000 TND last month; a 300 TND savings simulation whose cuts sum to 300 and stay inside observed categories; net wallet balance 18 181,300 TND, matching Home; largest category Food at 274,000 TND. The remote assistant line says it is not configured.
- Financial Studio after the final APK, Render already awake: LightGBM and XGBoost `experimental` at `0.1.0-synthetic`; anomaly and cash flow on the statistical baseline for insufficient history. `real_world_validated` stayed false. An earlier open during a cold start had marked only the expense task `model_service_unavailable`. The app retries that failure once. Cards 1, 6, 16, 17, and 18 were visible and kept their statistical or educational labels.

Not claimed from this run:

- A new registration, email verification, or password reset on the phone.
- Sign-out and a fresh sign-in.
- The biometric prompt on this final pass. Home was already unlocked.
- The camera scanner and a saved receipt.
- A live expired-session call.
- Arabic OCR recognition. The app only flags Arabic script.
- Account deletion. The server function is not installed.
