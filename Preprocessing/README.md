# Data Preprocessing & Cohort Extraction Pipeline

This directory contains the complete end-to-end data extraction, preprocessing, and feature engineering pipeline for the Final Year Project: **IoT-Integrated AI System for Pneumonia Risk Prediction Using Temporal Physiological Monitoring and Machine Learning**.

---

## Data Not Included

The MIMIC-IV data use agreement does not allow MIMIC-derived records to be shared, so the CSV files
named below (`patient_list.csv`, `patient_features.csv`, `merged_with_symptoms*.csv`,
`pneumonia_dataset_final.csv`, `pneumonia_dataset_with_labs*.csv`) are not stored in this repository.
They are rebuilt by running the two notebooks against a local copy of MIMIC-IV, and the
`.gitignore` keeps them out of future commits. The trained model files in
`pneumonia-assistant-main/pneumonia-assistant/models/` are included.

---

## Pipeline Overview

```
MIMIC-IV Raw Database
       │
       ▼ (Step 1: FYPpneumonia.ipynb)
Cohort Definition, Vital Signs Extraction & Comorbidity Merging
       │
       ▼
pneumonia_dataset_final.csv
       │
       ▼ (Step 2: pneumoniaLab.ipynb via DuckDB)
Laboratory Extraction (WBC, Neutrophils, Lymphocytes, CRP)
       │
       ▼
pneumonia_dataset_with_labs.csv (7,647 patients × 48 features)
       │
       ▼
Model Training (pneumonia-assistant-main/training)
```

---

## Directory Structure

* **`pneumoniaLab.ipynb`**:
  - **Purpose:** Stage 2 lab extraction and integration notebook.
  - Uses DuckDB to query large MIMIC-IV `labevents.csv` and `d_labitems.csv` files efficiently.
  - Extracts key laboratory biomarkers:
    - **WBC** (White Blood Cell Count)
    - **Neutrophils** (%)
    - **Lymphocytes** (%)
    - **CRP** (C-Reactive Protein)
  - Merges labs with physiological vitals to generate `pneumonia_dataset_with_labs.csv`.

* **`pneumonia_dataset_with_labs.csv`**:
  - **Purpose:** The final curated training dataset (7,647 patient records, 48 features).
  - Feeds directly into the two-stage machine learning training scripts (`train_stage2_v2.py`).

* **`IOT Pneumonia/`** (extracted from `IOT Pneumonia.zip`):
  - **`FYPpneumonia.ipynb`**: Cohort extraction, physiological vital sign aggregation, longitudinal trajectory feature calculation, and symptom mapping notebook.
  - **`patient_list.csv`**: Selected adult patient cohort matching inclusion/exclusion criteria.
  - **`patient_features.csv`**: Aggregated vital stats (min, mean, max, trend) across monitoring windows.
  - **`merged_with_symptoms.csv`**: Joined demographic, comorbidity, and clinical symptom records.
  - **`pneumonia_dataset_final.csv`**: Pre-lab consolidated dataset.
  - **`vitals_raw.csv` & `vitals_progress.csv`**: Intermediate temporal telemetry streams.
  - **`correlation_matrix_step9.png` & `feature_importance_step9.png`**: Exploratory correlation and feature ranking visualizations.

* **`IOT Pneumonia.zip`**:
  - Original compressed archive of the vital sign preprocessing workspace preserved for archive integrity.
