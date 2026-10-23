# Native iOS and web releases

Four Actions workflows are maintained: `ios.yml`, `release.yml`, `android.yml`, and `extensions.yml`. Pushes to `main` affecting `laterbox-ios/**` run native Swift/UI tests, an App Store archive and a TestFlight upload. `laterbox-web/**` pushes validate the web app and backend contracts, build OpenNext and deploy Cloudflare. Changes to the corresponding workflow also trigger that workflow. Pull requests validate without signing/upload/deploy. Web PRs affecting Supabase run backend contract checks. Android changes use their dedicated workflow; the extension workflow runs on main pushes and pull requests. The web workflow also watches extension changes and root `version.json` on pushes. Manual releases require `main`.

iOS uses GitHub's `xcode-27` runner (a macOS build host, not a macOS product release). The deployment target stays iOS 27.0. Both the native app `pro.micorp.laterbox` and extension `pro.micorp.laterbox.ShareExtension` retain team `LS42X27YFY` and App Group `group.pro.micorp.laterbox` from the existing App Store release identity.

Existing repository secrets used:

- `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`: Apple Distribution P12 and password.
- `APPLE_PROVISIONING_PROFILE_BASE64`, `APPLE_SHARE_EXTENSION_PROVISIONING_PROFILE_BASE64`: current App Store profiles for the app and extension, including the App Group. The main app profile must also include Sign in with Apple.
- `APPLE_TEAM_ID`: `LS42X27YFY`.
- `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect API key authorized to read builds and upload to the existing app.
- `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`: unchanged Cloudflare deployment credentials.

Secrets are never logged. Missing, expired, development or mismatched profiles stop release before archive. Temporary keychains, API keys and installed profiles are removed in an always-run cleanup step. Simulator PR tests use no Apple secrets.

After enabling Sign in with Apple for `pro.micorp.laterbox`, regenerate the **App Store distribution provisioning profile** for that App ID in Apple Developer > Certificates, Identifiers & Profiles > Profiles. Download the replacement `.mobileprovision` and update the repository's `APPLE_PROVISIONING_PROFILE_BASE64` Actions secret with its base64 content (`base64 < profile.mobileprovision | tr -d '\n'` on macOS). The previous profile does not gain new entitlements automatically. Keep the share-extension and widgets profiles unchanged unless their capabilities change. CI checks the entitlement before starting the archive.

iOS release metadata comes from **`laterbox-ios/version.json`**, independently of root `version.json` (used by web and extensions). The iOS version is now **1.1.0**, with its build number tracked separately. Update this iOS file for future native releases; `scripts/bump_version.js --sync-only` respects the separate iOS version when regenerating Xcode and Swift constants. If App Store versions are already at or above the requested iOS version, CI selects the next patch above them. TestFlight build numbers advance independently beyond prior App Store Connect builds. Archive overrides are ephemeral and identical for the app, share extension, and widgets; CI does not commit new version numbers. Web CI skips its legacy cross-platform prebuild bumper.

Uploads are serialized and Apple processing must reach `VALID` within 20 minutes. A timeout means an upload may exist but is not yet confirmed; inspect App Store Connect before retrying. CI retains IPA, dSYMs and test results. Upload does not submit for App Store review or automatically invite testers.

Local preflight: `python -m unittest discover -s laterbox-ios/ci -p 'test_*.py'` after installing `requirements.txt`. `signing.py` mutates signing settings only in the ephemeral release checkout. `verify_archive.py` validates signed identities, versions and App Group before export.

## Native test locations

Swift unit and migration tests live in `laterbox-ios/laterbox-iosTests/`; capture UI tests live in `laterbox-ios/laterbox-iosUITests/`. Paths are relative to the repository root. Use the native Xcode test targets when changing app behavior, alongside the Python release-tooling preflight.
