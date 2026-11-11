# Architecture

SmartWallet keeps secrets and model files off the phone.

```text
Flutter (Riverpod, GoRouter, Material 3)
  -> Supabase Auth JWT
  -> Postgres with row-level security
  -> Edge Functions smartwallet-ml and smartwallet-ai
  -> Render FastAPI https://smartwallet-ml-1.onrender.com
```

The phone calls `supabase.functions.invoke`. It never calls Render directly and never stores a model token.

`smartwallet-ml` reads the signed-in user's transactions, forwards one task (`expense`, `overrun`, `anomaly`, or `cashflow`) with the same user token, and rejects a response whose user id does not match. It forces `executed` and `blocks_transaction` to false.

`smartwallet-ai` reads the same user's budgets, goals, and transactions. Without an OpenAI key it returns the verified local sentence. It does not insert transactions.

The specialized assistant understands the question on the phone: normalization, intent, category and period, then the same spending rules as Home. A remote language model is not required. Follow-up questions keep the category and period of the open conversation.

Financial Studio still calculates the thirty cards on the device. The service panel above them shows the deployed response: status, model, version, reason, and `real_world_validated`.

The local biometric lock is separate from the Supabase session. Leaving the app locks the screen. The session stays signed in until the user signs out.

Money uses numeric amounts. Display rounding is three decimals for TND and two for EUR and USD. Month windows are half-open, `[start of month, start of next month)`, in local time.
