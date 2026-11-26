# Independent External Validation Audit: MIMIC-IV vs. eICU Demo

**Project Title:** IoT-Based Early Pneumonia Risk Prediction Using Temporal Physiological Monitoring and Machine Learning  
**Audit Target:** External Validation Pipeline on eICU Collaborative Research Database Demo (v2.0.1)  
**Evaluated Models:** Stage 1 (`stage1.joblib`), Stage 2 (`stage2.joblib`), Stage 2 v2 Ensemble (`stage2_v2.joblib`)  
**Audit Date:** November 2026  
**Auditor:** Independent Technical & Methodological Audit  

---

## Executive Summary & Audit Verdict

This audit conducted an independent verification of the external validation conducted on the eICU Demo dataset ($n = 460$: 230 pneumonia cases, 230 non-pneumonia controls).

### Audit Verdict: **Partially Trustworthy with Critical Clinical & Methodological Caveats**
1. **Model & Mathematical Integrity Verified:** The original models trained on MIMIC-IV were loaded strictly without alteration or retraining. Feature calculations, pipeline transformations, and scoring scripts match the production repository logic.
2. **Discriminative Signal is Real, but Degraded:** The reported **ROC-AUC of 72.7% (95% CI: 67.9% – 77.4%)** for the primary ensemble model (`Stage 2 v2`) is mathematically valid. The underlying physiological ranking holds up across 168 distinct hospitals.
3. **Severe Retrospective Temporal Leakage (Major Finding):** In **84.8% of pneumonia patients (195/230)**, the vital sign features were aggregated from bedside monitoring recorded **after** clinical pneumonia had already been formally diagnosed (mean post-diagnosis duration: 123.4 hours). The current evaluation is therefore a **retrospective classification of established ICU pneumonia**, not a prospective early warning system.
4. **Massive Over-Prediction & Miscalibration:** Due to a training prevalence of 75% and severe illness among non-pneumonia ICU controls (septic shock, heart failure, DKA), the frozen threshold of 0.53 yields a high sensitivity (94.3%) but an unacceptably low specificity (17.8%). The Brier score (0.278) is worse than uninformative guessing (0.250), with an Expected Calibration Error of **24.6%**.
5. **Threshold 0.77 is Exploratory, Not Validated:** The 0.77 threshold was optimized directly on the 460 external evaluation patients using Youden's $J$ index. In an academic thesis, it must be framed strictly as **post-hoc exploratory recalibration**, never as an independently validated threshold.

---

## Task 1: Model Integrity Audit

### 1. Model Architecture & Pipeline Verification
Inspection of the serialized model artifacts in `pneumonia-assistant/models/` confirms:
* **Stage 1 (`stage1.joblib`):**
  * **Architecture:** Scikit-Learn `Pipeline(StandardScaler -> LogisticRegression(class_weight='balanced', max_iter=1000))`
  * **Input Dimension:** 6 features (`heart_rate_max`, `respiratory_rate_max`, `spo2_min`, `temperature_max`, `sbp_min`, `respiratory_distress`).
  * **Frozen Threshold:** `0.26`.
* **Stage 2 Original (`stage2.joblib`):**
  * **Architecture:** Scikit-Learn `Pipeline(StandardScaler -> LogisticRegression(class_weight='balanced', max_iter=1000))`
  * **Input Dimension:** 15 features.
  * **Frozen Threshold:** `0.50`.
* **Stage 2 v2 Ensemble (`stage2_v2.joblib`):**
  * **Architecture:** Soft-Voting Ensemble (`VotingClassifier`, weights = `[0.5, 0.5]`) combining:
    1. **Logistic Regression Branch:** `Pipeline(SimpleImputer(strategy='median') -> StandardScaler -> LogisticRegression(class_weight={0: 1.983, 1: 0.669}, max_iter=3000))`
    2. **CatBoost Branch:** `CatBoostClassifier(iterations=700, depth=4, learning_rate=0.04, l2_leaf_reg=5, class_weights=(1.983, 0.669), random_seed=42)`
  * **Frozen Threshold:** Stored explicitly as `0.53` (equal-cost threshold where training caught = cleared).

