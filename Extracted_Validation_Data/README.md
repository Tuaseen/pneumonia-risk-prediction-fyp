# eICU External Validation: Retained Final Experiments

This directory contains the finalized, reproducible deliverables for the external validation of the frozen Stage 2 v2 pneumonia risk prediction model on the eICU Collaborative Research Database Demo cohort ($N = 460$: 230 Pneumonia cases, 230 Non-pneumonia controls across 168 hospitals).

Per the study protocol, the frozen model (`stage2_v2.joblib`) was kept strictly separate and unmodified in [`.../pneumonia-assistant/models/`](file:///home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant/models/). Exactly two experiments are retained in this repository:

---

## 1. Summary of Retained Experiments

| Dimension | Experiment 1: Primary External Validation | Experiment 2: Exploratory 24h Diagnostic Ablation |
|:---|:---|:---|
| **Directory** | [`1_primary_external_validation/`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/1_primary_external_validation/) | [`2_exploratory_24h_diagnostic_ablation/`](file:///home/tuaseen/Downloads/Extracted_Validation_Data/2_exploratory_24h_diagnostic_ablation/) |
| **Model** | Frozen Stage 2 v2 VotingClassifier | Same Frozen Stage 2 v2 VotingClassifier |
| **Decision Threshold** | **$\tau = 0.53$** (Frozen operating point) | **$\tau = 0.53$** (Exact same frozen threshold) |
| **Observation Window** | Entire ICU Stay (mean 108 hours) | **First 24 Hours of ICU Admission** ($t \in [0, 24\text{h}]$) |
| **Respiratory Distress** | Original Vital Surrogate Heuristic (95.7%) | **`NaN` (Unrecorded / native model imputation)** |
| **Diagnosis Information** | **Hybrid Rule:** Vital thresholds (`rr_max >= 24` \| `spo2_min < 90`) OR diagnosis table (`respiratory_distress_diag`) | **Zero Diagnosis Information:** Passed natively as `NaN` (no diagnosis strings used) |
| **ROC-AUC** | **0.7274** | **0.7322** |
| **PR-AUC** | **0.6977** | **0.7136** |
| **Brier Score** | **0.2779** | **0.2146** *(Lower overall probabilistic prediction error on cohort)* |
| **Sensitivity** | **94.35%** (217 / 230) | **74.78%** (172 / 230) |
| **Specificity** | **17.83%** (41 / 230) | **62.17%** (143 / 230) |
| **Balanced Accuracy** | **56.09%** | **68.48%** |
| **Precision (PPV)** | **53.45%** | **66.41%** |
| **Negative Predictive Value (NPV)** | **75.93%** | **71.14%** |
| **F1-Score** | **68.24%** | **70.35%** |
| **Confusion Matrix** | $\text{TP}=217, \text{TN}=41, \text{FP}=189, \text{FN}=13$ | $\text{TP}=172, \text{TN}=143, \text{FP}=87, \text{FN}=58$ |

---

## 2. Directory Structure

```
Extracted_Validation_Data/
├── 1_primary_external_validation/
│   ├── data/
│   │   ├── cohort_info.json                       # 460-patient cohort mapping
│   │   ├── eicu_model_ready_validation.csv        # Preprocessed raw inputs
│   │   └── features_43.csv                        # 43 model input features
│   ├── predictions/
│   │   └── eicu_model_predictions.csv             # Full-stay predictions
│   ├── metrics/
│   │   ├── primary_validation_metrics.json        # Complete metrics object
│   │   └── confusion_matrix.json                  # TP, TN, FP, FN counts
│   ├── scripts/
│   │   └── reproduce_primary_validation.py        # Independent reproduction script
│   └── PRIMARY_EXTERNAL_VALIDATION_REPORT.md      # Detailed experiment report
│
├── 2_exploratory_24h_diagnostic_ablation/
│   ├── data/
│   │   ├── cohort_info.json                       # 460-patient cohort mapping
│   │   ├── eicu_24h_model_ready.csv               # 24h preprocessed raw inputs
│   │   └── features_43_24h_ablation.csv           # 43 model input features (distress=NaN)
│   ├── predictions/
│   │   └── eicu_24h_ablation_predictions.csv      # 24h predictions
│   ├── metrics/
│   │   ├── ablation_metrics.json                  # Complete metrics object
│   │   └── confusion_matrix.json                  # TP, TN, FP, FN counts
│   ├── scripts/
│   │   └── reproduce_24h_ablation.py              # Independent reproduction script
│   └── 24H_DIAGNOSTIC_ABLATION_REPORT.md          # Detailed experiment report
│
├── archive/                                       # Archived temporary & exploratory files
│   ├── diagnosis_assisted_experiments/            # Retired post-diagnosis leak experiments
│   ├── threshold_077_exploratory/                 # Retired threshold-tuning sweeps
│   ├── audit_reports/                             # Preliminary technical audits
│   └── raw_timeseries/                            # Intermediate raw timeseries and plots
│
└── README.md                                      # This summary file
```

---

## 3. Reproduction Commands

Both experiments are completely self-contained and can be executed via `uv` or standard Python:

### Experiment 1: Primary External Validation
```bash
uv run --with pandas --with scikit-learn --with catboost --with joblib python 1_primary_external_validation/scripts/reproduce_primary_validation.py
```

### Experiment 2: Exploratory 24-Hour Diagnostic Ablation
```bash
uv run --with pandas --with scikit-learn --with catboost --with joblib python 2_exploratory_24h_diagnostic_ablation/scripts/reproduce_24h_ablation.py
```

---

## 4. Key Academic Lessons for FYP Thesis

1. **Pre-Registered Primary Benchmark (Experiment 1):**  
   Shows that the Stage 2 v2 model retained an ROC-AUC of 0.7274 across 168 external hospitals without fine-tuning, but operational specificity at $\tau = 0.53$ collapsed to 17.83% due to multi-day telemetry accumulation and proxy variable saturation.
2. **Diagnostic Ablation (Experiment 2):**  
   Proves that standardizing the observation window to the first 24 hours of ICU admission and removing the vital surrogate rule (`respiratory_distress = NaN`) recovers specificity from **17.83% to 62.17%** (+44.34%) and balanced accuracy from **56.09% to 68.48%** at the exact frozen threshold of 0.53 without any diagnosis leakage.
