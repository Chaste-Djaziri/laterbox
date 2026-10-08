import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

import run_tests


class SimulatorValidationTests(unittest.TestCase):
    def test_selects_latest_available_ios_27_with_compatible_iphone(self):
        def runtime(version, available=True, platform='iOS'):
            return {'identifier': f'com.apple.CoreSimulator.SimRuntime.{platform}-{version.replace(".", "-")}',
                    'version': version, 'isAvailable': available,
                    'supportedDeviceTypes': [{'productFamily': 'iPhone', 'identifier': 'iphone-type'}]}
        identifier, device = run_tests.simulator_profile([
            runtime('27.0'), runtime('27.2'), runtime('27.3', False), runtime('27.9', platform='visionOS')])
        self.assertTrue(identifier.endswith('iOS-27-2'))
        self.assertEqual(device, 'iphone-type')

    def test_missing_runtime_explains_how_to_install_it(self):
        with self.assertRaisesRegex(RuntimeError, 'Install it in Xcode'):
            run_tests.simulator_profile([])

    def test_timeout_terminates_process_and_preserves_log(self):
        process = Mock(pid=123, returncode=None)
        process.poll.return_value = None
        with tempfile.TemporaryDirectory() as directory, patch.object(run_tests, 'root', Path(directory)), \
                patch.object(run_tests.subprocess, 'Popen', return_value=process), \
                patch.object(run_tests.time, 'monotonic', side_effect=[0, 2]), \
                patch.object(run_tests.os, 'killpg') as kill, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(TimeoutError, 'SimulatorReady exceeded 1 seconds'):
                run_tests.run('SimulatorReady', ['bootstatus'], 1)
            self.assertTrue((Path(directory) / 'SimulatorReady.log').exists())
            kill.assert_called_once_with(123, run_tests.signal.SIGTERM)
            process.wait.assert_called_once_with(timeout=10)


if __name__ == '__main__':
    unittest.main()
