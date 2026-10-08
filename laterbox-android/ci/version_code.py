"""Reserve 100 version codes per workflow run so retries never reuse an upload."""
import os


def version_code(run_number, run_attempt):
    if run_number < 1 or not 1 <= run_attempt <= 100:
        raise ValueError('Workflow run must be positive and attempt must be between 1 and 100')
    # New CI namespace above the historical manually assigned codes (181).
    code = 1_000_000 + (run_number - 1) * 100 + run_attempt
    if code > 2_100_000_000:
        raise ValueError('Android version code exceeds the Google Play limit')
    return code


if __name__ == '__main__':
    code = version_code(int(os.environ['GITHUB_RUN_NUMBER']), int(os.environ['GITHUB_RUN_ATTEMPT']))
    with open(os.environ['GITHUB_ENV'], 'a') as output:
        output.write(f'ANDROID_VERSION_CODE={code}\n')
    print(f'Android CI version code: {code}; marketing version stays in version.json')
