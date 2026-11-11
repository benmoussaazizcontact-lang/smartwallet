"""Refuse to fit a production model on a short or leaked sample."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class TrainingRefusal(Exception):
    reason: str

    def __str__(self) -> str:
        return self.reason


def assert_trainable(row_count: int, *, task: str, minimum: int = 180) -> None:
    if row_count < minimum:
        raise TrainingRefusal(
            f"{task} needs at least {minimum} temporally ordered rows. Got {row_count}. No model file was written."
        )


def temporal_split(row_count: int, test_fraction: float = 0.2) -> tuple[int, int]:
    if row_count < 5:
        raise TrainingRefusal("Not enough rows to split without leakage.")
    test = max(1, int(row_count * test_fraction))
    train = row_count - test
    if train < 1:
        raise TrainingRefusal("The training slice would be empty.")
    return train, test
