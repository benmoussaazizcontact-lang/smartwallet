# Advanced modules test report

Date: 10 November 2026.

## Automated

- `flutter analyze`: no issues.
- `flutter test --reporter expanded`: 79 tests passed, including 9 new cases in `test/advanced_finance_test.dart`.
- Covered: high-expense and duplicate alerts that do not block, monthly subscription price increase, receipt match and duplicate receipt, 7/30-day forecast and overspend, allocation capped by surplus, goal scenario and comparison, volatility withheld without a price series, split totals, credit-limit consistency, and refusal on a short history.
- Existing auth, OCR, theme, locale, and wallet tests still pass.

## Not claimed

- The Android phone was not exercised for camera, OCR, login, or the assistant in this pass. A locked or absent screen is not a successful device test.
- CatBoost, XGBoost, LightGBM, SARIMAX, Prophet, Isolation Forest, and Sentence Transformers were not trained or scored.
- Migration `20261110120000_advanced_intelligence.sql` was not applied remotely. Insights are computed from tables that already exist.

## Release APK

`flutter build apk --release` succeeded. Output: `build\app\outputs\flutter-apk\app-release.apk` (94.1 MB).

After the migration, `adb devices` was empty. The release APK was not installed, and the phone flows were not opened.
