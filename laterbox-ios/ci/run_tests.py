"""Run native CI validation in bounded stages; retain logs even if Xcode hangs."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time

root = Path(os.environ.get('RUNNER_TEMP', '/tmp/laterbox-native-ci'))
root.mkdir(parents=True, exist_ok=True)

def run(name, command, timeout):
    print(f'::group::{name}', flush=True)
    log = root / (name + '.log')
    with log.open('w') as output:
        process = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
        deadline = time.monotonic() + timeout
        try:
            while process.poll() is None:
                if time.monotonic() >= deadline:
                    raise TimeoutError(f'{name} exceeded {timeout} seconds; see {log.name}')
                time.sleep(5)
            if process.returncode:
                raise RuntimeError(f'{name} exited with status {process.returncode}; see {log.name}')
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try: process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
            print(log.read_text(errors='replace')[-16000:], flush=True)
            print('::endgroup::', flush=True)

def simulator_profile(runtimes):
    available = [runtime for runtime in runtimes if runtime.get('isAvailable')
                 and runtime.get('version', '').split('.')[0] == '27'
                 and '.iOS-' in runtime.get('identifier', '')]
    if not available:
        raise RuntimeError('No available iOS 27 simulator runtime. Install it in Xcode Settings > Components.')
    runtime = max(available, key=lambda value: tuple(int(part) for part in value['version'].split('.')))
    iphones = [device for device in runtime.get('supportedDeviceTypes', []) if device.get('productFamily') == 'iPhone']
    if not iphones:
        raise RuntimeError('The iOS 27 runtime has no supported iPhone device type.')
    return runtime['identifier'], iphones[0]['identifier']


def main():
    runtimes = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'runtimes', '-j'], timeout=30))
    runtime, device_type = simulator_profile(runtimes['runtimes'])
    # Never reuse or shut down a developer's simulator on this self-hosted runner.
    simulator = subprocess.check_output(['xcrun', 'simctl', 'create', 'LaterBox CI ' + str(os.getpid()), device_type, runtime], timeout=60).decode().strip()
    print(f'Created CI simulator {simulator} ({runtime})', flush=True)
    base = ['xcodebuild', '-project', 'laterbox-ios/laterbox-ios.xcodeproj', '-scheme', 'laterbox-ios',
            '-destination', 'platform=iOS Simulator,id=' + simulator, '-derivedDataPath', str(root / 'DerivedData'),
            'CODE_SIGNING_ALLOWED=NO']
    try:
        run('SimulatorBoot', ['xcrun', 'simctl', 'boot', simulator], 90)
        # A fresh device performs first-boot data migration. Keep it bounded, but
        # allow more than the previous three minutes on a busy runner.
        run('SimulatorReady', ['xcrun', 'simctl', 'bootstatus', simulator, '-b'], 600)
        run('NativeBuild', base + ['build-for-testing'], 600)
        for target, name in [('laterbox-iosTests', 'NativeSwiftTests'), ('laterbox-iosUITests', 'NativeUITests')]:
            run(name, base + ['test-without-building', '-only-testing:' + target, '-parallel-testing-enabled', 'NO',
                             '-collect-test-diagnostics', 'never', '-test-timeouts-enabled', 'YES',
                             '-maximum-test-execution-time-allowance', '180', '-resultBundlePath', str(root / (name + '.xcresult'))], 300)
    except Exception as error:
        print(f'::error::{error}', flush=True)
        with (root / 'SimulatorDiagnostics.log').open('w') as output:
            subprocess.run(['xcrun', 'simctl', 'list', 'devices', '-j'], stdout=output, stderr=subprocess.STDOUT, timeout=30, check=False)
        raise
    finally:
        subprocess.run(['xcrun', 'simctl', 'shutdown', simulator], timeout=30, check=False)
        subprocess.run(['xcrun', 'simctl', 'delete', simulator], timeout=30, check=False)


if __name__ == '__main__':
    main()
