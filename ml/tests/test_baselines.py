import unittest

from smartwallet_ml.baselines import daily_forecast, dbscan_1d, ewma, mad_alerts, monte_carlo_net
from smartwallet_ml.train_gate import TrainingRefusal, assert_trainable, temporal_split


class BaselineTests(unittest.TestCase):
    def test_forecast_refuses_a_short_series(self):
        result = daily_forecast([10, 12])
        self.assertFalse(result["operational"])
        self.assertIsNone(result["model"])

    def test_forecast_extends_the_daily_average(self):
        result = daily_forecast([10, 10, 10, 10])
        self.assertEqual(result["method"], "statistical_baseline")
        self.assertAlmostEqual(result["horizon_30"], result["daily"] * 30)

    def test_mad_finds_a_large_amount(self):
        result = mad_alerts([20, 21, 19, 20, 22, 18, 20, 21, 400])
        self.assertIn(400, result["alerts"])
        self.assertIsNone(result["model"])

    def test_dbscan_groups_close_points(self):
        clusters = dbscan_1d([1, 1.1, 1.2, 30], eps=0.5)
        self.assertEqual(len(clusters[0]), 3)

    def test_ewma_waits_for_eight_returns(self):
        self.assertFalse(ewma([0.01, 0.02])["operational"])
        ready = ewma([0.01, -0.02, 0.03, 0.01, 0.02, -0.01, 0.04, 0.01])
        self.assertTrue(ready["operational"])
        self.assertIn("GARCH", ready["note"])

    def test_monte_carlo_is_seeded(self):
        first = monte_carlo_net(1000, 400)
        second = monte_carlo_net(1000, 400)
        self.assertEqual(first["p50"], second["p50"])

    def test_training_gate_blocks_the_demo_sample(self):
        with self.assertRaises(TrainingRefusal):
            assert_trainable(31, task="lightgbm")
        train, test = temporal_split(200)
        self.assertGreater(train, test)
        self.assertEqual(train + test, 200)


if __name__ == "__main__":
    unittest.main()
