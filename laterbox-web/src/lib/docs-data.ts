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
        description: 'Learn what LaterBox is, the local-first philosophy, and how it differs from traditional bookmarks.',
        category: 'Getting Started',
        badge: 'Start Here',
        headings: [
          { id: 'what-is-laterbox', text: 'What is LaterBox?', level: 2 },
          { id: 'core-philosophy', text: 'The Local-First Philosophy', level: 2 },
          { id: 'key-features', text: 'Core Capabilities', level: 2 },
          { id: 'next-steps', text: 'Next Steps', level: 2 },
        ],
        content: `
## What is LaterBox?

**LaterBox** is an open-source, local-first personal knowledge vault and universal save-for-later companion. It replaces cluttered browser tabs and siloed bookmarks with a blazing-fast, unified system that works seamlessly across macOS, Windows, Linux, iOS, Android, and all major web browsers.

Traditional bookmark managers store links in remote servers or obscure browser menus where saved items are forgotten. LaterBox treats every captured link as an enriched, offline-available knowledge artifact with automatic metadata extraction, distraction-free reading, and native media playback.

---

## The Local-First Philosophy

LaterBox is architected around the **Local-First Software** principles:

1. **Sub-10ms Responsiveness**: All reads and writes hit an embedded local SQLite database (powered by Drift ORM) immediately. No waiting on network roundtrips.
2. **100% Offline Resilience**: You can search, browse, tag, read cached articles, and capture new links on an airplane or subway without internet.
3. **Seamless Cloud Replication**: When connectivity is available, changes automatically synchronize bidirectionally to Supabase PostgreSQL with real-time updates and Row-Level Security.
4. **Data Ownership & Sovereignty**: Your data stays on your device. You can export your entire vault to JSON or Markdown at any time with a single click.

---

## Core Capabilities

- **⚡ Universal Quick Capture**: System-wide global hotkeys (\`⌥ Space\` on Mac, \`Ctrl+Alt+Space\` on Windows, \`Alt+Space\` on Linux), mobile share sheets, and 1-click browser extension popups.
- **🎬 Distraction-Free Media**: Watch YouTube videos and listen to audio without ads, algorithms, or tracking directly inside your vault.
- **📖 Clean Reader Mode**: Read long-form articles with customizable typography, dark/light themes, and private markdown annotations.
- **🏷️ Deep Search & Collections**: Instant full-text search across titles, URLs, summaries, and personal notes with custom visual collections.
- **🛡️ Zero Tracking**: No telemetry, no third-party ad pixels, and strict open-source source-available licensing.

---

## Next Steps

- Check out the [Quick Start & Installation Guide](/docs/quickstart) to install LaterBox on your devices.
- Master the [Keyboard Shortcuts & Hotkeys](/docs/shortcuts) for keyboard-driven workflows.
- Explore the [System Architecture](/docs/architecture) to understand how local SQLite and Supabase sync work together.
        `,
      },
      {
        slug: 'quickstart',
        title: 'Quick Start & Installation',
        description: 'Step-by-step instructions to install LaterBox on macOS, Windows, Linux, iOS, Android, and browser extensions.',
        category: 'Getting Started',
        badge: 'Setup',
        headings: [
          { id: 'web-app', text: 'Web Application', level: 2 },
          { id: 'desktop-apps', text: 'Desktop Companions (macOS & Windows)', level: 2 },
          { id: 'mobile-apps', text: 'Mobile Apps (iOS & Android)', level: 2 },
          { id: 'browser-extensions', text: 'Browser Extensions', level: 2 },
          { id: 'cli-installers', text: '1-Line CLI Installers', level: 2 },
        ],
        content: `
## Web Application

The easiest way to use LaterBox is directly in your modern web browser:

1. Navigate to **[laterbox.dev/inbox](https://laterbox.dev/inbox)**.
2. Click **Launch App** to try the Guest Sandbox, or **Sign In** with your email or OAuth provider.
3. Start capturing and organizing links immediately.

---

## Desktop Companions (macOS & Windows)

Desktop companions provide global system hotkeys, system tray integration, and native file attachment capabilities.

### macOS (Apple Silicon & Intel)
- Download the universal \`.dmg\` or \`.pkg\` installer from the **[Download Hub](/download?platform=macos)**.
- Drag LaterBox to your \`/Applications\` folder.
- Press \`⌥ Space\` anywhere to open the Quick Capture bar.

### Windows 10 & 11
- Download \`laterbox-windows-setup.exe\` (Inno Setup) or standalone zip from the **[Download Hub](/download?platform=windows)**.
- Run the setup executable.
- Press \`Ctrl+Alt+Space\` anywhere to open Quick Capture.

---

## Mobile Apps (iOS & Android)

- **iOS**: Available via Apple TestFlight beta program.
- **Android**: Available via Google Play Closed Beta or direct APK download (\`laterbox-android.apk\`).
- Both apps integrate directly with the native OS **Share Sheet**, allowing you to save links from Safari, Chrome, YouTube, or Twitter with a single tap.

---

## Browser Extensions

Capture active tabs and selected text with 1 click:
- **Chrome / Brave / Edge**: Download \`laterbox-chrome-extension.zip\` (Manifest V3).
- **Firefox**: Download \`laterbox-firefox-extension.zip\` (Gecko Add-on).
- **Safari**: Safari Web Extension bundle included with the macOS native companion.

---

## 1-Line CLI Installers

Install LaterBox directly from your terminal:

\`\`\`bash
# macOS & Linux
curl -fsSL https://laterbox.dev/install.sh | bash
\`\`\`

\`\`\`powershell
# Windows PowerShell
irm https://laterbox.dev/install.ps1 | iex
\`\`\`
        `,
      },
      {
        slug: 'shortcuts',
        title: 'Keyboard Shortcuts & Hotkeys',
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
    title: 'Architecture & Core Design',
    items: [
      {
        slug: 'system-architecture',
        title: 'System Architecture & Data Flow',
        description: 'Deep dive into the monorepo architecture, Flutter core, Drift SQLite database, and Supabase integration.',
        category: 'Architecture',
        badge: 'Core Design',
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
    title: 'Platforms & Companions',
    items: [
      {
        slug: 'desktop-companions',
        title: 'Desktop Companions (macOS & Windows)',
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
    ],
  },
  {
    id: 'backend',
    title: 'Backend & Edge Functions',
    items: [
      {
        slug: 'supabase-backend',
        title: 'Supabase Database & Security Model',
        description: 'PostgreSQL database schema, Row Level Security (RLS) policies, storage buckets, and account deletion cascades.',
        category: 'Backend',
        badge: 'Security',
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
    id: 'developer',
    title: 'Developer & Open Source',
    items: [
      {
        slug: 'contributing',
        title: 'Contributing Guide',
        description: 'How to set up your local development environment, run test suites, and submit pull requests.',
        category: 'Developer',
        badge: 'Community',
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
        description: 'Understanding the PolyForm Noncommercial 1.0.0 license terms and commercial licensing inquiries.',
        category: 'Developer',
        badge: 'Legal',
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
