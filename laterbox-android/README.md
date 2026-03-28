# LaterBox Android

Native Kotlin/Jetpack Compose application. Open this directory in Android Studio; the application module is `app/`.

## Toolchain

Use JDK 17 and Android SDK 36. The app currently has minimum SDK 26 and target SDK 36, as configured in `app/build.gradle.kts`.

## Local configuration

Copy `local.properties.example` to ignored `local.properties`, set `sdk.dir` for your machine, and configure `SUPABASE_URL` and `SUPABASE_KEY`. Review the template for optional web API and AI settings.

## Debug build

From this directory run:

```sh
./gradlew assembleDebug --no-daemon
```

Install the debug APK from `app/build/outputs/apk/debug/` on an emulator or device.

## Unit tests

Run `./gradlew test --no-daemon`. CI also runs `python3 -m unittest discover -s ci -p "test_*.py"` for release tooling.

## Data and synchronization

Room entities and DAOs live in `app/src/main/java/com/example/laterbox/data/local/`. `data/DataRepository.kt` coordinates data access and `data/sync/SyncWorker.kt` contains background synchronization.

## Capture and navigation

`ShareActivity.kt` handles native sharing. `MainActivity.kt`, `AppNavigation.kt`, and `ui/` contain app entry, navigation, and Compose screens beneath `app/src/main/java/com/example/laterbox/`.
