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

For the web app and browser extensions, use Node.js 22 to match CI. Start the web app with:

```sh
cd laterbox-web
npm ci
npm run dev
```

Open `laterbox-ios/laterbox-ios.xcodeproj` in Xcode and select the `laterbox-ios` scheme. See [Apple CI instructions](laterbox-ios/ci/README.md) for the configured toolchain, signing, and tests.

Open `laterbox-android/` in Android Studio. The project uses JDK 17 and Android SDK 36. Set `SUPABASE_URL` and `SUPABASE_KEY` in its ignored `local.properties` file.

```sh
cd laterbox-extension
npm ci
npm run typecheck
npm run build:all
```

See [extension setup](laterbox-extension/README.md), [deployment](docs/deployment.md), [architecture](docs/architecture.md), and [contributing](CONTRIBUTING.md).

## Local full-stack development

Use the local stack when testing authenticated sync, attachments, or email on the web, extensions, Android, and iOS. It runs Supabase locally in Docker, uses Supabase's bundled Mailpit inbox, and replaces Cloudflare R2 with local MinIO.

```sh
scripts/local-stack.sh start
# In a second terminal, while exercising Edge Functions:
scripts/local-stack.sh functions
# To erase and recreate only local Supabase data:
scripts/local-stack.sh reset
```

The startup command detects the active private LAN address, creates ignored configuration files for the web app, Edge Functions, Android, and an Xcode `LaterBoxLocal` Debug scheme. Start the web app on all interfaces with `cd laterbox-web && npm run dev -- --hostname 0.0.0.0`, then use the printed LAN address from a simulator, emulator, or physical device on the same network. In Xcode, choose the generated `LaterBoxLocal` scheme; release builds always retain their hosted endpoints.

Mailpit is available at `http://LAN_IP:54324`; MinIO's console is at `http://LAN_IP:9001`. Run `scripts/local-stack.sh stop` to stop the local services while preserving their data. The stack never runs `supabase link`, `supabase db push`, or a Cloudflare command, and it rejects hosted Supabase and Cloudflare R2 endpoints before writing local credentials.

## License and support

See [CHANGELOG.md](CHANGELOG.md) for notable updates.

See [LICENSE](LICENSE), [SECURITY.md](SECURITY.md), [SUPPORT.md](SUPPORT.md), and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Native setup guides

Use [Android setup](laterbox-android/README.md), [Apple CI](laterbox-ios/ci/README.md), and [web setup](laterbox-web/README.md) for project-specific build and test instructions.
