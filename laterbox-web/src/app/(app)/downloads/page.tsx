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
  Download,
  Puzzle,
  CheckCircle2,
  ExternalLink,
  Sparkles,
  ArrowRight,
  Clock,
  Hammer,
} from 'lucide-react';

export default function InAppDownloadsPage() {
  const [isAndroidModalOpen, setIsAndroidModalOpen] = useState(false);

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 py-6 sm:py-10 space-y-10">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-6 border-b border-[#e4e0d5]">
        <div>
          <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-[#ebe7dc] text-xs font-semibold text-[#6c6b63] mb-2">
            <Sparkles className="w-3.5 h-3.5 text-amber-600" />
            <span>Official Client & Platform Roadmap</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-[#171711] tracking-tight">
            Apps & Downloads
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] mt-1 max-w-xl">
            Download the official LaterBox iOS app directly from the Apple App Store, pair browser extensions, or track upcoming platforms.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href="/extension/connect"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold text-white bg-[#171711] hover:bg-[#282723] transition-all shadow-xs"
          >
            <Puzzle className="w-4 h-4" />
            <span>Pair Extension</span>
          </Link>
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs sm:text-sm font-semibold text-[#171711] bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] shadow-2xs transition-colors"
          >
            <span>App Store</span>
            <ExternalLink className="w-3.5 h-3.5 text-[#6c6b63]" />
          </a>
        </div>
      </div>

      {/* Featured iOS App Section */}
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
                Save articles, videos, bookmarks, and notes from any app on your iPhone or iPad using the system Share Sheet with offline-first synchronization back to your vault.
              </p>
            </div>

            {/* Highlights Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 pt-2 text-xs text-[#171711]">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Native iOS Share Sheet extension</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Offline-first local cache & quick search</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Continuous cloud synchronization</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-medium">Biometric Face ID / Touch ID lock</span>
              </div>
            </div>

            <p className="text-[11px] text-[#9e9b92] pt-1">
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
              className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6c6b63] hover:text-[#171711] transition-colors"
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
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
              Other Platforms
            </h2>
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#ebe7dc] text-[#6c6b63]">
              Roadmap
            </span>
          </div>
          <p className="text-xs sm:text-sm text-[#6c6b63]">
            Native clients for desktop and Android are actively being developed.
          </p>
        </div>

        {/* 4 Platform Status Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Android - Public Beta / Direct APK */}
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-4 flex flex-col justify-between hover:border-[#171711]/40 transition-all shadow-2xs">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-700">
                  <Smartphone className="w-5 h-5" />
                </div>
                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10.5px] font-bold bg-emerald-50 text-emerald-800 border border-emerald-300">
                  <Sparkles className="w-3 h-3 text-emerald-600" />
                  <span>Public Beta</span>
                </span>
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711]">Android</h3>
                <p className="text-xs text-[#6c6b63] mt-1.5 leading-relaxed">
                  Native Android app with biometric lock, instant share sheet capture, and offline AI vault.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#f0ede4] space-y-2">
              <a
                href="/api/download/laterbox.apk"
                download="LaterBox.apk"
                className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold transition-all cursor-pointer shadow-2xs"
              >
                <Download className="w-3.5 h-3.5 text-[#E7FF57]" />
                <span>Download .apk</span>
              </a>
              <button
                type="button"
                onClick={() => setIsAndroidModalOpen(true)}
                className="w-full inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-xl text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/50 text-[11px] font-bold transition-all cursor-pointer"
              >
                <span>Google Play Beta</span>
                <ArrowRight className="w-3 h-3" />
              </button>
            </div>
          </div>

          {/* macOS - Coming Soon */}
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

          {/* Windows - Coming Soon */}
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

          {/* Linux - Coming Soon */}
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
            Browser Integrations
          </h2>
          <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
            Extensions
          </span>
        </div>

        <p className="text-xs sm:text-sm text-[#6c6b63] max-w-2xl">
          Capture articles, links, and text directly into your vault from desktop browsers.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between shadow-2xs">
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
            <div className="space-y-2 pt-2 border-t border-[#f0ede4]">
              <a
                href="https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp?authuser=0&hl=en"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold transition-all cursor-pointer shadow-2xs"
              >
                <Download className="w-3.5 h-3.5 text-[#E7FF57]" />
                <span>Install from Chrome Web Store</span>
              </a>
              <Link
                href="/extension/connect"
                className="w-full inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-xl text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/50 text-[11px] font-bold transition-all cursor-pointer"
              >
                <span>Pair & Setup</span>
                <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between shadow-2xs">
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
                Native Firefox add-on with quick capture sheet and auto-sync with your vault.
              </p>
            </div>
            <div className="space-y-2 pt-2 border-t border-[#f0ede4]">
              <a
                href="/api/download/laterbox-firefox-extension.zip"
                download="laterbox-firefox-extension.zip"
                className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold transition-all cursor-pointer shadow-2xs"
              >
                <Download className="w-3.5 h-3.5 text-[#E7FF57]" />
                <span>Download .zip</span>
              </a>
              <Link
                href="/extension/connect"
                className="w-full inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-xl text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/50 text-[11px] font-bold transition-all cursor-pointer"
              >
                <span>Firefox Add-on Info</span>
                <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
          </div>

          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between shadow-2xs">
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
            <div className="space-y-2 pt-2 border-t border-[#f0ede4]">
              <a
                href="/api/download/laterbox-safari-extension.zip"
                download="laterbox-safari-extension.zip"
                className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold transition-all cursor-pointer shadow-2xs"
              >
                <Download className="w-3.5 h-3.5 text-[#E7FF57]" />
                <span>Download .zip</span>
              </a>
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-xl text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/50 text-[11px] font-bold transition-all cursor-pointer"
              >
                <span>Included in iOS App</span>
                <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* Android Tester Modal */}
      <AndroidTesterModal
        isOpen={isAndroidModalOpen}
        onClose={() => setIsAndroidModalOpen(false)}
        onDownloadApk={() => {
          window.location.href = '/api/download/laterbox.apk';
        }}
      />
    </div>
  );
}
