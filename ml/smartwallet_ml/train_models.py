"""Train experimental models on the synthetic household and record holdout metrics."""

from __future__ import annotations

import json
from pathlib import Path

import joblib
import lightgbm as lgb
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.metrics import (
    average_precision_score,
    f1_score,
    mean_absolute_error,
    mean_squared_error,
    precision_score,
    recall_score,
)
from statsmodels.tsa.statespace.sarimax import SARIMAX
import xgboost as xgb

from .prepare import anomaly_matrix, expense_examples, overrun_examples
from .synthetic import generate_household
from .train_gate import TrainingRefusal, assert_trainable, temporal_split

ARTIFACTS = Path(__file__).resolve().parents[1] / "artifacts"
DISCLAIMER = "Holdout metrics were measured on synthetic data and are not real-world accuracy."


def _split(count: int) -> int:
    train, _test = temporal_split(count)
    return train


def _regression(features: list[list[float]], targets: list[float]) -> dict:
    assert_trainable(len(targets), task="lightgbm_expense", minimum=120)
    cut = _split(len(targets))
    model = lgb.LGBMRegressor(
        n_estimators=80,
        learning_rate=0.05,
        num_leaves=15,
        min_child_samples=10,
        verbosity=-1,
    )
    model.fit(features[:cut], targets[:cut])
    predicted = model.predict(features[cut:])
    actual = np.asarray(targets[cut:], dtype=float)
    return {
        "model": model,
        "mae": float(mean_absolute_error(actual, predicted)),
        "rmse": float(mean_squared_error(actual, predicted) ** 0.5),
        "train_rows": cut,
        "test_rows": len(targets) - cut,
    }


def train(dataset: dict | None = None) -> dict:
    household = dataset or generate_household()
    if household.get("kind") != "synthetic" or household.get("real_user_records") is not False:
        raise TrainingRefusal("Training refuses a dataset that is not marked synthetic and separate from real users.")
    transactions = household["transactions"]
    assert_trainable(len(transactions), task="synthetic_household", minimum=180)
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    expense = {}
    expense_models = {}
    for horizon in (7, 15, 30):
        features, targets, _stamps = expense_examples(transactions, horizon)
        fitted = _regression(features, targets)
        expense_models[str(horizon)] = fitted["model"]
        expense[str(horizon)] = {key: value for key, value in fitted.items() if key != "model"}
    joblib.dump(expense_models, ARTIFACTS / "lightgbm_expense.joblib")

    features, labels, stamps = overrun_examples(transactions, household["budgets"])
    assert_trainable(len(labels), task="xgboost_overrun", minimum=40)
    cut = _split(len(labels))
    if len(set(labels[:cut])) < 2 or len(set(labels[cut:])) < 2:
        raise TrainingRefusal("Overrun labels need both classes in the train and test months.")
    classifier = xgb.XGBClassifier(
        n_estimators=80,
        max_depth=3,
        learning_rate=0.08,
        objective="binary:logistic",
        eval_metric="aucpr",
        verbosity=0,
    )
    classifier.fit(np.asarray(features[:cut]), np.asarray(labels[:cut]))
    probability = classifier.predict_proba(np.asarray(features[cut:]))[:, 1]
    predicted = (probability >= 0.5).astype(int)
    actual = np.asarray(labels[cut:])
    overrun = {
        "precision": float(precision_score(actual, predicted, zero_division=0)),
        "recall": float(recall_score(actual, predicted, zero_division=0)),
        "f1": float(f1_score(actual, predicted, zero_division=0)),
        "pr_auc": float(average_precision_score(actual, probability)),
        "train_rows": cut,
        "test_rows": len(labels) - cut,
    }
    joblib.dump({"model": classifier, "feature_names": ["pace", "income", "days_left", "spent", "recurring", "fixed"]}, ARTIFACTS / "xgboost_overrun.joblib")

    matrix, meta = anomaly_matrix(transactions)
    assert_trainable(len(matrix), task="isolation_forest", minimum=180)
    cut = _split(len(matrix))
    forest = IsolationForest(n_estimators=100, contamination=0.05, random_state=7)
    forest.fit(matrix[:cut])
    scores = -forest.decision_function(matrix[cut:])
    flagged = int((forest.predict(matrix[cut:]) == -1).sum())
    anomaly = {"test_rows": len(matrix) - cut, "flagged": flagged, "score_p95": float(np.quantile(scores, 0.95))}
    joblib.dump({"model": forest, "blocks_transaction": False}, ARTIFACTS / "isolation_forest.joblib")

    days_net = []
    from .prepare import daily_totals

    for day in daily_totals(transactions):
        days_net.append(day["income"] - day["spend"])
    assert_trainable(len(days_net), task="sarimax_cashflow", minimum=120)
    holdout = 30
    train_series = np.asarray(days_net[:-holdout], dtype=float)
    actual_holdout = np.asarray(days_net[-holdout:], dtype=float)
    result = SARIMAX(
        train_series,
        order=(1, 0, 1),
        seasonal_order=(1, 0, 0, 7),
        enforce_stationarity=False,
        enforce_invertibility=False,
    ).fit(disp=False, maxiter=30)
    forecast = np.asarray(result.get_forecast(holdout).predicted_mean, dtype=float)
    cashflow = {
        "mae_30": float(mean_absolute_error(actual_holdout, forecast)),
        "mae_7": float(mean_absolute_error(actual_holdout[:7], forecast[:7])),
        "holdout_days": holdout,
    }
    result.save(str(ARTIFACTS / "sarimax_evaluation.pkl"))

    report = {
        "status": "experimental",
        "training_data": "synthetic",
        "real_world_validated": False,
        "real_user_records_used": False,
        "user_id": household["user_id"],
        "disclaimer": DISCLAIMER,
        "lightgbm_expense": expense,
        "xgboost_overrun": overrun,
        "isolation_forest": anomaly,
        "sarimax_cashflow": cashflow,
        "versions": {"lightgbm": lgb.__version__, "xgboost": xgb.__version__},
    }
    (ARTIFACTS / "evaluation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


if __name__ == "__main__":
    print(json.dumps(train(), indent=2))
