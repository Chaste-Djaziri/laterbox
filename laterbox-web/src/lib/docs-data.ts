export interface DocSection {
  id: string;
  title: string;
  items: DocItem[];
}

export interface DocHeading {
  id: string;
  text: string;
  level: number;
}

export interface DocItem {
  slug: string;
  title: string;
  navTitle?: string;
  description: string;
  category: string;
  badge?: string;
  headings: DocHeading[];
  content: string; // Markdown or rich HTML-friendly content
}

export const DOCS_SECTIONS: DocSection[] = [
  {
    id: 'getting-started',
    title: 'Getting Started',
    items: [
      {
        slug: 'introduction',
        title: 'Introduction & Overview',
        navTitle: 'Introduction',
        description: 'Learn what LaterBox is, the local-first philosophy, and how it differs from traditional bookmarks.',
        category: 'Getting Started',
        headings: [
          { id: 'what-is-laterbox', text: 'What is LaterBox?', level: 2 },
          { id: 'core-philosophy', text: 'The Local-First Philosophy', level: 2 },
          { id: 'key-features', text: 'Core Capabilities', level: 2 },
          { id: 'ecosystem-matrix', text: 'Supported Ecosystem Matrix', level: 2 },
          { id: 'next-steps', text: 'Next Steps', level: 2 },
        ],
        content: `
## What is LaterBox?

**LaterBox** is an open-source, local-first personal knowledge vault and universal save-for-later companion. It replaces cluttered browser tabs, forgotten reading lists, and siloed bookmark bars with a blazing-fast, unified system that works seamlessly across **macOS, Windows, Linux, iOS, Android, and all major web browsers**.

Traditional bookmark managers store links on remote servers or obscure browser menus where saved items are quickly forgotten. LaterBox treats every captured link as an enriched, offline-available knowledge artifact with automatic metadata extraction, distraction-free reading mode, and native ad-free media playback.

---

## The Local-First Philosophy

LaterBox is architected from the ground up around **Local-First Software** principles:

1. **Sub-10ms Responsiveness**: All reads and writes hit an embedded local SQLite database (powered by Drift ORM) immediately. No waiting on network roundtrips or spinning loaders.
2. **100% Offline Resilience**: You can search, browse, tag, read cached articles, and capture new links on an airplane or subway without an internet connection.
3. **Seamless Cloud Replication**: When connectivity is available, changes automatically synchronize bidirectionally to Supabase PostgreSQL with real-time updates and Row-Level Security.
4. **Data Ownership & Sovereignty**: Your data stays on your device. You can export your entire vault to JSON or Markdown at any time with a single click.

---

## Core Capabilities

- **⚡ Universal Quick Capture**: System-wide global hotkeys (\`⌥ Space\` on Mac, \`Ctrl+Alt+Space\` on Windows, \`Alt+Space\` on Linux), mobile share sheets, and 1-click browser extension popups.
- **🎬 Distraction-Free Media**: Watch YouTube videos and listen to audio without ads, algorithms, or tracking directly inside your vault.
- **📖 Clean Reader Mode**: Read long-form articles with customizable typography, dark/light themes, and private markdown annotations.
- **🏷️ Deep Search & Collections**: Instant full-text search across titles, URLs, summaries, and personal notes with custom visual collections.
- **🛡️ Zero Telemetry & Privacy**: No tracking pixels, no third-party ad SDKs, and transparent PolyForm Noncommercial licensing.

---

## Supported Ecosystem Matrix

| Platform | Target Artifacts | Capabilities | Status |
|---|---|---|---|
| **macOS** | Universal \`.dmg\`, \`.pkg\` | Spotlight Quick Capture (\`⌥ Space\`), System Tray, Native File Picker | **Production Ready** |
| **Windows** | Inno Setup \`.exe\`, Portable Zip | Hotkey (\`Ctrl+Alt+Space\`), Tray Minimization, Toast Alerts | **Production Ready** |
| **Linux** | AppImage, Tarball | Hotkey (\`Alt+Space\`), SQLite FTS5 Local Storage | **Production Ready** |
| **iOS** | TestFlight Beta / IPA | Native iOS Share Sheet Extension, Biometrics | **Beta** |
| **Android** | Google Play Beta / APK | Android Share Intent Target, Offline Cache | **Beta** |
| **Web** | Next.js 16 (Turbopack) | Instant Guest Sandbox, Cloud Sync, Reader Mode | **Production Ready** |
| **Browser Extension** | Chrome, Firefox, Safari (MV3) | 1-Click Tab Saver, Token Handshake, Sidepanel | **Production Ready** |

---

## Next Steps

- Review the [Prerequisites & Tooling](/docs/prerequisites) before setting up your local environment.
- Configure your [Environment Variables](/docs/environment-variables) for Next.js, Supabase, and Flutter.
- Follow the [Quick Start Guide](/docs/quickstart) to run LaterBox locally in under 5 minutes.
        `,
      },
      {
        slug: 'prerequisites',
        title: 'Prerequisites & Tooling',
        navTitle: 'Prerequisites',
        description: 'Required runtimes, SDKs, compilers, and development tools for building LaterBox from source.',
        category: 'Getting Started',
        headings: [
          { id: 'required-runtimes', text: 'Required Runtimes & SDKs', level: 2 },
          { id: 'flutter-setup', text: 'Flutter & Dart Setup', level: 2 },
          { id: 'node-setup', text: 'Node.js & Package Managers', level: 2 },
          { id: 'supabase-tools', text: 'Supabase CLI & Docker', level: 2 },
          { id: 'platform-toolchains', text: 'Platform Native Compilers', level: 2 },
        ],
        content: `
## Required Runtimes & SDKs

Before contributing or building LaterBox locally, verify that your machine has the following tools installed:

| Tool | Minimum Version | Recommended Version | Purpose |
|---|---|---|---|
| **Flutter SDK** | \`3.29.0\` | \`3.29.1\` (Stable channel) | Core desktop, mobile, and native app runtime |
| **Dart SDK** | \`3.7.0\` | \`3.7.1\` | Dart language & Drift code generation |
| **Node.js** | \`20.0.0\` (LTS) | \`22.x\` | Next.js web application & browser extensions |
| **npm / pnpm** | \`10.x\` | \`pnpm 9.x\` or \`npm 10.x\` | Package manager for web and extension suites |
| **Supabase CLI** | \`1.150.0+\` | Latest via Homebrew / Scoop | Local database migrations and Edge Functions |
| **Docker Desktop** | \`24.0.0+\` | Latest | Local Supabase PostgreSQL & Studio stack |
| **Deno** | \`1.40.0+\` | \`1.45.0+\` | Supabase Edge Functions development & testing |

---

## Flutter & Dart Setup

Ensure Flutter is installed and accessible in your system \`$PATH\`:

\`\`\`bash
# Check your Flutter installation
flutter doctor -v

# Verify you are on the stable channel
flutter channel stable
flutter upgrade
\`\`\`

> **Note**: If developing for macOS or iOS, ensure Xcode command-line tools are installed (\`xcode-select --install\`). For Windows, install Visual Studio 2022 with **Desktop development with C++**.

---

## Node.js & Package Managers

The web dashboard and browser extensions use modern JavaScript/TypeScript tooling:

\`\`\`bash
# Verify Node.js version
node -v # Should return v20.x or higher

# Verify npm
npm -v
\`\`\`

---

## Supabase CLI & Docker

The Supabase CLI orchestrates local PostgreSQL, GoTrue authentication, Storage, and Deno Edge Functions in Docker containers:

\`\`\`bash
# macOS (Homebrew)
brew install supabase/tap/supabase

# Windows (Scoop / Winget)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Linux (Debian/Ubuntu)
curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.deb -o supabase.deb
sudo dpkg -i supabase.deb
\`\`\`

---

## Platform Native Compilers

- **macOS Desktop**: Xcode 15 or 16, CocoaPods (\`sudo gem install cocoapods\`).
- **Windows Desktop**: Visual Studio 2022 (MSVC v143, Windows 10/11 SDK), Inno Setup 6 (for packaging \`.exe\`).
- **Linux Desktop**: \`clang\`, \`cmake\`, \`ninja-build\`, \`pkg-config\`, \`libgtk-3-dev\`, \`libsecret-1-dev\`.
- **Android Mobile**: Android Studio Ladybug or newer, Android SDK Platform 34, JDK 17.
- **iOS Mobile**: Apple Developer certificate / provision profile for physical device deployment.
        `,
      },
      {
        slug: 'environment-variables',
        title: 'Environment Variables & Configuration',
        navTitle: 'Environment Variables',
        description: 'Comprehensive guide to all required and optional environment keys across Web, Supabase, Flutter, and Extensions.',
        category: 'Getting Started',
        headings: [
          { id: 'web-variables', text: 'Next.js Web Variables (.env.local & .dev.vars)', level: 2 },
          { id: 'edge-variables', text: 'Supabase Edge Functions Secrets', level: 2 },
          { id: 'flutter-variables', text: 'Flutter Client Configuration', level: 2 },
          { id: 'extension-variables', text: 'Browser Extension Configuration', level: 2 },
          { id: 'security-best-practices', text: 'Security & Key Handling Rules', level: 2 },
        ],
        content: `
## Next.js Web Variables (.env.local & .dev.vars)

Create a \`laterbox-web/.env.local\` file for local development or \`.dev.vars\` for Cloudflare Pages local testing:

\`\`\`bash
# ==============================================================================
# Supabase Configuration
# ==============================================================================
# Your Supabase Project URL (local: http://127.0.0.1:54321, remote: https://xyz.supabase.co)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co

# Public Anonymous API Key (safe for client-side browsers)
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Service Role Secret Key (REQUIRED for admin tasks: account deletion cascade RPC)
# CAUTION: NEVER expose this on client-side!
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ==============================================================================
# Public App Settings
# ==============================================================================
# Canonical public application URL
NEXT_PUBLIC_APP_URL=https://laterbox.dev

# ==============================================================================
# Optional Cloudflare / Proxy Tokens
# ==============================================================================
# Cloudflare API token for release caching & purge
CLOUDFLARE_API_TOKEN=your_cf_api_token_here
\`\`\`

---

## Supabase Edge Functions Secrets

The \`enrich-url\` edge function retrieves metadata and parses YouTube oEmbed links. Set these in your Supabase project:

\`\`\`bash
# Set secrets for local testing (supabase/functions/.env)
supabase secrets set --env-file ./supabase/functions/.env

# Or set individual remote project secrets:
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
supabase secrets set SUPABASE_ANON_KEY=eyJhbGci...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...

# Optional: Google / YouTube Data API Key for fallback high-res metadata
supabase secrets set YOUTUBE_API_KEY=AIzaSy...
\`\`\`

---

## Flutter Client Configuration

The Flutter mobile and desktop apps can read credentials at compile time via \`--dart-define\` or from \`lib/core/constants/api_constants.dart\`:

\`\`\`bash
# Run with compile-time defines:
flutter run -d macos \\
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
\`\`\`

| Variable | Description | Client Exposure |
|---|---|---|
| \`SUPABASE_URL\` | Supabase API Gateway endpoint | Safe (Public) |
| \`SUPABASE_ANON_KEY\` | Row-Level Security enabled anonymous key | Safe (Public) |

---

## Browser Extension Configuration

In \`extension/.env\` (built into \`extension/dist/\`):

\`\`\`bash
# Base URL for OAuth token handshake and extension connect page
VITE_LATERBOX_APP_URL=https://laterbox.dev
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOi...
\`\`\`

---

## Security & Key Handling Rules

1. **Never commit secrets**: Ensure \`.env\`, \`.env.local\`, \`.dev.vars\`, and \`*.key\` are in your \`.gitignore\`.
2. **Anonymous vs Service Role**: The \`NEXT_PUBLIC_SUPABASE_ANON_KEY\` is constrained by PostgreSQL Row Level Security. The \`SUPABASE_SERVICE_ROLE_KEY\` bypasses all RLS and must strictly remain on server-side endpoints (such as \`/api/account/delete\`).
3. **Rotating Keys**: If a service role key is compromised, regenerate it immediately in the Supabase Dashboard under **Project Settings > API**.
        `,
      },
      {
        slug: 'quickstart',
        title: 'Quick Start & Installation',
        navTitle: 'Quickstart',
        description: 'Step-by-step instructions to install, build, and run LaterBox across all platforms.',
        category: 'Getting Started',
        headings: [
          { id: 'clone-repo', text: '1. Clone Repository', level: 2 },
          { id: 'start-supabase', text: '2. Start Supabase (Local or Cloud)', level: 2 },
          { id: 'run-web', text: '3. Run Next.js Web App', level: 2 },
          { id: 'run-flutter', text: '4. Run Flutter Desktop & Mobile', level: 2 },
          { id: 'build-extensions', text: '5. Build Browser Extensions', level: 2 },
        ],
        content: `
## 1. Clone Repository

Clone the LaterBox monorepo to your local machine:

\`\`\`bash
git clone https://github.com/Chaste-Djaziri/laterbox.git
cd laterbox
\`\`\`

---

## 2. Start Supabase (Local or Cloud)

### Option A: Local Docker Stack (Recommended for offline development)
\`\`\`bash
# Start local PostgreSQL, GoTrue, Realtime, and Storage in Docker
supabase start

# Apply SQL migrations and RLS policies
supabase db reset
\`\`\`

### Option B: Cloud Supabase Project
1. Create a free project on **[supabase.com](https://supabase.com)**.
2. Link your local CLI:
   \`\`\`bash
   supabase link --project-ref your-project-id
   supabase db push
   \`\`\`

---

## 3. Run Next.js Web App

Navigate to \`laterbox-web/\`, install dependencies, and start the Turbopack dev server:

\`\`\`bash
cd laterbox-web
npm install

# Copy sample environment variables
cp .env.example .env.local

# Start development server on port 3000
npm run dev
\`\`\`

Open **[http://localhost:3000](http://localhost:3000)** in your browser. You can test the app in **Guest Sandbox Mode** immediately or sign in with your Supabase credentials.

---

## 4. Run Flutter Desktop & Mobile

In the root repository directory, fetch Flutter dependencies and start the app:

\`\`\`bash
# Fetch Dart & Flutter dependencies
flutter pub get

# Run on macOS Desktop
flutter run -d macos

# Run on Windows Desktop
flutter run -d windows

# Run on Linux Desktop
flutter run -d linux

# Run on iOS Simulator or Android Emulator
flutter run -d ios
flutter run -d android
\`\`\`

---

## 5. Build Browser Extensions

Navigate to \`extension/\` to compile the Manifest V3 extension bundle:

\`\`\`bash
cd extension
npm install

# Build extension packages
npm run package
\`\`\`

To load the extension into your browser:
1. Open **Chrome** and navigate to \`chrome://extensions/\`.
2. Toggle on **Developer mode** in the top right.
3. Click **Load unpacked** and select the \`extension/dist/chromium/\` folder.
        `,
      },
      {
        slug: 'shortcuts',
        title: 'Keyboard Shortcuts & Hotkeys',
        navTitle: 'Shortcuts & Hotkeys',
        description: 'Comprehensive cheat sheet of desktop hotkeys, web navigation shortcuts, and capture triggers.',
        category: 'Getting Started',
        headings: [
          { id: 'global-desktop', text: 'Global Desktop Hotkeys', level: 2 },
          { id: 'web-navigation', text: 'Web & Library Hotkeys', level: 2 },
          { id: 'extension-hotkeys', text: 'Browser Extension Shortcuts', level: 2 },
        ],
        content: `
## Global Desktop Hotkeys

These shortcuts work globally across your entire operating system when the LaterBox desktop app is running in the background:

| Action | macOS Hotkey | Windows Hotkey | Linux Hotkey |
|---|---|---|---|
| **Open Quick Capture** | \`⌥ Space\` (Option+Space) | \`Ctrl + Alt + Space\` | \`Alt + Space\` |
| **Submit / Save Link** | \`⌘ Enter\` | \`Ctrl + Enter\` | \`Ctrl + Enter\` |
| **Attach Files / Media** | \`⌘ O\` | \`Ctrl + O\` | \`Ctrl + O\` |
| **Dismiss / Hide Bar** | \`Escape\` | \`Escape\` | \`Escape\` |

---

## Web & Library Hotkeys

When navigating the LaterBox web dashboard or desktop main window:

| Action | Shortcut | Description |
|---|---|---|
| **Omnisearch** | \`/\` or \`⌘ K\` | Focuses the instant search input immediately |
| **New Item** | \`C\` or \`N\` | Opens the manual item creation modal |
| **Filter Articles** | \`1\` | Switches category filter to Articles |
| **Filter Videos** | \`2\` | Switches category filter to Videos |
| **Filter Notes** | \`3\` | Switches category filter to Notes |
| **Toggle Theme** | \`⌘ Shift L\` | Cycles between Light, Dark, and System theme |
| **Close Modal** | \`Escape\` | Closes active preview sheet or dialog |

---

## Browser Extension Shortcuts

| Action | Chrome / Brave | Firefox | Safari |
|---|---|---|---|
| **Save Active Tab** | \`⌘ Shift S\` / \`Ctrl+Shift+S\` | \`Alt + Shift + S\` | \`⌘ Shift S\` |
| **Toggle Sidepanel** | \`⌘ Shift L\` | \`Alt + Shift + L\` | Toolbar Icon |
        `,
      },
    ],
  },
  {
    id: 'architecture',
    title: 'Architecture',
    items: [
      {
        slug: 'system-architecture',
        title: 'System Architecture & Data Flow',
        navTitle: 'System Architecture',
        description: 'Deep dive into the monorepo architecture, Flutter core, Drift SQLite database, and Supabase integration.',
        category: 'Architecture',
        headings: [
          { id: 'monorepo-structure', text: 'Monorepo Structure', level: 2 },
          { id: 'data-flow', text: 'Data Flow & Synchronization', level: 2 },
          { id: 'database-engine', text: 'Database Engine: Drift & SQLite', level: 2 },
        ],
        content: `
## Monorepo Structure

LaterBox is organized as a unified monorepo containing the Flutter core, Next.js web application, browser extensions, and Supabase edge backend:

\`\`\`text
laterbox/
├── lib/                   # Flutter cross-platform core application
│   ├── core/              # Database (Drift), theme, network, auth, desktop windowing
│   ├── features/          # Feature slices: auth, inbox, quick_capture, reader, search
│   └── main.dart          # App entry point with platform-adaptive initialization
├── laterbox-web/          # Next.js 16 web app, landing page, download hub & docs reader
│   ├── src/app/           # App Router routes (/inbox, /download, /docs, /guide, API proxy)
│   ├── src/components/    # UI design system components
│   └── src/lib/           # Store context, Supabase client, versioning, docs data
├── extension/             # Manifest V3 browser extension suite
│   ├── src/               # Background service worker, popup UI, sidepanel reader
│   └── manifests/         # Chromium, Firefox, and Safari extension manifests
├── supabase/              # Supabase infrastructure
│   ├── migrations/        # SQL schema, RLS policies, indexes, and cascades
│   └── functions/         # Deno Edge Functions (enrich-url with YouTube oEmbed)
└── docs/                  # Markdown documentation & architectural specifications
\`\`\`

---

## Data Flow & Synchronization

The data lifecycle in LaterBox follows a strict **optimistic local-first** pattern:

1. **Capture Event**: User saves a link via Quick Capture bar, Share Sheet, or Web App.
2. **Local Write**: The item is written immediately to the local Drift SQLite database with a temporary UUID and \`sync_status = 'pending'\`.
3. **Instant UI Update**: The UI stream receives the updated SQLite entity and renders it in **< 10ms**.
4. **Edge Enrichment**: A background worker dispatches a request to the \`enrich-url\` Supabase Edge Function to extract OpenGraph tags, title, favicons, and video thumbnails.
5. **Bidirectional Sync**: When online, the sync manager pushes local changes to Supabase PostgreSQL and pulls remote updates.

---

## Database Engine: Drift & SQLite

The mobile and desktop applications utilize **[Drift](https://drift.simonbinder.eu/)** (formerly Moor), a reactive persistence library for Dart & SQLite.

- **Reactive Queries**: UI components subscribe to Dart Streams that automatically emit fresh state whenever SQLite tables change.
- **Optimized FTS5 Indexing**: Full-text search queries execute directly against SQLite's native FTS5 engine, providing instant fuzzy matching across thousands of saved items without network latency.
        `,
      },
      {
        slug: 'offline-sync',
        title: 'Offline-First & Data Sync Engine',
        navTitle: 'Offline & Sync Engine',
        description: 'How LaterBox handles conflict resolution, optimistic local state, and bidirectional cloud synchronization.',
        category: 'Architecture',
        headings: [
          { id: 'optimistic-writes', text: 'Optimistic Local Writes', level: 2 },
          { id: 'sync-lifecycle', text: 'Sync Lifecycle & Queue', level: 2 },
          { id: 'conflict-resolution', text: 'Conflict Resolution', level: 2 },
        ],
        content: `
## Optimistic Local Writes

Every user interaction—saving links, editing notes, toggling favorites, archiving, or organizing into collections—is applied locally first:

- **Zero Blocking**: The UI never blocks on HTTP requests or waits for Supabase acknowledgments.
- **Immediate State Consistency**: If the user closes the app immediately after saving an item, the item remains safely persisted in SQLite.

---

## Sync Lifecycle & Queue

The background sync manager operates as a reactive state machine:

1. **Change Tracking**: Any local modification increments an internal revision timestamp and flags the entity for sync.
2. **Online Detection**: Connectivity listeners monitor network changes using native OS APIs.
3. **Batch Push**: When online, un-synced items are batched and sent via Supabase REST RPC endpoints.
4. **Real-Time Subscription**: A Supabase Realtime channel listens for PostgreSQL \`INSERT\`, \`UPDATE\`, and \`DELETE\` events on the user's partition and merges them into the local SQLite store.

---

## Conflict Resolution

LaterBox utilizes **Last-Write-Wins (LWW)** with field-level merging based on UTC server timestamps:

- If an item was edited on mobile while offline and edited on desktop concurrently, the newer update timestamp takes precedence.
- Deleted items generate a soft tombstone record that propagates across devices to prevent resurfacing deleted items during sync cycles.
        `,
      },
    ],
  },
  {
    id: 'platforms',
    title: 'Platforms',
    items: [
      {
        slug: 'desktop-companions',
        title: 'Desktop Companions (macOS & Windows)',
        navTitle: 'Desktop Apps',
        description: 'Window management, Spotlight Quick Capture bar, native file attachments picker, and system tray integration.',
        category: 'Platforms',
        headings: [
          { id: 'quick-capture-architecture', text: 'Spotlight Quick Capture Architecture', level: 2 },
          { id: 'window-layering', text: 'Window Layering & Native File Pickers', level: 2 },
          { id: 'system-tray', text: 'System Tray & Background Running', level: 2 },
        ],
        content: `
## Spotlight Quick Capture Architecture

The LaterBox desktop companion features a floating Spotlight-style quick capture modal:

- **Global Hotkey Daemon**: Registers native OS keybinds (\`⌥ Space\` on Mac, \`Ctrl+Alt+Space\` on Windows) using native platform channels.
- **Frameless Window**: The window operates in a borderless, translucent floating mode centered horizontally in the upper third of the primary screen.
- **Instant Focus**: When invoked, the window forces OS focus directly into the URL input field.

---

## Window Layering & Native File Pickers

To support attaching local screenshots, PDFs, and files from desktop:

- **Layer Priority Management**: The Quick Capture bar uses \`setAlwaysOnTop(true)\` to remain above full-screen IDEs and browser windows.
- **Modal Guard**: When the user opens the native OS file picker (\`pickFiles()\`), the window manager temporarily lowers \`setAlwaysOnTop(false)\` and sets \`isModalOpen = true\` to prevent the capture bar from auto-dismissing on blur.
- **Focus Restoration**: Once a file is selected or canceled, \`setAlwaysOnTop(true)\` and focus are immediately restored.

---

## System Tray & Background Running

- Closing the main window minimizes LaterBox to the system tray / menu bar.
- The global hotkey daemon continues operating with minimal RAM consumption (< 40MB idle).
- Clicking the tray icon reveals quick status, recent items, and quick settings.
        `,
      },
      {
        slug: 'browser-extensions',
        title: 'Manifest V3 Browser Extensions',
        navTitle: 'Browser Extensions',
        description: 'Architecture of the Chrome, Firefox, and Safari extensions, token authentication, and clipping pipelines.',
        category: 'Platforms',
        headings: [
          { id: 'extension-architecture', text: 'Manifest V3 Architecture', level: 2 },
          { id: 'token-connect', text: 'Token Key Authentication', level: 2 },
          { id: 'local-building', text: 'Building & Packaging', level: 2 },
        ],
        content: `
## Manifest V3 Architecture

The LaterBox browser extension is built with **TypeScript** and **Vite**, complying with the latest Manifest V3 standards:

- **Background Service Worker**: Handles token verification, context menu creation, keyboard shortcut listeners, and background network requests to the Supabase ingestion endpoint.
- **Popup UI**: Lightweight React popup providing 1-click save, collection picker, tag selector, and immediate confirmation feedback.
- **Sidepanel Mode**: Allows reading saved articles and taking notes in a side-by-side browser panel while browsing the web.

---

## Token Key Authentication

Users can pair their browser extension to their LaterBox account without entering passwords in the extension:

1. Open **[laterbox.dev/extension/connect](https://laterbox.dev/extension/connect)**.
2. Sign in to your LaterBox account.
3. Click **Generate Connection Key**.
4. The extension automatically exchanges the temporary handshake token for an authenticated API session.

---

## Building & Packaging

To compile and package the extensions locally:

\`\`\`bash
cd extension
npm install

# Build for all targets (Chromium, Firefox, Safari)
npm run package
\`\`\`

Generated packages in \`extension/dist/\`:
- \`laterbox-chrome-extension.zip\`
- \`laterbox-firefox-extension.zip\`
- \`laterbox-safari-extension.zip\`
        `,
      },
      {
        slug: 'mobile-apps',
        title: 'Mobile Applications (iOS & Android)',
        navTitle: 'Mobile Apps',
        description: 'Native mobile companion features, OS Share Sheet integrations, and offline SQLite synchronization.',
        category: 'Platforms',
        headings: [
          { id: 'share-sheet', text: 'OS Share Sheet Receiver', level: 2 },
          { id: 'biometric-security', text: 'Biometric Security & Vault Locks', level: 2 },
          { id: 'offline-caching', text: 'Mobile Offline Caching', level: 2 },
        ],
        content: `
## OS Share Sheet Receiver

LaterBox integrates directly into iOS and Android system share sheets:

- **iOS Share Extension**: Native Swift extension that captures URLs from Safari, YouTube, Twitter/X, and Reddit without opening the full application.
- **Android Intent Receiver**: Listens for \`android.intent.action.SEND\` with MIME type \`text/plain\`, performing immediate background SQLite writes.

---

## Biometric Security & Vault Locks

- Supports **Face ID / Touch ID** on iOS and **BiometricPrompt** on Android.
- Allows users to lock private collections or the entire vault behind biometric authentication.

---

## Mobile Offline Caching

- Articles and metadata are cached in local SQLite.
- Extracted hero images are stored locally using \`flutter_cache_manager\` with automatic LRU cache eviction.
        `,
      },
    ],
  },
  {
    id: 'backend',
    title: 'Backend & API',
    items: [
      {
        slug: 'supabase-backend',
        title: 'Supabase Database & Security Model',
        navTitle: 'Database & Security',
        description: 'PostgreSQL database schema, Row Level Security (RLS) policies, storage buckets, and account deletion cascades.',
        category: 'Backend',
        headings: [
          { id: 'database-schema', text: 'PostgreSQL Schema', level: 2 },
          { id: 'row-level-security', text: 'Row Level Security (RLS) Policies', level: 2 },
          { id: 'cascade-deletion', text: 'Account Deletion & Data Purge', level: 2 },
        ],
        content: `
## PostgreSQL Schema

LaterBox data is partitioned by \`auth.uid()\` in Supabase PostgreSQL:

- **\`items\` table**: Core entity storing \`id\`, \`user_id\`, \`url\`, \`title\`, \`description\`, \`content\`, \`media_type\`, \`preview_image\`, \`is_starred\`, \`is_archived\`, \`created_at\`, \`updated_at\`.
- **\`collections\` table**: User-defined collections with custom colors and icons.
- **\`item_collections\` table**: Many-to-many join table for collection memberships.
- **\`tags\` table**: Granular categorization tags.

---

## Row Level Security (RLS) Policies

All tables strictly enforce PostgreSQL Row-Level Security:

\`\`\`sql
-- Users can only view their own items
CREATE POLICY "Users can view own items"
  ON public.items FOR SELECT
  USING (auth.uid() = user_id);

-- Users can only insert items belonging to their auth UID
CREATE POLICY "Users can insert own items"
  ON public.items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only update their own items
CREATE POLICY "Users can update own items"
  ON public.items FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can only delete their own items
CREATE POLICY "Users can delete own items"
  ON public.items FOR DELETE
  USING (auth.uid() = user_id);
\`\`\`

---

## Account Deletion & Data Purge

When a user deletes their account via **Settings > Danger Zone**:

1. The \`delete_user_account()\` PostgreSQL RPC executes with \`SECURITY DEFINER\`.
2. All records in \`items\`, \`collections\`, and \`tags\` are cascaded and deleted.
3. User files in Supabase Storage buckets are purged.
4. The \`auth.users\` record is deleted via admin Supabase service role API, guaranteeing zero leftover residual data.
        `,
      },
      {
        slug: 'enrich-url-function',
        title: 'Edge Function: enrich-url',
        navTitle: 'Enrich URL Function',
        description: 'Deno Edge Function extracting OpenGraph metadata, YouTube oEmbed previews, and fallback thumbnails.',
        category: 'Backend',
        headings: [
          { id: 'function-overview', text: 'Function Overview', level: 2 },
          { id: 'youtube-oembed', text: 'YouTube oEmbed & Fallback Thumbnail Resolver', level: 2 },
          { id: 'cors-caching', text: 'CORS & Edge Caching', level: 2 },
        ],
        content: `
## Function Overview

The **\`enrich-url\`** Supabase Edge Function (\`supabase/functions/enrich-url/index.ts\`) runs on Deno at Cloudflare Edge locations globally.

When a URL is submitted, the function:
1. Validates and sanitizes the target URL.
2. Checks specialized scrapers (YouTube, GitHub, Spotify, Twitter/X).
3. Fetches the page HTML and extracts OpenGraph (\`og:title\`, \`og:image\`, \`og:description\`), Twitter Card tags, and standard meta tags.
4. Returns a clean JSON payload for instant client storage.

---

## YouTube oEmbed & Fallback Thumbnail Resolver

For YouTube links (including \`watch\`, \`shorts\`, \`embed\`, \`live\`, and \`youtu.be\` short URLs):

1. **Video ID Parser**: Robust regex parser extracts the 11-character video ID.
2. **Unauthenticated oEmbed API**: Queries \`https://www.youtube.com/oembed?url=...&format=json\` to retrieve official video title, author, and high-res thumbnail.
3. **Deterministic Fallback**: If the video is restricted or oEmbed is blocked, deterministically resolves to Google CDN: \`https://i.ytimg.com/vi/<id>/hqdefault.jpg\`.

---

## CORS & Edge Caching

- Fully configured with permissive CORS headers (\`Access-Control-Allow-Origin: *\`) to support calls from mobile apps, desktop clients, and browser extensions.
- Responses include \`Cache-Control: public, max-age=86400\` to reduce redundant scraping on viral links.
        `,
      },
    ],
  },
  {
    id: 'deployment',
    title: 'Deployment & Self-Hosting',
    items: [
      {
        slug: 'deployment-options',
        title: 'Deployment Options & Cloud Hosting',
        navTitle: 'Deployment Options',
        description: 'Deploying LaterBox Web and Supabase backend to Cloudflare Pages, Vercel, Docker, or AWS.',
        category: 'Deployment',
        headings: [
          { id: 'cloudflare-pages', text: 'Deploying to Cloudflare Pages', level: 2 },
          { id: 'vercel-deployment', text: 'Deploying to Vercel', level: 2 },
          { id: 'docker-container', text: 'Deploying with Docker', level: 2 },
          { id: 'edge-functions-deploy', text: 'Deploying Edge Functions', level: 2 },
        ],
        content: `
## Deploying to Cloudflare Pages

LaterBox Web is optimized for **Cloudflare Pages** and Next.js OpenNext:

1. **Connect GitHub Repository** in Cloudflare Pages dashboard.
2. **Build Settings**:
   - **Framework Preset**: \`Next.js\`
   - **Root directory**: \`laterbox-web\`
   - **Build command**: \`npm run build\`
   - **Build output directory**: \`.next\` or \`.open-next/assets\`
3. **Environment Variables**: Add \`NEXT_PUBLIC_SUPABASE_URL\`, \`NEXT_PUBLIC_SUPABASE_ANON_KEY\`, and \`SUPABASE_SERVICE_ROLE_KEY\`.
4. **Custom Domain**: Bind \`laterbox.dev\` and \`docs.laterbox.dev\` in the Cloudflare Pages custom domains settings.

---

## Deploying to Vercel

1. Import the \`laterbox\` repository in **[Vercel Dashboard](https://vercel.com)**.
2. Set **Root Directory** to \`laterbox-web\`.
3. Add your environment variables in the Project Settings.
4. Click **Deploy**. Vercel will build and prerender all 35+ routes automatically.

---

## Deploying with Docker

To run the web app in a containerized environment (e.g. Kubernetes, AWS ECS, DigitalOcean App Platform):

\`\`\`dockerfile
# Dockerfile for laterbox-web
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
\`\`\`

\`\`\`bash
# Build and run Docker image
docker build -t laterbox-web ./laterbox-web
docker run -p 3000:3000 --env-file .env.local laterbox-web
\`\`\`

---

## Deploying Edge Functions

Deploy your Supabase Edge Functions globally:

\`\`\`bash
# Login to Supabase CLI
supabase login

# Deploy enrich-url function
supabase functions deploy enrich-url --project-ref your-project-id
\`\`\`
        `,
      },
      {
        slug: 'self-hosting',
        title: 'Self-Hosting LaterBox (100% Private)',
        navTitle: 'Self-Hosting Guide',
        description: 'Complete guide to hosting your own private LaterBox vault with Docker Compose and custom PostgreSQL.',
        category: 'Deployment',
        headings: [
          { id: 'self-hosting-overview', text: 'Self-Hosting Philosophy', level: 2 },
          { id: 'docker-compose-setup', text: 'Docker Compose Architecture', level: 2 },
          { id: 'applying-migrations', text: 'Initializing Database Schema', level: 2 },
          { id: 'connecting-apps', text: 'Connecting Desktop & Mobile Apps', level: 2 },
          { id: 'vault-backups', text: 'Backup & Vault Exports', level: 2 },
        ],
        content: `
## Self-Hosting Philosophy

LaterBox is designed to give you **100% data sovereignty**. You do not need to rely on any hosted cloud service. You can run your own private Supabase instance on a VPS, Raspberry Pi, or home server.

---

## Docker Compose Architecture

Run the official Supabase self-hosted Docker stack:

\`\`\`bash
# Clone official self-hosted Supabase Docker configuration
git clone --depth 1 https://github.com/supabase/supabase
cd supabase/docker

# Copy environment template
cp .env.example .env

# Generate secure secrets
# (Set POSTGRES_PASSWORD, JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY in .env)

# Launch the entire backend stack
docker compose up -d
\`\`\`

Services started:
- **PostgreSQL Database** (Port \`5432\`)
- **Supabase Studio UI** (Port \`8000\` or \`3000\`)
- **GoTrue Auth Service** (Port \`9999\`)
- **Realtime Server** (Port \`4000\`)
- **Storage Server** (Port \`5000\`)
- **Kong API Gateway** (Port \`8000\`)

---

## Initializing Database Schema

Apply the LaterBox database migrations to your self-hosted PostgreSQL:

\`\`\`bash
cd /path/to/laterbox
supabase db push --db-url "postgresql://postgres:your_password@localhost:5432/postgres"
\`\`\`

This creates the \`items\`, \`collections\`, \`tags\`, and \`item_collections\` tables, along with all security policies and indexes.

---

## Connecting Desktop & Mobile Apps

In your self-hosted setup, configure your client apps:

1. **Web Dashboard**: Set \`NEXT_PUBLIC_SUPABASE_URL=https://supabase.yourdomain.com\` and your self-hosted \`NEXT_PUBLIC_SUPABASE_ANON_KEY\`.
2. **Desktop & Mobile Apps**: Pass your self-hosted URL and Anon Key via \`--dart-define\` during build or update settings in the app.
3. **Browser Extensions**: Set your custom domain in \`extension/.env\`.

---

## Backup & Vault Exports

- **Database Dumps**:
  \`\`\`bash
  docker exec -t supabase-db pg_dump -U postgres postgres > laterbox_backup.sql
  \`\`\`
- **1-Click Vault Export**: Inside the LaterBox Web or Desktop App, go to **Settings > Export Vault** to download your complete data as a single JSON or Markdown archive.
        `,
      },
    ],
  },
  {
    id: 'developer',
    title: 'Community & Legal',
    items: [
      {
        slug: 'contributing',
        title: 'Contributing Guide',
        navTitle: 'Contributing',
        description: 'How to set up your local development environment, run test suites, and submit pull requests.',
        category: 'Developer',
        headings: [
          { id: 'dev-setup', text: 'Development Setup', level: 2 },
          { id: 'testing-guidelines', text: 'Testing Guidelines', level: 2 },
          { id: 'pull-requests', text: 'Submitting Pull Requests', level: 2 },
        ],
        content: `
## Development Setup

1. **Fork and clone** the repository:
   \`\`\`bash
   git clone https://github.com/Chaste-Djaziri/laterbox.git
   cd laterbox
   \`\`\`
2. **Install Flutter & Web Dependencies**:
   \`\`\`bash
   flutter pub get
   cd laterbox-web && npm install
   \`\`\`
3. **Run Static Analysis & Tests**:
   \`\`\`bash
   flutter analyze
   flutter test
   cd laterbox-web && npm run build
   \`\`\`

---

## Testing Guidelines

- **Flutter Unit & Widget Tests**: Located in \`test/\`. Run with \`flutter test\`.
- **Edge Function Tests**: Located in \`supabase/functions/enrich-url/classification.test.ts\`. Run with \`deno test\`.
- **Next.js Production Build**: Run \`npm run build\` inside \`laterbox-web/\`.

---

## Submitting Pull Requests

- Use **Conventional Commits** (\`feat:\`, \`fix:\`, \`docs:\`, \`chore:\`).
- Commit each modified file independently whenever making architectural changes.
- Ensure all tests and static analysis checks pass before opening your PR.
        `,
      },
      {
        slug: 'license',
        title: 'License & Noncommercial Terms',
        navTitle: 'License & Terms',
        description: 'Understanding the PolyForm Noncommercial 1.0.0 license terms and commercial licensing inquiries.',
        category: 'Developer',
        headings: [
          { id: 'license-summary', text: 'License Summary', level: 2 },
          { id: 'permitted-uses', text: 'Permitted Uses', level: 2 },
          { id: 'commercial-restrictions', text: 'Commercial Restrictions', level: 2 },
          { id: 'commercial-inquiries', text: 'Commercial Licensing', level: 2 },
        ],
        content: `
## License Summary

LaterBox is licensed under the **[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/)**.

This is a source-available, non-commercial public license that gives individuals, students, researchers, and open-source contributors complete access to read, study, run, test, and contribute to the software while restricting commercial exploitation.

---

## Permitted Uses

You are explicitly permitted and encouraged to:
- **Personal Productivity**: Run, test, build, and self-host LaterBox for your own personal use.
- **Education & Learning**: Read, study, inspect, and learn from the codebase and architecture.
- **Academic Research**: Use LaterBox in non-profit academic research and educational teaching.
- **Open-Source Contribution**: Submit bug fixes, enhancements, translations, and documentation back to the upstream repository.

---

## Commercial Restrictions

You may **not** use the software or any derived work for commercial purposes without a commercial license agreement from the author. Prohibited activities include:
- Charging money or fees for access to LaterBox software or modified versions.
- Hosting LaterBox as a paid Software-as-a-Service (SaaS) or managed cloud platform.
- Integrating LaterBox proprietary components into commercial commercial products.

---

## Commercial Licensing

To inquire about commercial licensing, proprietary enterprise distributions, or custom integrations:
- 📧 Email: **[licensing@laterbox.dev](mailto:licensing@laterbox.dev)** or **[chaste@laterbox.dev](mailto:chaste@laterbox.dev)**
        `,
      },
    ],
  },
];

export const ALL_DOCS = DOCS_SECTIONS.flatMap((s) => s.items);

export function getDocBySlug(slug: string): DocItem | undefined {
  return ALL_DOCS.find((d) => d.slug === slug);
}
