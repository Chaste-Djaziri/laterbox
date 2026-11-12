#!/usr/bin/env bash
# scripts/package_macos.sh
# Create only Developer ID signed + notarized macOS distributables.
set -euo pipefail
umask 077

for required in TEAM_ID CERTIFICATE_BASE64 CERTIFICATE_PASSWORD ASC_KEY_BASE64 ASC_KEY_ID ASC_ISSUER_ID; do
  if [[ -z "${!required:-}" ]]; then
    echo "::error::Missing required macOS distribution credential: $required"
    exit 1
  fi
done

KEYCHAIN="$RUNNER_TEMP/laterbox-macos-signing.keychain-db"
KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"
CERT_PATH="$RUNNER_TEMP/laterbox-macos-developer-id.p12"
ASC_KEY_PATH="$RUNNER_TEMP/AuthKey_${ASC_KEY_ID}.p8"
OUT="$RUNNER_TEMP/macos-release"
BUILD="$RUNNER_TEMP/LaterBoxMacBuild"
STAGE="$RUNNER_TEMP/LaterBoxMacDmg"
IDENTITY="Developer ID Application"

cleanup() {
  security delete-keychain "$KEYCHAIN" >/dev/null 2>&1 || true
  rm -f "$CERT_PATH" "$ASC_KEY_PATH"
}
trap cleanup EXIT

mkdir -p "$OUT" "$STAGE"
printf '%s' "$CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"
printf '%s' "$ASC_KEY_BASE64" | base64 --decode > "$ASC_KEY_PATH"
chmod 600 "$ASC_KEY_PATH"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 7200 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN"
security import "$CERT_PATH" -k "$KEYCHAIN" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security find-identity -v -p codesigning "$KEYCHAIN" | grep -F "$IDENTITY"
security find-identity -v -p codesigning "$KEYCHAIN" | grep -F "$TEAM_ID"

xcodebuild -project laterbox-ios/laterbox-ios.xcodeproj -scheme LaterBoxMac \
  -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$BUILD" ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" ENABLE_HARDENED_RUNTIME=YES \
  OTHER_CODE_SIGN_FLAGS="--timestamp" build

APP="$BUILD/Build/Products/Release/Laterbox.app"
test -d "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
codesign -dv --verbose=4 "$APP" 2>&1 | grep -F "TeamIdentifier=$TEAM_ID"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")" = 'pro.micorp.laterbox.macos'
cp -R "$APP" "$STAGE/Laterbox.app"
ln -s /Applications "$STAGE/Applications"

DMG="$OUT/LaterBox-macOS.dmg"
hdiutil create -volname 'LaterBox' -srcfolder "$STAGE" -format UDZO -ov "$DMG"
codesign --force --timestamp --sign "$IDENTITY" "$DMG"
codesign --verify --verbose=2 "$DMG"

# The notary service can return exit code 0 for a processed *Rejected*
# submission. Inspect the result and fetch Apple's issue report before stapling.
NOTARY_RESULT="$OUT/notarization-result.json"
NOTARY_LOG="$OUT/notarization-log.json"
xcrun notarytool submit "$DMG" --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" \
  --issuer "$ASC_ISSUER_ID" --wait --timeout 30m --output-format json > "$NOTARY_RESULT"
SUBMISSION_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "$NOTARY_RESULT")"
SUBMISSION_STATUS="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["status"])' "$NOTARY_RESULT")"
echo "Apple notarization submission: $SUBMISSION_ID; status: $SUBMISSION_STATUS"
if [[ "$SUBMISSION_STATUS" != "Accepted" ]]; then
  echo "::error::Apple rejected macOS notarization ($SUBMISSION_ID). See the issue report below."
  if xcrun notarytool log "$SUBMISSION_ID" --key "$ASC_KEY_PATH" \
      --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" \
      --output-format json > "$NOTARY_LOG"; then
    python3 -c '
import json, sys
data = json.load(open(sys.argv[1]))
print("Apple notarization status:", data.get("status", "unknown"))
print("Status code:", data.get("statusCode", "unknown"))
print("Status summary:", data.get("statusSummary") or "Not provided")
issues = data.get("issues") or []
if not issues:
    print("No file-level issues were provided by Apple.")
for issue in issues:
    print(" - {severity}: {message} ({path})".format(
        severity=issue.get("severity", "error"),
        message=issue.get("message", "Notarization issue"),
        path=issue.get("path", "unspecified")))
' "$NOTARY_LOG"
  else
    echo "::warning::Could not retrieve Apple notarization log for $SUBMISSION_ID"
  fi
  exit 1
fi
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"
(cd "$OUT" && shasum -a 256 LaterBox-macOS.dmg > LaterBox-macOS.dmg.sha256)
echo "Verified notarized installer: $DMG"
