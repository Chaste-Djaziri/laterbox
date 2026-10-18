import os
from pathlib import Path
import plistlib
import subprocess
import sys

archive = Path(sys.argv[1])
app = next((archive / 'Products/Applications').glob('*.app'))
expected_bundles = [
    (app, 'pro.micorp.laterbox'),
    (app / 'PlugIns/LaterBoxShare.appex', 'pro.micorp.laterbox.ShareExtension'),
    (app / 'PlugIns/LaterBoxWidgets.appex', 'pro.micorp.laterbox.widgets')
]

for bundle, identifier in expected_bundles:
    assert bundle.exists(), f'Expected bundle {bundle} does not exist in archive'
    info = plistlib.loads((bundle / 'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == identifier, f'Archive bundle identity mismatch for {bundle.name}'
    assert info['CFBundleShortVersionString'] == os.environ['IOS_VERSION'], f'Archive marketing version mismatch for {bundle.name}'
    assert info['CFBundleVersion'] == os.environ['IOS_BUILD'], f'Archive build version mismatch for {bundle.name}'
    subprocess.run(['codesign', '--verify', '--strict', str(bundle)], check=True)
    result = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(bundle)], capture_output=True, check=True)
    entitlements = plistlib.loads(result.stdout)
    assert entitlements['com.apple.developer.team-identifier'] == 'LS42X27YFY', f'Archive team mismatch for {bundle.name}'
    assert 'group.pro.micorp.laterbox' in entitlements.get('com.apple.security.application-groups', []), f'Archive App Group missing for {bundle.name}'
print('Verified native app, share extension, and widget extension identity, versions and signed App Group')
