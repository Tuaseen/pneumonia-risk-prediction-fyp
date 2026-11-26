# Pneumonia Assistant

Flutter cross-platform application (Android, iOS, Desktop, and Web) for the Final Year Project: **IoT-Integrated AI System for Pneumonia Risk Prediction Using Temporal Physiological Monitoring and Machine Learning**.

This application directly mirrors the design, clinical workflow, risk bands, and features of the Next.js clinical web frontend, transformed into a native, standalone application.

---

## What is Included

1. **Clinical Design System & Theme:**
   - Slate-neutral clinical aesthetic (`#F8FAFC` canvas, crisp white cards, `#E2E8F0` borders).
   - Primary clinical blue (`#1D4ED8`) and standardized risk bands:
     - **Low** (Green `#16A34A`): *"No concern right now"*
     - **Moderate** (Amber `#CA8A04`): *"Keep an eye on it"*
     - **High** (Red `#DC2626`): *"See a doctor today"*
     - **Pending** (Slate `#64748B`): *"More information needed"*
     - **Watch** (Orange `#EA580C`): *"Possible concern: re-checking"*

2. **Patient Dashboard:**
   - Personalized header greeting (`Hello, {Name}`) with current date and quick *"Ask the assistant"* action.
   - **6 Metric Widgets:**
     - **Heart Rate** (`bpm`, typical 60–100) with range status tag ("Normal" / "Above range" / "Below range") and sparkline.
     - **Breathing Rate** (`/min`, typical 12–20).
     - **Blood Pressure** (`mmHg`, typical 90–120).
     - **Blood Oxygen** (`%`, typical 95–100).
     - **Body Temperature** (`°F`, typical 97.0–99.0).
     - **Lab Results Widget** (WBC, Neutrophils, Lymphocytes, CRP).
   - **Critical Alerts Banner:** Immediate red alert panel if physiological readings are critical (e.g. SpO₂ < 90%, RR ≥ 24/min, fever > 100.4°F, hypotension < 90 mmHg).
   - **Pneumonia Risk Status Card:** Colored risk band, percentage probability score from the Stage 2 model, and clear clinical recommendations.

3. **Clinical Quick Check:**
   - Daily screening covering the exact 4 clinical symptoms:
     - Short of breath at rest? (`respiratory_distress`)
     - Coughing? (`cough`)
     - Feverish? (`fever`)
     - Weakness or fatigue? (`weakness`)
   - Interactive Yes / No segmented controls and instant Stage 2 calibrated evaluation.

4. **Lab Results Entry & CSV Upload:**
   - Direct entry and CSV file import for:
     - White Blood Cell count (WBC, $\times 10^9/\text{L}$)
     - Neutrophils (%)
     - Lymphocytes (%)
     - C-Reactive Protein (CRP, $\text{mg/L}$)

5. **AI Assistant Chat Screen:**
   - Conversational health assistant explaining risk bands, vital ranges, and symptom significance.
   - Connects to the FastAPI backend (`/chat`) with seamless offline fallback logic.
   - Suggested query chips (*"How am I doing today?"*, *"What does my last result mean?"*, *"Explain my blood oxygen trend"*).

6. **Longitudinal History & Charts:**
   - Multi-day trend charts with sparklines, interactive vital selector, and min/average/max summary stats.
   - Assessment history timeline with past risk bands, timestamps, and model scores.

7. **Doctor Care Workspace:**
   - Monitored patient roster with risk badges and critical alert indicators.
   - In-depth patient drilldown showing physiological vitals, clinical comorbidities, and risk progression.

8. **Profile & Comorbidities:**
   - Demographics (Age, Biological Sex).
   - The 6 Stage 2 clinical comorbidities:
     - COPD (chronic lung disease)
     - Asthma
     - Heart failure
     - Kidney disease
     - Diabetes
     - High blood pressure
   - Care team doctor linking/unlinking.
   - FastAPI server URL settings (`http://127.0.0.1:8000`).

---

## Running the Application

### 1. Prerequisites
- Flutter SDK (Dart 3.13.4 or later).

### 2. Run the App
```bash
cd /home/tuaseen/Downloads/pneumonia-assistant
flutter pub get
flutter run
```

### 3. Connect to the FastAPI Backend (Optional)
To connect this app to your Python FastAPI backend (`pneumonia-assistant/backend`):
1. Start your backend server:
   ```bash
   uvicorn backend.main:app --host 127.0.0.1 --port 8000
   ```
2. In the app, navigate to **Profile > FastAPI Server URL** and verify the URL is `http://127.0.0.1:8000`.
3. Tap **Test Connection**. When online, the app bar shows **API ONLINE** and routes all inference and chat through your live Stage 2 model pipeline.
4. If the server is offline, the app operates automatically in **OFFLINE DEMO** mode with full local risk calculation and clinical rules.
