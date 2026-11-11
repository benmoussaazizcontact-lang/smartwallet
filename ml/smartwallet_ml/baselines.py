"""Real statistical calculations. They are not trained gradient-boosted models."""

from __future__ import annotations

import math
import statistics
from typing import Iterable


def daily_forecast(amounts: Iterable[float], days: int = 28) -> dict:
    values = [float(value) for value in amounts if value > 0]
    if len(values) < 4 or days <= 0:
        return {"operational": False, "method": "insufficient_data", "model": None, "daily": 0.0, "horizon_30": 0.0}
    daily = sum(values) / days
    mean = statistics.fmean(values)
    variance = statistics.pvariance(values) if len(values) > 1 else 0.0
    return {
        "operational": True,
        "method": "statistical_baseline",
        "model": None,
        "daily": daily,
        "horizon_7": daily * 7,
        "horizon_30": daily * 30,
        "horizon_90": daily * 90,
        "uncertainty_30": math.sqrt(variance) * math.sqrt(30),
        "note": "SARIMAX and Prophet are not fitted.",
    }


def mad_alerts(amounts: Iterable[float]) -> dict:
    values = [float(value) for value in amounts if value > 0]
    if len(values) < 8:
        return {"operational": False, "method": "insufficient_data", "alerts": []}
    median = statistics.median(values)
    mad = statistics.median([abs(value - median) for value in values])
    scale = mad if mad else median * 0.15
    alerts = [value for value in values if scale and value > median + 3 * scale]
    return {
        "operational": True,
        "method": "statistical_baseline",
        "model": None,
        "alerts": alerts,
        "note": "Isolation Forest is not trained.",
    }


def dbscan_1d(values: Iterable[float], eps: float, min_pts: int = 2) -> list[list[int]]:
    points = [float(value) for value in values]
    seen: set[int] = set()
    clusters: list[list[int]] = []

    def neighbors(index: int) -> list[int]:
        return [other for other, point in enumerate(points) if abs(points[index] - point) <= eps]

    for start in range(len(points)):
        if start in seen:
            continue
        seed = neighbors(start)
        if len(seed) < min_pts:
            continue
        cluster: list[int] = []
        queue = list(seed)
        while queue:
            current = queue.pop()
            if current in seen:
                continue
            seen.add(current)
            cluster.append(current)
            more = neighbors(current)
            if len(more) >= min_pts:
                queue.extend(more)
        clusters.append(cluster)
    return clusters


def ewma(returns: Iterable[float], lam: float = 0.94) -> dict:
    series = [abs(float(value)) for value in returns]
    if len(series) < 8:
        return {"operational": False, "method": "insufficient_data", "value": None, "note": "GARCH is not fitted."}
    value = series[0]
    for point in series[1:]:
        value = lam * value + (1 - lam) * point
    return {"operational": True, "method": "ewma", "value": value, "note": "GARCH is not fitted. EWMA is the operational estimate."}


def monte_carlo_net(income: float, expense: float, paths: int = 200, seed: int = 42) -> dict:
    if income <= 0 and expense <= 0:
        return {"operational": False, "method": "insufficient_data", "p50": 0.0}
    state = seed & 0x7FFFFFFF

    def nxt() -> float:
        nonlocal state
        state = (1664525 * state + 1013904223) & 0x7FFFFFFF
        return state / 0x7FFFFFFF

    samples = []
    for _ in range(paths):
        samples.append(income * (0.5 + nxt() * 0.5) - expense)
    samples.sort()
    return {
        "operational": True,
        "method": "educational_simulation",
        "p10": samples[int((len(samples) - 1) * 0.1)],
        "p50": samples[len(samples) // 2],
        "note": "Hypothetical income shock. Not a guaranteed outcome.",
    }
