"""Train Model V2: the Stage 2 v2 recipe, unchanged, on the temperature-standardized dataset.

    python -m training.standardize_temperature          # 1. build the dataset (once)
    python -m training.train_stage2_v2_temp_corrected   # 2. train and compare with the saved model

Everything except the input file comes from training/train_stage2_v2.py:
  - split: 80/20, stratified, random_state=42 (1,530 test patients)
  - cleaning and the 43 features: train_stage2_v2.clean / api.features_v2
  - model: soft-voting average of logistic regression (median imputation,
    scaling, class_weight="balanced", max_iter=2000) and CatBoost
    (700 iterations, depth 4, learning rate 0.04, l2_leaf_reg 5,
    auto_class_weights="Balanced", random_seed=42)
  - threshold: the value in 0.20, 0.21, ..., 0.80 that maximises balanced
    accuracy on 5-fold out-of-fold training scores (StratifiedKFold, seed 42).
    The test set is not used to choose it.

Writes models/stage2_v2_temp_corrected.reproduced.joblib (never the deployed
file) and checks that its test-set scores equal the saved model's.
"""

import sys
from pathlib import Path

import joblib
import numpy as np
from sklearn.metrics import balanced_accuracy_score, roc_auc_score
from sklearn.model_selection import StratifiedKFold

import training.train_stage2_v2 as recipe
from api.features_v2 import FEATURES

DATA = Path(__file__).resolve().parents[3] / "Preprocessing" / "pneumonia_dataset_with_labs_v2_temp_corrected.csv"
SAVED = recipe.MODELS / "stage2_v2_temp_corrected.joblib"
OUT = recipe.MODELS / "stage2_v2_temp_corrected.reproduced.joblib"


def main():
    recipe.DATA = Path(sys.argv[1]) if len(sys.argv) > 1 else DATA
    X_tr, X_te, y_tr, y_te = recipe.load_split()
    print(f"Data {recipe.DATA.name}: train {len(X_tr)}, test {len(X_te)}, features {len(FEATURES)}")

    oof, aucs = np.zeros(len(X_tr)), []
    for a, b in StratifiedKFold(5, shuffle=True, random_state=recipe.SEED).split(X_tr, y_tr):
        oof[b] = recipe.make_model().fit(X_tr.loc[a], y_tr[a]).predict_proba(X_tr.loc[b])[:, 1]
        aucs.append(roc_auc_score(y_tr[b], oof[b]))
    ths = np.round(np.arange(0.20, 0.81, 0.01), 2)
    bal = [balanced_accuracy_score(y_tr, oof >= t) for t in ths]
    threshold = float(ths[int(np.argmax(bal))])
    print(f"CV AUC {np.mean(aucs):.4f} (+/- {np.std(aucs):.4f}); threshold {threshold} "
          f"(out-of-fold balanced accuracy {max(bal):.4f})")

    model = recipe.make_model().fit(X_tr, y_tr)
    p = model.predict_proba(X_te)[:, 1]
    print(f"Test AUC {roc_auc_score(y_te, p):.4f}")

    if OUT.exists():
        print(f"{OUT.name} already exists, left unchanged")
    else:
        joblib.dump({"model": model, "features": FEATURES, "threshold": threshold,
                     "version": "stage2-v2-temp-corrected"}, OUT)
        print(f"Wrote {OUT}")

    saved = joblib.load(SAVED)
    q = saved["model"].predict_proba(X_te[saved["features"]])[:, 1]
    same = np.abs(p - q).max() < 1e-9 and saved["threshold"] == threshold
    print(f"Saved {SAVED.name}: threshold {saved['threshold']}, max score difference {np.abs(p - q).max():.1e} "
          f"-> {'reproduced' if same else 'NOT reproduced'}")


if __name__ == "__main__":
    main()
