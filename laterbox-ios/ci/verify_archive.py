import os
from pathlib import Path
import plistlib
import subprocess
import sys

archive = Path(sys.argv[1])
app = next((archive / 'Products/Applications').glob('*.app'))
extension = next((app / 'PlugIns').glob('*.appex'))
for bundle, identifier in [(app, 'pro.micorp.laterbox'), (extension, 'pro.micorp.laterbox.ShareExtension')]:
    info = plistlib.loads((bundle / 'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == identifier, 'Archive bundle identity mismatch'
    assert info['CFBundleShortVersionString'] == os.environ['IOS_VERSION'], 'Archive marketing version mismatch'
    assert info['CFBundleVersion'] == os.environ['IOS_BUILD'], 'Archive build version mismatch'
    subprocess.run(['codesign', '--verify', '--strict', str(bundle)], check=True)
    result = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(bundle)], capture_output=True, check=True)
    entitlements = plistlib.loads(result.stdout)
    assert entitlements['com.apple.developer.team-identifier'] == 'LS42X27YFY', 'Archive team mismatch'
    assert 'group.pro.micorp.laterbox' in entitlements.get('com.apple.security.application-groups', []), 'Archive App Group missing'
print('Verified native app and share extension identity, versions and signed App Group')
