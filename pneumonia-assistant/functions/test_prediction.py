import unittest
from datetime import datetime, timezone
from prediction import demo_assessment


class PredictionTests(unittest.TestCase):
    def setUp(self):
        self.data = {'scenario': 'review', 'symptoms': {k: 'unknown' for k in ['breathing_difficulty','fever','hypoxemia_reported','cough','weakness']}}
        self.now = datetime(2026, 9, 26, tzinfo=timezone.utc)
        self.readings = [{'id': 'recent', 'at': '2026-09-25T00:00:00Z'}, {'id': 'old', 'at': '2026-09-01T00:00:00Z'}, {'id': 'future', 'at': '2026-09-27T00:00:00Z'}]

    def test_demo_has_no_probability_and_only_recent_readings(self):
        result = demo_assessment(self.data, self.readings, assessment_id='a', now=self.now)
        self.assertTrue(result['isDemo'])
        self.assertEqual(result['readingIds'], ['recent'])
        self.assertNotIn('probability', result)
        self.assertEqual(result['symptoms']['fever'], 'unknown')

    def test_missing_or_invalid_symptoms_rejected(self):
        for value in [{}, {'fever': 'yes'}, None]:
            with self.assertRaises(ValueError):
                demo_assessment({**self.data, 'symptoms': value}, self.readings, assessment_id='a')

    def test_unsupported_scenario_and_empty_readings_rejected(self):
        with self.assertRaises(ValueError):
            demo_assessment({**self.data, 'scenario': 'diagnosed'}, self.readings, assessment_id='a')
        with self.assertRaises(ValueError):
            demo_assessment(self.data, [], assessment_id='a')


if __name__ == '__main__':
    unittest.main()
