"""Load experimental artifacts. Short or missing histories stay on the statistical baseline."""

from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
from statsmodels.tsa.statespace.sarimax import SARIMAX

from .baselines import daily_forecast, mad_alerts
from .prepare import EXPENSE_FEATURES, anomaly_matrix, daily_totals, expense_examples, overrun_examples

ARTIFACTS = Path(__file__).resolve().parents[1] / "artifacts"
DISCLAIMER = "This model was trained on synthetic data. The figure is experimental and is not real-world accuracy."


def _baseline(kind: str, reason: str, **extra) -> dict:
    return {
        "status": "statistical_baseline",
        "model": None,
        "real_world_validated": False,
        "reason": reason,
        "kind": kind,
        "blocks_transaction": False,
        **extra,
    }


def _evaluation() -> dict:
    path = ARTIFACTS / "evaluation.json"
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def predict_expense(transactions: list[dict]) -> dict:
    days = daily_totals(transactions)
    amounts = [day["spend"] for day in days]
    baseline = daily_forecast(amounts)
    path = ARTIFACTS / "lightgbm_expense.joblib"
    if len(days) < 60 or not path.exists():
        return _baseline("expense", "insufficient_history_or_model", baseline=baseline)
    models = joblib.load(path)
    horizons = {}
    for horizon in (7, 15, 30):
        features, _targets, stamps = expense_examples(transactions, horizon)
        if not features:
            return _baseline("expense", "insufficient_history_or_model", baseline=baseline)
        predicted = float(models[str(horizon)].predict([features[-1]])[0])
        horizons[str(horizon)] = max(0.0, predicted)
    return {
        "status": "experimental",
        "model": "lightgbm",
        "version": "0.1.0-synthetic",
        "real_world_validated": False,
        "training_data": "synthetic",
        "disclaimer": DISCLAIMER,
        "as_of": stamps[-1] if features else None,
        "horizons": horizons,
        "baseline": baseline,
        "holdout_metrics": _evaluation().get("lightgbm_expense"),
        "blocks_transaction": False,
    }


def predict_overrun(transactions: list[dict], budgets: list[dict]) -> dict:
    features, _labels, stamps = overrun_examples(transactions, budgets)
    path = ARTIFACTS / "xgboost_overrun.joblib"
    if len(features) < 6 or not path.exists():
        return _baseline("overrun", "insufficient_history_or_model")
    bundle = joblib.load(path)
    probability = bundle["model"].predict_proba(np.asarray(features[-len(budgets) :]))[:, 1]
    names = bundle["feature_names"]
    latest = features[-len(budgets) :]
    rows = []
    for stamp, chance, vector in zip(stamps[-len(budgets) :], probability, latest):
        driver = names[int(np.argmax(np.abs(vector)))]
        rows.append(
            {
                "label": stamp,
                "probability": float(chance),
                "driver": driver,
                "explanation": f"{driver} is the largest numeric input for this category.",
            }
        )
    return {
        "status": "experimental",
        "model": "xgboost",
        "version": "0.1.0-synthetic",
        "real_world_validated": False,
        "training_data": "synthetic",
        "disclaimer": DISCLAIMER,
        "risks": rows,
        "holdout_metrics": _evaluation().get("xgboost_overrun"),
        "blocks_transaction": False,
    }


def predict_anomalies(transactions: list[dict]) -> dict:
    matrix, meta = anomaly_matrix(transactions)
    amounts = [float(row["amount"]) for row in transactions if row.get("type") in {"EXPENSE", "PAYMENT"}]
    baseline = mad_alerts(amounts)
    path = ARTIFACTS / "isolation_forest.joblib"
    if len(matrix) < 80 or not path.exists():
        return _baseline("anomaly", "insufficient_history_or_model", baseline=baseline, alerts=[])
    forest = joblib.load(path)["model"]
    prediction = forest.predict(matrix)
    scores = -forest.decision_function(matrix)
    alerts = []
    for row, flag, score, vector in zip(meta, prediction, scores, matrix):
        if flag != -1:
            continue
        reason = "amount is high versus earlier spending" if vector[1] > 2 else "frequency or gap differs from earlier behavior"
        alerts.append(
            {
                "date": row["date"],
                "merchant": row["merchant"],
                "amount": row["amount"],
                "score": float(score),
                "explanation": reason,
                "blocks_transaction": False,
            }
        )
    return {
        "status": "experimental",
        "model": "isolation_forest",
        "version": "0.1.0-synthetic",
        "real_world_validated": False,
        "training_data": "synthetic",
        "disclaimer": DISCLAIMER,
        "alerts": alerts[:12],
        "baseline": baseline,
        "blocks_transaction": False,
    }


def predict_cashflow(transactions: list[dict]) -> dict:
    days = daily_totals(transactions)
    net = [day["income"] - day["spend"] for day in days]
    spends = [day["spend"] for day in days]
    baseline = daily_forecast(spends)
    if len(net) < 120:
        return _baseline("cashflow", "insufficient_history", baseline=baseline)
    series = np.asarray(net, dtype=float)
    try:
        fitted = SARIMAX(
            series,
            order=(1, 0, 1),
            seasonal_order=(1, 0, 0, 7),
            enforce_stationarity=False,
            enforce_invertibility=False,
        ).fit(disp=False, maxiter=25)
        forecast = fitted.get_forecast(90)
        mean = np.asarray(forecast.predicted_mean, dtype=float)
        interval = forecast.conf_int(alpha=0.2)
        low = np.asarray(interval)[:, 0]
        high = np.asarray(interval)[:, 1]
    except Exception as error:  # noqa: BLE001 - a failed fit must leave the baseline in place
        return _baseline("cashflow", f"sarimax_failed: {error}", baseline=baseline)
    balance = 0.0

    def project(step: int) -> dict:
        return {
            "net": float(mean[:step].sum()),
            "low": float(low[:step].sum()),
            "high": float(high[:step].sum()),
            "projected_balance_change": float(balance + mean[:step].sum()),
        }

    return {
        "status": "fitted_on_request",
        "model": "sarimax",
        "version": "0.1.0",
        "real_world_validated": False,
        "disclaimer": "SARIMAX is refit on this request's series. Synthetic holdout MAE does not measure this user's accuracy.",
        "holdout_metrics": _evaluation().get("sarimax_cashflow"),
        "horizons": {"7": project(7), "30": project(30), "90": project(90)},
        "baseline": baseline,
        "blocks_transaction": False,
    }
