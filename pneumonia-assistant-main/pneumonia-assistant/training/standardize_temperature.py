"""Rebuild the temperature columns in Fahrenheit: the dataset Model V2 was trained on.

    python -m training.standardize_temperature            # writes ...v2_temp_corrected.reproduced.csv
    python -m training.standardize_temperature --check    # also compares with the saved V2 dataset

Why: the extraction notebook (FYPpneumonia.ipynb, step 3) mapped both MIMIC-IV
chartevents temperature items to one name without converting units:

    223761  Temperature Fahrenheit  -> "temperature"
    223762  Temperature Celsius     -> "temperature"

so vitals_raw.csv holds a mix of °F and °C values, and the original dataset's
temperature statistics mixed the two before IQR capping hid the problem.

Rules (the readings carry no item id any more, so the unit is read from the value):
  1. Window: the notebook's own, first 7 days counted from each admission's
     first vital of any kind (step 6).
  2. Unit: a value below 50 is Celsius (no Fahrenheit body temperature is below
     50; no Celsius one is above 50). Converted with F = C * 1.8 + 32.
  3. Implausible values: after conversion every reading is clipped to
     [80, 115] °F. This affects the 6 readings below 25 °C (0.2 to 9.0, entry
     errors that would otherwise become 32 to 48 °F), 1 reading between 50 and
     80 and 6 above 115 in the 7-day window.
  4. Per admission: mean, min, max, sample std (ddof=1; 0 for a single reading,
     as the app computes it), and trend = slope of value against reading order
     (np.polyfit), as in the notebook. trend is not a model feature.
  5. No IQR capping (that was what masked the mixed units).
  6. Admissions with no temperature reading in the window (36) keep their
     values from the original dataset, as the saved V2 dataset did.

Only the five temperature columns change; every other column is copied as is.
Existing files are never overwritten.
"""

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

PREP = Path(__file__).resolve().parents[3] / "Preprocessing"
RAW = PREP / "IOT Pneumonia" / "vitals_raw.csv"
BASE = PREP / "pneumonia_dataset_with_labs.csv"
SAVED_V2 = PREP / "pneumonia_dataset_with_labs_v2_temp_corrected.csv"
OUT = PREP / "pneumonia_dataset_with_labs_v2_temp_corrected.reproduced.csv"

CELSIUS_BELOW = 50.0
BOUNDS_F = (80.0, 115.0)
DAYS = 7
COLS = ["temperature_mean", "temperature_min", "temperature_max", "temperature_std", "temperature_trend"]


def temperature_readings(raw: Path = RAW) -> pd.DataFrame:
    v = pd.read_csv(raw)
    v["charttime"] = pd.to_datetime(v["charttime"])
    hours = v.groupby("hadm_id")["charttime"].transform(lambda x: (x - x.min()).dt.total_seconds() / 3600)
    v = v[(hours // 24).astype(int) + 1 <= DAYS]
    t = v[v["feature"] == "temperature"].copy()
    t["celsius"] = t["valuenum"] < CELSIUS_BELOW
    t["temp_f"] = np.where(t["celsius"], t["valuenum"] * 1.8 + 32, t["valuenum"]).clip(*BOUNDS_F)
    return t


def aggregate(t: pd.DataFrame) -> pd.DataFrame:
    g = t.groupby("hadm_id")["temp_f"]
    out = pd.DataFrame({"temperature_mean": g.mean(), "temperature_min": g.min(),
                        "temperature_max": g.max(), "temperature_std": g.std().where(g.size() > 1, 0.0)})
    out["temperature_trend"] = g.apply(lambda x: np.polyfit(range(len(x)), x, 1)[0] if len(x) > 1 else 0.0)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument("--check", action="store_true", help="compare with the saved V2 dataset")
    args = ap.parse_args()

    t = temperature_readings()
    x = t["valuenum"]
    print(f"Temperature readings in the {DAYS}-day window: {len(t):,}")
    print(f"  Celsius (< {CELSIUS_BELOW:g}): {t['celsius'].sum():,}  "
          f"(25-50: {((x >= 25) & (x < 50)).sum():,}, below 25: {(x < 25).sum():,})")
    print(f"  clipped to {BOUNDS_F}: {((t['temp_f'] == BOUNDS_F[0]) | (t['temp_f'] == BOUNDS_F[1])).sum():,}")

    base = pd.read_csv(BASE)
    new = aggregate(t).reindex(base["hadm_id"]).reset_index(drop=True)
    out = base.copy()
    for c in COLS:
        out[c] = new[c].where(new[c].notna(), base[c])   # rule 6
    print(f"Admissions without a temperature reading (kept as is): {new['temperature_mean'].isna().sum()}")

    if args.out.exists():
        print(f"{args.out} already exists, left unchanged")
    else:
        out.to_csv(args.out, index=False)
        print(f"Wrote {args.out}")

    if args.check:
        saved = pd.read_csv(SAVED_V2)
        assert (saved["hadm_id"] == out["hadm_id"]).all()
        worst = max(float((saved[c] - out[c]).abs().max()) for c in saved.columns if c != "hadm_id")
        print(f"Max difference from {SAVED_V2.name}, all columns: {worst:.2e} "
              f"-> {'reproduced' if worst < 1e-9 else 'NOT reproduced'}")


if __name__ == "__main__":
    main()
