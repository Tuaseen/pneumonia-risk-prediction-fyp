# eICU Time-Series Analysis & External Validation Dataset Report

**Project Title:** IoT-Based Early Pneumonia Risk Prediction Using Temporal Physiological Monitoring and Machine Learning  
**Dataset Analyzed:** eICU Collaborative Research Database Demo (v2.0.1)  
**Target Application:** Independent External Validation of MIMIC-IV-Trained Model  
**Output Directory:** `/home/tuaseen/.gemini/antigravity/scratch/eicu_validation/`  
**Generated Artifacts:**
- `eicu_timeseries.csv` (546,989 rows $\times$ 14 columns)
- `eicu_temporal_features.csv` (460 rows $\times$ 60 columns)
- `eicu_patient_summary.csv` (460 rows $\times$ 27 columns)
- `cohort_info.json` (460 verified patient mappings)
- `timeseries_plots/` (7 publication-ready PNG visualization figures)

---

## 1. Cohort Verification

The cohort extraction pipeline performed an exhaustive, deterministic audit across all 2,520 ICU stays and 1,841 unique patients in the eICU Demo database.

### Strict Patient Identification Criteria
- **Pneumonia Cohort:**
  - Diagnoses were queried across `diagnosis.csv.gz` (`diagnosisstring`, `icd9code`), `admissionDx.csv.gz` (`admitdxpath`, `admitdxname`), and `patient.csv.gz` (`apacheadmissiondx`).
  - Required an explicit, documented diagnosis of pneumonia (e.g., bacterial, viral, community-acquired, hospital-acquired, aspiration pneumonia).
  - Out of 256 unique explicit pneumonia patients in the entire demo dataset, **230 patients** fulfilled the multi-table vital sign requirement ($\ge 2$ timestamped readings for each of the 5 vital signs). These 230 patients represent **100% of all eligible pneumonia patients** in the database.
- **Non-Pneumonia Control Cohort:**
  - Selected from the 1,321 eligible patients who had **zero pneumonia diagnoses across all records** and possessed $\ge 2$ timestamped readings for all 5 vital signs.
  - Exactly **230 control patients** were sampled using a fixed random seed (`RandomState(42)`) to ensure exact scientific reproducibility.
- **Cohort Mutual Exclusivity:**
  $$\text{Pneumonia Cohort} \cap \text{Control Cohort} = \emptyset \quad (\text{Overlap} = 0)$$
  Any patient with even a single ambiguous or historical pneumonia diagnosis was permanently disqualified from the control pool to prevent label contamination.
- **Index Stay Mapping:**
  - 100% of the 460 selected patients ($460 / 460$) have their qualifying observations cleanly self-contained within their primary ICU stay (`patientunitstayid`).
  - No distinct hospital readmissions or disconnected stay timelines were artificially concatenated.

---

## 2. Number of Patients in Each Class & Demographics

| Demographic Metric | Pneumonia Class (Label = 1) | Non-Pneumonia Class (Label = 0) | Combined Cohort |
| :--- | :---: | :---: | :---: |
| **Unique Patients** | **230** (50.0%) | **230** (50.0%) | **460** (100.0%) |
| **Unique ICU Stays** | **230** | **230** | **460** |
| **Gender (Female / Male)** | 86 (37.4%) / 144 (62.6%) | 73 (31.7%) / 157 (68.3%) | 159 (34.6%) / 301 (65.4%) |
| **Mean Age $\pm$ Std** | $66.2 \pm 16.9$ years | $64.4 \pm 17.4$ years | $65.3 \pm 17.2$ years |
| **Median Age (IQR)** | 68.0 (57.0 – 79.0) | 67.0 (54.2 – 78.0) | 67.5 (55.0 – 78.0) |
| **Age Range** | 19.0 to 90.0 years | 17.0 to 90.0 years | 17.0 to 90.0 years |
| **Mean Monitoring Duration** | **141.4 hours** (5.89 days) | **98.0 hours** (4.08 days) | **119.7 hours** (4.99 days) |
| **Median Monitoring Duration** | **84.7 hours** (IQR: 43.8 – 189.9) | **65.2 hours** (IQR: 37.8 – 120.8) | **74.1 hours** (IQR: 40.5 – 156.4) |

