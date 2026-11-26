# Integration contracts

## Model replacement

`functions/model/demo_model.json` is the dummy model file. `functions/prediction.py` is its executable adapter. It returns a selected demo scenario and never computes a disease probability. The offline Flutter adapter is `DemoPredictionService` in `lib/domain/models.dart`.

`feature_schema.reference.json` contains the 35 names in the exact order recovered from the notebook output, including the correction that `spo2_max` was omitted. It is a reference, not a complete deployable preprocessing pipeline.

To connect the actual model:

1. Export the model together with fitted preprocessing parameters, dependency versions and an authoritative feature order. Keep Python model files on the backend, never in the APK. Only load trusted model artifacts.
2. Recover the training definitions for the seven-day window, slope/time units, temperature conversion, standard deviation, imputation and clipping. Do not invent these from a few raw readings.
3. Define minimum coverage and insufficient-data behavior. A single reading currently enables a **demo**, not real inference.
4. Resolve the meaning of patient-reported breathing difficulty versus diagnosis-coded `respiratory_distress`, and clinician-reported low oxygen versus diagnosis-coded `hypoxemia`. Cough and weakness are retained as patient reports but are not selected model features. Unknown is distinct from no.
5. Replace `assess_demo` with an authenticated real inference function and introduce an explicit result schema for model scores and validated categories. The Flutter `Assessment` type currently only supports demo scenarios; extend it intentionally, rather than relabelling fixtures as real results. Do not infer patient probabilities from raw uncalibrated scores.
6. Add a parity test comparing predictions from the original Python pipeline and deployed adapter on the same held-out feature rows. Test missing inputs, reversed timestamps and insufficient coverage.

Adding a dataset column does not automatically change app inference. Update the schema and model together if it becomes a predictor. Existing records use `schemaVersion: 1` and assessments preserve profile, symptoms and immutable reading IDs.

## Measurements

```json
{
  "id": "unique-reading-id",
  "at": "2026-09-26T10:15:00.000Z",
  "schemaVersion": 1,
  "source": "simulator",
  "deviceId": "ASTRA-DEMO",
  "values": {"heart_rate": 76, "spo2": 98, "temperature": 36.8}
}
```

Units: heart rate bpm, SpO2 percent, temperature Celsius, respiratory rate breaths/minute, sbp mmHg. Missing values are omitted, not replaced with zero. `source` is manual or simulator in this build. Reading timestamps are captured when the reading is saved; backdating is not exposed in the UI.

The simulator deliberately provides only the three measurements covered by the planned sensor setup. Respiratory rate and systolic pressure remain manual. Seeded demo fixtures have all five measurements for trend demonstration and are labelled simulated.

## Physical IoT device: pending

The app does not scan Bluetooth, pair a physical device, provision Wi-Fi, or upload firmware. Its connection button controls a local simulator. A real integration should:

- Authenticate each device to a backend ingestion endpoint; never embed a Firebase Admin key in firmware.
- Associate device ownership server-side and validate values, timestamp, units, sequence/duplicate IDs and signal quality.
- Write validated readings to `users/{ownerUid}/readings/{readingId}`. Real `source: iot` data should be written by the backend; current client rules intentionally allow only manual/simulator.
- Expose actual device heartbeat and connection state to the app. The current simulator status is never used to represent hardware connectivity.

Firebase patient mode listens to reading changes. A future backend ingestion writer can therefore update measurements without replacing the screens.

## Firebase records and permissions

- `users/{uid}`: name, age, sex, diagnosed conditions; owner can edit.
- `users/{uid}/readings/{id}`: immutable owner-created measurements.
- `users/{uid}/assessments/{id}`: server-created demo assessment and profile snapshot.
- `users/{uid}/careTeam/{doctorUid}`: server-managed consent grant.
- `doctorAccess/{doctorUid}/patients/{uid}`: server-maintained listing for that doctor.

Doctors require the Firebase Auth custom claim `role: doctor`. A client cannot assign itself that claim. The patient grants access using the doctor's UID; the callable checks the doctor exists, is enabled and has the role. Grant/revoke writes both documents atomically. Doctors may read shared patient profiles, readings and assessments, but cannot modify them. Revocation blocks subsequent server reads; already viewed information cannot be retracted.

No production project or credentials were supplied. Deploy rules and functions to your own development project before trying live mode. Firebase services, billing requirements and quotas must be reviewed in that project. No cloud deployment is performed by local app builds.

## Data limits

Live mode loads the latest 500 readings and 100 assessments. Patient charts/logs display up to 60 readings; the overview chart shows 14. This is a bounded prototype view, not unlimited archival pagination. Dense physical sensor ingestion will require server aggregation and pagination before real temporal inference. Local demo records persist on the device; use only fictional information in demo mode.

Firebase authentication supports email/password, patient registration and password reset. Sign-in is explicit on app launch. No push notifications, background sensor ingestion or clinically validated alerts are implemented. Priority review is a selected demo scenario visible in history and the shared doctor view.

References: [FlutterFire setup](https://firebase.google.com/docs/flutter/setup), [callable functions](https://firebase.google.com/docs/functions/callable), [custom claims](https://firebase.google.com/docs/auth/admin/custom-claims).
