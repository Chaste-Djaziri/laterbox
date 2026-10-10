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
        title: "Introduction & Overview",
        description: "LaterBox native clients, web application, and shared backend.",
        category: "Getting Started",
        headings: [{"id": "what-is-laterbox", "text": "What is LaterBox?", "level": 2}, {"id": "applications", "text": "Applications", "level": 2}, {"id": "availability", "text": "Availability", "level": 2}, {"id": "next-steps", "text": "Next Steps", "level": 2}],
        content: "## What is LaterBox?\nLaterBox is a local-first save-for-later app with independent native Apple and Android clients, a web application, and browser extensions.\n\n## Applications\n- Apple: Swift/SwiftUI in `laterbox-ios/`, with SwiftData persistence and native capture.\n- Android: Kotlin/Jetpack Compose in `laterbox-android/`, with Room persistence and WorkManager.\n- Web: Next.js, React, and TypeScript in `laterbox-web/`.\n- Extensions: TypeScript browser capture in `laterbox-extension/` and a native Safari host in `safari_app/`.\n\n## Availability\nThe Apple release scheme currently targets iOS. macOS-specific source remains, but its standalone release target needs validation. Windows and Linux native replacements are future work. Platform source and capability do not imply a published release.\n\n## Next Steps\nRead [Prerequisites](/docs/prerequisites), [Quick Start](/docs/quickstart), and [Architecture](/docs/system-architecture).\n",
      },
      {
        slug: 'prerequisites',
        title: "Prerequisites & Tooling",
        description: "Toolchains for native Apple, Android, web, and backend development.",
        category: "Getting Started",
        headings: [{"id": "native-apple", "text": "Native Apple", "level": 2}, {"id": "native-android", "text": "Native Android", "level": 2}, {"id": "web-and-extensions", "text": "Web and Extensions", "level": 2}, {"id": "backend", "text": "Backend", "level": 2}],
        content: "## Native Apple\nInstall the Xcode toolchain configured in the repository's native Apple CI guide. Open `laterbox-ios/laterbox-ios.xcodeproj` and select `laterbox-ios`.\n\n## Native Android\nUse Android Studio, JDK 17, and Android SDK 36. Open `laterbox-android/`.\n\n## Web and Extensions\nUse Node.js 22 and npm. Install dependencies separately in `laterbox-web/` and `laterbox-extension/` with `npm ci`.\n\n## Backend\nUse Supabase CLI for local services and migrations, and Deno for edge-function checks. Keep signing and service credentials outside source control.\n",
      },
      {
        slug: 'environment-variables',
        title: "Environment Variables & Configuration",
        description: "Configure the independent native and web clients safely.",
        category: "Getting Started",
        headings: [{"id": "web-configuration", "text": "Web Configuration", "level": 2}, {"id": "android-configuration", "text": "Android Configuration", "level": 2}, {"id": "apple-configuration", "text": "Apple Configuration", "level": 2}, {"id": "extensions-and-backend", "text": "Extensions and Backend", "level": 2}],
        content: "## Web Configuration\nUse the web app's environment example and deployment configuration. Public client configuration includes `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`. Keep service-role, provider, and signing credentials server-side.\n\n## Android Configuration\nSet `SUPABASE_URL` and `SUPABASE_KEY` in ignored `laterbox-android/local.properties`. Preserve Android Studio's local SDK configuration in that file.\n\n## Apple Configuration\nUse the native Apple project's configuration and CI signing guide. Configure bundle identifiers, App Groups, entitlements, and App Store signing for the actual build target.\n\n## Extensions and Backend\nExtension build scripts select hosted or local capture and approval origins. Supabase functions use their own environment configuration. Never publish privileged keys in client apps.\n",
      },
      {
        slug: 'quickstart',
        title: "Quick Start & Installation",
        description: "Run the maintained native apps, web app, and browser extensions.",
        category: "Getting Started",
        headings: [{"id": "web", "text": "Web", "level": 2}, {"id": "apple", "text": "Apple", "level": 2}, {"id": "android", "text": "Android", "level": 2}, {"id": "extensions", "text": "Extensions", "level": 2}],
        content: "## Web\n```sh\ncd laterbox-web\nnpm ci\nnpm run dev\n```\n\n## Apple\nOpen `laterbox-ios/laterbox-ios.xcodeproj` in Xcode and run the `laterbox-ios` scheme on a supported simulator or device.\n\n## Android\nOpen `laterbox-android/` in Android Studio, configure its SDK and Supabase client values, and run on an emulator or device.\n\n## Extensions\n```sh\ncd laterbox-extension\nnpm ci\nnpm run typecheck\nnpm run build:all\n```\nLocal extension builds use an account-free local library at `http://localhost:8080`. Start Next.js with `npm run dev -- --port 8080` in `laterbox-web/` and open `/inbox`. Select Local library in the extension to save without Supabase or a subscription. Account-connected extension capture is also free.\n",
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
| **Open Quick Capture** | \`⌃ ⌥ Space\` (Control+Option+Space) | \`Ctrl + Shift + L\` | \`Alt + Space\` |
| **Submit / Save Link** | \`⌘ Enter\` | \`Ctrl + Enter\` | \`Ctrl + Enter\` |
| **Attach Files / Media** | \`⌘ O\` | \`Ctrl + O\` | \`Ctrl + O\` |
| **Dismiss / Hide Bar** | \`Escape\` | \`Escape\` | \`Escape\` |

---

## Web & Library Hotkeys

When navigating the LaterBox web dashboard or desktop main window:

| Action | Shortcut | Description |
|---|---|---|
| **Quick Capture** | \`⌃ ⌥ L\` (Control+Option+L) / \`Ctrl + Alt + L\` | Opens the Quick Capture modal from anywhere |
| **Omnisearch** | \`⌘ K\` / \`Ctrl + K\` or \`/\` | Focuses on-page search or opens Search Modal |
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
        title: "System Architecture & Data Flow",
        description: "Independent native UIs and persistence backed by shared Supabase services.",
        category: "Architecture",
        headings: [{"id": "repository", "text": "Repository", "level": 2}, {"id": "local-persistence", "text": "Local Persistence", "level": 2}, {"id": "shared-backend", "text": "Shared Backend", "level": 2}, {"id": "platform-boundaries", "text": "Platform Boundaries", "level": 2}],
        content: "## Repository\n`laterbox-ios/` contains Swift/SwiftUI, `laterbox-android/` contains Kotlin/Compose, `laterbox-web/` contains Next.js, and `laterbox-extension/` contains browser capture. `supabase/` owns migrations and edge functions; `assets/` holds shared artwork.\n\n## Local Persistence\nApple clients use SwiftData, Android uses Room, and the web app uses account-scoped local caching and pending capture queues. Each client implements its own UI and synchronization behavior.\n\n## Shared Backend\nSupabase provides authentication, PostgreSQL with Row-Level Security, and storage. Web APIs provide enrichment, entitlement, and notification services. Share data contracts rather than UI runtime code.\n\n## Platform Boundaries\nThe current Apple release scheme targets iOS. macOS-specific source remains for native desktop work. Windows and Linux native clients are future work.\n",
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
        title: "Native Desktop Applications",
        description: "Native desktop source and remaining release work.",
        category: "Platforms",
        headings: [{"id": "macos", "text": "macOS", "level": 2}, {"id": "windows-and-linux", "text": "Windows and Linux", "level": 2}],
        content: "## macOS\nmacOS-specific Swift source remains in the Apple project. The current release scheme targets iOS; establish and verify a native macOS target, entitlements, signing, and packaging before publishing a desktop app. Safari extension hosting remains in `safari_app/`.\n\n## Windows and Linux\nNative replacements are future work. The retired desktop runners and their build scripts have been removed. Use the web application while native clients are developed.\n",
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
cd laterbox-extension
npm install

# Build for all targets (Chromium, Firefox, Safari)
npm run package
\`\`\`

Generated packages in \`laterbox-extension/dist/\`:
- \`laterbox-chrome-extension.zip\`
- \`laterbox-firefox-extension.zip\`
- \`laterbox-safari-extension.zip\`
        `,
      },
      {
        slug: 'mobile-apps',
        title: "Mobile Applications (iOS & Android)",
        description: "Native mobile capture, persistence, and platform integration.",
        category: "Platforms",
        headings: [{"id": "apple", "text": "Apple", "level": 2}, {"id": "android", "text": "Android", "level": 2}, {"id": "verification", "text": "Verification", "level": 2}],
        content: "## Apple\nThe Swift/SwiftUI application and share extension live in `laterbox-ios/`. Use the native Xcode scheme and CI guide for simulator tests, signing, archive validation, and TestFlight distribution.\n\n## Android\nThe Kotlin/Jetpack Compose application lives in `laterbox-android/`. Room handles local persistence and WorkManager supports background synchronization. Use Android Studio with the project's configured SDK and JDK.\n\n## Verification\nTest offline captures, account switching, attachment recovery, scheduled returns, permissions, and purchase restoration on supported native devices before release.\n",
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
2. **Desktop & Mobile Apps**: Configure your self-hosted URL and public client key in the native Apple or Android project configuration.
3. **Browser Extensions**: Set your custom domain in \`laterbox-extension/.env\`.

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
        title: "Contributing Guide",
        description: "Contribute to the maintained native, web, extension, and backend projects.",
        category: "Developer",
        headings: [{"id": "workflow", "text": "Workflow", "level": 2}, {"id": "verification", "text": "Verification", "level": 2}, {"id": "review", "text": "Review", "level": 2}],
        content: "## Workflow\nFollow repository `AGENTS.md`: work directly on main, record user-facing changes in the changelog before implementation, and commit each logical edit immediately using conventional commits.\n\n## Verification\n- Web: `npx tsc --noEmit --incremental false` and `npm test` in `laterbox-web/`.\n- Extensions: `npm run typecheck` and `npm run build:all` in `laterbox-extension/`.\n- Apple: native Swift/UI tests in Xcode and Python release preflight tests under `laterbox-ios/ci/`.\n- Android: Gradle unit tests and builds through Android Studio.\n- Backend: Deno checks and regression tests from the web release workflow.\n\n## Review\nDescribe the problem, resulting behavior, and actual validation. Keep generated artifacts, environment files, and signing credentials out of commits.\n",
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
