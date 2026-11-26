import pandas as pd
from pathlib import Path

out_dir = Path('/home/tuaseen/Downloads/Extracted_Validation_Data/low_specificity_audit')
out_dir.mkdir(parents=True, exist_ok=True)

# 1. Feature Compatibility Audit CSV
features_data = [
    # Vitals HR
    ('heart_rate_mean', 'Vital Signs (HR)', 'bpm', 'chartevents', 'vitalPeriodic', 'Exact (continuous vs periodic telemetry)', 'Compatible', 'Secondary contributor (tachycardia in sepsis/shock)'),
    ('heart_rate_min', 'Vital Signs (HR)', 'bpm', 'chartevents', 'vitalPeriodic', 'Exact', 'Compatible', 'Low impact'),
    ('heart_rate_max', 'Vital Signs (HR)', 'bpm', 'chartevents', 'vitalPeriodic', 'Exact (sampling density increases extreme max in longer stays)', 'Minor divergence', 'Moderate contributor (max HR 118 in FP vs 100 in TN)'),
    ('heart_rate_std', 'Vital Signs (HR)', 'bpm', 'chartevents', 'vitalPeriodic', 'Exact', 'Compatible', 'Low impact'),
    # Vitals RR
    ('respiratory_rate_mean', 'Vital Signs (RR)', 'breaths/min', 'chartevents', 'vitalPeriodic', 'Exact', 'Compatible', 'Major contributor (mean RR 19.9 in FP vs 16.7 in TN)'),
    ('respiratory_rate_min', 'Vital Signs (RR)', 'breaths/min', 'chartevents', 'vitalPeriodic', 'Exact', 'Compatible', 'Low impact'),
    ('respiratory_rate_max', 'Vital Signs (RR)', 'breaths/min', 'chartevents', 'vitalPeriodic', 'Exact (continuous 5-min charting catches transient tachypnea)', 'Minor divergence', 'Major contributor (max RR 36.3 in FP vs 26.5 in TN)'),
    ('respiratory_rate_std', 'Vital Signs (RR)', 'breaths/min', 'chartevents', 'vitalPeriodic', 'Exact', 'Compatible', 'Low impact'),
    # Vitals SBP
    ('sbp_mean', 'Vital Signs (SBP)', 'mmHg', 'chartevents', 'vitalAperiodic + vitalPeriodic', 'Exact (invasive + non-invasive pooled)', 'Compatible', 'Low impact'),
    ('sbp_min', 'Vital Signs (SBP)', 'mmHg', 'chartevents', 'vitalAperiodic + vitalPeriodic', 'Exact (hypotension in sepsis/shock)', 'Minor divergence', 'Major contributor (min SBP 81.5 in FP vs 99.8 in TN)'),
    ('sbp_max', 'Vital Signs (SBP)', 'mmHg', 'chartevents', 'vitalAperiodic + vitalPeriodic', 'Exact', 'Compatible', 'Low impact'),
    ('sbp_std', 'Vital Signs (SBP)', 'mmHg', 'chartevents', 'vitalAperiodic + vitalPeriodic', 'Exact', 'Compatible', 'Low impact'),
    # Vitals SpO2
    ('spo2_mean', 'Vital Signs (SpO2)', '%', 'chartevents', 'vitalPeriodic', 'Exact (mean SpO2 96.3% in FP vs 96.9% in TN)', 'Compatible', 'Low impact'),
    ('spo2_min', 'Vital Signs (SpO2)', '%', 'chartevents', 'vitalPeriodic', 'Discrepant (5-min telemetry catches sensor drops; 27.4% < MIMIC min)', 'Major discrepancy', 'Critical driver (min SpO2 80.7% in FP vs 91.4% in TN, SMD=-1.00)'),
    ('spo2_std', 'Vital Signs (SpO2)', '%', 'chartevents', 'vitalPeriodic', 'Exact', 'Compatible', 'Low impact'),
    # Vitals Temp
    ('temperature_mean', 'Vital Signs (Temp)', 'deg F', 'chartevents (°F)', 'nurseCharting + vitalPeriodic (°C -> °F)', 'Converted correctly via affine T_F = T_C * 9/5 + 32', 'Compatible', 'Low impact'),
    ('temperature_min', 'Vital Signs (Temp)', 'deg F', 'chartevents (°F)', 'nurseCharting + vitalPeriodic (°C -> °F)', 'Converted correctly', 'Compatible', 'Low impact'),
    ('temperature_max', 'Vital Signs (Temp)', 'deg F', 'chartevents (°F)', 'nurseCharting + vitalPeriodic (°C -> °F)', 'Converted correctly', 'Compatible', 'Moderate contributor (max temp 99.6 in FP vs 98.5 in TN)'),
    ('temperature_std', 'Vital Signs (Temp)', 'deg F', 'chartevents (°F)', 'nurseCharting + vitalPeriodic (°C -> °F)', 'Converted correctly (std scaled by 9/5)', 'Compatible', 'Low impact'),
    # Engineered
    ('shock_index', 'Engineered Index', 'ratio (HR_max/SBP_min)', 'features_v2.py', 'features_v2.py', 'Identical logic; driven higher by low SBP and high HR in ICU shock', 'Compatible', 'Major contributor (shock index 1.65 in FP vs 1.09 in TN)'),
    ('news_vitals', 'Engineered Score', 'integer points (0-15)', 'features_v2.py', 'features_v2.py', 'Identical logic; strongly elevated in acute ICU controls', 'Compatible', 'Critical driver (NEWS 10.35 in FP vs 6.44 in TN, SMD=+1.90)'),
    ('fever_measured', 'Engineered Flag', 'binary (0/1)', 'features_v2.py', 'features_v2.py', 'Identical logic (T_max >= 100.4 F)', 'Compatible', 'Moderate contributor (fever in 25.4% of FP vs 4.9% in TN)'),
    ('spo2_drop', 'Engineered Drop', '% (mean - min)', 'features_v2.py', 'features_v2.py', 'Identical logic; heavily inflated by low SpO2_min from continuous telemetry', 'Major discrepancy', 'Critical driver (drop 15.6% in FP vs 5.5% in TN, SMD=+0.97)'),
    ('heart_rate_range', 'Engineered Range', 'bpm (max - min)', 'features_v2.py', 'features_v2.py', 'Identical logic; wider in longer ICU stays', 'Minor divergence', 'Moderate contributor'),
    ('respiratory_rate_range', 'Engineered Range', 'breaths/min', 'features_v2.py', 'features_v2.py', 'Identical logic', 'Minor divergence', 'Major contributor (range 26.7 in FP vs 15.9 in TN)'),
    ('sbp_range', 'Engineered Range', 'mmHg', 'features_v2.py', 'features_v2.py', 'Identical logic', 'Minor divergence', 'Moderate contributor (range 91.5 in FP vs 69.4 in TN)'),
    ('temperature_range', 'Engineered Range', 'deg F', 'features_v2.py', 'features_v2.py', 'Identical logic', 'Compatible', 'Moderate contributor'),
    # Symptoms & Clinical Flags
    ('respiratory_distress', 'Clinical Flag', 'binary (0/1)', 'Explicit clinical intake flag in MIMIC-IV', 'Surrogate rule: (rr_max >= 24) | (spo2_min < 90) | (diag string)', 'INCOMPATIBLE: Saturated to 100% in FP controls (216/230 in controls)', 'Saturated / Incompatible', 'PRIMARY DRIVER: Saturated in 189/189 FP controls; dominant model weight'),
    ('hypoxemia', 'Clinical Flag', 'binary (0/1)', '(spo2_min < 90) | flag', '(spo2_min < 90)', 'Surrogate rule triggered by pulseox drops', 'Minor divergence', 'Critical driver (hypoxemia in 74.6% of FP vs 9.8% in TN)'),
    ('weakness', 'Clinical Flag', 'binary (0/1)', 'Patient-reported symptom', 'Not charted in eICU; arbitrarily hardcoded to 0', 'Unrecorded / Zeroed', 'Missingness discrepancy', 'Neutral (set to 0 for all patients)'),
    # Demographics
    ('age', 'Demographics', 'years', 'admissions/patients', 'patient.csv (>89 mapped to 90.0)', 'Exact', 'Compatible', 'Low impact (mean age 62.4 in FP vs 63.2 in TN)'),
    ('gender_male', 'Demographics', 'binary (0/1)', 'patients', 'patient.csv (Male=1, Female=0)', 'Exact', 'Compatible', 'Low impact (male 65.1% in FP vs 65.9% in TN)'),
    # Chronic Conditions
    ('copd', 'Chronic Comorbidity', 'binary (0/1)', 'ICD-9/10 admission codes', 'diagnosis.csv + pastHistory.csv keyword matching', 'Comparable string mapping', 'Compatible', 'Minor contributor (COPD in 19.0% of FP vs 7.3% in TN)'),
    ('asthma', 'Chronic Comorbidity', 'binary (0/1)', 'ICD-9/10 admission codes', 'diagnosis.csv + pastHistory.csv keyword matching', 'Comparable string mapping', 'Compatible', 'Low impact (asthma in 7.9% of FP vs 2.4% in TN)'),
    ('diabetes', 'Chronic Comorbidity', 'binary (0/1)', 'ICD-9/10 admission codes', 'diagnosis.csv + pastHistory.csv keyword matching', 'Comparable string mapping', 'Compatible', 'Neutral (diabetes in 34.4% of FP vs 36.6% in TN)'),
    ('hypertension', 'Chronic Comorbidity', 'binary (0/1)', 'ICD-9/10 admission codes', 'diagnosis.csv + pastHistory.csv keyword matching', 'Comparable string mapping', 'Compatible', 'Neutral (hypertension in 54.0% of FP vs 53.7% in TN)'),
    ('heart_failure', 'Chronic Comorbidity', 'binary (0/1)', 'ICD-9/10 admission codes', 'diagnosis.csv + pastHistory.csv keyword matching', 'Comparable string mapping', 'Compatible', 'Minor contributor (HF in 18.5% of FP vs 14.6% in TN)'),
    ('renal', 'Chronic Comorbidity', 'binary (0/1)', 'ICD-9/10 admission codes', 'diagnosis.csv + pastHistory.csv keyword matching', 'Comparable string mapping', 'Compatible', 'Moderate contributor (renal in 27.5% of FP vs 12.2% in TN)'),
    # Laboratories
    ('wbc', 'Laboratory', 'K/uL', 'labevents', 'lab.csv (WBC x 1000)', 'Exact units; stay-level average vs admission', 'Compatible', 'Moderate contributor (WBC 11.0 in FP vs 9.4 in TN)'),
    ('neutrophils', 'Laboratory', '%', 'labevents', 'lab.csv (-polys)', 'Exact units; stay-level average vs admission', 'Compatible', 'Moderate contributor (neutrophils 75.3% in FP vs 71.3% in TN)'),
    ('lymphocytes', 'Laboratory', '%', 'labevents', 'lab.csv (-lymphs)', 'Exact units; stay-level average vs admission', 'Compatible', 'Moderate contributor (lymphocytes 13.5% in FP vs 16.5% in TN)'),
    ('nlr', 'Laboratory', 'ratio (neut/lymph)', 'features_v2.py', 'features_v2.py', 'Derived ratio; elevated in severe inflammation/sepsis', 'Compatible', 'Moderate contributor (NLR 8.8 in FP vs 6.1 in TN)'),
    ('crp', 'Laboratory', 'mg/L vs mg/dL', 'labevents (mg/L)', 'lab.csv (mg/dL for standard, mg/L for CRP-hs)', 'INCOMPATIBLE: Unit mismatch (x10 factor) + 94.3% missing; imputed as median 6.0', 'Major discrepancy', 'Secondary contributor (imputed as median 6.0 for 94% of cohort)')
]

