# SmartWallet AI

Flutter application for personal wallets, budgets, goals, and educational financial simulations. The signed-in user reaches experimental expense, overrun, anomaly, and cash-flow models through Supabase Edge Functions and a FastAPI service on Render.

## Run locally

1. Flutter SDK compatible with the constraint in `pubspec.yaml`.
2. Copy the environment template and set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. Do not put the service role or an LLM key in the app.
3. `flutter pub get`
4. `flutter run`

Release APK:

```text
flutter build apk --release
```

The output is `build/app/outputs/flutter-apk/app-release.apk`. Install on a connected phone with `adb install -r`. Do not uninstall the app and do not clear its data.

## What is operational

- Email sign-up, confirmation, password reset, sessions, profile, and a local biometric lock.
- Wallets, transactions, transfers, budgets, goals, and manual investment positions.
- Financial Studio: 30 on-device calculations, labeled as statistical or educational.
- Four experimental models behind `smartwallet-ml`: LightGBM, XGBoost, Isolation Forest, and SARIMAX.
- Assistant answers from verified records, including misspelled and mixed-language questions. A remote language model is used only when `OPENAI_API_KEY` is configured on the Edge Function. It is not configured.
- Receipt scan with on-device Latin OCR. Arabic script is flagged, not recognized.

## Limits

- Synthetic model metrics are not real-world accuracy. Responses keep `real_world_validated: false`.
- Internal transfers are excluded from income and expenses.
- Account deletion is implemented in the app but the server function in `supabase/pending/delete_own_account.sql` is not applied. Nothing is deleted until that function is authorized and installed.
- Do not run `supabase db push`. The local migration history does not match the remote project.

Package id: `com.example.wallet_app`.
