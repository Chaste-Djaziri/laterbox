# docs/macos-distribution.md

# LaterBox macOS — App Store Connect distribution

The macOS build is uploaded to **App Store Connect** for processing, TestFlight, and eventual Mac App Store review. It is not notarized and no DMG is published as a GitHub Release asset. Uploading a build **does not automatically publish it** on the Mac App Store.

## Required GitHub Actions secrets

These secret names correspond to the existing repository secrets:

- `APPLE_TEAM_ID`: Apple Developer Team ID.
- `APPLE_CERTIFICATE_BASE64` and `APPLE_CERTIFICATE_PASSWORD`: Apple Distribution .p12 and export password.
- `APPLE_INSTALLER_CERTIFICATE_BASE64` and `APPLE_INSTALLER_CERTIFICATE_PASSWORD`: Mac App Store installer distribution .p12 and password.
- `APPLE_MAC_PROVISIONING_PROFILE_BASE64`: **Mac App Store Connect** provisioning profile for `pro.micorp.laterbox`. A Developer ID, development, or device-restricted profile is not suitable.
- `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect key for archive upload.

The script checks the profile bundle identifier, macOS platform, team, expiration date, and distribution requirements before upload. Apple requires a separate **Mac App Store Connect provisioning profile** even though macOS and iOS share the same bundle ID; an iOS App Store provisioning profile cannot sign the native macOS target. If the saved profile is not a Mac App Store Connect profile, create one in the [Apple Developer portal](https://developer.apple.com/account/resources/profiles/list) for `pro.micorp.laterbox` and update `APPLE_MAC_PROVISIONING_PROFILE_BASE64`.

**Important:** An existing macOS app record with bundle ID `pro.micorp.laterbox` must exist in [App Store Connect](https://appstoreconnect.apple.com/). For the existing iOS app record, add macOS as another platform in App Store Connect before uploading. A separate Mac app record is not required when using the same bundle ID. App Store Connect and Apple can also impose capability, metadata, agreements, or processing requirements that are not satisfied merely by signing correctly.

## CI workflow

- `.github/workflows/macos.yml` runs independently on macOS-related pushes to main and via manual dispatch. Pull requests only compile an unsigned macOS build.
- `scripts/upload_macos_appstore.sh` imports the Apple Distribution and installer certificates, validates and installs the Mac App Store profile, archives the universal Mac app with sandbox entitlements, signs a Mac App Store installer `.pkg` using the separate **3rd Party Mac Developer Installer** identity, verifies the package signature, and submits it through `xcrun altool` using the App Store Connect API key.
- A successful upload means Apple accepted the transfer, **not** that build processing or App Review succeeded.
- There is **no Developer ID notarization, stapling, DMG artifact, or macOS binary in GitHub Releases** while App Store distribution is selected.
- The managed GitHub Release workflow for the web, extensions, and iOS remains independent of Mac App Store uploads.
- The download page displays **Mac App Store coming soon** until a verified macOS App Store listing URL is available. Do not link the iOS listing as a Mac download without verifying compatibility.

## Troubleshooting

If `xcodebuild -exportArchive` reports that the Mac App Store profile does not include a **3rd Party Mac Developer Installer** certificate, do not add that installer certificate to the app's provisioning profile: the app and package use different signing identities. The upload script now uses `productbuild` to sign the `.pkg` separately before App Store Connect upload. If the archive reports a provisioning mismatch, confirm that `APPLE_MAC_PROVISIONING_PROFILE_BASE64` contains a **Mac App Store Connect** distribution profile for `pro.micorp.laterbox`, associated with the same Apple Distribution certificate imported by CI. If upload fails with a missing app record, create the corresponding macOS app record in App Store Connect. An Apple notarization status 7000 applies to Developer ID distribution and is not part of this upload pipeline.

## Re-enabling direct Mac downloads

Restoring a direct DMG requires a separately maintained Developer ID signed and **successfully notarized** distribution pipeline. Do not publish an unnotarized installer as a replacement.

## Paused Android

Android CI and Android release assets remain disabled; the public Android download endpoint returns HTTP 410, and the download page labels Android Coming soon.
