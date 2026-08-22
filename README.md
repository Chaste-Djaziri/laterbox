# laterbox

<p align="center">
  <img src="assets/branding/laterbox-logo.png" alt="laterbox logo" width="120" />
</p>

<h3 align="center">Save anything now. Read, watch & organize later.</h3>

<p align="center">
  <a href="https://laterbox.micorp.pro"><strong>Live Web App</strong></a> •
  <a href="#quick-start"><strong>Quick Start</strong></a> •
  <a href="docs/architecture.md"><strong>Architecture</strong></a> •
  <a href="docs/deployment.md"><strong>Deployment</strong></a> •
  <a href="docs/browser-extensions.md"><strong>Browser Extensions</strong></a>
</p>

---

## ✨ Features

- ⚡ **Universal Quick Capture**: Capture links, notes, images, and documents across iOS, macOS, Android, Web, and Browser Extensions.
- 🔄 **Offline-First & Cloud Sync**: Local-first SQLite database with background synchronization to Supabase with real-time updates.
- 🏷️ **Smart Organization**: Full-text search, customizable tags, categories (Articles, Videos, Notes, Archive), and pinned favorites.
- 🎨 **Modern Design & Dark Mode**: Sleek dark and light themes with fluid micro-interactions and responsive layouts.
- 🌐 **Browser Extensions**: Manifest V3 extensions for Chrome, Safari, and Firefox with sidepanel reading mode and one-click clipping.
- 💻 **Native Desktop Integrations**: System tray support, macOS share sheet extension, and global keyboard shortcuts (`Cmd+Shift+Space`).
- 🔔 **Instant Web Update Detector**: Live version polling with non-intrusive floating corner reload prompts for instant zero-downtime updates.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Mobile & Desktop** | [Flutter](https://flutter.dev) (iOS, macOS, Android, Web, Windows, Linux) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev) |
| **Backend & Auth** | [Supabase](https://supabase.com) (PostgreSQL, Row Level Security, Storage, Edge Functions) |
| **Web Hosting** | [Cloudflare Pages](https://pages.cloudflare.com) |
| **Browser Extensions** | TypeScript + Vite (Manifest V3 for Safari, Chrome, and Firefox) |

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.0`)
- [Node.js](https://nodejs.org) (v18+) for building browser extensions

### 1. Clone & Run Flutter Application
```bash
git clone https://github.com/Chaste-Djaziri/laterbox.git
cd laterbox

# Install dependencies
flutter pub get

# Run tests
flutter test

# Launch on your preferred device / browser
flutter run
```

*Note: The production backend and configuration are built-in by default. No additional `.env` files are required to get started.*

---

## 🧩 Browser Extensions

Manifest V3 browser extensions are located in the [`extension/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/extension) directory.

### Build and Package All Extensions:
```bash
cd extension
npm install
npm run package
```

Generated store ZIP packages:
- `extension/dist/laterbox-chrome-extension.zip`
- `extension/dist/laterbox-safari-extension.zip`
- `extension/dist/laterbox-firefox-extension.zip`

See [`docs/browser-extensions.md`](docs/browser-extensions.md) for local installation instructions.

---

## 📦 Deployment & Publishing

- **Web (Cloudflare Pages)**: Run `python3 scripts/deploy_web.py` to auto-increment version metadata and deploy live to Cloudflare Pages.
- **iOS & macOS (App Store / TestFlight)**:
  - iOS Archive: `DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer flutter build ipa --release`
  - macOS Archive: `DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer xcodebuild archive -workspace macos/Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=macOS' -archivePath build/macos/archive/Runner.xcarchive`

Detailed deployment steps are available in [`docs/deployment.md`](docs/deployment.md).

---

## 📚 Detailed Documentation

- 🏛️ [System Architecture & Data Flow](docs/architecture.md)
- 🧩 [Browser Extension Guide](docs/browser-extensions.md)
- 🚀 [Deployment & Release Workflows](docs/deployment.md)
- 🖥️ [Desktop & System Integrations](docs/desktop-features.md)

---

## 📄 License

This project is proprietary and confidential. All rights reserved.
