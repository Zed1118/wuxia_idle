import unittest

import numpy as np

import measure_black_point_drift as drift


class BlackPointDriftTest(unittest.TestCase):
    def test_common_stable_dark_mask_excludes_changed_background(self):
        first = np.array(
            [[[0.20, 0.20, 0.20], [0.90, 0.90, 0.90]]], dtype=np.float32
        )
        second = np.array(
            [[[0.22, 0.21, 0.20], [0.10, 0.20, 0.30]]], dtype=np.float32
        )

        mask = drift.stable_character_mask([first, second])
        samples = drift.sample_black_points([first, second], mask)

        self.assertEqual(mask.tolist(), [[True, False]])
        self.assertLess(samples["drift"], 0.05)


if __name__ == "__main__":
    unittest.main()
