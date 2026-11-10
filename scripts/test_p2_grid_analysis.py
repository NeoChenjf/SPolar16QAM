import unittest
import numpy as np
from analyze_p2_grid_study import paired_bands

class PairedBandsTest(unittest.TestCase):
    def setUp(self):
        r=np.random.default_rng(3)
        self.g=.32+r.normal(0,.005,(20,3)); self.b=np.full((20,3),.08)
        self.e=1+r.normal(0,.1,(20,3))
    def test_identical_policies_have_exact_zero_gain(self):
        c,l,h,_=paired_bands(self.g,self.g,self.b,self.b,self.e,self.e,2000)
        np.testing.assert_allclose(c[-3:],0,atol=1e-12)
        np.testing.assert_allclose(l[-3:],0,atol=1e-12)
        np.testing.assert_allclose(h[-3:],0,atol=1e-12)
    def test_known_paired_ten_percent_gain_exceeds_five_percent(self):
        c,l,h,_=paired_bands(self.g,self.g,self.b,self.b,self.e,self.e*1.1,2000)
        np.testing.assert_allclose(c[-3:],.1,atol=1e-12)
        self.assertTrue((l[-3:]>.05).all())
    def test_zero_proxy_denominator_is_rejected(self):
        with self.assertRaises(AssertionError):
            paired_bands(self.g,self.g,self.b,self.b,np.zeros_like(self.e),self.e,20)
    def test_reproducible_and_contains_estimate(self):
        a=paired_bands(self.g,self.g+.002,self.b,self.b,self.e,self.e*1.03+.01,2000)
        b=paired_bands(self.g,self.g+.002,self.b,self.b,self.e,self.e*1.03+.01,2000)
        for x,y in zip(a,b): np.testing.assert_array_equal(x,y)
        self.assertTrue((a[1]<=a[0]).all() and (a[0]<=a[2]).all())

if __name__=='__main__': unittest.main()
