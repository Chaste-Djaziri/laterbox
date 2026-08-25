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
