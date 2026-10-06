# Deployment

## Web

The Next.js application lives in `laterbox-web/`. `.github/workflows/release.yml` validates types, unit tests, and backend contracts, then builds and deploys through OpenNext to Cloudflare Workers. Configure the workflow's Cloudflare secrets before deployment.

For a local preview run `npm run dev` in `laterbox-web/`. For a production build use the existing package scripts; version metadata is managed by `scripts/bump_version.js`.

## Apple

Open `laterbox-ios/laterbox-ios.xcodeproj` and select `laterbox-ios`. `.github/workflows/ios.yml` runs native tests, validates signing, archives the app and share extension, and uploads to TestFlight. See [the native CI guide](../laterbox-ios/ci/README.md).

The current release scheme targets iOS. macOS-specific source does not by itself establish a signed macOS product; configure and validate a native macOS release target before publishing.

## Android

Open `laterbox-android/` in Android Studio using JDK 17 and SDK 36. Configure public Supabase client values in ignored `local.properties`, then build a signed Android App Bundle using Android Studio. Configure release signing and Play Console separately.

## Extensions and backend

Build browser bundles from `laterbox-extension/` using `npm run build:all`. The Safari host remains in `safari_app/`; the Xcode Cloud post-clone hook builds and copies its extension assets.

Deploy migrations and functions from `supabase/` using the project's existing Supabase workflow. Preserve Row-Level Security and keep service credentials server-side.

Windows and Linux native packaging is future work; the legacy platform runners and packaging scripts have been removed.
