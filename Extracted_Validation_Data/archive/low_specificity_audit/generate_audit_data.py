import sys
import os
from pathlib import Path
import json
import numpy as np
import pandas as pd
from scipy import stats

ROOT = Path('/home/tuaseen/Downloads/pneumonia-assistant-main/pneumonia-assistant')
sys.path.insert(0, str(ROOT))
from api import features_v2
from training.train_stage2_v2 import clean, SEED
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix, recall_score, precision_score, f1_score, balanced_accuracy_score, roc_auc_score, average_precision_score

out_dir = Path('/home/tuaseen/Downloads/Extracted_Validation_Data/low_specificity_audit')

# 1. Load MIMIC-IV training and test datasets
raw_mimic = pd.read_csv('/home/tuaseen/Downloads/pneumonia_dataset_with_labs.csv')
X, y = raw_mimic.drop(columns=['hadm_id', 'pneumonia_label']), raw_mimic['pneumonia_label']
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.20, stratify=y, random_state=SEED)

df_mimic_tr = clean(X_tr)
df_mimic_te = clean(X_te)
y_tr = y_tr.reset_index(drop=True)
y_te = y_te.reset_index(drop=True)

# 2. Load eICU model ready and predictions
df_eicu_ready = pd.read_csv('/home/tuaseen/.gemini/antigravity/scratch/eicu_validation/eicu_model_ready_validation.csv')
df_eicu_feats = features_v2.build(df_eicu_ready)
y_eicu = df_eicu_ready['label'].values

df_preds = pd.read_csv('/home/tuaseen/Downloads/Extracted_Validation_Data/eicu_model_predictions.csv')
p2_scores = df_preds['stage2_v2_risk_score'].values

# Also load eicu_temporal_features.csv for monitoring durations
df_eicu_temp = pd.read_csv('/home/tuaseen/Downloads/Extracted_Validation_Data/eicu_temporal_features.csv')

features_43 = list(df_mimic_tr.columns)

# -------------------------------------------------------------
# TASK A: Feature Distribution Comparison (MIMIC Train vs eICU)
# -------------------------------------------------------------
dist_rows = []
for f in features_43:
    m_s = df_mimic_tr[f].dropna()
    e_s = df_eicu_feats[f].dropna()
    
    m_mean, m_std = m_s.mean(), m_s.std()
    e_mean, e_std = e_s.mean(), e_s.std()
    
    m_med, m_iqr = m_s.median(), m_s.quantile(0.75) - m_s.quantile(0.25)
    e_med, e_iqr = e_s.median(), e_s.quantile(0.75) - e_s.quantile(0.25)
    
    m_min, m_max = m_s.min(), m_s.max()
    e_min, e_max = e_s.min(), e_s.max()
    
    m_miss_pct = (df_mimic_tr[f].isna().sum() / len(df_mimic_tr)) * 100
    e_miss_pct = (df_eicu_feats[f].isna().sum() / len(df_eicu_feats)) * 100
    
    # Standardized Mean Difference (Cohen's d / SMD)
    pooled_std = np.sqrt(((len(m_s) - 1) * m_std**2 + (len(e_s) - 1) * e_std**2) / (len(m_s) + len(e_s) - 2)) if (m_std > 0 or e_std > 0) else 1e-6
    smd = (e_mean - m_mean) / pooled_std if pooled_std > 0 else 0.0
    
    # % of eICU values outside MIMIC training range [m_min, m_max]
    outside_cnt = ((e_s < m_min) | (e_s > m_max)).sum()
    pct_outside = (outside_cnt / len(e_s)) * 100 if len(e_s) > 0 else 0.0
    
    dist_rows.append({
        'feature': f,
        'mimic_train_mean': round(m_mean, 3),
        'mimic_train_std': round(m_std, 3),
        'eicu_mean': round(e_mean, 3),
        'eicu_std': round(e_std, 3),
        'smd': round(smd, 3),
        'mimic_train_median': round(m_med, 3),
        'mimic_train_iqr': round(m_iqr, 3),
        'eicu_median': round(e_med, 3),
        'eicu_iqr': round(e_iqr, 3),
        'mimic_min': round(m_min, 3),
        'mimic_max': round(m_max, 3),
        'eicu_min': round(e_min, 3),
        'eicu_max': round(e_max, 3),
        'mimic_missing_pct': round(m_miss_pct, 2),
        'eicu_missing_pct': round(e_miss_pct, 2),
        'pct_eicu_outside_mimic_range': round(pct_outside, 2)
    })

