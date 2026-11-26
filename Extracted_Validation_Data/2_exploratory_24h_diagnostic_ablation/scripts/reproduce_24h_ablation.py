#!/usr/bin/env python3
"""
Reproduce Experiment 2: Exploratory 24-Hour Diagnostic Ablation
Target: Same Frozen Stage 2 v2 VotingClassifier
Threshold: 0.53
Observation Window: First 24 Hours of ICU Stay (t in [0, 24h])
Condition: respiratory_distress = NaN (native model imputation: LR=1.0, CB=0.0; NO diagnosis string used)
Expected Metrics:
  ROC-AUC: 0.7322
  Sensitivity: 74.78%
  Specificity: 62.17%
  Balanced Accuracy: 68.48%
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
DATA_PATH = os.path.join(EXP_DIR, "data", "eicu_24h_model_ready.csv")
PREDS_PATH = os.path.join(EXP_DIR, "predictions", "eicu_24h_ablation_predictions.csv")
METRICS_PATH = os.path.join(EXP_DIR, "metrics", "ablation_metrics.json")
THRESHOLD = 0.53

def main():
    print("=" * 70)
    print("EXPERIMENT 2: EXPLORATORY 24-HOUR DIAGNOSTIC ABLATION REPRODUCTION")
    print("=" * 70)
    print(f"Loading frozen model from: {MODEL_PATH}")
    obj = joblib.load(MODEL_PATH)
    model = obj["model"]
    features_order = obj["features"]

    print(f"Loading 24h ablation dataset from: {DATA_PATH}")
    df_24h = pd.read_csv(DATA_PATH)
    y_true = df_24h["label"].values

    print("Building 43 model features using api.features_v2 (respiratory_distress = NaN)...")
    X = build(df_24h.copy())
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
    print(f"  ROC-AUC:           {auc:.4f}  (Expected: 0.7322)")
    print(f"  PR-AUC:            {pr_auc:.4f}")
    print(f"  Brier Score:       {brier:.4f}")
    print(f"  Sensitivity:       {sens*100:.2f}%  (Expected: 74.78%)")
    print(f"  Specificity:       {spec*100:.2f}%  (Expected: 62.17%)")
    print(f"  Balanced Accuracy: {bal_acc*100:.2f}%  (Expected: 68.48%)")
    print(f"  Precision:         {prec*100:.2f}%")
    print(f"  NPV:               {npv*100:.2f}%")
    print(f"  F1-Score:          {f1*100:.2f}%")
    print(f"  Accuracy:          {acc*100:.2f}%")

    print("\n--- CONFUSION MATRIX ---")
    print(f"  True Positives (TP):  {tp}  (Expected: 172)")
    print(f"  True Negatives (TN):  {tn}  (Expected: 143)")
    print(f"  False Positives (FP): {fp}  (Expected: 87)")
    print(f"  False Negatives (FN): {fn}  (Expected: 58)")

    assert tp == 172 and tn == 143 and fp == 87 and fn == 58, "Mismatch in confusion matrix counts!"
    print("\n[SUCCESS] 24-Hour Diagnostic Ablation reproduced exactly.")

if __name__ == "__main__":
    main()
