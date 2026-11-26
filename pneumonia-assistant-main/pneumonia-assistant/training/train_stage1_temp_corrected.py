"""Retrain Stage 1 on the temperature-standardized dataset (the notebook's recipe, unchanged).

    python -m training.train_stage1_temp_corrected

Recipe (pneumonia_two_stage_pipeline.ipynb, cells 7-12):
  - features: heart_rate_max, respiratory_rate_max, spo2_min, temperature_max,
    sbp_min, respiratory_distress
  - model: StandardScaler + LogisticRegression(max_iter=1000, class_weight="balanced")
  - split: 80/20, stratified, random_state=42 (the same 6,117 / 1,530 patients as Stage 2)
  - threshold: the highest value in np.linspace(0.05, 0.95, 181) that still finds at
    least 90% of pneumonia patients in 5-fold out-of-fold training scores
    (StratifiedKFold, shuffle, seed 42). The test set is not used to choose it.

Only the input changes: temperature_max now comes from the standardized dataset
(training/standardize_temperature.py). Writes models/stage1_temp_corrected.joblib
(never overwrites it, and never touches the original models/stage1.joblib) and
prints the held-out comparison with the original Stage 1.
"""

from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import recall_score, roc_auc_score
from sklearn.model_selection import StratifiedKFold, cross_val_predict, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "models"
PREP = ROOT.parents[1] / "Preprocessing"
DATA = PREP / "pneumonia_dataset_with_labs_v2_temp_corrected.csv"
ORIGINAL_DATA = PREP / "pneumonia_dataset_with_labs.csv"
OUT = MODELS / "stage1_temp_corrected.joblib"
FEATURES = ["heart_rate_max", "respiratory_rate_max", "spo2_min", "temperature_max", "sbp_min",
            "respiratory_distress"]
SEED = 42
MIN_RECALL = 0.90


def make_model():
    return Pipeline([("scale", StandardScaler()),
                     ("clf", LogisticRegression(max_iter=1000, class_weight="balanced"))])


def split(path):
    df = pd.read_csv(path)
    tr, te = train_test_split(np.arange(len(df)), test_size=0.20, stratify=df["pneumonia_label"],
                              random_state=SEED)
    return df.iloc[tr], df.iloc[te]


def summary(y, p, th):
    pred = p >= th
    return (f"AUC {roc_auc_score(y, p):.4f}  sensitivity {recall_score(y, pred) * 100:.2f}%  "
            f"specificity {recall_score(y, pred, pos_label=0) * 100:.2f}%")


def main():
    train, test = split(DATA)
    X, y = train[FEATURES], train["pneumonia_label"]
    cv = StratifiedKFold(5, shuffle=True, random_state=SEED)
    oof = cross_val_predict(make_model(), X, y, cv=cv, method="predict_proba")[:, 1]
    threshold = None
    for t in np.linspace(0.05, 0.95, 181):
        if recall_score(y, oof >= t) >= MIN_RECALL:
            threshold = round(float(t), 2)
    print(f"Train {len(train)}, test {len(test)}; out-of-fold AUC {roc_auc_score(y, oof):.4f}; "
          f"threshold {threshold}")

    model = make_model().fit(X, y)
    if OUT.exists():
        print(f"{OUT.name} already exists, left unchanged")
    else:
        joblib.dump({"model": model, "features": FEATURES, "threshold": threshold,
                     "version": "stage1-temp-corrected"}, OUT)
        print(f"Wrote {OUT}")

    saved = joblib.load(OUT)
    old = joblib.load(MODELS / "stage1.joblib")
    _, test_orig = split(ORIGINAL_DATA)
    yt = test["pneumonia_label"]
    print("\nHeld-out test set (1,530 patients):")
    print(f"  original Stage 1, original inputs    {summary(yt, old['model'].predict_proba(test_orig[FEATURES])[:, 1], old['threshold'])}")
    print(f"  original Stage 1, corrected inputs   {summary(yt, old['model'].predict_proba(test[FEATURES])[:, 1], old['threshold'])}")
    print(f"  retrained Stage 1, corrected inputs  {summary(yt, saved['model'].predict_proba(test[FEATURES])[:, 1], saved['threshold'])}")


if __name__ == "__main__":
    main()