*Observation:* Patients with pneumonia exhibit significantly longer ICU lengths of stay (median 84.7 h vs 65.2 h), reflecting increased clinical acuity and prolonged pulmonary support.

---

## 3. Time-Series Availability

The extracted time series consists of **546,989 genuine clinical observation timestamps** across the 460 patients.

### Observation Count per Patient Across the Five Vitals
| Vital Sign | Overall Total Measurements | Pneumonia Patient Mean (Median) | Control Patient Mean (Median) | Min Obs / Patient | Max Obs / Patient |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Heart Rate (HR)** | 477,529 | 1,256.1 (809.5) | 820.1 (499.0) | 12 | 13,355 |
| **SpO2** | 442,528 | 1,195.9 (764.5) | 728.1 (407.0) | 14 | 12,990 |
| **Respiratory Rate (RR)** | 450,138 | 1,187.9 (761.5) | 769.2 (471.5) | 9 | 12,863 |
| **Body Temperature** | 65,189 | 210.1 (20.5) | 73.4 (18.0) | 2 | 6,196 |
| **Systolic BP (SBP)** | 144,034 | 377.8 (136.5) | 248.5 (75.5) | 2 | 6,046 |

All 460 patients have extensive, longitudinal monitoring spanning days of ICU stay, readily fulfilling the requirement of multiple timestamped observations per vital sign.

---

## 4. Sampling Frequency for Each Vital Sign

The eICU dataset integrates telemetry from heterogeneous bedside systems, resulting in distinct physiological sampling frequencies:

1. **Heart Rate, SpO2, and Respiratory Rate (Bedside Telemetry Monitor):**
   - **Median sampling interval:** Exactly **5.0 minutes** across both cohorts.
   - Over 99% of consecutive monitor readings occur at the standard 5-minute telemetry epoch.
   - Provides dense, quasi-continuous temporal trajectories.
2. **Systolic Blood Pressure (Oscillometric Cuff / Arterial Line):**
   - **Median sampling interval:** **30.0 minutes** (Pneumonia) and **29.5 minutes** (Controls).
   - Reflects routine automated cuff cycling (typically every 15, 30, or 60 minutes depending on patient stability).
3. **Body Temperature (Bedside Nursing Assessment):**
   - **Median sampling interval:** Exactly **240.0 minutes (4.0 hours)** across both cohorts.
   - Reflects the standard clinical nursing shift protocol of intermittent oral/axillary/tympanic temperature checks every 4 hours.

---

## 5. Missing-Data Analysis & Temporal Alignment

### Row-Level Sparsity in `eicu_timeseries.csv`
Because the five vital signs are measured asynchronously by different modalities, row-level sparsity is an inherent property of raw ICU data:

| Column Name | Non-Null Rows | Row-Level Coverage (%) | Row-Level Missing (%) | Nature of Measurement |
| :--- | :---: | :---: | :---: | :--- |
| `offset_minutes` | 546,989 | 100.0% | 0.0% | Timeline index (minutes from admit) |
| `heart_rate` | 477,529 | 87.3% | 12.7% | 5-minute automated telemetry |
| `spo2` | 442,528 | 80.9% | 19.1% | 5-minute automated telemetry |
| `respiratory_rate` | 450,138 | 82.3% | 17.7% | 5-minute automated telemetry |
| `systolic_bp` | 144,034 | 26.3% | 73.7% | Intermittent cuff / invasive line |
| `temperature` | 65,189 | 11.9% | 88.1% | 4-hour nursing chart checks |

### Scientific Treatment of Temporal Alignment
> [!IMPORTANT]
> **No artificial simultaneous measurements were created.**
> In `eicu_timeseries.csv`, every measurement is positioned at its exact genuine timestamp (`offset_minutes`). At timestamps where only continuous telemetry fired (e.g. minute 10), `temperature` and `systolic_bp` remain `NaN` rather than being forward-filled or interpolated.

