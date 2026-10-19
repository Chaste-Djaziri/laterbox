"""Use a global clock for Play version codes; workflow run numbers reset per workflow."""
import os
from datetime import datetime, timezone


EPOCH = datetime(2026, 1, 1, tzinfo=timezone.utc)


def version_code(build_time):
    if build_time.tzinfo is None:
        raise ValueError('Build time must include a timezone')
    # One code per UTC second, above the old workflow-scoped 1,000,000 range.
    code = 1_500_000_000 + int((build_time - EPOCH).total_seconds())
    if code < 1_500_000_000:
        raise ValueError('Build time predates the version code epoch')
    if code > 2_100_000_000:
        raise ValueError('Android version code exceeds the Google Play limit')
    return code


if __name__ == '__main__':
    code = version_code(datetime.now(timezone.utc))
    with open(os.environ['GITHUB_ENV'], 'a') as output:
        output.write(f'ANDROID_VERSION_CODE={code}\n')
    print(f'Android CI version code: {code}; marketing version stays in version.json')
