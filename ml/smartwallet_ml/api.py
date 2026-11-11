"""Inference API. The caller must be the Supabase user whose rows are scored."""

from __future__ import annotations

import logging

from .auth_user import AuthError, require_same_user, verify_supabase_user
from .infer import predict_anomalies, predict_cashflow, predict_expense, predict_overrun

logger = logging.getLogger("smartwallet_ml")
if not logger.handlers:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

STATS = {"requests": 0, "errors": 0, "last_error": None}

try:
    from fastapi import FastAPI, Header, HTTPException
except ImportError:
    FastAPI = None  # type: ignore
    Header = None  # type: ignore
    HTTPException = Exception  # type: ignore


def _clean_transactions(value) -> list[dict]:
    if not isinstance(value, list) or len(value) > 5000:
        raise AuthError(400, "Invalid transactions")
    cleaned = []
    for row in value:
        if not isinstance(row, dict):
            raise AuthError(400, "Invalid transactions")
        try:
            amount = float(row.get("amount"))
        except (TypeError, ValueError) as error:
            raise AuthError(400, "Invalid transactions") from error
        kind = str(row.get("type") or "")
        if kind not in {"EXPENSE", "PAYMENT", "INCOME", "REFUND"} or amount < 0:
            raise AuthError(400, "Invalid transactions")
        cleaned.append(
            {
                "date": str(row.get("date") or "")[:10],
                "type": kind,
                "amount": amount,
                "category": str(row.get("category") or "other")[:40],
                "merchant": str(row.get("merchant") or "")[:80],
                "recurring": bool(row.get("recurring")),
            }
        )
    return cleaned


def score_request(payload: dict, authorization: str | None, *, verifier=None) -> dict:
    STATS["requests"] += 1
    check_user = verifier or verify_supabase_user
    try:
        if not isinstance(payload, dict):
            raise AuthError(400, "Invalid request")
        user = check_user(authorization)
        require_same_user(user, str(payload.get("user_id") or ""))
        transactions = _clean_transactions(payload.get("transactions") or [])
        kind = str(payload.get("task") or "expense")
        if kind == "expense":
            result = predict_expense(transactions)
        elif kind == "overrun":
            budgets = payload.get("budgets") if isinstance(payload.get("budgets"), list) else []
            result = predict_overrun(transactions, budgets)
        elif kind == "anomaly":
            result = predict_anomalies(transactions)
        elif kind == "cashflow":
            result = predict_cashflow(transactions)
        else:
            raise AuthError(400, "Unknown task")
        result["user_id"] = user
        result["executed"] = False
        result["real_world_validated"] = False
        logger.info("score user=%s task=%s status=%s", user[:8], kind, result.get("status"))
        return result
    except AuthError:
        STATS["errors"] += 1
        raise
    except Exception as error:  # noqa: BLE001 - unexpected scoring errors stay counted and become a baseline
        STATS["errors"] += 1
        STATS["last_error"] = type(error).__name__
        logger.exception("score failed without an authorization decision")
        return {
            "status": "statistical_baseline",
            "model": None,
            "real_world_validated": False,
            "reason": "inference_error",
            "blocks_transaction": False,
            "executed": False,
        }


if FastAPI is not None:
    app = FastAPI(title="SmartWallet ML", version="1.1.0")

    @app.get("/health")
    def health() -> dict:
        from pathlib import Path

        artifacts = Path(__file__).resolve().parents[1] / "artifacts"
        return {
            "ok": True,
            "operational_fallback": "statistical_baseline",
            "artifacts": sorted(path.name for path in artifacts.glob("*")) if artifacts.exists() else [],
            "requests": STATS["requests"],
            "errors": STATS["errors"],
            "last_error": STATS["last_error"],
        }

    @app.post("/v1/score")
    def score(payload: dict, authorization: str | None = Header(default=None)) -> dict:
        try:
            return score_request(payload, authorization)
        except AuthError as error:
            raise HTTPException(status_code=error.status, detail=error.detail) from error
else:
    app = None
