# laterbox Deployment Guide

This guide describes how to build, package, and deploy laterbox across all supported platforms.

---

## 1. Web Application (Cloudflare Pages)

The web app is hosted on Cloudflare Pages (`https://laterbox.dev`).

### Automated Deployment & Version Stamping
We provide an automated deployment script that auto-increments the build version in `web/version.json`, compiles Flutter Web, and deploys directly to Cloudflare Pages:

```bash
python3 scripts/deploy_web.py
```

### Manual Deployment
```bash
flutter build web --release
npx wrangler pages deploy build/web --project-name=laterbox
```

---

## 2. iOS (App Store & TestFlight)

### Prerequisites
- macOS machine with Xcode 26+ installed.
- Apple Developer Account with Team ID configured (`LS42X27YFY`).

### Build Release Archive & IPA
```bash
DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer flutter build ipa --release
```

- **Output Archive**: `build/ios/archive/Runner.xcarchive`
- **Output IPA**: `build/ios/ipa/laterbox.ipa`

### Uploading to TestFlight
1. Open the **Apple Transporter** app on macOS.
2. Drag and drop `build/ios/ipa/laterbox.ipa` into Transporter.
3. Click **Deliver**.
4. Check build processing under **App Store Connect → TestFlight → iOS**.

### App Store Review Information
For the **App Review Information** section in App Store Connect:
- **Sign-in Required**: Checked
- **User Name**: `apple.review@laterbox.micorp.pro`
- **Password**: `LaterboxReview2026!`
- **Contact Information**: Chaste Djaziri (`security@laterbox.dev` / `chaste@laterbox.dev`)
- **Review Notes**: See below for copy-paste review instructions.

---

## 3. macOS Desktop (App Store & Direct Distribution)

### Build Release Application & Archive
```bash
DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer flutter build macos --release

DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer xcodebuild archive \
  -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath build/macos/archive/Runner.xcarchive
```

- **Output App**: `build/macos/Build/Products/Release/laterbox.app`
- **Output Archive**: `build/macos/archive/Runner.xcarchive`

### Notarized DMG (Direct Distribution) + Sparkle Auto-Update
Direct builds are ad-hoc signed by default. When a **Developer ID Application** certificate and notarization secrets are present, CI automatically:

1. Codesigns with `--options runtime --timestamp` (hardened runtime)
2. Creates a DMG via `hdiutil create -format UDZO`
3. Notarizes with `xcrun notarytool submit --wait` + `xcrun stapler staple`
4. Generates a Sparkle `appcast.xml` via `generate_appcast` when `SPARKLE_PRIVATE_KEY` is set.

**Required GitHub Secrets for direct DMG + Sparkle:**

| Secret | Purpose |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Developer ID Application .p12 |
| `APPLE_CERTIFICATE_PASSWORD` | .p12 password |
| `APPLE_ID` | Apple ID for notarytool |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password |
| `APPLE_TEAM_ID` | `LS42X27YFY` |
| `SPARKLE_PRIVATE_KEY` | Ed25519 private key (`generate_keys` output) |
| `SPARKLE_PUBLIC_KEY` | Goes in `macos/Runner/Info.plist` `SUPublicEDKey` |

**Local Sparkle key generation:**
```bash
# Install Sparkle tools
brew install sparkle
generate_keys  # prints public key for Info.plist, private key for secret
```

**Enabling Sparkle in Xcode (one-time):**
1. Open `macos/Runner.xcworkspace` → Runner → Package Dependencies → `+` → `https://github.com/sparkle-project/Sparkle` (Up to Next Major 2.6.0)
2. Add `Sparkle` to Runner target → Build Phases → Link Binary
3. `UpdaterService.swift` is already wired; no code change needed. Without the package it compiles as a no-op.

SPARKLE feed lives at `https://laterbox.dev/api/appcast.xml` (`SUFeedURL` in `Info.plist`). The CI-generated `dist/appcast.xml` should be deployed alongside the DMG.

### Mac App Store Packaging
MAS builds are **not** Sparkle-based (updates via App Store). Create a separate `Release MAS` xcconfig with `app-sandbox true` and provisioning profile injection; upload via `xcrun altool --upload-app` as in the iOS lane. Do not notarize MAS builds.

---

## 4. Browser Extensions

From the `extension/` directory:

```bash
cd extension
npm install
npm run package
```

Upload the generated `.zip` files in `extension/dist/` to:
- **Chrome Web Store Developer Dashboard**: `laterbox-chrome-extension.zip`
- **Safari Web Extension Packager / App Store**: `laterbox-safari-extension.zip`
- **Firefox Add-on Developer Hub**: `laterbox-firefox-extension.zip`
