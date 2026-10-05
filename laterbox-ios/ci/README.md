# Native iOS and web releases

Only two Actions workflows remain. Pushes to `main` affecting `laterbox-ios/**` run native Swift/UI tests, an App Store archive and a TestFlight upload. `laterbox-web/**` pushes validate the web app and backend contracts, build OpenNext and deploy Cloudflare. Changes to the corresponding workflow also trigger that workflow. Pull requests validate without signing/upload/deploy. Web PRs affecting Supabase run backend contract checks. Unrelated Flutter/Android/desktop changes do not trigger either push workflow. Manual releases require `main`.

iOS uses GitHub's `xcode-27` runner (a macOS build host, not a macOS product release). The deployment target stays iOS 27.0. Both the native app `pro.micorp.laterbox` and extension `pro.micorp.laterbox.ShareExtension` retain team `LS42X27YFY` and App Group `group.pro.micorp.laterbox` from the existing Flutter release identity.

Existing repository secrets used:

- `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`: Apple Distribution P12 and password.
- `APPLE_PROVISIONING_PROFILE_BASE64`, `APPLE_SHARE_EXTENSION_PROVISIONING_PROFILE_BASE64`: current App Store profiles for the app and extension, including the App Group.
- `APPLE_TEAM_ID`: `LS42X27YFY`.
- `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect API key authorized to read builds and upload to the existing app.
- `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`: unchanged Cloudflare deployment credentials.

Secrets are never logged. Missing, expired, development or mismatched profiles stop release before archive. Temporary keychains, API keys and installed profiles are removed in an always-run cleanup step. Simulator PR tests use no Apple secrets.

Release metadata comes from root `version.json`. If App Store versions are already at or above the repository version, CI selects the next patch above them. The build number exceeds both repository and all existing App Store Connect build numbers. These overrides are ephemeral and identical on app and extension; no CI version commits are made. Web CI skips its legacy cross-platform prebuild bumper.

Uploads are serialized and Apple processing must reach `VALID` within 20 minutes. A timeout means an upload may exist but is not yet confirmed; inspect App Store Connect before retrying. CI retains IPA, dSYMs and test results. Upload does not submit for App Store review or automatically invite testers.

Local preflight: `python -m unittest discover -s laterbox-ios/ci -p 'test_*.py'` after installing `requirements.txt`. `signing.py` mutates signing settings only in the ephemeral release checkout. `verify_archive.py` validates signed identities, versions and App Group before export.