#### Alignment Strategies for Downstream Validation Models:
1. **Asynchronous Deep Learning (Recommended for modern models):** Feed the sparse multi-rate time series directly into architectures designed for irregular sampling (e.g., GRU-D, Continuous-Time LSTM, Transformer with temporal pos-encoding, or Neural ODEs) using observation masks $\mathbf{m}_t$ and time deltas $\Delta t$.
2. **Fixed-Grid Epoch Aggregation (Recommended for tabular / tree-based models):** Bin the timeline into uniform windows (e.g., 1-hour or 2-hour epochs) and compute statistical aggregates ($\text{mean}, \text{min}, \text{max}$). If a vital is unmeasured within a 1-hour bin, apply forward-filling with a maximum validity horizon (e.g., 4 hours for temperature, 2 hours for BP).

---

## 6. Temperature Unit Verification & Standardization

An essential clinical informatics finding emerged during the schema audit:

1. **`vitalPeriodic.csv.gz` Unit Ambiguity:**
   - Nominally documented as Celsius (°C), but **2.58% of values were $> 45.0$** (reaching up to $103.0^\circ\text{F}$).
   - These represent unflagged Fahrenheit monitor data ingested without unit conversion from certain hospital units.
2. **`nurseCharting.csv.gz` Paired Duplication:**
   - Bedside nurses charted temperatures under two simultaneous cell labels: `Temperature (C)` (61,880 rows) and `Temperature (F)` (61,880 rows).
   - In 61,879 cases, the Fahrenheit and Celsius readings occurred at the **exact same minute offset** for the same patient stay.
   - Blindly merging both would double-count every temperature measurement.

### Standardization Applied:
- Prioritized `Temperature (C)` from `nurseCharting` to preserve the exact clinician-entered Celsius reading.
- Where only Fahrenheit was available (or in `vitalPeriodic` values $> 45.0$), converted using:
  $$\text{Temp}_{^\circ\text{C}} = (\text{Temp}_{^\circ\text{F}} - 32.0) \times \frac{5}{9}$$
- Enforced a physiological validity filter ($20.0^\circ\text{C} \le \text{Temp} \le 45.0^\circ\text{C}$), discarding uncalibrated probe artifacts.

---

## 7. Blood Pressure Source Verification & Modality

In eICU, blood pressure is recorded across two distinct modalities:
1. **Invasive Arterial Catheter (`systemicsystolic` in `vitalPeriodic.csv.gz`):**
   - High-frequency 5-minute automated arterial line feed.
   - Present in 87 of the 460 patients (34 pneumonia, 53 controls).
   - Raw data contains zero/negative artifacts (down to $-44\text{ mmHg}$) from transducer flushing and leveling maneuvers. Filtered to $30 \le \text{SBP} \le 300\text{ mmHg}$.
2. **Non-Invasive Oscillometric Cuff (`noninvasivesystolic` in `vitalAperiodic.csv.gz`):**
   - Intermittent pneumatic cuff readings (every 15 to 60 minutes).
   - Present in 456 of the 460 patients.

### Patient Modality Distribution:
- **Non-Invasive Cuff Only:** 373 patients (195 Pneumonia, 178 Controls)
- **Both Modalities Recorded:** 83 patients (34 Pneumonia, 49 Controls)
- **Invasive Arterial Only:** 4 patients (1 Pneumonia, 3 Controls)

In `eicu_timeseries.csv`, the unified `systolic_bp` column combines both modalities (preferring calibrated arterial line readings when available, otherwise cuff), while `invasive_systolic_bp`, `noninvasive_systolic_bp`, and `sbp_source` preserve the exact provenance for every time-point.

---

## 8. Temporal Feature Calculations (`eicu_temporal_features.csv`)

For each of the 460 patients, 10 temporal features were calculated chronologically across all 5 vital signs (50 physiological features total), plus patient metadata:

