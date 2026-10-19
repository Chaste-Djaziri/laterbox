import unittest
from datetime import datetime, timedelta, timezone
from version_code import version_code


class VersionCodeTests(unittest.TestCase):
    def test_new_namespace_exceeds_old_workflow_codes(self):
        self.assertGreater(version_code(datetime(2026, 10, 19, tzinfo=timezone.utc)), 1_000_000)

    def test_new_builds_increase_across_workflows_and_retries(self):
        first = datetime(2026, 10, 19, tzinfo=timezone.utc)
        self.assertLess(version_code(first), version_code(first + timedelta(seconds=1)))
        self.assertEqual(version_code(first), version_code(first.astimezone(timezone(timedelta(hours=2)))))

    def test_rejects_invalid_times_and_play_limit(self):
        for build_time in [datetime(2026, 1, 1), datetime(2025, 12, 31, tzinfo=timezone.utc),
                           datetime(2050, 1, 1, tzinfo=timezone.utc)]:
            with self.assertRaises(ValueError): version_code(build_time)


if __name__ == '__main__':
    unittest.main()