df_dist = pd.DataFrame(dist_rows)
df_dist.to_csv(out_dir / 'feature_distribution_comparison.csv', index=False)
print("Saved feature_distribution_comparison.csv")

# -------------------------------------------------------------
# TASK C: Missingness Comparison (MIMIC vs eICU, and eICU Class Split)
# -------------------------------------------------------------
miss_rows = []
for f in features_43:
    m_miss_overall = (df_mimic_tr[f].isna().sum() / len(df_mimic_tr)) * 100
    m_pneu_miss = (df_mimic_tr.loc[y_tr == 1, f].isna().sum() / (y_tr == 1).sum()) * 100
    m_ctrl_miss = (df_mimic_tr.loc[y_tr == 0, f].isna().sum() / (y_tr == 0).sum()) * 100
    
    e_miss_overall = (df_eicu_feats[f].isna().sum() / len(df_eicu_feats)) * 100
    e_pneu_miss = (df_eicu_feats.loc[y_eicu == 1, f].isna().sum() / (y_eicu == 1).sum()) * 100
    e_ctrl_miss = (df_eicu_feats.loc[y_eicu == 0, f].isna().sum() / (y_eicu == 0).sum()) * 100
    
    diff_eicu_classes = e_pneu_miss - e_ctrl_miss
    
    miss_rows.append({
        'feature': f,
        'mimic_overall_missing_pct': round(m_miss_overall, 2),
        'mimic_pneumonia_missing_pct': round(m_pneu_miss, 2),
        'mimic_control_missing_pct': round(m_ctrl_miss, 2),
        'eicu_overall_missing_pct': round(e_miss_overall, 2),
        'eicu_pneumonia_missing_pct': round(e_pneu_miss, 2),
        'eicu_control_missing_pct': round(e_ctrl_miss, 2),
        'eicu_missing_diff_pneu_minus_ctrl': round(diff_eicu_classes, 2)
    })

df_miss = pd.DataFrame(miss_rows)
df_miss.to_csv(out_dir / 'missingness_comparison.csv', index=False)
print("Saved missingness_comparison.csv")

# -------------------------------------------------------------
# TASK 5: Deep False Positive Analysis
# -------------------------------------------------------------
# 4 groups based on actual label y_eicu and predicted at 0.53 (p2_scores >= 0.53)
pred_053 = (p2_scores >= 0.53).astype(int)

# Group assignment:
# 1: True Negative (y=0, pred=0) -> 41
# 2: False Positive (y=0, pred=1) -> 189
# 3: True Positive (y=1, pred=1) -> 217
# 4: False Negative (y=1, pred=0) -> 13
groups = {
    'TN_controls': (y_eicu == 0) & (pred_053 == 0),
    'FP_controls': (y_eicu == 0) & (pred_053 == 1),
    'TP_pneumonia': (y_eicu == 1) & (pred_053 == 1),
    'FN_pneumonia': (y_eicu == 1) & (pred_053 == 0)
}

print(f"Group counts: TN={groups['TN_controls'].sum()}, FP={groups['FP_controls'].sum()}, TP={groups['TP_pneumonia'].sum()}, FN={groups['FN_pneumonia'].sum()}")

# Merge features with duration, scores, and prediction bands
df_analysis = df_eicu_feats.copy()
df_analysis['patientunitstayid'] = df_eicu_ready['patientunitstayid']
df_analysis['actual_label'] = y_eicu
df_analysis['stage2_risk_score'] = p2_scores
df_analysis['predicted_053'] = pred_053
df_analysis['monitoring_duration_hours'] = df_eicu_temp['monitoring_duration_hours']

