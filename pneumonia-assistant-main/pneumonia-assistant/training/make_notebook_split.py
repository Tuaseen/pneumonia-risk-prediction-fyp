"""Recreate data/train_clean.csv and data/test_clean.csv exactly as the notebook does.

    python -m training.make_notebook_split [path/to/pneumonia_dataset_final.csv]

Copy of cells 0 and 1 of pneumonia_two_stage_pipeline.ipynb. The test suite
(tests/test_predictor.py::test_batch_auc_on_test_set) reads test_clean.csv to
check the original Stage 1 and Stage 2 models against the notebook's AUCs.
Existing files are never overwritten.
"""

import sys
from pathlib import Path

import pandas as pd
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT.parent / "data"
DEFAULT_SRC = ROOT.parents[1] / "Preprocessing" / "IOT Pneumonia" / "pneumonia_dataset_final.csv"


def clean(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df = df.drop(columns=["spo2_max"])                                  # 100 for everyone
    df = df.drop(columns=[c for c in df.columns if c.endswith("_trend")])  # trend calculation bug
    df["spo2_mean"] = df["spo2_mean"].clip(upper=100)
    for v in ["heart_rate", "respiratory_rate", "sbp", "spo2", "temperature"]:
        df[f"{v}_mean"] = df[f"{v}_mean"].clip(df[f"{v}_min"], df[f"{v}_max"] if f"{v}_max" in df else None)
    return df


def main():
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SRC
    df = pd.read_csv(src)
    X, y = df.drop(columns=["hadm_id", "pneumonia_label"]), df["pneumonia_label"]
    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.20, stratify=y, random_state=42)
    DATA_DIR.mkdir(exist_ok=True)
    for name, part in [("train_clean.csv", X_tr.assign(pneumonia_label=y_tr)),
                       ("test_clean.csv", X_te.assign(pneumonia_label=y_te))]:
        out = DATA_DIR / name
        if out.exists():
            print(f"{out} already exists, left unchanged")
            continue
        clean(part).to_csv(out, index=False)
        print(f"Wrote {out} {part.shape}")


if __name__ == "__main__":
    main()
