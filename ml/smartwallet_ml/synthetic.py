"""Development-only household. These rows are not a real customer's records."""

from __future__ import annotations

import random
from datetime import date, timedelta

SYNTHETIC_USER = "synthetic-household"
REAL_DEMO_USER = "c19ec2bd-0480-428a-9f10-13a4640d9293"


def generate_household(days: int = 480, seed: int = 7) -> dict:
    if days < 200:
        raise ValueError("The synthetic household needs at least 200 days.")
    rng = random.Random(seed)
    start = date(2024, 1, 1)
    rows: list[dict] = []
    for offset in range(days):
        current = start + timedelta(days=offset)
        if current.day in (1, 15):
            rows.append(_row(current, "INCOME", 1450 + rng.uniform(-30, 30), "income", "employer", False))
        if current.day == 3:
            rows.append(_row(current, "EXPENSE", 520 + rng.uniform(-5, 8), "housing", "rent", True))
        if current.day == 12:
            amount = 30 if current < date(2025, 6, 1) else 36
            rows.append(_row(current, "EXPENSE", amount, "entertainment", "netflix", True))
        if current.weekday() in (4, 5) or rng.random() < 0.55:
            rows.append(_row(current, "EXPENSE", 18 + rng.uniform(0, 22), "food", "market", False))
        if rng.random() < 0.35:
            rows.append(_row(current, "EXPENSE", 8 + rng.uniform(0, 14), "transport", "fuel", False))
        if rng.random() < 0.18:
            rows.append(_row(current, "EXPENSE", 25 + rng.uniform(0, 40), "shopping", "shop", False))
        if rng.random() < 0.08:
            rows.append(_row(current, "EXPENSE", 12 + rng.uniform(0, 20), "health", "pharmacy", False))
        if offset % 90 == 40:
            rows.append(_row(current, "EXPENSE", 260, "shopping", "unusual-store", False))
    budgets = [
        {"category": "food", "limit": 700},
        {"category": "transport", "limit": 220},
        {"category": "shopping", "limit": 90},
        {"category": "entertainment", "limit": 80},
        {"category": "housing", "limit": 560},
        {"category": "health", "limit": 80},
    ]
    return {
        "user_id": SYNTHETIC_USER,
        "kind": "synthetic",
        "real_user_records": False,
        "separated_from": REAL_DEMO_USER,
        "seed": seed,
        "days": days,
        "transactions": rows,
        "budgets": budgets,
        "disclaimer": "Synthetic development data. Metrics from it are not real-world accuracy.",
    }


def _row(current: date, kind: str, amount: float, category: str, merchant: str, recurring: bool) -> dict:
    return {
        "date": current.isoformat(),
        "type": kind,
        "amount": round(amount, 3),
        "category": category,
        "merchant": merchant,
        "recurring": recurring,
        "currency": "TND",
    }
