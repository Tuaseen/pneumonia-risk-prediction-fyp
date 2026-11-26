# Primary External Validation Report

**Model:** Frozen Stage 2 v2 VotingClassifier (`LogisticRegression` + `CatBoostClassifier`)  
**Derivation Dataset:** MIMIC-IV ($N = 7,647$)  
**External Cohort:** eICU Collaborative Research Database Demo v2.0.1 ($N = 460$: 230 Pneumonia, 230 Controls)  
**Frozen Decision Threshold:** $\tau = 0.53$  
**Observation Window:** Entire ICU Stay (Original Preprocessing Pipeline, mean 108 hours)

---

## 1. Overview & Protocol
This experiment represents the pre-registered, frozen external validation benchmark of the Stage 2 v2 pneumonia risk prediction model. The model architecture, hyperparameters, and decision threshold (0.53) were held strictly constant without any post-hoc tuning, fine-tuning, or retraining.

The feature extraction pipeline evaluated patient measurements across their entire ICU stay, using the original heuristic surrogate for respiratory distress:
$$\text{distress} = (\text{RR}_{\max} \ge 24) \lor (\text{SpO}_{2,\min} < 90\%) \lor (\text{respiratory failure diagnosis})$$

> [!NOTE]
> **Diagnosis Information in Experiment 1:** This surrogate rule is a hybrid definition that explicitly includes physician-entered EHR diagnosis codes for acute respiratory failure (`respiratory_distress_diag` in 147 patients). It is therefore not a purely physiological vital sign measure.

---

## 2. Quantitative Results

### Performance Summary
| Metric | Value | Interpretation |
|:---|:---:|:---|
| **ROC-AUC** | **0.7274** | Moderate discriminative ranking ability retained across 168 external hospitals. |
| **PR-AUC** | **0.6977** | Strong precision-recall profile at balanced 50% prevalence. |
| **Brier Score** | **0.2779** | Reflects probability calibration drift under cross-database domain shift. |
| **Sensitivity (Recall)** | **94.35%** | Captures 217 of 230 confirmed pneumonia patients. |
| **Specificity** | **17.83%** | Only 41 of 230 non-pneumonia ICU controls correctly cleared. |
| **Balanced Accuracy** | **56.09%** | Arithmetic mean of sensitivity and specificity. |
| **Precision (PPV)** | **53.45%** | 217 true positives out of 406 positive flags. |
| **NPV** | **75.93%** | 41 true negatives out of 54 negative predictions. |
| **F1-Score** | **68.24%** | Harmonic mean of precision and recall. |
| **Overall Accuracy** | **56.09%** | 258 correct classifications out of 460 patients. |

### Confusion Matrix ($\tau = 0.53$)
```
                     Actual Pneumonia (1)    Actual Control (0)
Predicted High (1)         217 (TP)               189 (FP)
Predicted Low  (0)          13 (FN)                41 (TN)
```

---

## 3. Clinical & Methodological Findings
1. **Preserved Discriminative Ranking:** An ROC-AUC of 0.7274 confirms that the model's underlying scoring function successfully separates higher-risk from lower-risk patients.
2. **The Specificity Collapse (17.83%):** Root cause auditing proved that the low specificity at the fixed threshold of 0.53 was driven by:
   - **Surrogate Feature Saturation:** The vital heuristic rule triggered in 100% of False Positive controls (189/189) and 95.65% overall.
   - **ICU Control Spectrum Bias:** Controls were critically ill ICU admissions with Septic Shock, Congestive Heart Failure, and DKA, creating physiological mimicry.
   - **Multi-Day Telemetry Accumulation:** Observing continuous 5-minute telemetry over ~108 hours mathematically drove extreme-value vitals (`spo2_min`, `rr_max`) to abnormal levels.

---

## 4. Reproduction
To reproduce these exact results from the command line:
```bash
uv run --with pandas --with scikit-learn --with catboost --with joblib python scripts/reproduce_primary_validation.py
```
Outputs are verified against `predictions/eicu_model_predictions.csv` and `metrics/primary_validation_metrics.json`.