df_compat = pd.DataFrame(features_data, columns=[
    'feature_name', 'category', 'expected_units', 'mimic_source', 'eicu_source',
    'extraction_methodology_and_divergence', 'semantic_compatibility_rating', 'role_in_driving_low_specificity'
])
df_compat.to_csv(out_dir / 'feature_compatibility_audit.csv', index=False)
print("Saved feature_compatibility_audit.csv")

# 2. Root Cause Findings CSV
root_causes = [
    (1, 'Surrogate Respiratory Distress Saturation', 'Feature Incompatibility / Extraction Defect', 'Yes (Confirmed by Direct Code & Data Evidence)',
     'Respiratory distress surrogate rule (rr_max>=24 | spo2_min<90 | diag) triggered in 189/189 (100.0%) of False Positive controls and 440/460 (95.7%) overall. In MIMIC training, it was present in only 51.7% of patients and has the single highest feature importance in the model.',
     'CRITICAL', 'Replace surrogate rule with strict clinical charting flag or set unrecorded symptom to NaN for native model imputation.'),
     
    (2, 'Spectrum Bias of ICU Non-Pneumonia Controls', 'Cohort Selection / Clinical Population Shift', 'Yes (Confirmed by Direct Clinical Diagnoses Evidence)',
     'eICU controls are not healthy individuals; they are critically ill ICU patients with Septic Shock (n=14), Congestive Heart Failure (n=15), DKA (n=10), Acute MI (n=14), and Bronchitis/COPD (n=11). 14/15 CHF, 14/14 Sepsis, and 9/10 DKA patients were classified as False Positives due to real systemic tachycardia, tachypnea, and hypotension.',
     'CRITICAL', 'Evaluate external validation against true ambulatory outpatients or mild inpatient respiratory controls; document spectrum bias in thesis.'),
     
    (3, 'Extreme-Value Vital Inflation via Continuous Telemetry & Long Stays', 'Temporal & Observation Window Bias', 'Yes (Confirmed by Duration & Sampling Evidence)',
     'FP controls had mean monitoring duration of 107.7 hours (vs 53.2 hours in TN controls, p<0.0001) with thousands of 5-min readings. Extreme-value features (spo2_min, rr_max, sbp_min, spo2_drop, shock_index) were mathematically driven to extremes over 4-day stays, causing NEWS score to reach 10.35 in FP controls (vs 6.44 in TN).',
     'MAJOR', 'Standardize observation windows to a fixed 24-hour admission window rather than entire multi-day ICU stays.'),
     
    (4, 'Prior Probability Shift & Unadjusted Frozen Threshold (0.53)', 'Prior Prevalence Mismatch', 'Yes (Confirmed by Bayesian Odds & Calibration Evidence)',
     'Model was trained on 74.79% pneumonia prevalence with balanced class weights. At frozen threshold 0.53, model assumes a high prior probability of pneumonia. Adjusting the threshold to 0.77 (matching balanced 50% cohort) recovers specificity from 17.83% to 63.91% with balanced accuracy 69.35%.',
     'MAJOR', 'Apply prevalence-adaptive Bayesian threshold recalibration for balanced or low-prevalence deployment settings.'),
     
    (5, 'Lab Discrepancies & CRP Unit Mismatch', 'Laboratory Incompatibility', 'Yes (Confirmed by Unit and Missingness Inspection)',
     'CRP was charted in mg/dL in eICU (vs mg/L in MIMIC) without unit conversion, reaching values up to 2,840 mg/dL. However, 94.35% of eICU patients lacked CRP and were filled with training median 6.0 mg/L, dampening the net impact of the unit error across the cohort.',
     'MODERATE', 'Apply unit conversion (x10 for mg/dL) and test model performance on lab-complete subsets.'),
     
    (6, 'Arbitrary Zeroing of Missing Symptom (Weakness)', 'Missingness Handling Defect', 'Yes (Confirmed by prepare_validation_data.py Inspection)',
     'Weakness was unrecorded in eICU structured tables and silently set to 0 for all 460 patients. While this did not push scores up, it artificially eliminated a feature that differentiates pneumonia from other acute conditions.',
     'MINOR', 'Pass missing symptoms as np.nan to utilize CatBoost and SimpleImputer native missing-value branches.')
]

df_rc = pd.DataFrame(root_causes, columns=[
    'rank', 'suspected_cause_or_hypothesis', 'category', 'confirmation_status',
    'key_quantitative_evidence', 'impact_on_low_specificity', 'recommended_action'
])
df_rc.to_csv(out_dir / 'root_cause_findings.csv', index=False)
print("Saved root_cause_findings.csv")
