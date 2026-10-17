# Deployment

## Web

The Next.js application lives in `laterbox-web/`. `.github/workflows/release.yml` validates types, unit tests, and backend contracts, then builds and deploys through OpenNext to Cloudflare Workers. Configure the workflow's Cloudflare secrets before deployment.

For a local preview run `npm run dev` in `laterbox-web/`. For a production build use the existing package scripts; version metadata is managed by `scripts/bump_version.js`.

## Apple

Open `laterbox-ios/laterbox-ios.xcodeproj` and select `laterbox-ios`. `.github/workflows/ios.yml` runs native tests, validates signing, archives the app and share extension, uploads to TestFlight, and attaches the IPA to the shared GitHub Release. See [the native CI guide](../laterbox-ios/ci/README.md).

The current release scheme targets iOS. macOS-specific source does not by itself establish a signed macOS product; configure and validate a native macOS release target before publishing.

## Android

Open `laterbox-android/` in Android Studio using JDK 17 and SDK 36. Configure public Supabase client values in ignored `local.properties`, then build a signed Android App Bundle using Android Studio. Configure release signing and Play Console separately.

## Extensions and backend

Build browser bundles from `laterbox-extension/` using `npm run build:all`. The Safari host remains in `safari_app/`; the Xcode Cloud post-clone hook builds and copies its extension assets.

Deploy migrations and functions from `supabase/` using the project's existing Supabase workflow. Preserve Row-Level Security and keep service credentials server-side.

Windows and Linux native packaging is future work; the legacy platform runners and packaging scripts have been removed.

## Android automation

`.github/workflows/android.yml` runs Gradle tests and produces AAB/APK artifacts. Main-branch release runs attach Android files to GitHub Releases and submit to Play when service-account credentials are configured. See [Android release setup](../laterbox-android/README.md).

## Extension automation

`.github/workflows/extensions.yml` validates types, tests capture behavior, and runs `npm run package`. It uploads browser ZIP artifacts and attaches them to GitHub Releases on eligible main runs; browser-store publication remains a separate step.

## Web release triggers

The web workflow watches web source, extension source, root `version.json`, release scripts, the changelog, and its own workflow on main pushes. Supabase changes also trigger PR contract checks. Inspect `release.yml` before relying on a backend-only push to deploy anything.

Every platform workflow uploads `CHANGELOG.md` as a build artifact and includes it in the shared GitHub Release. `scripts/prepare_release_assets.sh` carries forward assets already present on the current release and then the previous non-draft release, so a web-only, iOS-only, Android-only, or extension-only build does not remove the other platform downloads.

## Build output locations

Web CI retains `.open-next/`; Android retains APK, AAB, and R8 mapping artifacts; extension ZIPs are built under `laterbox-extension/dist/`. Apple output handling is documented in the [native CI guide](../laterbox-ios/ci/README.md).
