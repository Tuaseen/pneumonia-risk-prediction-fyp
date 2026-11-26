"""Replace this adapter only after exporting a verified model + preprocessing bundle."""
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path

MODEL = json.loads((Path(__file__).parent / 'model' / 'demo_model.json').read_text())
SYMPTOM_KEYS = {'breathing_difficulty', 'fever', 'hypoxemia_reported', 'cough', 'weakness'}


def demo_assessment(data, readings, *, assessment_id, now=None):
    if not isinstance(data, dict):
        raise ValueError('Expected an assessment object.')
    scenario = data.get('scenario')
    if not isinstance(scenario, str) or scenario not in MODEL['scenarios']:
        raise ValueError('Choose a supported demo scenario.')
    symptoms = data.get('symptoms')
    if not isinstance(symptoms, dict) or set(symptoms) != SYMPTOM_KEYS:
        raise ValueError('Supply all symptom responses, using unknown where unassessed.')
    if any(not isinstance(v, str) or v not in {'yes', 'no', 'unknown'} for v in symptoms.values()):
        raise ValueError('Invalid symptom response.')
    if not readings:
        raise ValueError('Add at least one reading before an assessment.')
    now = now or datetime.now(timezone.utc)
    start = now - timedelta(days=7)
    recent = []
    for reading in readings:
        try:
            at = datetime.fromisoformat(reading['at'].replace('Z', '+00:00'))
            if at.tzinfo is not None and start <= at <= now:
                recent.append(reading['id'])
        except (KeyError, ValueError, TypeError):
            continue
    return {
        'id': assessment_id,
        'at': now.isoformat(timespec='microseconds').replace('+00:00', 'Z'),
        'scenario': scenario,
        'symptoms': dict(symptoms),
        'readingIds': recent,
        'isDemo': True,
        'modelVersion': MODEL['modelVersion'],
        'schemaVersion': 1,
    }
