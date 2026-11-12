# docs/macos-distribution.md

# LaterBox macOS direct distribution

The release workflow builds a **universal (Apple Silicon + Intel)** app for macOS 14+, signs it with a **Developer ID Application** certificate, notarizes the DMG with Apple, staples the ticket, verifies Gatekeeper and publishes `LaterBox-macOS.dmg` plus a SHA-256 checksum in the managed GitHub Release.

## Configure GitHub Actions secrets

Set these repository secrets in **Settings → Secrets and variables → Actions**:

- `APPLE_DEVELOPER_ID_CERTIFICATE_BASE64`: Base64 of the exported Developer ID Application **.p12** certificate (including its private key). Use the Developer ID certificate, **not** the iOS Apple Distribution certificate.
- `APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD`: Password used to export that .p12.
- `APPLE_TEAM_ID`: Apple Developer Team ID.
- `APP_STORE_CONNECT_API_KEY_BASE64`: Base64 of the App Store Connect API private `.p8` key.
- `APP_STORE_CONNECT_KEY_ID`: API key identifier.
- `APP_STORE_CONNECT_ISSUER_ID`: API issuer UUID.

These secret names match the repository's existing Apple Developer ID and App Store Connect entries. The runner imports the Developer ID private key only for the build; a local Developer ID identity is not required when GitHub Secrets contain the correct .p12. The stored certificate must be valid and include its private key. The existing iOS App Store Connect secrets may be reused if they have the correct permissions. Credentials stay in GitHub Secrets and are never embedded in the installer or source tree. The pipeline fails closed if any required secret is missing or signing/notarization fails.

## Release path

1. Push code to `main`. `Complete GitHub Release` detects macOS changes and invokes `Native macOS Distributable`; the latter can also run manually from Actions.
2. Xcode 27 builds the `LaterBoxMac` scheme in Release mode. On PRs, it compiles without publishing a distributable.
3. Production builds import the Developer ID certificate into a temporary keychain, build a universal binary with hardened runtime and timestamp, validate the signed app and prepare an installer with a drag-to-Applications shortcut.
4. Apple's notary service must accept the DMG; the ticket is stapled and verified **only after an explicit `Accepted` result**. For `Rejected` or other statuses, the workflow fetches Apple's notarization issues, prints them in the job log, and uploads the diagnostic JSON as a temporary artifact. Rejected installers are never published.
5. The web downloads page checks the latest published GitHub Release for `LaterBox-macOS.dmg` and enables its Mac download link only when the signed asset exists.

**Important:** GitHub Actions artifacts are for CI validation and have limited retention. The GitHub Release asset is the public download. Production download activation requires a successful macOS build and complete managed release.

## Paused Android

Android CI is retained for future development but both automated triggers and the build job are disabled. `Complete GitHub Release` no longer invokes it or carries Android APK/AAB files into new managed releases. The public Android download endpoint returns HTTP 410, and the download page labels Android Coming soon. Re-enabling Android requires explicitly restoring workflow triggers and release assets.

## Apple notarization team provisioning

If Apple returns `statusCode: 7000` and `statusSummary: Team is not yet configured for notarization`, the Developer Program team has not been enabled for notarization. The app can sign successfully and still be rejected. Contact [Apple Developer Support](https://developer.apple.com/contact/) under **Development and Technical → Other Development or Technical Questions** and provide the notarization submission ID. Do not weaken signing verification, bypass notarization, or keep retrying unchanged installers. Apple's log can include `issues: null` in this condition; the CI diagnostic parser handles this and prints the team-level summary.
