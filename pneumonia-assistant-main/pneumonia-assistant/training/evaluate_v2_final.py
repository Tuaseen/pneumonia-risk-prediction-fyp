"""Every Model V2 number reported in the thesis, from the saved model files.

    python -m training.evaluate_v2_final

No training and no threshold tuning: the deployed V2 model is scored at its own
threshold (0.49, chosen on training data), and V1 and V2 are also compared at
V1's 0.53 so that only the model differs. Inputs:
  - MIMIC-IV test set: the 1,530 held-out patients. V1 is scored on the original
    dataset, V2 on the temperature-standardized one (each on what it was trained on).
  - eICU primary external validation (full ICU stay) and the exploratory
    first-24-hour window, from Extracted_Validation_Data/*/data/features_43*.csv.
Writes models/stage2_v2_temp_corrected_metrics.json, test and eICU score files for
the figures, and V2 permutation importance (same settings as
training/experiments/stage2_feature_importance.py). Existing files are never overwritten.
"""

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.inspection import permutation_importance
from sklearn.metrics import average_precision_score, brier_score_loss, roc_auc_score

import training.train_stage2_v2 as recipe

ROOT = Path(__file__).resolve().parents[1]
FYP = ROOT.parents[1]
V1_DATA = FYP / "Preprocessing" / "pneumonia_dataset_with_labs.csv"
V2_DATA = FYP / "Preprocessing" / "pneumonia_dataset_with_labs_v2_temp_corrected.csv"
EICU = {"eicu_full_stay": FYP / "Extracted_Validation_Data" / "1_primary_external_validation" / "data" / "features_43.csv",
        "eicu_24h": FYP / "Extracted_Validation_Data" / "2_exploratory_24h_diagnostic_ablation" / "data"
                    / "features_43_24h_ablation.csv"}
OUT = recipe.MODELS / "stage2_v2_temp_corrected_metrics.json"
SCORES = recipe.MODELS / "stage2_v2_temp_corrected_scores.csv"
IMPORTANCE = recipe.MODELS / "stage2_v2_temp_corrected_importance.csv"


def metrics(y, p, th) -> dict:
    y, pred = np.asarray(y), np.asarray(p) >= th
    tp, fn = int((pred & (y == 1)).sum()), int((~pred & (y == 1)).sum())
    tn, fp = int((~pred & (y == 0)).sum()), int((pred & (y == 0)).sum())
    sens, spec = tp / (tp + fn), tn / (tn + fp)
    ppv = tp / (tp + fp) if tp + fp else float("nan")
    return {"threshold": th, "n": int(len(y)), "roc_auc": float(roc_auc_score(y, p)),
            "pr_auc": float(average_precision_score(y, p)), "brier": float(brier_score_loss(y, p)),
            "sensitivity": sens, "specificity": spec, "balanced_accuracy": (sens + spec) / 2,
            "ppv": ppv, "npv": tn / (tn + fn) if tn + fn else float("nan"),
            "f1": 2 * ppv * sens / (ppv + sens) if ppv + sens else 0.0,
            "tp": tp, "fn": fn, "tn": tn, "fp": fp}


def test_split(path):
    recipe.DATA = path
    _, X_te, _, y_te = recipe.load_split()
    return X_te, y_te


def main():
    v1 = joblib.load(recipe.MODELS / "stage2_v2.joblib")
    v2 = joblib.load(recipe.MODELS / "stage2_v2_temp_corrected.joblib")
    th1, th2 = v1["threshold"], v2["threshold"]
    score = lambda b, X: b["model"].predict_proba(X[b["features"]])[:, 1]

    X1, y1 = test_split(V1_DATA)
    X2, y2 = test_split(V2_DATA)
    assert (y1.values == y2.values).all()
    p1, p2 = score(v1, X1), score(v2, X2)
    rng, ci = np.random.default_rng(recipe.SEED), []
    for _ in range(2000):
        i = rng.integers(0, len(y2), len(y2))
        if y2[i].nunique() == 2:
            ci.append(roc_auc_score(y2[i], p2[i]))
    out = {"model": "stage2_v2_temp_corrected.joblib", "threshold_v2": th2, "threshold_v1": th1,
           "mimic_test": {"v2_at_v2_threshold": {**metrics(y2, p2, th2),
                                                  "roc_auc_ci95": [float(np.percentile(ci, 2.5)),
                                                                   float(np.percentile(ci, 97.5))]},
                          "v1_at_0.53": metrics(y1, p1, th1), "v2_at_0.53": metrics(y2, p2, th1)}}
    rows = [pd.DataFrame({"set": "mimic_test", "label": y2.values, "v1": p1, "v2": p2})]

    for name, path in EICU.items():
        df = pd.read_csv(path)
        e1, e2 = score(v1, df), score(v2, df)
        out[name] = {"v2_at_v2_threshold": metrics(df["label"], e2, th2),
                     "v1_at_0.53": metrics(df["label"], e1, th1), "v2_at_0.53": metrics(df["label"], e2, th1),
                     "respiratory_distress_missing": int(df["respiratory_distress"].isna().sum())}
        rows.append(pd.DataFrame({"set": name, "label": df["label"].values, "v1": e1, "v2": e2}))

    lr_imputer = v2["model"].named_estimators_["logreg"].named_steps["impute"]
    out["respiratory_distress_lr_median"] = float(
        lr_imputer.statistics_[v2["features"].index("respiratory_distress")])

    perm = permutation_importance(v2["model"], X2[v2["features"]], y2, scoring="roc_auc", n_repeats=20,
                                  random_state=recipe.SEED, n_jobs=-1)
    imp = pd.DataFrame({"perm_auc_drop": perm.importances_mean, "perm_std": perm.importances_std},
                       index=v2["features"]).sort_values("perm_auc_drop", ascending=False)

    for path, write in [(OUT, lambda p: p.write_text(json.dumps(out, indent=2))),
                        (SCORES, lambda p: pd.concat(rows).to_csv(p, index=False, float_format="%.6f")),
                        (IMPORTANCE, lambda p: imp.to_csv(p, float_format="%.5f"))]:
        if path.exists():
            print(f"{path.name} already exists, left unchanged")
        else:
            write(path)
            print(f"Wrote {path}")

    for k in ["mimic_test", "eicu_full_stay", "eicu_24h"]:
        for which, m in out[k].items():
            if isinstance(m, dict):
                print(f"{k:15s} {which:20s} AUC {m['roc_auc']:.4f} Brier {m['brier']:.4f} "
                      f"sens {m['sensitivity']*100:.2f} spec {m['specificity']*100:.2f} "
                      f"bal {m['balanced_accuracy']*100:.2f}  TP {m['tp']} FN {m['fn']} TN {m['tn']} FP {m['fp']}")


if __name__ == "__main__":
    main()
