# Machine Learning-Based Pneumonia Risk Prediction Using Temporal Physiological Data

Final Year Project (FYP) repository containing the complete end-to-end clinical machine learning pipeline, REST inference backend, and cross-platform Flutter clinical companion.

---

## Repository Structure

```
FYP/
├── pneumonia-assistant/                 # Cross-platform Flutter Application (Client)
│   ├── lib/                             # Application source code (Patient portal, Doctor workspace)
│   ├── test/                            # Comprehensive UI and unit test suites
│   ├── run_app.sh                       # One-click startup script (Backend + Flutter)
│   └── pubspec.yaml                     # Flutter package dependencies
│
├── pneumonia-assistant-main/            # FastAPI ML Backend & Model Training
│   ├── pneumonia-assistant/
│   │   ├── app.py                       # FastAPI application entrypoint
│   │   ├── api/                         # REST inference endpoints (/assess/stage1, /assess/stage2, /chat)
│   │   ├── models/                      # Serialized ML models (stage1.joblib; stage2_v2_temp_corrected.joblib = Model V2, deployed; stage2_v2.joblib = Model V1, archived)
│   │   ├── agent/                       # Clinical conversational assistant logic
│   │   └── training/                    # Model training, ablation, and evaluation scripts
│   └── data/                            # Linked preprocessed training dataset
│
├── Preprocessing/                       # Data Extraction & Feature Engineering
│   ├── pneumoniaLab.ipynb               # Stage 2: MIMIC-IV DuckDB lab extraction (WBC, Neutrophils, Lymphocytes, CRP)
│   ├── (MIMIC-derived CSVs)             # Not in this repo; rebuilt locally by the notebooks (see Preprocessing/README.md)
│   ├── IOT Pneumonia/                   # Stage 1: Cohort selection & vital sign aggregation
│   │   └── FYPpneumonia.ipynb           # Vital trajectory extraction notebook
│   └── README.md                        # Documentation of the extraction pipeline
│
└── Extracted_Validation_Data/           # External Clinical Validation & Research
    ├── 1_primary_external_validation/   # eICU Collaborative Research Database validation splits
    └── 2_exploratory_24h_diagnostic_ablation/ # 24-hour temporal vital ablation experiments
```

---

## Quick Start

### 1. Prerequisites
- Python 3.10+
- Flutter SDK (Dart 3.13.4+)
- Chrome / Chromium or Linux Desktop build tools

### 2. Run Everything (One-Click)
```bash
cd pneumonia-assistant
./run_app.sh
```
This automatically starts the FastAPI backend on port 8000, loads the trained ML models, and launches the Flutter application.

---

## Two-Stage Machine Learning Pipeline
1. **Stage 1 (Community / Daily Triage):** Evaluates non-invasive physiological vitals (SpO₂, Respiratory Rate, Heart Rate, Temperature, Blood Pressure) and symptoms (Dyspnea, Cough, Fever, Fatigue) to provide early screening.
2. **Stage 2 (Clinical Biomarker Risk Scoring):** Incorporates inflammatory laboratory biomarkers (WBC, Neutrophil %, Lymphocyte %, CRP) and multi-day vital trajectory changes to estimate calibrated clinical risk and hemodynamic shock index.
