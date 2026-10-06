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
  Clock,
  Hammer,
  ShieldCheck,
  Zap,
} from 'lucide-react';

export default function InAppDownloadsPage() {
  const [isAndroidModalOpen, setIsAndroidModalOpen] = useState(false);

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 py-6 sm:py-10 space-y-10">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-6 border-b border-[#e5e0d3] dark:border-[#2e2d27]">
        <div>
          <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-[#ebe7dc] dark:bg-[#282723] text-xs font-semibold text-[#6c6b63] dark:text-[#a09e94] mb-2">
            <Sparkles className="w-3.5 h-3.5 text-amber-600" />
            <span>Official Client & Platform Roadmap</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-[#171711] dark:text-[#f4f2ea] tracking-tight">
            Apps & Downloads
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] dark:text-[#a09e94] mt-1 max-w-xl">
            Download the official LaterBox iOS app directly from the Apple App Store, pair browser extensions, or track upcoming platforms.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href="/extension/connect"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold text-white bg-[#171711] dark:bg-[#383731] hover:bg-[#282723] transition-all shadow-xs"
          >
            <Puzzle className="w-4 h-4" />
            <span>Pair Extension</span>
          </Link>
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs sm:text-sm font-semibold text-[#6c6b63] dark:text-[#a09e94] bg-[#ebe7dc]/70 dark:bg-[#282723] hover:text-[#171711] dark:hover:text-[#f4f2ea] transition-colors"
          >
            <span>App Store</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </a>
        </div>
      </div>

      {/* Featured iOS App Section */}
      <section className="relative overflow-hidden rounded-3xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] p-6 sm:p-8 md:p-10 shadow-xs">
        {/* Subtle decorative glow */}
        <div className="absolute top-0 right-0 -mr-20 -mt-20 w-80 h-80 rounded-full bg-[#E7FF57]/15 dark:bg-[#E7FF57]/10 blur-3xl pointer-events-none" />

        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-8">
          <div className="space-y-4 max-w-xl">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#171711] dark:bg-[#2e2d27] text-[#E7FF57] text-xs font-bold">
                <Apple className="w-3.5 h-3.5" />
                <span>iOS & iPadOS</span>
              </span>
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-100 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-300 text-xs font-bold">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>Live on App Store</span>
              </span>
            </div>

            <div>
              <h2 className="text-2xl sm:text-3xl font-extrabold text-[#171711] dark:text-[#f4f2ea] tracking-tight">
                LaterBox for iPhone & iPad
              </h2>
              <p className="text-xs sm:text-sm text-[#6c6b63] dark:text-[#a09e94] mt-2 leading-relaxed">
                Save articles, videos, bookmarks, and notes from any app on your iPhone or iPad using the system Share Sheet with offline-first synchronization back to your vault.
              </p>
            </div>

            {/* Highlights Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-2 text-xs text-[#171711] dark:text-[#f4f2ea]">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span className="font-medium">Native iOS Share Sheet extension</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span className="font-medium">Offline-first local cache & quick search</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span className="font-medium">Continuous cloud synchronization</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                <span className="font-medium">Biometric Face ID / Touch ID lock</span>
              </div>
            </div>

            <p className="text-[11px] text-[#9e9b92] dark:text-[#7d7a71] pt-1">
              Requires iOS 16.0 or iPadOS 16.0 or later.
            </p>
          </div>

          {/* App Store Download Badge */}
          <div className="flex flex-col items-start md:items-end justify-center gap-3 shrink-0">
            <AppStoreButton size="large" theme="dark" />
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6c6b63] dark:text-[#a09e94] hover:text-[#171711] dark:hover:text-[#f4f2ea] transition-colors"
            >
              <span>View product page on Apple.com</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </section>

      {/* Other Platforms Section */}
      <section className="space-y-6 pt-2">
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711] dark:text-[#f4f2ea]">
              Other Platforms
            </h2>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#ebe7dc] dark:bg-[#282723] text-[#6c6b63] dark:text-[#a09e94]">
              Roadmap
            </span>
          </div>
          <p className="text-xs sm:text-sm text-[#6c6b63] dark:text-[#a09e94]">
            Native clients for desktop and Android are actively being developed.
          </p>
        </div>

        {/* 4 Platform Status Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Android - Under Development */}
          <div className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 dark:hover:border-white/20 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-amber-500/10 flex items-center justify-center text-amber-700 dark:text-amber-400">
                  <Smartphone className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-amber-100 dark:bg-amber-950/40 text-amber-800 dark:text-amber-400 border border-amber-300 dark:border-amber-800">
                  <Hammer className="w-3 h-3 text-amber-700 dark:text-amber-400" />
                  <span>Under Development</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711] dark:text-[#f4f2ea]">Android</h3>
                <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-1.5 leading-relaxed">
                  Native Android app built with Jetpack Compose featuring system share sheet integration and offline sync.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4] dark:border-[#2e2d27]">
              <button
                type="button"
                onClick={() => setIsAndroidModalOpen(true)}
                className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-[#171711] dark:bg-[#2e2d27] hover:bg-[#282723] text-white text-xs font-bold transition-all cursor-pointer shadow-2xs"
              >
                <span>Join Android Testers</span>
                <ArrowRight className="w-3.5 h-3.5 text-[#E7FF57]" />
              </button>
            </div>
          </div>

          {/* macOS - Coming Soon */}
          <div className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 dark:hover:border-white/20 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] flex items-center justify-center text-[#171711] dark:text-[#f4f2ea]">
                  <Apple className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-[#ebe7dc] dark:bg-[#282723] text-[#6c6b63] dark:text-[#a09e94] border border-[#e5e0d3] dark:border-[#2e2d27]">
                  <Clock className="w-3 h-3 text-[#6c6b63] dark:text-[#a09e94]" />
                  <span>Coming Soon</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711] dark:text-[#f4f2ea]">macOS</h3>
                <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-1.5 leading-relaxed">
                  Native Swift menu bar companion with global quick capture (⌥Space) and sub-millisecond local search.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4] dark:border-[#2e2d27]">
              <div className="text-[11px] font-medium text-[#9e9b92] dark:text-[#7d7a71] text-center py-1">
                Apple Silicon & Intel builds
              </div>
            </div>
          </div>

          {/* Windows - Coming Soon */}
          <div className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 dark:hover:border-white/20 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] flex items-center justify-center text-[#171711] dark:text-[#f4f2ea]">
                  <Laptop className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-[#ebe7dc] dark:bg-[#282723] text-[#6c6b63] dark:text-[#a09e94] border border-[#e5e0d3] dark:border-[#2e2d27]">
                  <Clock className="w-3 h-3 text-[#6c6b63] dark:text-[#a09e94]" />
                  <span>Coming Soon</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711] dark:text-[#f4f2ea]">Windows</h3>
                <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-1.5 leading-relaxed">
                  Native 64-bit Windows companion with system tray capture and global hotkeys.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4] dark:border-[#2e2d27]">
              <div className="text-[11px] font-medium text-[#9e9b92] dark:text-[#7d7a71] text-center py-1">
                Windows 10 & 11 (x64 / ARM64)
              </div>
            </div>
          </div>

          {/* Linux - Coming Soon */}
          <div className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 dark:hover:border-white/20 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] flex items-center justify-center text-[#171711] dark:text-[#f4f2ea]">
                  <Terminal className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-[#ebe7dc] dark:bg-[#282723] text-[#6c6b63] dark:text-[#a09e94] border border-[#e5e0d3] dark:border-[#2e2d27]">
                  <Clock className="w-3 h-3 text-[#6c6b63] dark:text-[#a09e94]" />
                  <span>Coming Soon</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711] dark:text-[#f4f2ea]">Linux</h3>
                <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-1.5 leading-relaxed">
                  Native Linux desktop package (.deb, AppImage) for Ubuntu, Fedora, Debian, and Arch.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4] dark:border-[#2e2d27]">
              <div className="text-[11px] font-medium text-[#9e9b92] dark:text-[#7d7a71] text-center py-1">
                Debian, AppImage & Tarball
              </div>
            </div>
          </div>
        </div>
      </section>

      <div className="border-b border-[#e5e0d3] dark:border-[#2e2d27]" />

      {/* Browser Extensions Section */}
      <section className="space-y-4">
        <div className="flex items-center gap-2.5">
          <h2 className="text-xl sm:text-2xl font-bold text-[#171711] dark:text-[#f4f2ea]">
            Browser Integrations
          </h2>
          <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
            Extensions
          </span>
        </div>

        <p className="text-xs sm:text-sm text-[#6c6b63] dark:text-[#a09e94] max-w-2xl">
          Capture articles, links, and text directly into your vault from desktop browsers.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
          <div className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-3 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="w-10 h-10 rounded-xl bg-[#e6edb0] flex items-center justify-center">
                  <Puzzle className="w-5 h-5 text-[#171711]" />
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] dark:bg-[#282723] text-[#171711] dark:text-[#f4f2ea]">
                  Manifest V3
                </span>
              </div>
              <h3 className="text-base font-bold text-[#171711] dark:text-[#f4f2ea]">Chrome / Brave / Edge</h3>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-1">
                1-click capture popup, keyboard shortcut (⌘+Shift+S), and right-click context menu.
              </p>
            </div>
            <Link
              href="/extension/connect"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] dark:bg-[#383731] hover:bg-[#282723] text-white text-xs font-bold shadow-2xs transition-all cursor-pointer"
            >
              <span>Pair Extension</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-3 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="w-10 h-10 rounded-xl bg-[#e6edb0] flex items-center justify-center">
                  <Puzzle className="w-5 h-5 text-[#171711]" />
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] dark:bg-[#282723] text-[#171711] dark:text-[#f4f2ea]">
                  Gecko Add-on
                </span>
              </div>
              <h3 className="text-base font-bold text-[#171711] dark:text-[#f4f2ea]">Mozilla Firefox</h3>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-1">
                Native Firefox add-on with quick capture sheet and auto-sync with your vault.
              </p>
            </div>
            <Link
              href="/extension/connect"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] hover:bg-[#e0dbcd] dark:hover:bg-[#33322d] text-[#171711] dark:text-[#f4f2ea] text-xs font-bold transition-all cursor-pointer"
            >
              <span>Firefox Add-on Info</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>

          <div className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-3 flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="w-10 h-10 rounded-xl bg-[#e6edb0] flex items-center justify-center">
                  <Apple className="w-5 h-5 text-[#171711]" />
                </div>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] dark:bg-[#282723] text-[#171711] dark:text-[#f4f2ea]">
                  Safari Extension
                </span>
              </div>
              <h3 className="text-base font-bold text-[#171711] dark:text-[#f4f2ea]">Apple Safari</h3>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-1">
                Safari Web Extension bundle integrated directly with the LaterBox iOS app.
              </p>
            </div>
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] hover:bg-[#e0dbcd] dark:hover:bg-[#33322d] text-[#171711] dark:text-[#f4f2ea] text-xs font-bold transition-all cursor-pointer"
            >
              <span>Included in iOS App</span>
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </section>

      {/* Android Tester Modal */}
      <AndroidTesterModal
        isOpen={isAndroidModalOpen}
        onClose={() => setIsAndroidModalOpen(false)}
      />
    </div>
  );
}
