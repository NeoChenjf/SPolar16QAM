"""Behavioral checks for monotonic and observation-free model inference."""
import unittest
import numpy as np
import pandas as pd
from prediction_redesign import fit, predict, features


class PredictionTests(unittest.TestCase):
    def fixture(self):
        n = 30
        return pd.DataFrame(dict(q=np.linspace(.001, .2, n), p=.3, K=1926,
                                 S_count=244, control='shaped', sigma_mean=.2,
                                 gain_min=.1, gain_log_mean=-1., bits=10000,
                                 errors=np.arange(n)*80))

    def test_increasing_q_cannot_reduce_conditional_prediction(self):
        t = self.fixture()
        for kind in ['shared_q', 'conditional_q', 'hybrid']:
            model = fit(t, kind, 1.)
            p = predict(t, model)
            self.assertTrue(np.all(np.diff(p) >= -1e-12))
            self.assertGreater(p[-1], p[0])
            self.assertTrue(np.all((p > 0) & (p < 1)))

    def test_inference_does_not_read_observed_errors_or_labels(self):
        t = self.fixture()
        changed = t.assign(errors=9999, bits=1, reference_db=-100, group=999)
        for kind in ['shared_q', 'conditional_q', 'cheap', 'hybrid']:
            np.testing.assert_array_equal(features(t, kind), features(changed, kind))

    def test_cheap_features_are_independent_of_q(self):
        t = self.fixture()
        np.testing.assert_array_equal(features(t, 'cheap'),
                                      features(t.assign(q=.49), 'cheap'))
        np.testing.assert_array_equal(features(t, 'cheap'),
                                      features(t.drop(columns='q'), 'cheap'))


if __name__ == '__main__':
    unittest.main()
