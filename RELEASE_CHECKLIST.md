# Release checklist

- [x] Home and the assistant use the same month expense rule.
- [x] Transfers and refunds are excluded from income and expenses.
- [x] The assistant waits for records before a definitive amount.
- [x] The local biometric lock arms again after Home.
- [x] Experimental model responses keep `real_world_validated: false`.
- [x] The assistant understands misspelled and mixed-language financial questions on device.
- [x] Home, wallets, and the assistant net balance matched on the Samsung.
- [x] A failed model call is retried once after the other tasks, so a cold Render start does not keep the first task failed.
- [x] `flutter analyze`: no issues. `flutter test`: 96 passed. Python `pytest`: 19 passed.
- [x] Release APK rebuilt and installed with `adb install -r`. Home reopened at 18 181,300 TND, income 2 200,000 TND, expenses 703,900 TND.
- [x] Financial Studio on that APK showed LightGBM and XGBoost as experimental and the other two tasks on the statistical baseline.
- [ ] Account-deletion SQL remains unapplied until an explicit approval.
- [ ] No `supabase db push`.
- [ ] No new Edge Function deploy.
- [ ] No Google Play upload.

APK path after a successful release build: `build/app/outputs/flutter-apk/app-release.apk`.

Signing is still the debug release configuration. An upload keystore is required before a Play App Bundle can be published. This delivery does not create that keystore and does not upload an AAB.
