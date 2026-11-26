#!/usr/bin/env python3
"""
Reproduce Experiment 1: Primary External Validation
Target: Frozen Stage 2 v2 VotingClassifier
Threshold: 0.53
Observation Window: Entire ICU Stay (original preprocessing)
Expected Metrics:
  ROC-AUC: 0.7274
  Sensitivity: 94.35%
  Specificity: 17.83%
  Balanced Accuracy: 56.09%
"""
import os
import sys
import json
import joblib
import pandas as pd
import numpy as np
from sklearn.metrics import roc_auc_score, average_precision_score, confusion_matrix, precision_score, recall_score, f1_score, balanced_accuracy_score, brier_score_loss, accuracy_score

# Resolve paths relative to script location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
EXP_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
REPO_ROOT = "/home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant"
sys.path.append(REPO_ROOT)

from api.features_v2 import build

MODEL_PATH = os.path.join(REPO_ROOT, "models", "stage2_v2.joblib")
DATA_PATH = os.path.join(EXP_DIR, "data", "eicu_model_ready_validation.csv")
PREDS_PATH = os.path.join(EXP_DIR, "predictions", "eicu_model_predictions.csv")
METRICS_PATH = os.path.join(EXP_DIR, "metrics", "primary_validation_metrics.json")
THRESHOLD = 0.53

def main():
    print("=" * 70)
    print("EXPERIMENT 1: PRIMARY EXTERNAL VALIDATION REPRODUCTION")
    print("=" * 70)
    print(f"Loading frozen model from: {MODEL_PATH}")
    obj = joblib.load(MODEL_PATH)
    model = obj["model"]
    features_order = obj["features"]

    print(f"Loading validation dataset from: {DATA_PATH}")
    df_ready = pd.read_csv(DATA_PATH)
    y_true = df_ready["label"].values

    print("Building 43 model features using api.features_v2...")
    X = build(df_ready.copy())
    X_model = X[features_order]

    print(f"Generating predictions at frozen threshold: {THRESHOLD}...")
    probs = model.predict_proba(X_model)[:, 1]
    preds = (probs >= THRESHOLD).astype(int)

    # Calculate metrics
    auc = roc_auc_score(y_true, probs)
    pr_auc = average_precision_score(y_true, probs)
    brier = brier_score_loss(y_true, probs)
    tn, fp, fn, tp = confusion_matrix(y_true, preds).ravel()
    sens = tp / (tp + fn)
    spec = tn / (tn + fp)
    bal_acc = (sens + spec) / 2
    prec = precision_score(y_true, preds)
    npv = tn / (tn + fn)
    f1 = f1_score(y_true, preds)
    acc = accuracy_score(y_true, preds)

    print("\n--- PERFORMANCE METRICS ---")
    print(f"  ROC-AUC:           {auc:.4f}  (Expected: 0.7274)")
    print(f"  PR-AUC:            {pr_auc:.4f}")
    print(f"  Brier Score:       {brier:.4f}")
    print(f"  Sensitivity:       {sens*100:.2f}%  (Expected: 94.35%)")
    print(f"  Specificity:       {spec*100:.2f}%  (Expected: 17.83%)")
    print(f"  Balanced Accuracy: {bal_acc*100:.2f}%  (Expected: 56.09%)")
    print(f"  Precision:         {prec*100:.2f}%")
    print(f"  NPV:               {npv*100:.2f}%")
    print(f"  F1-Score:          {f1*100:.2f}%")
    print(f"  Accuracy:          {acc*100:.2f}%")

    print("\n--- CONFUSION MATRIX ---")
    print(f"  True Positives (TP):  {tp}  (Expected: 217)")
    print(f"  True Negatives (TN):  {tn}  (Expected: 41)")
    print(f"  False Positives (FP): {fp}  (Expected: 189)")
    print(f"  False Negatives (FN): {fn}  (Expected: 13)")

    assert tp == 217 and tn == 41 and fp == 189 and fn == 13, "Mismatch in confusion matrix counts!"
    print("\n[SUCCESS] Primary External Validation reproduced exactly.")

if __name__ == "__main__":
    main()
