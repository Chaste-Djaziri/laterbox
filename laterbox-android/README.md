# LaterBox Android

Native Kotlin/Jetpack Compose application. Open this directory in Android Studio; the application module is `app/`.

## Toolchain

Use JDK 17 and Android SDK 36. The app currently has minimum SDK 26 and target SDK 36, as configured in `app/build.gradle.kts`.

## Local configuration

Copy `local.properties.example` to ignored `local.properties`, set `sdk.dir` for your machine, and configure `SUPABASE_URL` and `SUPABASE_KEY`. Review the template for optional web API and AI settings.
