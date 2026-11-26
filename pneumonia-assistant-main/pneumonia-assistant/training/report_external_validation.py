"""External validation on independent eICU cohort (460 patients: 230 pneumonia, 230 controls).

    python -m training.report_external_validation
"""

from pathlib import Path
import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score, balanced_accuracy_score, recall_score, roc_auc_score, confusion_matrix, brier_score_loss

from api import features_v2

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "models"
EICU_DATA = Path("/home/tuaseen/Downloads/Extracted_Validation_Data/eicu_model_ready_validation.csv")
OUT_PREDS = Path("/home/tuaseen/Downloads/Extracted_Validation_Data/eicu_model_predictions.csv")


def main():
    if not EICU_DATA.exists():
        fallback = Path("/home/tuaseen/.gemini/antigravity/scratch/eicu_validation/eicu_model_ready_validation.csv")
        if fallback.exists():
            data_file = fallback
        else:
            raise FileNotFoundError(f"External validation dataset not found at {EICU_DATA}")
    else:
        data_file = EICU_DATA

    df = pd.read_csv(data_file)
    y_true = df["label"].values

    s1 = joblib.load(MODELS / "stage1.joblib")
    old = joblib.load(MODELS / "stage2.joblib")
    v2 = joblib.load(MODELS / "stage2_v2_temp_corrected.joblib")

    # Stage 1 inputs
    X_s1 = df[s1["features"]]
    p1 = s1["model"].predict_proba(X_s1)[:, 1]
    flagged = p1 >= s1["threshold"]

    # Stage 2 inputs
    X_old = df[old["features"]]
    po = old["model"].predict_proba(X_old)[:, 1]

    # Stage 2 v2 inputs
    X_v2 = features_v2.build(df)
    p2 = v2["model"].predict_proba(X_v2)[:, 1]

    # Two-stage predictions
    # If Stage 1 clears (score < threshold) -> Low Risk (0)
    # If Stage 1 flags -> Stage 2 score
    pred_two_stage_v2 = np.zeros_like(y_true)
    for i in range(len(y_true)):
        if flagged[i] and (p2[i] >= v2["threshold"]):
            pred_two_stage_v2[i] = 1

    pred_two_stage_old = np.zeros_like(y_true)
    for i in range(len(y_true)):
        if flagged[i] and (po[i] >= old["threshold"]):
            pred_two_stage_old[i] = 1

    print("=" * 75)
    print("   INDEPENDENT EXTERNAL VALIDATION REPORT (eICU DATABASE)")
    print("=" * 75)
    print(f"Cohort: {len(y_true)} patients | Pneumonia: {(y_true==1).sum()} (50.0%) | Controls: {(y_true==0).sum()} (50.0%)\n")

    header = f"{'Model':<26}{'ROC AUC':>10}{'Bal. Acc':>11}{'Sens (Recall)':>15}{'Specificity':>13}"
    print(header)
    print("-" * len(header))

    def print_row(name, y_t, probs, preds):
        auc = roc_auc_score(y_t, probs) if probs is not None else float("nan")
        bal = balanced_accuracy_score(y_t, preds) * 100
        sens = recall_score(y_t, preds) * 100
        tn, fp, fn, tp = confusion_matrix(y_t, preds).ravel()
        spec = (tn / (tn + fp)) * 100
        auc_str = f"{auc*100:9.1f}%" if not np.isnan(auc) else f"{'—':>9s}"
        print(f"{name:<26}{auc_str}{bal:10.1f}%{sens:14.1f}%{spec:12.1f}%")

    print_row("Stage 1 (Screening)", y_true, p1, flagged)
    print_row("Stage 2 (Original)", y_true, po, po >= old["threshold"])
    print_row("Stage 2 v2 (Ensemble)", y_true, p2, p2 >= v2["threshold"])
    print_row("Two-Stage (with Original)", y_true, None, pred_two_stage_old)
    print_row("Two-Stage (with v2)", y_true, None, pred_two_stage_v2)

    print("\n" + "=" * 75)
    print("   THRESHOLD RE-CALIBRATION ANALYSIS (YOUDEN'S J INDEX)")
    print("=" * 75)
    print("Prevalence in MIMIC training was 75%; eICU validation is balanced at 50%.")
    print("Recalibrating the decision threshold to the external hospital setting yields:\n")

    header_cal = f"{'Model':<26}{'Threshold':>11}{'ROC AUC':>10}{'Bal. Acc':>11}{'Sens (Recall)':>15}{'Specificity':>13}"
    print(header_cal)
    print("-" * len(header_cal))

    def find_opt(y_t, probs, name):
        thresholds = np.linspace(0.01, 0.99, 100)
        best_j = -1
        best_t = 0.5
        for t in thresholds:
            yp = (probs >= t).astype(int)
            sens = recall_score(y_t, yp, zero_division=0)
            tn, fp, fn, tp = confusion_matrix(y_t, yp).ravel()
            spec = tn / (tn + fp)
            if (sens + spec - 1) > best_j:
                best_j = sens + spec - 1
                best_t = t
        yp_best = (probs >= best_t).astype(int)
        auc = roc_auc_score(y_t, probs)
        bal = balanced_accuracy_score(y_t, yp_best) * 100
        sens = recall_score(y_t, yp_best) * 100
        tn, fp, fn, tp = confusion_matrix(y_t, yp_best).ravel()
        spec = (tn / (tn + fp)) * 100
        print(f"{name:<26}{best_t:>10.2f}{auc*100:9.1f}%{bal:10.1f}%{sens:14.1f}%{spec:12.1f}%")

    find_opt(y_true, p1, "Stage 1 (Calibrated)")
    find_opt(y_true, po, "Stage 2 (Calibrated)")
    find_opt(y_true, p2, "Stage 2 v2 (Calibrated)")

    print("\n" + "=" * 75)
    print("   TWO-STAGE CLINICAL TRIAGE BREAKDOWN (Stage 1 -> Stage 2 v2)")
    print("=" * 75)
    
    # Risk bands
    bands = []
    for i in range(len(y_true)):
        if not flagged[i]:
            bands.append("Low")
        elif p2[i] < v2["threshold"]:
            bands.append("Moderate")
        else:
            bands.append("High")
    df_bands = pd.Series(bands)

    print(f"1. Low Risk (Ruled out at Stage 1):    {(df_bands == 'Low').sum():>3} patients ({(df_bands == 'Low').mean()*100:.1f}%)")
    print(f"2. Moderate Risk (Flagged, Stage 2 <): {(df_bands == 'Moderate').sum():>3} patients ({(df_bands == 'Moderate').mean()*100:.1f}%)")
    print(f"3. High Risk (Stage 2 confirmed):      {(df_bands == 'High').sum():>3} patients ({(df_bands == 'High').mean()*100:.1f}%)")

    print("\nPrevalence of True Pneumonia by Assigned Risk Band:")
    for b in ["Low", "Moderate", "High"]:
        subset_y = y_true[df_bands == b]
        rate = subset_y.mean() * 100 if len(subset_y) > 0 else 0
        print(f"  • {b:<10} Band: {subset_y.sum():>3} / {len(subset_y):>3} true pneumonia cases ({rate:5.1f}%)")

    # Export predictions CSV
    df_out = pd.DataFrame({
        "uniquepid": df["uniquepid"],
        "patientunitstayid": df["patientunitstayid"],
        "actual_pneumonia_label": y_true,
        "stage1_risk_score": np.round(p1, 4),
        "stage1_flagged": flagged.astype(int),
        "stage2_v2_risk_score": np.round(p2, 4),
        "assigned_risk_band": bands,
        "correctly_identified_pneumonia": ((df_bands == "High") & (y_true == 1)).astype(int),
        "correctly_cleared_control": ((df_bands != "High") & (y_true == 0)).astype(int)
    })
    df_out.to_csv(OUT_PREDS, index=False)
    print(f"\nSaved patient-level predictions to: {OUT_PREDS}")


if __name__ == "__main__":
    main()
