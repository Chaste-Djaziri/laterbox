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

xcrun notarytool submit "$DMG" --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" \
  --issuer "$ASC_ISSUER_ID" --wait --timeout 30m
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"
(cd "$OUT" && shasum -a 256 LaterBox-macOS.dmg > LaterBox-macOS.dmg.sha256)
echo "Verified notarized installer: $DMG"
