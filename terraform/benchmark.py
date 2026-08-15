"""LightGBM benchmark for the Kaggle Credit Card Fraud dataset."""

import json
import time
from pathlib import Path

import lightgbm as lgb
import numpy as np
import pandas as pd
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split


DATASET_PATH = Path.home() / "ml-benchmark" / "creditcard.csv"
RESULT_PATH = Path.home() / "ml-benchmark" / "benchmark_result.json"
RANDOM_STATE = 42


def main() -> None:
    load_started = time.perf_counter()
    data = pd.read_csv(DATASET_PATH)
    load_seconds = time.perf_counter() - load_started

    features = data.drop(columns="Class")
    target = data["Class"]
    x_train, x_test, y_train, y_test = train_test_split(
        features,
        target,
        test_size=0.2,
        random_state=RANDOM_STATE,
        stratify=target,
    )

    model = lgb.LGBMClassifier(
        objective="binary",
        n_estimators=1000,
        learning_rate=0.05,
        num_leaves=31,
        random_state=RANDOM_STATE,
        n_jobs=-1,
        verbosity=-1,
    )

    training_started = time.perf_counter()
    model.fit(
        x_train,
        y_train,
        eval_set=[(x_test, y_test)],
        eval_metric="auc",
        callbacks=[lgb.early_stopping(50, verbose=False)],
    )
    training_seconds = time.perf_counter() - training_started

    probabilities = model.predict_proba(x_test)[:, 1]
    predictions = (probabilities >= 0.5).astype(int)

    one_row = x_test.iloc[[0]]
    model.predict_proba(one_row)  # Warm up before measuring latency.
    latency_samples = []
    for _ in range(100):
        started = time.perf_counter()
        model.predict_proba(one_row)
        latency_samples.append(time.perf_counter() - started)
    latency_ms = float(np.median(latency_samples) * 1000)

    batch = x_test.iloc[:1000]
    started = time.perf_counter()
    model.predict_proba(batch)
    batch_seconds = time.perf_counter() - started

    result = {
        "dataset_rows": int(len(data)),
        "train_rows": int(len(x_train)),
        "test_rows": int(len(x_test)),
        "load_time_seconds": load_seconds,
        "training_time_seconds": training_seconds,
        "best_iteration": int(model.best_iteration_),
        "auc_roc": float(roc_auc_score(y_test, probabilities)),
        "accuracy": float(accuracy_score(y_test, predictions)),
        "f1_score": float(f1_score(y_test, predictions)),
        "precision": float(precision_score(y_test, predictions)),
        "recall": float(recall_score(y_test, predictions)),
        "inference_latency_one_row_ms_median_100_runs": latency_ms,
        "inference_1000_rows_seconds": batch_seconds,
        "inference_throughput_rows_per_second": float(len(batch) / batch_seconds),
    }

    RESULT_PATH.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    print(f"\nSaved results to {RESULT_PATH}")


if __name__ == "__main__":
    main()