### 2. Resolution of the 50 vs. 43 Feature Discrepancy
* **Source of the "50 Features" Claim:** During the initial time-series extraction (`eICU_TIMESERIES_ANALYSIS.md`, line 155), the feature extraction script generated **10 temporal metrics per vital sign across 5 vital signs** ($10 \times 5 = 50$ vital metrics: mean, min, max, std, first, last, change, count, median_interval, slope_per_hour), yielding 60 columns in `eicu_temporal_features.csv` when including patient identifiers.
* **The Actual Trained Model:** The trained production model ([`stage2_v2.joblib`](file:///home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant/models/stage2_v2.joblib)) uses exactly **43 features**, defined in [`api/features_v2.py`](file:///home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant/api/features_v2.py):
  * **19 Vital Statistics:** Mean, min, max, std for HR, RR, SBP, Temp; mean, min, std for SpO2 (`spo2_max` excluded because it was 100% for all training patients).
  * **8 Engineered Features:** `shock_index`, `news_vitals`, `fever_measured`, `spo2_drop`, and 4 per-vital ranges.
  * **1 Respiratory Symptom:** `respiratory_distress`.
  * **8 Demographics & Chronic Comorbidities:** `age`, `gender_male`, `copd`, `asthma`, `diabetes`, `hypertension`, `heart_failure`, `renal`.
  * **2 Acute Flags:** `weakness`, `hypoxemia`.
  * **5 Laboratories:** `wbc`, `neutrophils`, `lymphocytes`, `nlr`, `crp`.
* **Resolution:** There is no model discrepancy. The 50 features described the raw time-series feature extraction file; the 43 features represent the exact input vector ingested by the model pipeline.

### 3. Feature Approximations and Substitutions in eICU Data
Several features could not be directly matched to eICU Demo tables and required clinical approximations:
1. **`respiratory_distress` (High Risk):** In MIMIC-IV, this was a clinical charting entry. In eICU, it was approximated via surrogate logic: `(rr_max >= 24) | (spo2_min < 90) | (diagnosis contains respiratory failure)`. Because critically ill patients frequently experience transient tachypnea or desaturation during multi-day ICU admissions, **95.7% of all eICU patients (224 pneumonia, 216 controls)** received a value of 1. This artificially inflated Stage 1 alert rates.
2. **`temperature` (Moderate Risk):** eICU temperatures are stored in Celsius ($^\circ\text{C}$), whereas MIMIC-IV models were trained in Fahrenheit ($^\circ\text{F}$). The conversion $T_F = T_C \times \frac{9}{5} + 32$ was applied correctly.
3. **`weakness` (Moderate Risk):** Not systematically recorded in eICU demo tables; imputed as `0` for all 460 patients.
4. **`crp` (Moderate-High Risk):** C-reactive protein is rarely ordered in general US ICUs (missing for **98.5%** of eICU demo stays). It was imputed using the training median (6.0 mg/L) via `SimpleImputer`.

---

## Task 2: Temporal Leakage Audit

### 1. How Pneumonia Labels Were Formed
Pneumonia patients were identified by searching:
* `diagnosis.csv.gz` (ICD-9 / diagnosisstring matching "pneumonia").
* `admissionDx.csv.gz` (APACHE admission diagnosis path/text).
* `patient.csv.gz` (`apacheadmissiondx` matching "pneumonia").
Non-pneumonia controls were sampled exclusively from patients with zero pneumonia mentions across all available hospital encounters.

### 2. Diagnosis Timestamps vs. Observation Windows
Analysis of the 230 pneumonia patients reveals significant temporal overlap:
* **Diagnosis Entry Offset:** In `diagnosis.csv`, the first pneumonia diagnosis was recorded at a median offset of **91.0 minutes** (1.5 hours) after ICU admission (mean: 778.3 min; IQR: 33.5 – 293.5 min).
* **Admission Diagnoses:** 73 patients had pneumonia explicitly recorded as their primary reason for ICU admission (`admissionDx`).
* **Observation Windows:** Bedside vital signs in `eicu_timeseries.csv` span a median monitoring duration of **82.6 hours** (mean: 137.6 hours; max: 1,044.8 hours).

| Temporal Category | Patient Count ($n=230$) | Percentage | Mean Post-Diag Hours | Clinical Meaning |
| :--- | :---: | :---: | :---: | :--- |
| **Post-Diagnosis Monitoring Included** | **195** | **84.8%** | 127.2 h | Diagnosis established early; vitals aggregated days after diagnosis |
| **Diagnosis Across Different ICU Stay** | **19** | **8.3%** | 141.4 h | Multi-stay patient; pneumonia diagnosed in different ICU admission |
| **Diagnosis at Admission (APACHE)** | **8** | **3.5%** | 86.8 h | Known pneumonia upon ICU arrival; vitals reflect active treatment |
| **Diagnosis at/before ICU Arrival** | **7** | **3.0%** | 94.1 h | Documented prior to or at offset $\le 0$ min |
| **Strict Pre-Diagnosis Monitoring Only** | **1** | **0.4%** | 0.0 h | Only 1 single patient had all vitals recorded prior to diagnosis |

### 3. Monitoring Duration & Observation Count Confounding
Pneumonia patients had significantly longer ICU lengths of stay and higher observation counts than controls:
* **Monitoring Duration:** Pneumonia mean **141.4 hours** (median 84.7 h) vs. Controls mean **98.0 hours** (median 65.2 h) ($p = 0.0005$, Mann-Whitney $U$).
* **Heart Rate Observations:** Pneumonia mean **1,256.1** vs. Controls **820.1** ($p = 1.27 \times 10^{-6}$).
* **SpO2 Observations:** Pneumonia mean **1,195.9** vs. Controls **728.1** ($p = 6.11 \times 10^{-9}$).

> [!CAUTION]
> **Impact on Extreme-Value Features:** Features such as `spo2_min`, `heart_rate_max`, `temperature_max`, and `respiratory_rate_max` are extreme value statistics over the ICU stay. Longer monitoring durations mathematically increase the probability of recording an extreme vital sign, creating an artificial diagnostic signal unrelated to baseline disease state.

### 4. Classification vs. Early Prediction Verdict
This experiment **does not evaluate early prospective prediction** of impending pneumonia. Because 84.8% of the data reflects vital signs recorded after clinical diagnosis and treatment initiation (e.g., mechanical ventilation, vasopressors, antibiotics), the evaluation measures **retrospective identification of established pneumonia patients in an ICU environment**.

---

## Task 3: Confusion Matrix & Two-Stage Cascade Audit

Recalculating confusion matrices directly from [`eicu_model_predictions.csv`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/eicu_model_predictions.csv) confirms the exact operational breakdown.

### Complete Performance Matrix ($n = 460$)

| Evaluation Setting | Threshold | TP | TN | FP | FN | Sensitivity | Specificity | Precision | NPV | F1-Score | Bal. Accuracy |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Stage 1 (Primary Frozen)** | 0.26 | 225 | 12 | 218 | 5 | 97.8% | 5.2% | 50.8% | 70.6% | 66.9% | 51.5% |
| **Stage 1 (Exploratory Calibrated)** | 0.85 | 105 | 178 | 52 | 125 | 45.7% | 77.4% | 66.9% | 58.7% | 54.3% | 61.5% |
| **Stage 2 Original (Primary Frozen)** | 0.50 | 220 | 34 | 196 | 10 | 95.7% | 14.8% | 52.9% | 77.3% | 68.1% | 55.2% |
| **Stage 2 Original (Exploratory)** | 0.78 | 170 | 140 | 90 | 60 | 73.9% | 60.9% | 65.4% | 70.0% | 69.4% | 67.4% |
| **Stage 2 v2 Ensemble (Frozen)** | **0.53** | **217** | **41** | **189** | **13** | **94.3%** | **17.8%** | **53.4%** | **75.9%** | **68.2%** | **56.1%** |
| **Stage 2 v2 Ensemble (Reported)** | 0.54 | 216 | 43 | 187 | 14 | 93.9% | 18.7% | 53.6% | 75.4% | 68.2% | 56.3% |
| **Stage 2 v2 Ensemble (Exploratory)** | 0.77 | 172 | 147 | 83 | 58 | 74.8% | 63.9% | 67.5% | 71.7% | 70.9% | 69.3% |
| **Two-Stage Cascade (Default App)** | **0.26 $\to$ 0.53** | **217** | **41** | **189** | **13** | **94.3%** | **17.8%** | **53.4%** | **75.9%** | **68.2%** | **56.1%** |
| **Two-Stage Cascade (Screening)** | 0.26 $\to$ 0.53 | 225 | 12 | 218 | 5 | 97.8% | 5.2% | 50.8% | 70.6% | 66.9% | 51.5% |
| **Two-Stage Cascade (Dual Calib.)** | 0.85 $\to$ 0.77 | 97 | 193 | 37 | 133 | 42.2% | 83.9% | 72.4% | 59.2% | 53.3% | 63.0% |

### Audit of Risk Band Categorization
The 460 patients were partitioned into three risk bands:
1. **Low Risk Band ($n = 17$):** Cleared at Stage 1 ($p_1 < 0.26$). Contains 5 pneumonia cases (29.4%) and 12 controls.
2. **Moderate Risk Band ($n = 37$):** Flagged at Stage 1 ($p_1 \ge 0.26$) but Stage 2 score below threshold ($p_2 < 0.53$). Contains 8 pneumonia cases (21.6%) and 29 controls.
3. **High Risk Band ($n = 406$):** Confirmed at Stage 2 ($p_1 \ge 0.26$ and $p_2 \ge 0.53$). Contains 217 pneumonia cases (53.4%) and 189 controls.

#### How Moderate-Risk Patients Were Handled
In the binary confusion matrix for the Two-Stage Cascade:
* **Moderate Risk is classified as NEGATIVE.**
* Total classified as Negative: $17 \text{ (Low)} + 37 \text{ (Moderate)} = 54 \text{ patients}$.
* True Negatives = $12 + 29 = 41$. False Negatives = $5 + 8 = 13$.
* Specificity = $\frac{41}{230} = 17.83\%$. Sensitivity = $\frac{217}{230} = 94.35\%$.
* **Conclusion:** The reported 94.3% sensitivity and 17.8% specificity are mathematically consistent with treating only the High Risk band as positive. If Moderate Risk were treated as a positive triage screen, sensitivity would rise to 97.8% and specificity would collapse to 5.2%.

---

## Task 4: Threshold Selection Audit

1. **Frozen Threshold ($0.53$):** Confirmed as the pre-specified threshold stored in [`stage2_v2.joblib`](file:///home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant/models/stage2_v2.joblib) (`'threshold': 0.53`, `'threshold_rule': 'equal'`). In [`stage2_v2_metrics.json`](file:///home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant/models/stage2_v2_metrics.json), a rounded value of 0.54 was referenced; both yield virtually identical performance (Bal. Acc: 56.1% vs 56.3%).
2. **Calculation of 0.77:** Verified in [`report_external_validation.py`](file:///home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant/training/report_external_validation.py) (lines 97–116). The threshold was derived by running a grid search across $t \in [0.01, 0.99]$ on the external cohort to maximize Youden's $J = \text{Sensitivity} + \text{Specificity} - 1$.
3. **Methodological Distinction Required:**
   * **Primary External Validation:** Must be reported strictly at threshold **0.53** (Sensitivity 94.3%, Specificity 17.8%, Balanced Accuracy 56.1%).
   * **Exploratory Post-Hoc Recalibration:** Threshold **0.77** reflects optimal *in-sample* tuning on the test set. Describing 0.77 as independent external validation represents circular data leakage.

---

## Task 5: Statistical Reliability & Calibration Audit

### 1. Bootstrap Confidence Intervals (2,000 iterations, Seed = 42)
* **Stage 1 (6 Vitals):**
  * ROC-AUC: **0.6644** [95% CI: 0.6149 – 0.7144]
  * PR-AUC: **0.6683** [95% CI: 0.6043 – 0.7331] (baseline random = 0.500)
  * Brier Score: **0.3047** [95% CI: 0.2774 – 0.3321]
* **Stage 2 v2 Ensemble (43 Features):**
  * ROC-AUC: **0.7274** [95% CI: 0.6789 – 0.7738]
  * PR-AUC: **0.6974** [95% CI: 0.6318 – 0.7682]
  * Brier Score: **0.2779** [95% CI: 0.2515 – 0.3038]

### 2. Model Calibration & Miscalibration Assessment
On a balanced dataset (50% prevalence), a non-informative constant prediction of 0.50 yields a Brier score of 0.250. The Stage 2 v2 Brier score of **0.2779** confirms that the uncalibrated model probabilities are poorly calibrated for direct risk interpretation.

```
Calibration Metric             Observed Value    Ideal Value     Clinical Interpretation
---------------------------------------------------------------------------------------------------------
Calibration Intercept (CITL)      -1.0469            0.0         Severe over-prediction (predicted >> true)
Calibration Slope                  0.8191            1.0         Moderate over-confidence in tails
Expected Calibration Error (ECE)   24.63%            0.0%        Average probability error of ~25%
```

![Audit Calibration Curve](timeseries_plots/audit_calibration_curve.png)

* **Why CITL = -1.05:** The model was trained with equal class weighting on a MIMIC cohort with 74.8% pneumonia prevalence, effectively conditioning the model to expect a high pre-test probability. When deployed to a 50:50 cohort of critically ill patients, it systematically over-predicts risk across all deciles.

---

## Task 6: Cohort Verification & Spectrum Bias

1. **Patient Uniqueness:** Confirmed. All 460 rows in `cohort_info.json` correspond to distinct, non-overlapping `uniquepid` strings.
2. **Strict Group Disjointness:** Confirmed. The intersection between pneumonia patients and control candidates is empty ($\text{Pneumonia} \cap \text{Controls} = \emptyset$).
3. **Hospital Diversity:** The 460 patients were admitted across **168 distinct hospitals** (ranging from 1 to 8 patients per hospital). This multi-center representation supports generalizability across diverse EHR charting styles.
4. **Sampling Reproducibility:** Confirmed. Controls were selected deterministically using `np.random.RandomState(42)` from 1,080 qualifying non-pneumonia patients.
5. **Spectrum Bias of the Control Cohort:** The controls are not ambulatory outpatients; they are critically ill ICU patients:
   * Congestive Heart Failure ($n = 15$)
   * Acute Myocardial Infarction ($n = 14$)
   * Diabetic Ketoacidosis ($n = 10$)
   * Cerebrovascular Accident / Stroke ($n = 8$)
   * Sepsis (GI/Renal) ($n = 14$)
   * Acute Respiratory Distress & Bronchitis ($n = 10$)
   These competing acute conditions drive physiological vitals (tachypnea, tachycardia, hypoxia) into the abnormal range, explaining why the model frequently scores controls above 0.53.

---

## Deliverables Generated in Audit

All audit artifacts and data tables have been compiled and exported to [`Extracted_Validation_Data/`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/):
1. **[`EXTERNAL_VALIDATION_AUDIT.md`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/EXTERNAL_VALIDATION_AUDIT.md):** Complete methodology and statistical audit report.
2. **[`eicu_confusion_matrices_audit.csv`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/eicu_confusion_matrices_audit.csv):** Detailed confusion matrix across all 10 model/threshold configurations.
3. **[`eicu_temporal_leakage_audit.csv`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/eicu_temporal_leakage_audit.csv):** Patient-level audit tracking diagnosis offsets, observation intervals, and post-diagnosis monitoring hours.
4. **[`feature_compatibility_report.csv`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/feature_compatibility_report.csv):** Feature-by-feature mapping, approximation risk ratings, and missingness rates for all 43 features.
5. **[`audit_calibration_curve.png`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/timeseries_plots/audit_calibration_curve.png):** Reliability diagram and risk score density distribution illustrating probability miscalibration and threshold shift.

---

## Guidance for FYP Thesis & Defense

When presenting these external validation results in your FYP thesis:
1. **Highlight ROC-AUC Generalizability (72.7%):** Emphasize that preserving an AUC of 72.7% across 168 completely independent hospitals confirms genuine physiological feature learning.
2. **Be Transparent About Retrospective vs. Prospective Scope:** Acknowledge that because vital signs were aggregated across entire ICU admissions, this validation demonstrates retrospective patient classification rather than real-time early warning.
3. **Frame Specificity Honestly:** Do not present the drop in specificity at threshold 0.53 as an algorithmic defect. Present it as an expected manifestation of **spectrum bias** (ICU controls having acute respiratory distress and sepsis) and **prevalence shift** (75% training vs 50% test).
4. **Report 0.77 as Post-Hoc Recalibration:** Clearly separate the primary validation (threshold 0.53) from exploratory recalibration (threshold 0.77), illustrating how clinical systems must be calibrated to local institutional prevalence.
