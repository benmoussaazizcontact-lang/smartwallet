"""Feature rows built only from information available on the decision date."""

from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, timedelta

EXPENSE_FEATURES = [
    "lag_1",
    "lag_7",
    "lag_14",
    "lag_28",
    "mean_7",
    "mean_28",
    "income_30",
    "recurring_30",
    "dow",
    "month",
    "food_28",
    "transport_28",
    "shopping_28",
]


def _parse(value: str) -> date:
    return datetime.fromisoformat(str(value)[:10]).date()


def daily_totals(transactions: list[dict]) -> list[dict]:
    spend = defaultdict(float)
    income = defaultdict(float)
    recurring = defaultdict(float)
    categories = defaultdict(lambda: defaultdict(float))
    dates = [_parse(row["date"]) for row in transactions]
    if not dates:
        return []
    for row, current in zip(transactions, dates):
        amount = float(row["amount"])
        if row.get("type") == "INCOME":
            income[current] += amount
        elif row.get("type") in {"EXPENSE", "PAYMENT"}:
            spend[current] += amount
            categories[current][str(row.get("category") or "other")] += amount
            if row.get("recurring"):
                recurring[current] += amount
    start, end = min(dates), max(dates)
    rows = []
    cursor = start
    while cursor <= end:
        rows.append(
            {
                "date": cursor,
                "spend": spend[cursor],
                "income": income[cursor],
                "recurring": recurring[cursor],
                "categories": dict(categories[cursor]),
            }
        )
        cursor += timedelta(days=1)
    return rows


def _window(values: list[float], end: int, length: int) -> float:
    start = max(0, end - length + 1)
    chunk = values[start : end + 1]
    return sum(chunk) / length if length else 0.0


def expense_examples(transactions: list[dict], horizon: int) -> tuple[list[list[float]], list[float], list[str]]:
    days = daily_totals(transactions)
    spend = [day["spend"] for day in days]
    income = [day["income"] for day in days]
    recurring = [day["recurring"] for day in days]
    features: list[list[float]] = []
    targets: list[float] = []
    stamps: list[str] = []
    for index in range(28, len(days) - horizon):
        food = sum(days[i]["categories"].get("food", 0.0) for i in range(index - 27, index + 1))
        transport = sum(days[i]["categories"].get("transport", 0.0) for i in range(index - 27, index + 1))
        shopping = sum(days[i]["categories"].get("shopping", 0.0) for i in range(index - 27, index + 1))
        features.append(
            [
                spend[index],
                spend[index - 7],
                spend[index - 14],
                spend[index - 28],
                _window(spend, index, 7),
                _window(spend, index, 28),
                sum(income[index - 29 : index + 1]),
                sum(recurring[index - 29 : index + 1]),
                float(days[index]["date"].weekday()),
                float(days[index]["date"].month),
                food,
                transport,
                shopping,
            ]
        )
        targets.append(sum(spend[index + 1 : index + 1 + horizon]))
        stamps.append(days[index]["date"].isoformat())
    return features, targets, stamps


def overrun_examples(transactions: list[dict], budgets: list[dict]) -> tuple[list[list[float]], list[int], list[str]]:
    limits = {item["category"]: float(item["limit"]) for item in budgets}
    by_month: dict[str, list[dict]] = defaultdict(list)
    for row in transactions:
        if row.get("type") not in {"EXPENSE", "PAYMENT"}:
            continue
        by_month[_parse(row["date"]).strftime("%Y-%m")].append(row)
    months = sorted(by_month)
    features: list[list[float]] = []
    labels: list[int] = []
    stamps: list[str] = []
    income_by_month = defaultdict(float)
    for row in transactions:
        if row.get("type") == "INCOME":
            income_by_month[_parse(row["date"]).strftime("%Y-%m")] += float(row["amount"])
    for month in months:
        year, month_no = (int(part) for part in month.split("-"))
        decision = date(year, month_no, 14)
        month_rows = by_month[month]
        spent_full = defaultdict(float)
        spent_now = defaultdict(float)
        recurring = 0.0
        for row in month_rows:
            category = str(row.get("category") or "other")
            amount = float(row["amount"])
            spent_full[category] += amount
            if _parse(row["date"]) <= decision:
                spent_now[category] += amount
                if row.get("recurring"):
                    recurring += amount
        for category, limit in limits.items():
            if limit <= 0:
                continue
            so_far = spent_now[category]
            features.append(
                [
                    so_far / limit,
                    income_by_month[month],
                    16,
                    so_far,
                    recurring,
                    1.0 if category in {"housing", "entertainment"} else 0.0,
                ]
            )
            labels.append(1 if spent_full[category] > limit else 0)
            stamps.append(f"{month}:{category}")
    return features, labels, stamps


def anomaly_matrix(transactions: list[dict]) -> tuple[list[list[float]], list[dict]]:
    spends = [row for row in transactions if row.get("type") in {"EXPENSE", "PAYMENT"}]
    spends.sort(key=lambda row: row["date"])
    features: list[list[float]] = []
    meta: list[dict] = []
    history: list[float] = []
    last_by_merchant: dict[str, date] = {}
    recent: list[date] = []
    for row in spends:
        current = _parse(row["date"])
        amount = float(row["amount"])
        prior = sorted(history) or [amount]
        median = prior[len(prior) // 2]
        recent = [day for day in recent if (current - day).days <= 7]
        merchant = str(row.get("merchant") or "")
        previous = last_by_merchant.get(merchant)
        gap = 30.0 if previous is None else float((current - previous).days)
        features.append(
            [
                amount,
                amount / median if median else 0.0,
                float(len(recent)),
                gap,
                float(current.weekday()),
                1.0 if row.get("recurring") else 0.0,
            ]
        )
        meta.append({"date": current.isoformat(), "amount": amount, "merchant": merchant, "category": row.get("category")})
        history.append(amount)
        recent.append(current)
        if merchant:
            last_by_merchant[merchant] = current
    return features, meta
