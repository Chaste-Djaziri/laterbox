# LaterBox architecture

LaterBox has separate native Apple and Android applications, a Next.js web application, browser extensions, and a shared Supabase backend.

## Clients

- `laterbox-ios/`: Swift/SwiftUI views, SwiftData persistence, native capture, and Apple integrations. The release scheme currently targets iOS; macOS-specific source remains for native macOS work.
- `laterbox-android/`: Kotlin/Jetpack Compose, Room persistence, and WorkManager synchronization.
- `laterbox-web/`: Next.js/React, account-scoped local caching and pending capture queues, plus authenticated Supabase synchronization.
- `laterbox-extension/` and `safari_app/`: browser capture and its native Safari host. Extensions use scoped connection credentials rather than exposing service-role keys.

## Shared services

`supabase/` owns PostgreSQL migrations, Row-Level Security, storage contracts, and edge functions. The web app also provides enrichment, entitlement, and notification APIs. Each client implements its own native UI and device persistence; shared interfaces are data and service contracts rather than a common UI runtime.

`assets/` contains shared branding. `version.json` supplies release metadata, including the Android build configuration. `scripts/bump_version.js` synchronizes the maintained Apple, web, and extension version files.

Windows and Linux native clients are not yet present. Removing their legacy runners does not create replacement applications.

## Apple source map

Native models are in `laterbox-ios/laterbox-ios/Models/`, views in `Views/`, and integrations in `Services/`. `IOSCloudSync.swift` and `SyncCoordinator.swift` are starting points for sync work; `SharedCaptureImporter.swift` handles shared capture imports.

## Android source map

Native source is under `laterbox-android/app/src/main/java/com/example/laterbox/`. Room models live in `data/local/`, background synchronization in `data/sync/`, and Compose screens in `ui/`. See [Android setup](../laterbox-android/README.md).

## Web source map

`laterbox-web/src/app/api/` owns Next.js server endpoints. `src/lib/store/` holds application contexts, `src/lib/supabase/` owns the Supabase client contract, and `src/lib/extension/` owns web-side extension integration.
