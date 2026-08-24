# Contributing to LaterBox

Thank you for your interest in contributing to LaterBox! 🎉

LaterBox is an open-source, local-first personal knowledge vault and universal bookmarking toolkit built with **Flutter**, **Next.js**, **TypeScript**, **Supabase**, and **Cloudflare**.

Whether you're fixing a bug, adding platform enhancements, writing documentation, or improving translations, we welcome your contributions.

---

## Code of Conduct

All contributors are expected to uphold our [Code of Conduct](CODE_OF_CONDUCT.md). Please be kind, constructive, and respectful.

---

## Monorepo Architecture

The LaterBox repository is organized as a modular monorepo:

| Directory | Description | Technology |
|---|---|---|
| [`lib/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/lib) | Cross-platform core app (iOS, Android, macOS, Windows, Linux) | Flutter & Riverpod |
| [`laterbox-web/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/laterbox-web) | Web client, landing page, download hub & docs reader | Next.js 16, React, Tailwind CSS |
| [`extension/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/extension) | Manifest V3 browser extensions (Chrome, Firefox, Safari) | TypeScript, Vite, Tailwind CSS |
| [`supabase/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/supabase) | Database migrations, schemas, RLS policies & Edge Functions | PostgreSQL, Deno, TypeScript |
| [`docs/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/docs) | Project documentation, guides, and architectural specifications | Markdown |

---

## Local Development Setup

### 1. Prerequisites

- **Flutter SDK**: `^3.19.0` or latest stable ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Node.js**: `v20+` or `v22+` with `npm` ([Install Node.js](https://nodejs.org))
- **Supabase CLI** (optional for local edge function testing): `npm install -g supabase`

---

### 2. Setting up the Flutter App

```bash
# Clone the repository
git clone https://github.com/Chaste-Djaziri/laterbox.git
cd laterbox

# Fetch Flutter dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Launch on your desktop or mobile simulator
flutter run -d macos    # or windows, linux, chrome, ios, android
```

---

### 3. Setting up the Web Dashboard & Docs Reader

```bash
cd laterbox-web

# Install dependencies
npm install

# Start local Next.js dev server
npm run dev

# Open http://localhost:3000
```

---

### 4. Setting up Browser Extensions

```bash
cd extension

# Install dependencies
npm install

# Build in watch mode
npm run dev

# Package extensions for Chrome, Firefox, and Safari
npm run package
```

To load unpacked extension in Chrome:
1. Navigate to `chrome://extensions`.
2. Enable **Developer Mode**.
3. Click **Load unpacked** and select `extension/dist/chromium`.

---

## Development Workflow & Guidelines

### Branch Naming

Create a feature branch with a descriptive name:
```bash
git checkout -b feat/offline-search-filters
git checkout -b fix/youtube-preview-fallback
```

### Commit Guidelines (Conventional Commits)

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` A new feature
- `fix:` A bug fix
- `docs:` Documentation changes
- `chore:` Build scripts, version bumps, tooling maintenance
- `refactor:` Code refactoring without behavioral change
- `test:` Adding or fixing test suites
- `perf:` Performance optimizations

> **Rule**: Commit each changed file as its own independent commit whenever making architectural changes (one logical file/subsystem per `git add` + `git commit`).

---

## Submitting a Pull Request

1. **Verify All Tests Pass**:
   ```bash
   flutter analyze
   flutter test
   cd laterbox-web && npm run build
   ```
2. **Push to Your Fork**:
   ```bash
   git push origin feat/my-new-feature
   ```
3. **Open a PR**: Fill out the [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md) detailing what changed and how you verified it.

---

## Need Help?

- 💬 Join our community discussions on [GitHub Discussions](https://github.com/Chaste-Djaziri/laterbox/discussions).
- 🐛 Report bugs via [GitHub Issues](https://github.com/Chaste-Djaziri/laterbox/issues).
- 📖 Read the full documentation at [docs.laterbox.dev](https://docs.laterbox.dev).