# Let's compute mean and std for each group across all 43 features + score + duration
fp_rows = []
all_cols = features_43 + ['stage2_risk_score', 'monitoring_duration_hours']

for col in all_cols:
    tn_vals = df_analysis.loc[groups['TN_controls'], col].dropna()
    fp_vals = df_analysis.loc[groups['FP_controls'], col].dropna()
    tp_vals = df_analysis.loc[groups['TP_pneumonia'], col].dropna()
    fn_vals = df_analysis.loc[groups['FN_pneumonia'], col].dropna()
    
    # Statistical test between FP and TN controls
    if len(tn_vals) > 0 and len(fp_vals) > 0 and (tn_vals.std() > 0 or fp_vals.std() > 0):
        # Mann-Whitney U test
        mw_stat, mw_p = stats.mannwhitneyu(fp_vals, tn_vals, alternative='two-sided')
        pooled_s = np.sqrt(((len(tn_vals) - 1)*tn_vals.std()**2 + (len(fp_vals) - 1)*fp_vals.std()**2) / (len(tn_vals) + len(fp_vals) - 2)) if (tn_vals.std() > 0 or fp_vals.std() > 0) else 1e-6
        smd_fp_vs_tn = (fp_vals.mean() - tn_vals.mean()) / pooled_s if pooled_s > 0 else 0.0
    else:
        mw_p = 1.0
        smd_fp_vs_tn = 0.0
        
    fp_rows.append({
        'feature': col,
        'TN_mean': round(tn_vals.mean(), 3),
        'TN_std': round(tn_vals.std(), 3),
        'FP_mean': round(fp_vals.mean(), 3),
        'FP_std': round(fp_vals.std(), 3),
        'TP_mean': round(tp_vals.mean(), 3),
        'TP_std': round(tp_vals.std(), 3),
        'FN_mean': round(fn_vals.mean(), 3),
        'FN_std': round(fn_vals.std(), 3),
        'smd_FP_vs_TN': round(smd_fp_vs_tn, 3),
        'p_value_FP_vs_TN': round(mw_p, 4)
    })

df_fp = pd.DataFrame(fp_rows)
df_fp.to_csv(out_dir / 'false_positive_analysis.csv', index=False)
print("Saved false_positive_analysis.csv")

# -------------------------------------------------------------
# TASK 4: Threshold Sensitivity Analysis (0.05 to 0.95)
# -------------------------------------------------------------
th_rows = []
for t in np.round(np.arange(0.05, 0.96, 0.01), 2):
    yp = (p2_scores >= t).astype(int)
    tn, fp, fn, tp = confusion_matrix(y_eicu, yp).ravel()
    sens = tp / (tp + fn)
    spec = tn / (tn + fp)
    prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    npv = tn / (tn + fn) if (tn + fn) > 0 else 0.0
    f1 = 2 * (prec * sens) / (prec + sens) if (prec + sens) > 0 else 0.0
    bal_acc = (sens + spec) / 2.0
    acc = (tp + tn) / len(y_eicu)
    youden_j = sens + spec - 1.0
    
    th_rows.append({
        'threshold': t,
        'TP': int(tp), 'TN': int(tn), 'FP': int(fp), 'FN': int(fn),
        'sensitivity': round(sens, 4),
        'specificity': round(spec, 4),
        'precision': round(prec, 4),
        'npv': round(npv, 4),
        'f1_score': round(f1, 4),
        'balanced_accuracy': round(bal_acc, 4),
        'accuracy': round(acc, 4),
        'youden_j': round(youden_j, 4)
    })

df_th = pd.DataFrame(th_rows)
df_th.to_csv(out_dir / 'threshold_sensitivity_analysis.csv', index=False)
print("Saved threshold_sensitivity_analysis.csv")

print("All base CSV files generated successfully!")
