import unittest
import numpy as np
import pandas as pd
from report_prediction_validation import evaluate


class EvaluationTests(unittest.TestCase):
    def fixture(self):
        return pd.DataFrame(dict(split=1, channel=np.arange(20), errors=100,
                                 bits=10000, ber=.01, predicted=.01, rate_cp=.4,
                                 frames=40, simulation_seconds=4., online_seconds=.001))

    def test_perfect_predictions_with_sufficient_channels_pass(self):
        r = evaluate(self.fixture()).iloc[0]
        self.assertTrue(r.pass_gate)
        self.assertAlmostEqual(r.median_factor, 1.)
        self.assertAlmostEqual(r.online_speedup, 100.)
        self.assertEqual(r.case_frames, 800)

    def test_repeated_cells_cannot_replace_independent_channels(self):
        r = evaluate(self.fixture().assign(channel=1)).iloc[0]
        self.assertFalse(r.pass_gate)
        self.assertEqual(r.eligible_channels, 1)

    def test_error_and_speed_gates_can_fail(self):
        self.assertFalse(evaluate(self.fixture().assign(predicted=.1)).iloc[0].pass_gate)
        self.assertFalse(evaluate(self.fixture().assign(online_seconds=.1)).iloc[0].pass_gate)

    def test_percentile_matches_original_matlab_convention(self):
        t = self.fixture().assign(predicted=np.arange(1, 21)*.01)
        self.assertAlmostEqual(evaluate(t).iloc[0].p90_factor, 18.5)


if __name__ == '__main__':
    unittest.main()
