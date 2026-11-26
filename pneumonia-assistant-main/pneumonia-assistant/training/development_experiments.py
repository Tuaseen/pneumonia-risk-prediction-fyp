"""Model-selection experiments from the notebook, on the temperature-standardized dataset.

    python -m training.development_experiments      (needs imbalanced-learn for SMOTENC)

Copies cells 1-7 of pneumonia_two_stage_pipeline.ipynb: the same 80/20 split
(stratified, random_state=42), the notebook's cleaning, and 5-fold stratified
cross-validation on the 6,117 training patients only. The input is the
standardized dataset without its laboratory columns (the notebook's 32 features).
Also prints the cohort characteristics by class (Table 4.2 of the report).
"""

from pathlib import Path

import numpy as np
import pandas as pd
from imblearn.over_sampling import SMOTENC
from imblearn.pipeline import Pipeline as ImbPipeline
from sklearn.ensemble import HistGradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import make_scorer, recall_score
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

DATA = Path(__file__).resolve().parents[3] / "Preprocessing" / "pneumonia_dataset_with_labs_v2_temp_corrected.csv"
LABS = ["wbc", "neutrophils", "lymphocytes", "crp"]
STAGE1 = ["heart_rate_max", "respiratory_rate_max", "spo2_min", "temperature_max", "sbp_min", "respiratory_distress"]
STAGE2_FIRST = ["heart_rate_max", "heart_rate_std", "respiratory_rate_max", "respiratory_rate_mean", "sbp_min",
                "sbp_std", "spo2_min", "spo2_mean", "temperature_max", "temperature_std", "respiratory_distress",
                "hypoxemia", "copd", "heart_failure", "renal"]
SCORING = {"roc_auc": "roc_auc", "balanced_acc": "balanced_accuracy", "pneumonia_recall": "recall",
           "control_recall": make_scorer(recall_score, pos_label=0)}
SEED = 42


def clean(df):
    """Notebook cell 1."""
    df = df.drop(columns=["spo2_max"] + [c for c in df.columns if c.endswith("_trend")])
    df["spo2_mean"] = df["spo2_mean"].clip(upper=100)
    for v in ["heart_rate", "respiratory_rate", "sbp", "spo2", "temperature"]:
        df[f"{v}_mean"] = df[f"{v}_mean"].clip(df[f"{v}_min"], df[f"{v}_max"] if f"{v}_max" in df else None)
    return df


def cv(model, X, y):
    res = cross_validate(model, X, y, cv=StratifiedKFold(5, shuffle=True, random_state=SEED), scoring=SCORING)
    return {m: round(res[f"test_{m}"].mean() * 100, 1) for m in SCORING}


def lr(weight=None):
    return LogisticRegression(max_iter=1000, class_weight=weight)


def main():
    raw = pd.read_csv(DATA)
    cohort(raw)
    df = raw.drop(columns=[f"{l}_{s}" for l in LABS for s in ("value", "done")])
    X, y = df.drop(columns=["hadm_id", "pneumonia_label"]), df["pneumonia_label"]
    X_tr, _, y_tr, _ = train_test_split(X, y, test_size=0.20, stratify=y, random_state=SEED)
    X_tr, y_tr = clean(X_tr.reset_index(drop=True)), y_tr.reset_index(drop=True)
    binary = [X_tr.columns.get_loc(c) for c in X_tr.columns if X_tr[c].nunique() == 2]
    smote = lambda: SMOTENC(categorical_features=binary, random_state=SEED)
    print(f"\nTraining patients {len(X_tr)}, features {X_tr.shape[1]}")

    models = {
        "LR, no weighting": Pipeline([("scale", StandardScaler()), ("clf", lr())]),
        "LR, class weights": Pipeline([("scale", StandardScaler()), ("clf", lr("balanced"))]),
        "LR, SMOTENC": ImbPipeline([("smote", smote()), ("scale", StandardScaler()), ("clf", lr())]),
        "Gradient boosting, weights": HistGradientBoostingClassifier(class_weight="balanced", random_state=SEED),
        "Gradient boosting, SMOTENC": ImbPipeline([("smote", smote()),
                                                   ("clf", HistGradientBoostingClassifier(random_state=SEED))]),
        "Random forest, weights": RandomForestClassifier(n_estimators=500, min_samples_leaf=5, class_weight="balanced",
                                                         n_jobs=-1, random_state=SEED),
        "Random forest, SMOTENC": ImbPipeline([("smote", smote()),
                                               ("clf", RandomForestClassifier(n_estimators=500, min_samples_leaf=5,
                                                                              n_jobs=-1, random_state=SEED))]),
    }
    print("\nImbalance strategies (cross-validated, %)")
    print(pd.DataFrame({k: cv(m, X_tr, y_tr) for k, m in models.items()}).T.to_string())

    weighted = lambda: Pipeline([("scale", StandardScaler()), ("clf", lr("balanced"))])
    print("\nFeature sets, weighted logistic regression (cross-validated, %)")
    sets = {"All 32 features": list(X_tr.columns), "First Stage 2 (15 features)": STAGE2_FIRST, "Stage 1 (6 features)": STAGE1}
    print(pd.DataFrame({k: cv(weighted(), X_tr[c], y_tr) for k, c in sets.items()}).T.to_string())


def cohort(raw):
    raw = raw.assign(wbc=raw["wbc_value"].where(raw["wbc_done"] == 1))
    rows = [("Age, mean (years)", "age", "mean"), ("Male sex (%)", "gender_male", "pct"),
            ("Respiratory rate, mean (/min)", "respiratory_rate_mean", "mean"),
            ("Heart rate, mean (bpm)", "heart_rate_mean", "mean"), ("SpO2, minimum (%)", "spo2_min", "mean"),
            ("Temperature, maximum (F)", "temperature_max", "mean"), ("SBP, minimum (mmHg)", "sbp_min", "mean"),
            ("Respiratory distress flag (%)", "respiratory_distress", "pct"), ("COPD (%)", "copd", "pct"),
            ("Heart failure (%)", "heart_failure", "pct"), ("WBC, mean (10^9/L)", "wbc", "mean"),
            ("CRP measured (%)", "crp_done", "pct")]
    print("Cohort by class (pneumonia / control)")
    for label, col, kind in rows:
        vals = [raw.loc[raw["pneumonia_label"] == k, col] for k in (1, 0)]
        f = (lambda s: s.mean() * 100) if kind == "pct" else (lambda s: s.mean())
        print(f"  {label:32s} {f(vals[0]):6.1f}  {f(vals[1]):6.1f}")


if __name__ == "__main__":
    main()
