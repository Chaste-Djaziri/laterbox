// laterbox-web/src/app/(marketing)/download/page.tsx
'use client';

import React from 'react';
import Link from 'next/link';
import { AppStoreButton, APP_STORE_URL } from '@/components/download/AppStoreButton';
import { LatestReleaseNotes } from '@/components/download/LatestReleaseNotes';
import {
  Apple,
  ArrowRight,
  CheckCircle2,
  Clock,
  Download,
  ExternalLink,
  Globe2,
  Laptop,
  Lock,
  Puzzle,
  ShieldCheck,
  Smartphone,
  Sparkles,
  Terminal,
  Zap,
} from 'lucide-react';

export default function DownloadPage() {
  return (
    <div className="w-full flex-1 bg-[#fbfaf6]">
      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 sm:py-16 space-y-12">
        {/* Header Hero Section */}
        <section className="space-y-4 max-w-3xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#181b14] text-xs font-bold">
            <Sparkles className="w-3.5 h-3.5 text-[#5e773c]" />
            <span>Platforms &amp; Downloads</span>
          </div>
          <h1 className="text-3xl sm:text-5xl font-black text-[#181b14] tracking-[-0.04em] leading-[1.1]">
            Get LaterBox everywhere you think.
          </h1>
          <p className="text-sm sm:text-base text-[#606458] font-medium leading-relaxed">
            One calm place for your links, thoughts, notes, and files. Capture from your phone, browser, or desktop with offline-first synchronization.
          </p>
        </section>

        {/* Primary Available Clients Grid */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg sm:text-xl font-bold text-[#181b14]">
              Available Now
            </h2>
            <span className="text-xs font-semibold text-[#83897b]">
              Ready to install &amp; use
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* 1. iOS & iPadOS Card */}
            <div className="relative overflow-hidden rounded-3xl bg-white border border-[#e4e0d5] p-6 sm:p-7 flex flex-col justify-between shadow-2xs hover:border-[#181b14]/30 transition-all">
              <div className="space-y-4">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#181b14] text-white">
                      <Apple className="w-5 h-5" />
                    </span>
                    <div>
                      <h3 className="text-base sm:text-lg font-bold text-[#181b14]">
                        iOS &amp; iPadOS
                      </h3>
                      <p className="text-xs text-[#7e8576]">iPhone &amp; iPad App</p>
                    </div>
                  </div>
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324] text-[11px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#5e773c]" />
                    <span>App Store</span>
                  </span>
                </div>

                <p className="text-xs sm:text-sm text-[#505549] leading-relaxed">
                  Capture from Safari or any app via the system Share Sheet. Features offline local caching, biometric lock, and widgets.
                </p>

                <div className="space-y-1.5 text-xs text-[#383d34] pt-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Native Share Sheet extension</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Instant offline library &amp; search</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Automatic sync with LaterBox Web</span>
                  </div>
                </div>
              </div>

              <div className="pt-6 mt-6 border-t border-[#f0ede4] flex flex-wrap items-center justify-between gap-3">
                <AppStoreButton size="default" theme="dark" />
                <span className="text-[11px] text-[#8e9587]">Requires iOS 16.0+</span>
              </div>
            </div>

            {/* 2. Chrome & Chromium Extension Card */}
            <div className="relative overflow-hidden rounded-3xl bg-white border border-[#e4e0d5] p-6 sm:p-7 flex flex-col justify-between shadow-2xs hover:border-[#181b14]/30 transition-all">
              <div className="space-y-4">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#181b14]">
                      <Puzzle className="w-5 h-5" />
                    </span>
                    <div>
                      <h3 className="text-base sm:text-lg font-bold text-[#181b14]">
                        Browser Extension
                      </h3>
                      <p className="text-xs text-[#7e8576]">Chrome, Brave, Edge &amp; Arc</p>
                    </div>
                  </div>
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324] text-[11px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#5e773c]" />
                    <span>Manifest V3</span>
                  </span>
                </div>

                <p className="text-xs sm:text-sm text-[#505549] leading-relaxed">
                  One-click popup capture, keyboard shortcut (<code className="font-mono text-xs px-1.5 py-0.5 rounded bg-[#f4f7eb]">⌘+Shift+S</code>), and right-click context menus.
                </p>

                <div className="space-y-1.5 text-xs text-[#383d34] pt-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Direct Chrome Web Store installation</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Auto title, summary &amp; favicon detection</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Works offline with local queueing</span>
                  </div>
                </div>
              </div>

              <div className="pt-6 mt-6 border-t border-[#f0ede4] flex flex-wrap items-center justify-between gap-3">
                <a
                  href="https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
                >
                  <Download className="w-3.5 h-3.5 text-[#e6edb0]" />
                  <span>Add to Chrome</span>
                </a>
                <Link
                  href="/extension/connect"
                  className="inline-flex items-center gap-1 text-xs font-bold text-[#606458] hover:text-[#181b14] transition-colors"
                >
                  <span>Pair extension</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>

            {/* 3. Android APK Card */}
            <div className="relative overflow-hidden rounded-3xl bg-white border border-[#e4e0d5] p-6 sm:p-7 flex flex-col justify-between shadow-2xs hover:border-[#181b14]/30 transition-all">
              <div className="space-y-4">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#ecf4df] text-[#465b2d]">
                      <Smartphone className="w-5 h-5" />
                    </span>
                    <div>
                      <h3 className="text-base sm:text-lg font-bold text-[#181b14]">
                        LaterBox for Android
                      </h3>
                      <p className="text-xs text-[#7e8576]">Direct APK Download</p>
                    </div>
                  </div>
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324] text-[11px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#5e773c]" />
                    <span>Direct .APK</span>
                  </span>
                </div>

                <p className="text-xs sm:text-sm text-[#505549] leading-relaxed">
                  Native Android package with quick capture share target, biometric authentication, and offline library database.
                </p>

                <div className="space-y-1.5 text-xs text-[#383d34] pt-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Android Share Sheet integration</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Biometric fingerprint &amp; face unlock</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Full offline access and search</span>
                  </div>
                </div>
              </div>

              <div className="pt-6 mt-6 border-t border-[#f0ede4] flex flex-wrap items-center justify-between gap-3">
                <a
                  href="/api/download/laterbox.apk"
                  download="LaterBox.apk"
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
                >
                  <Download className="w-3.5 h-3.5 text-[#e6edb0]" />
                  <span>Download .apk</span>
                </a>
                <span className="text-[11px] text-[#8e9587]">Android 10.0+</span>
              </div>
            </div>

            {/* 4. Web App Card */}
            <div className="relative overflow-hidden rounded-3xl bg-white border border-[#e4e0d5] p-6 sm:p-7 flex flex-col justify-between shadow-2xs hover:border-[#181b14]/30 transition-all">
              <div className="space-y-4">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5">
                    <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#ebe7dc] text-[#181b14]">
                      <Globe2 className="w-5 h-5" />
                    </span>
                    <div>
                      <h3 className="text-base sm:text-lg font-bold text-[#181b14]">
                        Universal Web App
                      </h3>
                      <p className="text-xs text-[#7e8576]">Zero Installation</p>
                    </div>
                  </div>
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324] text-[11px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#5e773c]" />
                    <span>PWA Ready</span>
                  </span>
                </div>

                <p className="text-xs sm:text-sm text-[#505549] leading-relaxed">
                  Run LaterBox in any modern browser with local offline caching, full keyboard navigation, and instant search.
                </p>

                <div className="space-y-1.5 text-xs text-[#383d34] pt-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Instant access without downloading</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Installable as a desktop PWA app</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#5e773c] shrink-0" />
                    <span>Full keyboard shortcuts support</span>
                  </div>
                </div>
              </div>

              <div className="pt-6 mt-6 border-t border-[#f0ede4] flex flex-wrap items-center justify-between gap-3">
                <Link
                  href="/inbox"
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
                >
                  <span>Launch Web App</span>
                  <ArrowRight className="w-3.5 h-3.5 text-[#e6edb0]" />
                </Link>
                <span className="text-[11px] text-[#8e9587]">All modern browsers</span>
              </div>
            </div>
          </div>
        </section>

        {/* Section 2: Desktop Companions Roadmap */}
        <section className="rounded-3xl border border-[#e4e0d5] bg-white p-6 sm:p-8 space-y-6 shadow-2xs">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <h2 className="text-lg sm:text-xl font-bold text-[#181b14]">
                Desktop Native Apps
              </h2>
              <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#ebe7dc] text-[#606458]">
                Roadmap
              </span>
            </div>
            <p className="text-xs sm:text-sm text-[#606458]">
              Lightweight desktop companions with global quick-capture shortcuts are currently in active engineering.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
            {/* macOS */}
            <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e9e6dd] space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Apple className="w-4 h-4 text-[#181b14]" />
                  <span className="font-bold text-sm text-[#181b14]">macOS</span>
                </div>
                <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#f4f7eb] text-[#4a5f33] border border-[#d6e0bc]">
                  <Clock className="w-3 h-3" />
                  <span>Private Beta</span>
                </span>
              </div>
              <p className="text-xs text-[#606458] leading-relaxed">
                Native Swift menu bar app with global quick capture (<code className="font-mono text-[11px]">⌥Space</code>) and instant search. Apple Silicon &amp; Intel.
              </p>
            </div>

            {/* Windows */}
            <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e9e6dd] space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Laptop className="w-4 h-4 text-[#181b14]" />
                  <span className="font-bold text-sm text-[#181b14]">Windows</span>
                </div>
                <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[#606458] border border-[#e4e0d5]">
                  <Clock className="w-3 h-3" />
                  <span>In Development</span>
                </span>
              </div>
              <p className="text-xs text-[#606458] leading-relaxed">
                Native 64-bit companion with system tray capture and global hotkeys for Windows 10 &amp; 11 (x64 / ARM64).
              </p>
            </div>

            {/* Linux */}
            <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e9e6dd] space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Terminal className="w-4 h-4 text-[#181b14]" />
                  <span className="font-bold text-sm text-[#181b14]">Linux</span>
                </div>
                <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[#606458] border border-[#e4e0d5]">
                  <Clock className="w-3 h-3" />
                  <span>In Development</span>
                </span>
              </div>
              <p className="text-xs text-[#606458] leading-relaxed">
                Native Linux packages (.deb, AppImage, tarball) for Ubuntu, Fedora, Debian, and Arch workstations.
              </p>
            </div>
          </div>

          <div className="p-3.5 rounded-2xl bg-[#f4f7eb] border border-[#d6e0bc] flex items-center justify-between gap-3 text-xs text-[#3d4b29]">
            <span className="font-medium">
              💡 <strong>Tip:</strong> You can install LaterBox Web as a standalone desktop app right now using Chrome, Edge, or Safari (<em>File → Add to Dock / Install</em>).
            </span>
            <Link href="/inbox" className="shrink-0 font-bold underline hover:text-[#181b14]">
              Open Web App
            </Link>
          </div>
        </section>

        {/* Section 3: Firefox & Safari Extension Details */}
        <section className="space-y-4">
          <h2 className="text-lg sm:text-xl font-bold text-[#181b14]">
            Other Browser Add-ons
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between shadow-2xs">
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-sm text-[#181b14]">Mozilla Firefox</span>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[#606458]">
                    Gecko Add-on
                  </span>
                </div>
                <p className="text-xs text-[#606458] leading-relaxed">
                  Standalone Firefox add-on bundle with quick capture sheet and auto-sync with your web dashboard.
                </p>
              </div>
              <div className="pt-3 border-t border-[#f0ede4] flex items-center justify-between">
                <a
                  href="/api/download/laterbox-firefox-extension.zip"
                  download="laterbox-firefox-extension.zip"
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-[#181b14] hover:text-[#5e773c] transition-colors"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download .zip for Firefox</span>
                </a>
              </div>
            </div>

            <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between shadow-2xs">
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-sm text-[#181b14]">Apple Safari</span>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#e6edb0] text-[#181b14]">
                    Integrated
                  </span>
                </div>
                <p className="text-xs text-[#606458] leading-relaxed">
                  Safari Web Extension is bundled directly inside the LaterBox iOS &amp; iPadOS app from the App Store.
                </p>
              </div>
              <div className="pt-3 border-t border-[#f0ede4] flex items-center justify-between">
                <a
                  href={APP_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-[#181b14] hover:text-[#5e773c] transition-colors"
                >
                  <span>Included in iOS App Store release</span>
                  <ExternalLink className="w-3.5 h-3.5 text-[#8e9587]" />
                </a>
              </div>
            </div>
          </div>
        </section>

        {/* Section 4: Privacy & Platform Pillars */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2">
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-9 h-9 rounded-xl bg-[#ecf4df] flex items-center justify-center text-[#465b2d]">
              <Zap className="w-4 h-4" />
            </div>
            <h3 className="text-sm font-bold text-[#181b14]">Universal Quick Capture</h3>
            <p className="text-xs text-[#606458] leading-relaxed">
              Global shortcuts, browser popups, and native share sheets save anything in under a second.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-9 h-9 rounded-xl bg-[#ecf4df] flex items-center justify-center text-[#465b2d]">
              <ShieldCheck className="w-4 h-4" />
            </div>
            <h3 className="text-sm font-bold text-[#181b14]">Local-First &amp; Offline</h3>
            <p className="text-xs text-[#606458] leading-relaxed">
              Your library is stored locally on your device. Search, organize, and read with zero network required.
            </p>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-9 h-9 rounded-xl bg-[#ecf4df] flex items-center justify-center text-[#465b2d]">
              <Lock className="w-4 h-4" />
            </div>
            <h3 className="text-sm font-bold text-[#181b14]">Private by Design</h3>
            <p className="text-xs text-[#606458] leading-relaxed">
              Zero ads, zero data mining, and zero tracking cookies. Your thoughts and files remain strictly yours.
            </p>
          </div>
        </section>

        {/* Section 5: Latest Release Notes */}
        <LatestReleaseNotes />
      </main>
    </div>
  );
}
