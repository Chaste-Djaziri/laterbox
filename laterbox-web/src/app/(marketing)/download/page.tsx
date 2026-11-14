// laterbox-web/src/app/(marketing)/download/page.tsx
'use client';

import Link from 'next/link';
import { AppStoreButton } from '@/components/download/AppStoreButton';
import {
  Apple,
  ArrowRight,
  Download,
  Globe2,
  Laptop,
  Puzzle,
  Smartphone,
  Terminal,
} from 'lucide-react';

const CHROME_STORE_URL =
  'https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp';
const CHROME_ZIP_URL =
  'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-chrome-extension.zip';

export default function DownloadPage() {

  return (
    <div className="w-full flex-1 bg-[#fbfaf6]">
      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12 sm:py-20 space-y-10">
        {/* Direct Header */}
        <div className="space-y-2 text-center sm:text-left">
          <h1 className="text-3xl sm:text-5xl font-black text-[#181b14] tracking-[-0.04em]">
            Download LaterBox
          </h1>
          <p className="text-sm sm:text-base text-[#606458] font-medium">
            Get LaterBox for Mac, iPhone, your browser, and the web.
          </p>
        </div>

        {/* 4 Direct Download Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {/* iOS Card */}
          <div className="rounded-2xl bg-white border border-[#e4e0d5] p-6 flex flex-col justify-between space-y-6 shadow-2xs hover:border-[#181b14]/30 transition-all">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#181b14] text-white">
                  <Apple className="w-5 h-5" />
                </span>
                <div>
                  <h2 className="text-base font-bold text-[#181b14]">iOS &amp; iPadOS</h2>
                  <p className="text-xs text-[#7e8576]">iPhone &amp; iPad</p>
                </div>
              </div>
              <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324]">
                App Store
              </span>
            </div>

            <div className="flex items-center justify-between pt-2">
              <AppStoreButton size="default" theme="dark" />
              <span className="text-[11px] text-[#8e9587]">iOS 16+</span>
            </div>
          </div>

          {/* Chrome Extension Card */}
          <div className="rounded-2xl bg-white border border-[#e4e0d5] p-6 flex flex-col justify-between space-y-6 shadow-2xs hover:border-[#181b14]/30 transition-all">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#e6edb0] text-[#181b14]">
                  <Puzzle className="w-5 h-5" />
                </span>
                <div>
                  <h2 className="text-base font-bold text-[#181b14]">Browser Extension</h2>
                  <p className="text-xs text-[#7e8576]">Chrome, Brave, Edge &amp; Arc</p>
                </div>
              </div>
              <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324]">
                Manifest V3
              </span>
            </div>

            <div className="space-y-3 pt-2">
              <div className="flex flex-wrap items-center gap-2">
                <a
                  href={CHROME_STORE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
                >
                  <Download className="w-3.5 h-3.5 text-[#e6edb0]" />
                  <span>Add from Chrome Web Store</span>
                </a>
                <a
                  href={CHROME_ZIP_URL}
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-[#181b14]/20 bg-white hover:bg-[#f4f7eb] text-[#181b14] text-xs font-bold transition-all"
                  aria-label="Download LaterBox Chrome extension ZIP for manual installation"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download Chrome ZIP</span>
                </a>
              </div>
              <p className="text-xs leading-5 text-[#606458]">
                Manual install: unzip the download, open <code className="font-semibold text-[#181b14]">chrome://extensions</code>,
                enable Developer mode, select Load unpacked, then choose the unzipped folder.
                Chrome cannot install the ZIP file directly.
              </p>
              <Link
                href="/extension/connect"
                className="inline-flex items-center gap-1 text-xs font-bold text-[#606458] hover:text-[#181b14] transition-colors"
              >
                <span>Pair extension</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>

          {/* macOS is uploaded to App Store Connect; no direct DMG distribution. */}
          <div className="rounded-2xl bg-white border border-[#e4e0d5] p-6 flex flex-col justify-between space-y-6 shadow-2xs hover:border-[#181b14]/30 transition-all">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#181b14] text-[#e6edb0]">
                  <Laptop className="w-5 h-5" />
                </span>
                <div>
                  <h2 className="text-base font-bold text-[#181b14]">macOS</h2>
                  <p className="text-xs text-[#7e8576]">Native Mac application</p>
                </div>
              </div>
              <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324]">
                Mac App Store
              </span>
            </div>
            <div className="flex items-center justify-between pt-2 gap-3">
              <span className="text-xs font-semibold text-[#606458]">App Store release coming soon</span>
              <span className="text-[11px] text-[#8e9587]">macOS 14+</span>
            </div>
          </div>

          {/* Web App Card */}
          <div className="rounded-2xl bg-white border border-[#e4e0d5] p-6 flex flex-col justify-between space-y-6 shadow-2xs hover:border-[#181b14]/30 transition-all">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#ebe7dc] text-[#181b14]">
                  <Globe2 className="w-5 h-5" />
                </span>
                <div>
                  <h2 className="text-base font-bold text-[#181b14]">Web App</h2>
                  <p className="text-xs text-[#7e8576]">Any browser</p>
                </div>
              </div>
              <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-[#2c3324]">
                PWA Ready
              </span>
            </div>

            <div className="flex items-center justify-between pt-2">
              <Link
                href="/inbox"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
              >
                <span>Launch Web</span>
                <ArrowRight className="w-3.5 h-3.5 text-[#e6edb0]" />
              </Link>
              <span className="text-[11px] text-[#8e9587]">No install needed</span>
            </div>
          </div>
        </div>

        {/* Minimalist Desktop Roadmap Strip */}
        <div className="rounded-2xl bg-white border border-[#e4e0d5] px-5 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs text-[#606458]">
          <span className="font-bold text-[#181b14]">Coming soon:</span>
          <div className="flex flex-wrap items-center gap-2">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-[#faf8f5] border border-[#e9e6dd] text-[#181b14] font-medium">
              <Smartphone className="w-3.5 h-3.5" />
              <span>Android</span>
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-[#faf8f5] border border-[#e9e6dd] text-[#181b14] font-medium">
              <Laptop className="w-3.5 h-3.5" />
              <span>Windows</span>
            </span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-[#faf8f5] border border-[#e9e6dd] text-[#181b14] font-medium">
              <Terminal className="w-3.5 h-3.5" />
              <span>Linux</span>
            </span>
          </div>
        </div>
      </main>
    </div>
  );
}
