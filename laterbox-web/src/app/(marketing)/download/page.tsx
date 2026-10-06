'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { AndroidTesterModal } from '@/components/download/AndroidTesterModal';
import { AppStoreButton, APP_STORE_URL } from '@/components/download/AppStoreButton';
import {
  Apple,
  Laptop,
  Terminal,
  Smartphone,
  Puzzle,
  CheckCircle2,
  ExternalLink,
  Sparkles,
  ArrowRight,
  Globe2,
  Clock,
  Hammer,
  ShieldCheck,
  Zap,
} from 'lucide-react';

export default function DownloadPage() {
  const [isAndroidModalOpen, setIsAndroidModalOpen] = useState(false);

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12 space-y-12 w-full flex-1">
      {/* Header Title Section */}
      <div className="space-y-2">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#ebe7dc] text-xs font-semibold text-[#6c6b63] w-fit">
          <Sparkles className="w-3.5 h-3.5 text-amber-600" />
          <span>Official Releases & Ecosystem Roadmap</span>
        </div>
        <h1 className="text-3xl sm:text-4xl font-extrabold text-[#171711] tracking-tight flex items-center gap-2">
          <span>Download LaterBox</span>
          <span className="w-1.5 h-6 rounded-full bg-gradient-to-b from-[#E7FF57] to-[#171711] inline-block animate-pulse" />
        </h1>
        <p className="text-xs sm:text-sm text-[#6c6b63] font-medium max-w-2xl">
          LaterBox is available today on iOS via the Apple App Store, with companion browser extensions and additional platforms rolling out soon.
        </p>
      </div>

      {/* Primary Featured Download: iOS App Store Hero */}
      <section className="relative overflow-hidden rounded-3xl bg-white border border-[#e4e0d5] p-6 sm:p-8 md:p-10 shadow-xs">
        {/* Subtle decorative glow */}
        <div className="absolute top-0 right-0 -mr-20 -mt-20 w-80 h-80 rounded-full bg-[#E7FF57]/20 blur-3xl pointer-events-none" />

        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-8">
          <div className="space-y-4 max-w-xl">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#171711] text-white text-xs font-bold shadow-2xs">
                <Apple className="w-3.5 h-3.5" />
                <span>iOS & iPadOS</span>
              </span>
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold shadow-2xs">
                <span className="w-1.5 h-1.5 rounded-full bg-[#171711] animate-pulse" />
                <span>Live on App Store</span>
              </span>
            </div>

            <div>
              <h2 className="text-2xl sm:text-3xl font-extrabold text-[#171711] tracking-tight">
                LaterBox for iPhone & iPad
              </h2>
              <p className="text-xs sm:text-sm text-[#6c6b63] mt-2 leading-relaxed">
                Save articles, videos, bookmarks, and quick notes anywhere on iOS. Tap the system Share Sheet in Safari or any app to capture instantly with offline-first synchronization.
              </p>
            </div>

            {/* Feature Highlights Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-2 text-xs text-[#171711]">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Native iOS Share Sheet extension</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Offline-first local cache & fast search</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Auto-sync with LaterBox Web</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Biometric security & clean dark theme</span>
              </div>
            </div>

            <p className="text-[11px] text-[#9e9b92] pt-1">
              Requires iOS 16.0 or iPadOS 16.0 or later. Optimized for iPhone and iPad.
            </p>
          </div>

          {/* App Store Download Button Box */}
          <div className="flex flex-col items-start md:items-end justify-center gap-3 shrink-0">
            <AppStoreButton size="large" theme="dark" />
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6c6b63] hover:text-[#171711] transition-colors"
            >
              <span>View product page on Apple.com</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </section>

      {/* Secondary Section: Other Platforms & Development Status */}
      <section className="space-y-6 pt-2">
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
              Other Platforms
            </h2>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#ebe7dc] text-[#6c6b63]">
              Roadmap
            </span>
          </div>
          <p className="text-xs sm:text-sm text-[#6c6b63]">
            Dedicated native companions for desktop and Android are in active engineering.
          </p>
        </div>

        {/* 4 Cards Grid: Android, macOS, Windows, Linux */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* 1. Android - Under Development */}
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-amber-500/10 flex items-center justify-center text-amber-700">
                  <Smartphone className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-amber-100 text-amber-800 border border-amber-300">
                  <Hammer className="w-3 h-3 text-amber-700" />
                  <span>Under Development</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711]">Android</h3>
                <p className="text-xs text-[#6c6b63] mt-1.5 leading-relaxed">
                  Native Android app built with Jetpack Compose featuring system share sheet integration and offline sync.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4]">
              <button
                type="button"
                onClick={() => setIsAndroidModalOpen(true)}
                className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold transition-all cursor-pointer shadow-2xs"
              >
                <span>Join Android Testers</span>
                <ArrowRight className="w-3.5 h-3.5 text-[#E7FF57]" />
              </button>
            </div>
          </div>

          {/* 2. macOS - Coming Soon */}
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-[#ebe7dc] flex items-center justify-center text-[#171711]">
                  <Apple className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-[#ebe7dc] text-[#6c6b63] border border-[#e4e0d5]">
                  <Clock className="w-3 h-3 text-[#6c6b63]" />
                  <span>Coming Soon</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711]">macOS</h3>
                <p className="text-xs text-[#6c6b63] mt-1.5 leading-relaxed">
                  Native Swift menu bar companion with global quick capture (⌥Space) and sub-millisecond local search.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4]">
              <div className="text-[11px] font-medium text-[#9e9b92] text-center py-1">
                Apple Silicon & Intel builds
              </div>
            </div>
          </div>

          {/* 3. Windows - Coming Soon */}
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-[#ebe7dc] flex items-center justify-center text-[#171711]">
                  <Laptop className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-[#ebe7dc] text-[#6c6b63] border border-[#e4e0d5]">
                  <Clock className="w-3 h-3 text-[#6c6b63]" />
                  <span>Coming Soon</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711]">Windows</h3>
                <p className="text-xs text-[#6c6b63] mt-1.5 leading-relaxed">
                  Native 64-bit Windows companion with system tray capture and global hotkeys.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4]">
              <div className="text-[11px] font-medium text-[#9e9b92] text-center py-1">
                Windows 10 & 11 (x64 / ARM64)
              </div>
            </div>
          </div>

          {/* 4. Linux - Coming Soon */}
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-[#ebe7dc] flex items-center justify-center text-[#171711]">
                  <Terminal className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-[#ebe7dc] text-[#6c6b63] border border-[#e4e0d5]">
                  <Clock className="w-3 h-3 text-[#6c6b63]" />
                  <span>Coming Soon</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711]">Linux</h3>
                <p className="text-xs text-[#6c6b63] mt-1.5 leading-relaxed">
                  Native Linux desktop package (.deb, AppImage) for Ubuntu, Fedora, Debian, and Arch.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4]">
              <div className="text-[11px] font-medium text-[#9e9b92] text-center py-1">
                Debian, AppImage & Tarball
              </div>
            </div>
          </div>
        </div>
      </section>

      <div className="border-b border-[#e4e0d5]" />

      {/* Browser Extensions Section */}
      <section className="space-y-4">
        <div className="flex items-center gap-2.5">
          <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
            LaterBox for Browsers
          </h2>
          <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
            Extensions
          </span>
        </div>

        <p className="text-xs sm:text-sm text-[#6c6b63] max-w-2xl">
          Bring LaterBox 1-click capture into Chrome, Brave, Edge, Firefox, and Safari on desktop.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="w-10 h-10 rounded-xl bg-[#e6edb0] flex items-center justify-center">
                  <Puzzle className="w-5 h-5 text-[#171711]" />
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[#171711]">
                  Manifest V3
                </span>
              </div>
              <h3 className="text-base font-bold text-[#171711]">Chrome / Brave / Edge</h3>
              <p className="text-xs text-[#6c6b63] mt-1">
                1-click capture popup, keyboard shortcut (⌘+Shift+S), and right-click context menu.
              </p>
            </div>
            <Link
              href="/extension/connect"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-2xs transition-all cursor-pointer"
            >
              <span>Pair Extension</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="w-10 h-10 rounded-xl bg-[#e6edb0] flex items-center justify-center">
                  <Puzzle className="w-5 h-5 text-[#171711]" />
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[#171711]">
                  Gecko Add-on
                </span>
              </div>
              <h3 className="text-base font-bold text-[#171711]">Mozilla Firefox</h3>
              <p className="text-xs text-[#6c6b63] mt-1">
                Native Firefox add-on with quick capture sheet and auto-sync with your web dashboard.
              </p>
            </div>
            <Link
              href="/extension/connect"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
            >
              <span>Firefox Add-on Info</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="w-10 h-10 rounded-xl bg-[#e6edb0] flex items-center justify-center">
                  <Apple className="w-5 h-5 text-[#171711]" />
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[#171711]">
                  Safari Extension
                </span>
              </div>
              <h3 className="text-base font-bold text-[#171711]">Apple Safari</h3>
              <p className="text-xs text-[#6c6b63] mt-1">
                Safari Web Extension bundle integrated directly with the LaterBox iOS app.
              </p>
            </div>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
            >
              <span>Included in iOS App</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </section>

      {/* Web App Banner */}
      <section className="p-6 sm:p-8 rounded-3xl bg-[#f7f5ee] border border-[#e4e0d5] flex flex-col sm:flex-row sm:items-center justify-between gap-6">
        <div className="space-y-1.5 max-w-xl">
          <div className="flex items-center gap-2 text-xs font-bold text-[#171711]">
            <Globe2 className="w-4 h-4 text-emerald-600" />
            <span>Always available anywhere</span>
          </div>
          <h3 className="text-xl font-bold text-[#171711]">
            Looking for LaterBox Web?
          </h3>
          <p className="text-xs sm:text-sm text-[#6c6b63]">
            Access your entire knowledge vault directly from any modern web browser with offline caching and keyboard navigation.
          </p>
        </div>
        <Link
          href="/inbox"
          className="inline-flex items-center gap-2 px-6 py-3 rounded-2xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shrink-0 transition-all shadow-xs"
        >
          <span>Launch Web Dashboard</span>
          <ArrowRight className="w-4 h-4 text-[#E7FF57]" />
        </Link>
      </section>

      {/* Android Tester Modal */}
      <AndroidTesterModal
        isOpen={isAndroidModalOpen}
        onClose={() => setIsAndroidModalOpen(false)}
      />
    </div>
  );
}
