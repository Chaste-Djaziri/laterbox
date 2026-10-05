"""Run native CI validation in bounded stages; retain logs even if Xcode hangs."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time

root = Path(os.environ['RUNNER_TEMP'])

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

if __name__ == '__main__':
    devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '-j'], timeout=30))
    simulator = next(d for runtime, entries in devices['devices'].items() if 'iOS-27' in runtime for d in entries if d['name'].startswith('iPhone'))
    if simulator['state'] != 'Booted': run('SimulatorBoot', ['xcrun', 'simctl', 'boot', simulator['udid']], 60)
    run('SimulatorReady', ['xcrun', 'simctl', 'bootstatus', simulator['udid'], '-b'], 180)
    base = ['xcodebuild', '-project', 'laterbox-ios/laterbox-ios.xcodeproj', '-scheme', 'laterbox-ios',
            '-destination', 'platform=iOS Simulator,id=' + simulator['udid'], '-derivedDataPath', str(root / 'DerivedData'),
            'CODE_SIGNING_ALLOWED=NO']
    try:
        run('NativeBuild', base + ['build-for-testing'], 600)
        for target, name in [('laterbox-iosTests', 'NativeSwiftTests'), ('laterbox-iosUITests', 'NativeUITests')]:
            run(name, base + ['test-without-building', '-only-testing:' + target, '-parallel-testing-enabled', 'NO',
                             '-collect-test-diagnostics', 'never', '-test-timeouts-enabled', 'YES',
                             '-maximum-test-execution-time-allowance', '180', '-resultBundlePath', str(root / (name + '.xcresult'))], 300)
    finally:
        subprocess.run(['xcrun', 'simctl', 'shutdown', simulator['udid']], timeout=30, check=False)
