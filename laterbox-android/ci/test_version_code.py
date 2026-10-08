import unittest
from version_code import version_code


class VersionCodeTests(unittest.TestCase):
    def test_new_namespace_exceeds_used_build(self):
        self.assertGreater(version_code(1, 1), 181)

    def test_retries_and_new_pushes_have_increasing_codes(self):
        self.assertLess(version_code(14, 1), version_code(14, 2))
        self.assertLess(version_code(14, 100), version_code(15, 1))

    def test_rejects_exhausted_attempts_and_play_limit(self):
        for run, attempt in [(0, 1), (1, 0), (1, 101), (21_000_001, 1)]:
            with self.assertRaises(ValueError): version_code(run, attempt)


if __name__ == '__main__':
    unittest.main()
