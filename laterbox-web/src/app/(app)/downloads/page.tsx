// laterbox-web/src/app/(app)/downloads/page.tsx
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

export default function InAppDownloadsPage() {
  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 py-8 sm:py-12 space-y-10">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-6 border-b border-[#e4e0d5]">
        <div>
          <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-[#e6edb0] border border-[#cbd79c] text-xs font-bold text-[#181b14] mb-2">
            <Sparkles className="w-3.5 h-3.5 text-[#5e773c]" />
            <span>Official Apps &amp; Clients</span>
          </div>
          <h1 className="text-2xl sm:text-4xl font-black text-[#181b14] tracking-tight">
            Apps &amp; Downloads
          </h1>
          <p className="text-sm text-[#606458] mt-1 max-w-xl">
            Get LaterBox on iOS, Android, and desktop browsers to capture from anywhere into your library.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href="/extension/connect"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold text-white bg-[#181b14] hover:bg-[#30392a] transition-all shadow-2xs"
          >
            <Puzzle className="w-4 h-4 text-[#e6edb0]" />
            <span>Pair Extension</span>
          </Link>
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs sm:text-sm font-bold text-[#181b14] bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] shadow-2xs transition-colors"
          >
            <span>App Store</span>
            <ExternalLink className="w-3.5 h-3.5 text-[#8e9587]" />
          </a>
        </div>
      </div>

      {/* Primary Clients Grid */}
      <section className="space-y-4">
        <h2 className="text-lg font-bold text-[#181b14]">Available Platforms</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* iOS Card */}
          <div className="rounded-3xl bg-white border border-[#e4e0d5] p-6 flex flex-col justify-between shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#181b14] text-white">
                    <Apple className="w-5 h-5" />
                  </span>
                  <div>
                    <h3 className="text-base font-bold text-[#181b14]">iOS &amp; iPadOS</h3>
                    <p className="text-xs text-[#7e8576]">App Store release</p>
                  </div>
                </div>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324]">
                  Live
                </span>
              </div>
              <p className="text-xs text-[#505549] leading-relaxed">
                Native Share Sheet extension, biometric lock, offline local cache, and background sync.
              </p>
            </div>
            <div className="pt-5 mt-5 border-t border-[#f0ede4] flex items-center justify-between">
              <AppStoreButton size="default" theme="dark" />
              <span className="text-[11px] text-[#8e9587]">iOS 16+</span>
            </div>
          </div>

          {/* Chrome Extension Card */}
          <div className="rounded-3xl bg-white border border-[#e4e0d5] p-6 flex flex-col justify-between shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#181b14]">
                    <Puzzle className="w-5 h-5" />
                  </span>
                  <div>
                    <h3 className="text-base font-bold text-[#181b14]">Browser Extension</h3>
                    <p className="text-xs text-[#7e8576]">Chrome, Brave, Edge &amp; Arc</p>
                  </div>
                </div>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324]">
                  Manifest V3
                </span>
              </div>
              <p className="text-xs text-[#505549] leading-relaxed">
                One-click popup capture, keyboard shortcut (⌘+Shift+S), and right-click context menus.
              </p>
            </div>
            <div className="pt-5 mt-5 border-t border-[#f0ede4] flex items-center justify-between">
              <a
                href="https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
              >
                <Download className="w-3.5 h-3.5 text-[#e6edb0]" />
                <span>Add to Chrome</span>
              </a>
              <Link
                href="/extension/connect"
                className="inline-flex items-center gap-1 text-xs font-bold text-[#606458] hover:text-[#181b14]"
              >
                <span>Pair extension</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>

          {/* Android Card */}
          <div className="rounded-3xl bg-white border border-[#e4e0d5] p-6 flex flex-col justify-between shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#ecf4df] text-[#465b2d]">
                    <Smartphone className="w-5 h-5" />
                  </span>
                  <div>
                    <h3 className="text-base font-bold text-[#181b14]">Android App</h3>
                    <p className="text-xs text-[#7e8576]">Direct APK Download</p>
                  </div>
                </div>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324]">
                  Direct .APK
                </span>
              </div>
              <p className="text-xs text-[#505549] leading-relaxed">
                Native Android package with quick capture share target, biometric authentication, and offline library.
              </p>
            </div>
            <div className="pt-5 mt-5 border-t border-[#f0ede4] flex items-center justify-between">
              <a
                href="/api/download/laterbox.apk"
                download="LaterBox.apk"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
              >
                <Download className="w-3.5 h-3.5 text-[#e6edb0]" />
                <span>Download .apk</span>
              </a>
              <span className="text-[11px] text-[#8e9587]">Android 10+</span>
            </div>
          </div>

          {/* Desktop Companions Summary */}
          <div className="rounded-3xl bg-[#faf8f5] border border-[#e4e0d5] p-6 flex flex-col justify-between">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#ebe7dc] text-[#181b14]">
                    <Laptop className="w-5 h-5" />
                  </span>
                  <div>
                    <h3 className="text-base font-bold text-[#181b14]">Desktop Companions</h3>
                    <p className="text-xs text-[#7e8576]">macOS, Windows &amp; Linux</p>
                  </div>
                </div>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#ebe7dc] text-[#606458]">
                  In Engineering
                </span>
              </div>
              <p className="text-xs text-[#505549] leading-relaxed">
                Native menu bar and tray companion apps with global shortcuts are currently in active development.
              </p>
            </div>
            <div className="pt-5 mt-5 border-t border-[#e9e6dd] flex items-center justify-between text-xs text-[#505549]">
              <span className="font-medium">Install as a desktop PWA in Chrome or Edge</span>
              <span className="font-bold text-[#181b14]">PWA Supported</span>
            </div>
          </div>
        </div>
      </section>

      {/* Release Notes */}
      <LatestReleaseNotes />
    </div>
  );
}
