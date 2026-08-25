# laterbox

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/branding/laterbox-logo-white.png" />
    <source media="(prefers-color-scheme: light)" srcset="assets/branding/laterbox-logo.png" />
    <img alt="laterbox logo" src="assets/branding/laterbox-logo.png" width="220" />
  </picture>
</p>

<h3 align="center">Save anything now. Read, watch & organize later.</h3>

<p align="center">
  <a href="https://laterbox.dev"><strong>Live Web App</strong></a> •
  <a href="https://docs.laterbox.dev"><strong>Documentation (docs.laterbox.dev)</strong></a> •
  <a href="https://laterbox.dev/download"><strong>Downloads</strong></a> •
  <a href="CONTRIBUTING.md"><strong>Contributing</strong></a> •
  <a href="LICENSE"><strong>License</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-PolyForm%20Noncommercial%201.0.0-blue.svg" alt="License" />
  <img src="https://img.shields.io/badge/Flutter-3.19+-02569B.svg?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Next.js-16.2-000000.svg?logo=next.js&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E.svg?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/TypeScript-5.x-3178C6.svg?logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Offline--First-SQLite%20Sync-E7FF57.svg?labelColor=171711" alt="Offline First" />
</p>

---

## ✨ Overview

LaterBox is a modern, high-speed save-for-later tool and personal knowledge vault. It is engineered for instant capture across desktop, mobile, and browser environments with zero-friction offline caching and automatic cloud sync.

- ⚡ **Universal Quick Capture**: System-wide Spotlight bar (`⌥ Space` on macOS, `Ctrl+Alt+Space` on Windows, `Alt+Space` on Linux), mobile share sheets, and 1-click browser extension popups.
- 🔄 **Offline-First Resilience**: Local SQLite database with Drift ORM powering sub-10ms queries, full-text search, and real-time bidirectional Supabase replication.
- 🎬 **Distraction-Free Media**: Watch YouTube videos and listen to audio without ads or tracking directly inside the vault.
- 📖 **Distraction-Free Reader**: Clean distraction-free article reader with personal annotations and notes.
- 🌐 **Cross-Platform Ecosystem**: Native companions for macOS (Apple Silicon & Intel DMG/PKG), Windows (Inno Setup), Linux, iOS (TestFlight), Android (Google Play Closed Beta), and Manifest V3 Extensions (Chrome, Firefox, Safari).

---

## 🛠️ Tech Stack & Monorepo

| Directory | Layer | Technologies |
|---|---|---|
| [`lib/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/lib) | **Mobile & Desktop App** | Flutter 3.19+, Riverpod, Drift (SQLite), Window Manager |
| [`laterbox-web/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/laterbox-web) | **Web Dashboard & Docs** | Next.js 16 (Turbopack), React 19, Tailwind CSS, Lucide Icons |
| [`extension/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/extension) | **Browser Extensions** | TypeScript, Vite, Manifest V3 (Chrome, Firefox, Safari) |
| [`supabase/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/supabase) | **Backend & Edge Functions** | PostgreSQL, Row-Level Security (RLS), Storage, Deno Edge Functions |
| [`docs/`](file:///Users/chastedjazirihabimanahirwa/Documents/Github/laterbox/docs) | **Documentation Vault** | Markdown documentation rendered live on [docs.laterbox.dev](https://docs.laterbox.dev) |

---

## 🚀 Quick Start

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.19.0`)
- [Node.js](https://nodejs.org) (v20+ or v22+)
- Git

### 2. Running the Flutter App (macOS, Windows, Linux, Mobile)
```bash
# Clone the repository
git clone https://github.com/Chaste-Djaziri/laterbox.git
cd laterbox

# Fetch dependencies & run tests
flutter pub get
flutter test

# Launch on your desktop or simulator
flutter run -d macos    # or windows, linux, chrome, ios, android
```

### 3. Running the Web App & Docs Reader Locally
```bash
cd laterbox-web
npm install
npm run dev
# Open http://localhost:3000 or http://localhost:3000/docs
```

### 4. Building the Browser Extensions
```bash
cd extension
npm install
npm run package
# Output ZIP packages will be generated in extension/dist/
```

---

## 📚 Documentation Reader

Complete guides, architectural specifications, and API documentation are available in the **Docs Reader**:

- 📖 **Live Web Docs**: [https://docs.laterbox.dev](https://docs.laterbox.dev) (or `/docs` on the web app)
- 🏛️ [System Architecture & Data Flow](docs/architecture.md)
- 🧩 [Browser Extension Guide](docs/browser-extensions.md)
- 🖥️ [Desktop Quick Capture & Features](docs/desktop-features.md)
- 🚀 [Deployment & Release Workflows](docs/deployment.md)

---

## 🤝 Contributing & Community

We welcome community contributions for personal use, learning, bug fixes, translations, and documentation improvements!

- 📖 **[Contributing Guide](CONTRIBUTING.md)**: Monorepo setup, branch naming, and PR checklist.
- 🏷️ **[Good First Issues](https://github.com/Chaste-Djaziri/laterbox/labels/good%20first%20issue)**: Great starting points for new contributors.
- 💬 **[Community Discussions](https://github.com/Chaste-Djaziri/laterbox/discussions)**: Q&A, ideas, and feature discussions.
- 🆘 **[Support Policy](SUPPORT.md)**: Where to get help and troubleshoot issues.
- 🛡️ **[Code of Conduct](CODE_OF_CONDUCT.md)**: Contributor Covenant standards.
- 🔒 **[Security Policy](SECURITY.md)**: Confidential vulnerability reporting.

---

## 📜 Citation

If you use LaterBox or its local-first SQLite sync architecture in academic research, studies, or educational publications, please cite it using our [`CITATION.cff`](CITATION.cff) file or:

```bibtex
@software{LaterBox2026,
  author = {Habimanahirwa, Chaste Djaziri},
  title = {LaterBox: A Local-First, Cross-Platform Personal Knowledge Vault & Universal Bookmarking Toolkit},
  url = {https://laterbox.dev},
  year = {2026},
  publisher = {GitHub}
}
```

---

## 📄 License & Terms

LaterBox is licensed under the **[PolyForm Noncommercial License 1.0.0](LICENSE)**.

- ✅ **Free for Personal Use**: You are free to run, test, and self-host LaterBox for your own individual use.
- ✅ **Free for Educational & Study Use**: You are free to study the codebase, learn from the architecture, and use it for research and educational purposes.
- ❌ **No Commercial Use**: Commercial hosting, SaaS reselling, monetized distribution, or integration into proprietary commercial software without a commercial license agreement from the author is strictly prohibited.

For commercial licensing inquiries, please contact: [licensing@laterbox.dev](mailto:licensing@laterbox.dev).
