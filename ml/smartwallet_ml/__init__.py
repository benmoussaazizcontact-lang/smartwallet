"""On-server statistical baselines and a gate that refuses tiny training sets."""

from .baselines import daily_forecast, dbscan_1d, ewma, mad_alerts, monte_carlo_net
from .train_gate import TrainingRefusal, assert_trainable

__all__ = [
    "daily_forecast",
    "dbscan_1d",
    "ewma",
    "mad_alerts",
    "monte_carlo_net",
    "TrainingRefusal",
    "assert_trainable",
]
