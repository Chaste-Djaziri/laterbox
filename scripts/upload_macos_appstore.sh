#!/usr/bin/env bash
# scripts/upload_macos_appstore.sh
# Upload the sandboxed macOS app to App Store Connect; no Developer ID or notarization.
set -euo pipefail
umask 077

for required in RUNNER_TEMP TEAM_ID CERTIFICATE_BASE64 CERTIFICATE_PASSWORD INSTALLER_CERTIFICATE_BASE64 INSTALLER_CERTIFICATE_PASSWORD MAC_PROFILE_BASE64 ASC_KEY_BASE64 ASC_KEY_ID ASC_ISSUER_ID; do
  if [[ -z "${!required:-}" ]]; then
    echo "::error::Missing macOS App Store upload credential: $required"
    exit 1
  fi
done

KEYCHAIN="$RUNNER_TEMP/laterbox-mac-appstore.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"
CERT_PATH="$RUNNER_TEMP/laterbox-apple-distribution.p12"
INSTALLER_CERT_PATH="$RUNNER_TEMP/laterbox-mac-installer.p12"
PROFILE_PATH="$RUNNER_TEMP/laterbox-macos.provisionprofile"
ASC_KEY_PATH="$RUNNER_TEMP/AuthKey_${ASC_KEY_ID}.p8"
PROFILE_PLIST="$RUNNER_TEMP/laterbox-macos-profile.plist"
PACKAGE="$RUNNER_TEMP/LaterBox-macOS-AppStore.pkg"
ASC_ALTOOL_DIR="$HOME/.appstoreconnect/private_keys"
ARCHIVE="$RUNNER_TEMP/LaterBoxMac.xcarchive"
PACKAGE_STAGE="$RUNNER_TEMP/laterbox-macos-package-stage"
INSTALLED_PROFILE=""
cleanup() {
  if [[ -n "$INSTALLED_PROFILE" ]]; then rm -f "$INSTALLED_PROFILE"; fi
  security delete-keychain "$KEYCHAIN" >/dev/null 2>&1 || true
  rm -f "$CERT_PATH" "$INSTALLER_CERT_PATH" "$PROFILE_PATH" "$ASC_KEY_PATH" "$PROFILE_PLIST" "$ASC_ALTOOL_DIR/AuthKey_${ASC_KEY_ID}.p8"
}
trap cleanup EXIT

printf '%s' "$CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"
printf '%s' "$INSTALLER_CERTIFICATE_BASE64" | base64 --decode > "$INSTALLER_CERT_PATH"
printf '%s' "$MAC_PROFILE_BASE64" | base64 --decode > "$PROFILE_PATH"
printf '%s' "$ASC_KEY_BASE64" | base64 --decode > "$ASC_KEY_PATH"
chmod 600 "$CERT_PATH" "$INSTALLER_CERT_PATH" "$PROFILE_PATH" "$ASC_KEY_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 7200 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN" "$HOME/Library/Keychains/login.keychain-db"
security import "$CERT_PATH" -k "$KEYCHAIN" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
security import "$INSTALLER_CERT_PATH" -k "$KEYCHAIN" -P "$INSTALLER_CERTIFICATE_PASSWORD" -T /usr/bin/productbuild -T /usr/bin/productsign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security find-identity -v -p codesigning "$KEYCHAIN" | grep -F 'Apple Distribution'
# Installer identities are not code-signing identities: do not filter with -p codesigning.
security find-identity -v "$KEYCHAIN" | grep -F '3rd Party Mac Developer Installer:'
security cms -D -i "$PROFILE_PATH" > "$PROFILE_PLIST"

# A Mac App Store Connect profile is required. Reject development, Developer ID,
# device-restricted and incorrect-bundle profiles before attempting an upload.
PROFILE_NAME="$(python3 - "$PROFILE_PLIST" "$TEAM_ID" <<'PY'
import datetime
import plistlib
import sys
from pathlib import Path

profile = plistlib.loads(Path(sys.argv[1]).read_bytes())
team = sys.argv[2]
bundle = "pro.micorp.laterbox"
entitlements = profile.get("Entitlements", {})
if team not in profile.get("TeamIdentifier", []):
    raise SystemExit("::error::macOS provisioning profile belongs to a different Apple team")
profile_app_id = entitlements.get("com.apple.application-identifier") or entitlements.get("application-identifier")
if profile_app_id != team + "." + bundle:
    raise SystemExit("::error::macOS profile app ID mismatch (expected " + bundle + "; stored profile: " + str(profile_app_id).removeprefix(team + ".") + ")")
platforms = profile.get("Platform") or []
if not any(platform in ("OSX", "macOS") for platform in platforms):
    raise SystemExit("::error::Expected a Mac App Store provisioning profile for " + bundle + "; an iOS profile cannot sign the native macOS app (profile platform: " + ", ".join(platforms) + ")")
if entitlements.get("com.apple.security.get-task-allow", entitlements.get("get-task-allow")):
    raise SystemExit("::error::Development provisioning profile cannot be used for App Store Connect")
