import json
import unittest
from pathlib import Path

from smartwallet_ml.api import score_request
from smartwallet_ml.auth_user import AuthError, require_same_user, verify_supabase_user
from smartwallet_ml.infer import predict_anomalies, predict_cashflow, predict_expense
from smartwallet_ml.synthetic import REAL_DEMO_USER, SYNTHETIC_USER, generate_household
from smartwallet_ml.train_gate import TrainingRefusal, assert_trainable
from smartwallet_ml.train_models import ARTIFACTS, train


class ModelTests(unittest.TestCase):
    def test_synthetic_data_is_not_the_demo_account(self):
        household = generate_household(days=200, seed=7)
        self.assertEqual(household["user_id"], SYNTHETIC_USER)
        self.assertNotEqual(household["user_id"], REAL_DEMO_USER)
        self.assertFalse(household["real_user_records"])
        self.assertGreater(len(household["transactions"]), 180)

    def test_short_real_history_keeps_the_baseline(self):
        rows = [
            {"date": "2026-11-01", "type": "EXPENSE", "amount": 20, "category": "food", "merchant": "shop", "recurring": False},
            {"date": "2026-11-02", "type": "EXPENSE", "amount": 22, "category": "food", "merchant": "shop", "recurring": False},
        ]
        for predictor in (predict_expense, predict_anomalies, predict_cashflow):
            result = predictor(rows)
            self.assertEqual(result["status"], "statistical_baseline")
            self.assertIsNone(result["model"])
            self.assertFalse(result["blocks_transaction"])

    def test_training_refuses_a_short_sample(self):
        with self.assertRaises(TrainingRefusal):
            assert_trainable(31, task="lightgbm")

    def test_cross_user_scoring_is_refused(self):
        with self.assertRaises(AuthError):
            require_same_user("account-a", "account-b")
        with self.assertRaises(AuthError):
            verify_supabase_user("Bearer service_role-secret")

        def verifier(authorization):
            self.assertTrue(authorization.startswith("Bearer "))
            return "account-a"

        with self.assertRaises(AuthError) as raised:
            score_request(
                {"user_id": "account-b", "task": "expense", "transactions": []},
                "Bearer user-token",
                verifier=verifier,
            )
        self.assertEqual(raised.exception.status, 403)

    def test_invalid_rows_are_rejected_for_the_same_user(self):
        def verifier(_authorization):
            return "account-a"

        with self.assertRaises(AuthError):
            score_request(
                {"user_id": "account-a", "task": "expense", "transactions": [{"amount": "nope"}]},
                "Bearer user-token",
                verifier=verifier,
            )

    def test_synthetic_holdout_is_labeled_experimental(self):
        report_path = ARTIFACTS / "evaluation.json"
        if not report_path.exists():
            train()
        report = json.loads(report_path.read_text(encoding="utf-8"))
        self.assertEqual(report["status"], "experimental")
        self.assertFalse(report["real_world_validated"])
        self.assertFalse(report["real_user_records_used"])
        self.assertEqual(report["user_id"], SYNTHETIC_USER)
        self.assertIn("mae", report["lightgbm_expense"]["30"])
        self.assertIn("pr_auc", report["xgboost_overrun"])
        self.assertIn("mae_30", report["sarimax_cashflow"])
        self.assertGreaterEqual(report["isolation_forest"]["test_rows"], 1)
        scored = predict_anomalies(generate_household()["transactions"])
        self.assertFalse(scored["blocks_transaction"])
        self.assertTrue(all(alert["blocks_transaction"] is False for alert in scored["alerts"]))


if __name__ == "__main__":
    unittest.main()
