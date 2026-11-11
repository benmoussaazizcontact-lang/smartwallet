# AI models

The four named models are experimental. They were trained on a synthetic household, not on SmartWallet users. `real_world_validated` stays false.

| Task | Model | Minimum history | Version when the model runs |
| --- | --- | --- | --- |
| Expense, 7/15/30 | LightGBM | 60 daily points | 0.1.0-synthetic |
| Budget overrun | XGBoost | 6 feature rows | 0.1.0-synthetic |
| Anomaly | Isolation Forest | 80 spend rows | 0.1.0-synthetic |
| Cash flow, 7/30/90 | SARIMAX, refit on the request | 120 daily points | 0.1.0 |

Below those gates, or if Render is unavailable, the response is `statistical_baseline`. Isolation Forest never blocks a transaction. SARIMAX is refit on the submitted series. Its status is `fitted_on_request`, not a claim about the synthetic holdout.

Synthetic holdout figures, not real-world accuracy:

- LightGBM MAE at 7/15/30 days: 204.46 / 234.20 / 259.19
- XGBoost precision, recall, and F1: 0.75; PR-AUC 0.66
- Isolation Forest: 7 of 137 holdout rows flagged
- SARIMAX holdout MAE: 245.43 at 7 days and 150.91 at 30 days

On the signed-in demonstration account, one Financial Studio open during a cold start showed the expense task as `statistical_baseline` with reason `model_service_unavailable`, while XGBoost still answered. The app now retries a failed task once after the other tasks. After installing that build and opening Studio again, with Render already awake, the phone showed:

- Expense: LightGBM `experimental`, version `0.1.0-synthetic`, reason `none`, `real_world_validated: false`
- Overrun: XGBoost `experimental`, version `0.1.0-synthetic`, reason `none`, `real_world_validated: false`
- Anomaly: `statistical_baseline`, reason `insufficient_history_or_model`, `real_world_validated: false`
- Cash flow: `statistical_baseline`, reason `insufficient_history`, `real_world_validated: false`

The second open did not itself prove the retry, because the service was already awake. The cold-start failure remains the reason the retry exists.

The thirty Financial Studio cards remain on-device calculations. They are not these models.

The assistant has no OpenAI key. It returns the verified local sentence and says the remote assistant is not configured. It does not execute a transaction.

Receipt OCR uses on-device ML Kit for Latin text. Arabic script is detected and the user is told to check the fields. A transaction is saved only after confirmation.