| Vital Sign | Feature Name | Pneumonia Mean $\pm$ Std | Control Mean $\pm$ Std | Clinical Interpretation |
| :--- | :--- | :---: | :---: | :--- |
| **Heart Rate** | `hr_mean` (bpm) | $87.65 \pm 15.22$ | $83.48 \pm 14.81$ | Significantly elevated in pneumonia (tachycardia / SIRS) |
| | `hr_min` (bpm) | $63.26 \pm 14.73$ | $60.54 \pm 14.19$ | Elevated basal heart rate |
| | `hr_max` (bpm) | $116.89 \pm 22.01$ | $110.83 \pm 20.35$ | Higher tachycardic peaks |
| | `hr_std` (bpm) | $11.05 \pm 4.31$ | $10.12 \pm 4.15$ | Increased temporal heart rate variability |
| | `hr_slope_per_hour` | $-0.2505 \pm 0.81$ | $-0.0568 \pm 0.69$ | Negative trajectory reflecting ICU resuscitation response |
| **SpO2** | `spo2_mean` (%) | $95.59 \pm 2.61$ | $96.43 \pm 2.18$ | Lower oxygenation in pneumonia (impaired alveolar diffusion) |
| | `spo2_min` (%) | $82.50 \pm 8.74$ | $84.97 \pm 7.92$ | Deeper hypoxic desaturations |
| | `spo2_max` (%) | $99.78 \pm 0.64$ | $99.82 \pm 0.58$ | Supplemental oxygen ceilings |
| | `spo2_std` (%) | $3.21 \pm 1.62$ | $2.84 \pm 1.48$ | Greater oxygenation instability |
| | `spo2_slope_per_hour` | $-0.1832 \pm 0.52$ | $-0.0681 \pm 0.44$ | Steeper oxygen degradation over time |
| **Resp Rate** | `rr_mean` (breaths/min) | $21.59 \pm 4.88$ | $19.28 \pm 4.21$ | Prominent tachypnea in pneumonia cohort |
| | `rr_min` (breaths/min) | $11.23 \pm 4.25$ | $9.82 \pm 3.79$ | Elevated minimum ventilatory rate |
| | `rr_max` (breaths/min) | $35.41 \pm 8.92$ | $31.85 \pm 8.11$ | Elevated peak tachypneic excursions |
| | `rr_std` (breaths/min) | $4.82 \pm 1.76$ | $4.29 \pm 1.54$ | Higher respiratory variability |
| | `rr_slope_per_hour` | $-0.0569 \pm 0.28$ | $+0.0086 \pm 0.22$ | Downward trend post-ventilatory stabilization |
| **Temperature**| `temp_mean` (°C) | $36.86 \pm 0.58$ | $36.76 \pm 0.51$ | Slightly higher basal temperature in infection |
| | `temp_max` (°C) | $37.94 \pm 0.94$ | $37.64 \pm 0.83$ | Greater frequency of febrile episodes ($\ge 38.0^\circ\text{C}$) |
| | `temp_change` (°C) | $+0.08 \pm 0.74$ | $-0.04 \pm 0.66$ | Positive temperature change over stay |
| **Systolic BP**| `sbp_mean` (mmHg) | $119.06 \pm 15.68$ | $123.86 \pm 16.42$ | Lower systemic perfusion pressure in pneumonia (septic vasodilation) |
| | `sbp_min` (mmHg) | $82.74 \pm 17.51$ | $87.12 \pm 18.25$ | More pronounced hypotensive dips |
| | `sbp_max` (mmHg) | $162.34 \pm 23.41$ | $166.12 \pm 22.89$ | Peak pressures |

---

## 9. Data-Quality Issues & Cleaning Log

1. **Extreme Sensor Artifacts Filtered:**
   - Heart Rate $< 20$ or $> 260\text{ bpm}$ set to NaN (leads disconnected).
   - SpO2 $< 50\%$ set to NaN (pulse oximeter motion displacement / perfusion loss).
   - Respiratory Rate $< 4$ or $> 80\text{ breaths/min}$ set to NaN (impedance pneumography motion artifacts).
   - Invasive Systolic BP $< 30\text{ mmHg}$ set to NaN (unzeroed arterial transducer artifacts, negative values down to $-44\text{ mmHg}$).
   - Temperature $< 20.0^\circ\text{C}$ or $> 45.0^\circ\text{C}$ set to NaN.
2. **Duplicate Timestamps Resolved:**
   - In `vitalAperiodic.csv.gz`, repeated cuff attempts within the same minute offset were aggregated by averaging valid numeric values.
   - In `nurseCharting.csv.gz`, paired `Temperature (F)` and `Temperature (C)` entries recorded simultaneously were deduplicated.
3. **No Synthetic Value Generation:**
   - Missing rows remain empty (NaN). No artificial numbers were hallucinated.

---

## 10. Visualizations Generated

All visualization artifacts have been saved in [`timeseries_plots/`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots):

