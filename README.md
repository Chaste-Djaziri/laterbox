# LaterBox

A local-first save-for-later app with native clients, a web app, and browser extensions.

## Projects

| Directory | Implementation |
| --- | --- |
| `laterbox-ios/` | Native Apple application and share extension in Swift/SwiftUI |
| `laterbox-android/` | Native Android application in Kotlin/Jetpack Compose |
| `laterbox-web/` | Next.js, React, and TypeScript web app |
| `laterbox-extension/` | TypeScript browser extensions for Chromium, Firefox, and Safari |
| `safari_app/` | Native Safari extension host |
| `supabase/` | PostgreSQL migrations and TypeScript edge functions |
| `assets/` | Shared branding and store artwork |

Windows and Linux native applications are future work. The Apple project contains macOS-specific source, but its current release scheme targets iOS; a standalone macOS release target must be verified separately.

## Development

For the web app, install Node.js and run:

```sh
cd laterbox-web
npm ci
npm run dev
```

Open `laterbox-ios/laterbox-ios.xcodeproj` in Xcode and select the `laterbox-ios` scheme. See [Apple CI instructions](laterbox-ios/ci/README.md) for the configured toolchain, signing, and tests.

Open `laterbox-android/` in Android Studio. The project uses JDK 17 and Android SDK 36. Set `SUPABASE_URL` and `SUPABASE_KEY` in its ignored `local.properties` file.

```sh
cd extension
npm ci
npm run typecheck
npm run build:all
```

See [extension setup](laterbox-extension/README.md), [deployment](docs/deployment.md), [architecture](docs/architecture.md), and [contributing](CONTRIBUTING.md).

## License and support

See [LICENSE](LICENSE), [SECURITY.md](SECURITY.md), [SUPPORT.md](SUPPORT.md), and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
