import logging
import unittest
from pathlib import Path

from fastapi.testclient import TestClient

from smartwallet_ml import api
from smartwallet_ml.auth_user import AuthError

ROOT = Path(__file__).resolve().parents[2]


class DeploymentSecurityTests(unittest.TestCase):
    def test_health_reports_the_baseline_and_saved_models(self):
        client = TestClient(api.app)
        response = client.get("/health")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["ok"])
        self.assertEqual(body["operational_fallback"], "statistical_baseline")
        self.assertIn("lightgbm_expense.joblib", body["artifacts"])
        self.assertIn("xgboost_overrun.joblib", body["artifacts"])
        self.assertIn("isolation_forest.joblib", body["artifacts"])

    def test_score_rejects_a_missing_token(self):
        client = TestClient(api.app)
        response = client.post("/v1/score", json={"user_id": "account-a", "task": "expense", "transactions": []})
        self.assertEqual(response.status_code, 401)

    def test_score_rejects_another_users_rows(self):
        client = TestClient(api.app)
        original = api.verify_supabase_user
        api.verify_supabase_user = lambda _authorization: "account-a"
        try:
            response = client.post(
                "/v1/score",
                headers={"Authorization": "Bearer user-access-token"},
                json={"user_id": "account-b", "task": "cashflow", "transactions": []},
            )
        finally:
            api.verify_supabase_user = original
        self.assertEqual(response.status_code, 403)
        self.assertNotIn("user-access-token", response.text)

    def test_same_user_short_history_stays_on_the_baseline(self):
        records = logging.getLogger("smartwallet_ml")
        with self.assertLogs(records, level="INFO") as captured:
            result = api.score_request(
                {
                    "user_id": "account-a",
                    "task": "expense",
                    "transactions": [
                        {"date": "2026-11-01", "type": "EXPENSE", "amount": 12, "category": "food"},
                        {"date": "2026-11-02", "type": "EXPENSE", "amount": 9, "category": "food"},
                    ],
                },
                "Bearer user-access-token",
                verifier=lambda _authorization: "account-a",
            )
        self.assertEqual(result["status"], "statistical_baseline")
        self.assertFalse(result["real_world_validated"])
        self.assertFalse(result["executed"])
        self.assertFalse(result["blocks_transaction"])
        self.assertEqual(result["user_id"], "account-a")
        joined = "\n".join(captured.output)
        self.assertNotIn("user-access-token", joined)
        self.assertNotIn("Bearer", joined)

    def test_privileged_credential_is_rejected_before_scoring(self):
        with self.assertRaises(AuthError) as raised:
            api.score_request(
                {"user_id": "account-a", "task": "anomaly", "transactions": []},
                "Bearer service_role-secret",
            )
        self.assertEqual(raised.exception.status, 401)

    def test_edge_functions_keep_user_scope_and_the_baseline(self):
        ml = (ROOT / "supabase" / "functions" / "smartwallet-ml" / "index.ts").read_text(encoding="utf-8")
        assistant = (ROOT / "supabase" / "functions" / "smartwallet-ai" / "index.ts").read_text(encoding="utf-8")
        flutter = "\n".join(path.read_text(encoding="utf-8") for path in (ROOT / "lib").rglob("*.dart"))
        self.assertIn('mlUrl.startsWith("https://")', ml)
        self.assertIn("scored.user_id !== userId", ml)
        self.assertIn("model_service_unavailable", ml)
        self.assertIn("real_world_validated: false", ml)
        self.assertNotIn("service_role", ml)
        self.assertNotIn(".insert(", assistant)
        self.assertIn("executed: false", assistant)
        self.assertIn("executes: false", assistant)
        self.assertIn('Deno.env.get("OPENAI_API_KEY")', assistant)
        self.assertNotIn("service_role", assistant)
        self.assertNotIn("SMARTWALLET_ML_TOKEN", flutter)
        self.assertNotIn("OPENAI_API_KEY", flutter)
        self.assertNotIn("service_role", flutter)


if __name__ == "__main__":
    unittest.main()