1. **[`hr_timeseries.png`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots/hr_timeseries.png):** 48-hour longitudinal heart rate trajectory comparing representative pneumonia patients (`010-10505`, `027-101368`) against non-pneumonia controls (`024-12045`, `018-102555`). Shows persistent tachycardia in pneumonia.
2. **[`spo2_timeseries.png`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots/spo2_timeseries.png):** 48-hour SpO2 trajectory demonstrating acute hypoxic desaturations ($< 90\%$) in pneumonia cases.
3. **[`rr_timeseries.png`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots/rr_timeseries.png):** Respiratory rate trajectory displaying tachypneic spikes ($> 25\text{ breaths/min}$) in pneumonia patients.
4. **[`temp_timeseries.png`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots/temp_timeseries.png):** Intermittent temperature trajectory displaying febrile episodes ($> 38.0^\circ\text{C}$) in pneumonia cases versus stable normothermia in controls.
5. **[`sbp_timeseries.png`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots/sbp_timeseries.png):** Systolic blood pressure trajectory showing hemodynamic fluctuations.
6. **[`sampling_intervals_distribution.png`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots/sampling_intervals_distribution.png):** Boxplot comparison of sampling intervals illustrating the multi-modal nature of ICU data (5 min for periodic vitals, 30 min for BP, 240 min for temperature).
7. **[`multimodal_patient_timeline.png`](file:///home/tuaseen/.gemini/antigravity/scratch/eicu_validation/timeseries_plots/multimodal_patient_timeline.png):** 5-panel synchronous physiological timeline for a single representative pneumonia patient showing concurrent trends across all five vital signs with clinical threshold baselines.

---

## 11. Suitability for External Validation Against MIMIC-IV

### Commonalities with MIMIC-IV
- **Physiological Feature Parity:** The five key IoT vitals (HR, SpO2, RR, Temp, SBP) are clinically identical in meaning, scale, and physiological relevance between MIMIC-IV and eICU.
- **Dynamic Response Patterns:** Pneumonia patients in eICU exhibit the exact cardinal triad observed in MIMIC-IV: elevated resting heart rate, elevated respiratory rate (tachypnea), and reduced/unstable SpO2.
- **Genuine Time Series:** eICU provides authentic multi-day longitudinal monitoring with exact minute-level offsets.

### Structural Differences to Account for During Validation
1. **Time-Series Density & Table Architecture:**
   - In MIMIC-IV, vitals reside in `chartevents` with variable charting intervals (typically 1 hour for routine vitals).
   - In eICU, automated monitor telemetry (`vitalPeriodic`) is sampled every **5 minutes**, while temperature is charted in `nurseCharting` every **4 hours**.
   - *Recommendation:* If your MIMIC-IV model expects 1-hour uniform vectors, aggregate the eICU data into 1-hour median/mean bins before feeding it into the model.
2. **Temperature and BP Modalities:**
   - MIMIC-IV consolidates invasive and non-invasive BP into specific `itemid`s. In eICU, cuff BP (`vitalAperiodic`) and arterial BP (`vitalPeriodic`) must be combined, as done in `eicu_timeseries.csv`.
3. **Cohort Size on Demo Data:**
   - The eICU Demo dataset yields exactly **230 pneumonia patients vs 230 control patients** (460 patients total).
   - This sample is statistically robust for a pilot external validation benchmark (calculating AUROC, AUPRC, sensitivity, specificity, and calibration curves).
   - For definitive clinical trials, the identical pipeline should be executed on the **full eICU Collaborative Research Database** (v2.0, >200,000 stays).

---

## Verification Checklist

- [x] 230 unique pneumonia patients verified.
- [x] 230 unique non-pneumonia patients verified.
- [x] Cohorts are strictly mutually exclusive (0 overlap).
- [x] All 5 vital signs present for each patient with $\ge 2$ observations.
- [x] Genuine recorded measurements preserved (no synthetic data generated).
- [x] Accurate temperature unit conversion applied (Celsius standardized).
- [x] SBP modalities (invasive vs non-invasive) fully documented and preserved.
- [x] Asynchronous timestamps kept intact (no arbitrary interpolation).
- [x] 50 temporal features calculated across all 5 vitals.
- [x] 7 visualization plots generated.
- [x] No ML models trained or modified.
