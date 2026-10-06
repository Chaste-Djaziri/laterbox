# LaterBox architecture

LaterBox has separate native Apple and Android applications, a Next.js web application, browser extensions, and a shared Supabase backend.

## Clients

- `laterbox-ios/`: Swift/SwiftUI views, SwiftData persistence, native capture, and Apple integrations. The release scheme currently targets iOS; macOS-specific source remains for native macOS work.
- `laterbox-android/`: Kotlin/Jetpack Compose, Room persistence, and WorkManager synchronization.
- `laterbox-web/`: Next.js/React, account-scoped local caching and pending capture queues, plus authenticated Supabase synchronization.
- `extension/` and `safari_app/`: browser capture and its native Safari host. Extensions use scoped connection credentials rather than exposing service-role keys.

## Shared services

`supabase/` owns PostgreSQL migrations, Row-Level Security, storage contracts, and edge functions. The web app also provides enrichment, entitlement, and notification APIs. Each client implements its own native UI and device persistence; shared interfaces are data and service contracts rather than a common UI runtime.

`assets/` contains shared branding. `version.json` supplies release metadata, including the Android build configuration. `scripts/bump_version.js` synchronizes the maintained Apple, web, and extension version files.

Windows and Linux native clients are not yet present. Removing their legacy runners does not create replacement applications.
