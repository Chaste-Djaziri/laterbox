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
EXPORT_OPTIONS="$RUNNER_TEMP/MacAppStoreExportOptions.plist"
ARCHIVE="$RUNNER_TEMP/LaterBoxMac.xcarchive"
EXPORT="$RUNNER_TEMP/MacAppStoreExport"
INSTALLED_PROFILE=""
cleanup() {
  if [[ -n "$INSTALLED_PROFILE" ]]; then rm -f "$INSTALLED_PROFILE"; fi
  security delete-keychain "$KEYCHAIN" >/dev/null 2>&1 || true
  rm -f "$CERT_PATH" "$INSTALLER_CERT_PATH" "$PROFILE_PATH" "$ASC_KEY_PATH" "$PROFILE_PLIST" "$EXPORT_OPTIONS"
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
security import "$INSTALLER_CERT_PATH" -k "$KEYCHAIN" -P "$INSTALLER_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/productsign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security find-identity -v -p codesigning "$KEYCHAIN" | grep -F 'Apple Distribution'
security cms -D -i "$PROFILE_PATH" > "$PROFILE_PLIST"

# A Mac App Store Connect profile is required. Reject development, Developer ID,
# device-restricted and incorrect-bundle profiles before attempting an upload.
PROFILE_NAME="$(python3 - "$PROFILE_PLIST" "$TEAM_ID" "$EXPORT_OPTIONS" <<'PY'
import datetime
import plistlib
import sys
from pathlib import Path

profile = plistlib.loads(Path(sys.argv[1]).read_bytes())
team = sys.argv[2]
bundle = "pro.micorp.laterbox.macos"
entitlements = profile.get("Entitlements", {})
if team not in profile.get("TeamIdentifier", []):
    raise SystemExit("::error::macOS provisioning profile belongs to a different Apple team")
if entitlements.get("com.apple.application-identifier", entitlements.get("application-identifier")) != team + "." + bundle:
    raise SystemExit("::error::macOS provisioning profile does not match " + bundle)
if entitlements.get("com.apple.security.get-task-allow", entitlements.get("get-task-allow")):
    raise SystemExit("::error::Development provisioning profile cannot be used for App Store Connect")
if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices"):
    raise SystemExit("::error::Expected a Mac App Store distribution profile, not a device or Developer ID profile")
expiry = profile["ExpirationDate"]
if expiry.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
    raise SystemExit("::error::macOS provisioning profile has expired")
name = profile["Name"]
options = {
    "method": "app-store-connect",
    "destination": "upload",
    "signingStyle": "manual",
    "signingCertificate": "Apple Distribution",
    "teamID": team,
    "provisioningProfiles": {bundle: name},
    "manageAppVersionAndBuildNumber": False,
}
Path(sys.argv[3]).write_bytes(plistlib.dumps(options))
print(name)
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
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" = 'pro.micorp.laterbox.macos'
codesign -dv --verbose=4 "$APP" 2>&1 | grep -F "TeamIdentifier=$TEAM_ID"

echo "Uploading macOS archive to App Store Connect (not publishing to the Mac App Store)"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
echo "App Store Connect upload completed. Apple must process the build before TestFlight/review."