if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices"):
    raise SystemExit("::error::Expected a Mac App Store distribution profile, not a device or Developer ID profile")
expiry = profile["ExpirationDate"]
if expiry.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
    raise SystemExit("::error::macOS provisioning profile has expired")
print(profile["Name"])
PY
)"
PROFILE_UUID="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$PROFILE_PLIST")"
PROFILE_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$PROFILE_DIR"
INSTALLED_PROFILE="$PROFILE_DIR/$PROFILE_UUID.provisionprofile"
cp "$PROFILE_PATH" "$INSTALLED_PROFILE"

# Every CI upload needs a new build number. The marketing version follows version.json.
MARKETING_VERSION="$(python3 -c 'import json; print(json.load(open("laterbox-ios/version.json"))["version"])')"
BUILD_NUMBER="${GITHUB_RUN_NUMBER:-1}"
# Confidential credentials were created with umask 077 and explicit 0600 modes.
# Build artifacts must instead be readable by all users when installed by macOS.
umask 022
echo "Archiving LaterBox macOS v$MARKETING_VERSION ($BUILD_NUMBER) for App Store Connect"
xcodebuild -project laterbox-ios/laterbox-ios.xcodeproj -scheme LaterBoxMac \
  -configuration Release -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE" ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY='Apple Distribution' \
  DEVELOPMENT_TEAM="$TEAM_ID" PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
  MARKETING_VERSION="$MARKETING_VERSION" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" archive

APP="$ARCHIVE/Products/Applications/Laterbox.app"
test -d "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" = 'pro.micorp.laterbox'
codesign -dv --verbose=4 "$APP" 2>&1 | grep -F "TeamIdentifier=$TEAM_ID"

# Do not package the signed archive in place. A restrictive umask or generated
# assets can leave app resources inaccessible to normal users.
# Normalize a staging copy, preserve executable bits, then verify its signature.
mkdir -p "$PACKAGE_STAGE"
ditto "$APP" "$PACKAGE_STAGE/Laterbox.app"
chmod -R a+rX "$PACKAGE_STAGE/Laterbox.app"
python3 - "$PACKAGE_STAGE/Laterbox.app" <<'PY'
import os
import stat
import sys
root = sys.argv[1]
unreadable = []
for directory, dirs, files in os.walk(root, followlinks=False):
    for name in dirs + files:
        path = os.path.join(directory, name)
        if os.path.islink(path):
            continue
        mode = os.stat(path).st_mode
        if not (mode & stat.S_IROTH) or (stat.S_ISDIR(mode) and not (mode & stat.S_IXOTH)):
            unreadable.append(os.path.relpath(path, root))
if unreadable:
    print("::error::Mac app resources unreadable by standard users:", *unreadable[:25], sep="\\n")
    raise SystemExit(1)
print("Verified all staged Mac app resources are readable by standard users")
PY
codesign --verify --deep --strict --verbose=2 "$PACKAGE_STAGE/Laterbox.app"
APP="$PACKAGE_STAGE/Laterbox.app"

# Xcode's exportArchive can incorrectly compare the installer certificate to
# the app's provisioning profile. macOS App Store submissions are signed PKGs;
# package the already Apple Distribution-signed app using the *installer* identity.
INSTALLER_ID="$(security find-identity -v "$KEYCHAIN" | awk -F '"' '/3rd Party Mac Developer Installer:/{print $2; exit}')"
if [[ -z "$INSTALLER_ID" ]]; then
  echo "::error::Mac Installer Distribution identity is missing from the signing keychain"
  exit 1
fi
# productbuild must be authorized to access the installer private key in CI.
# Avoid an invisible keychain authorization dialog hanging the runner indefinitely.
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
python3 - "$APP" "$INSTALLER_ID" "$KEYCHAIN" "$PACKAGE" <<'PY'
import subprocess
import sys
argv = ["productbuild", "--component", sys.argv[1], "/Applications",
        "--sign", sys.argv[2], "--keychain", sys.argv[3], sys.argv[4]]
try:
    subprocess.run(argv, check=True, timeout=300)
except subprocess.TimeoutExpired:
    print("::error::productbuild timed out: check installer private-key ACL and package filesystem permissions", flush=True)
    raise SystemExit(1)
PY
pkgutil --check-signature "$PACKAGE"
test -s "$PACKAGE"

# altool reads API keys from this standard directory for authenticated uploads.
mkdir -p "$ASC_ALTOOL_DIR"
cp "$ASC_KEY_PATH" "$ASC_ALTOOL_DIR/AuthKey_${ASC_KEY_ID}.p8"
chmod 600 "$ASC_ALTOOL_DIR/AuthKey_${ASC_KEY_ID}.p8"
echo "Uploading signed macOS App Store package to App Store Connect"
xcrun altool --upload-app --type macos --file "$PACKAGE" \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
echo "App Store Connect transfer completed. Apple's build processing and review are separate."
