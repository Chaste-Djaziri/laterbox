// laterbox-web/src/app/(app)/downloads/page.tsx
'use client';

import React from 'react';
import Link from 'next/link';
import { AppStoreButton } from '@/components/download/AppStoreButton';
import {
  Apple,
  ArrowRight,
  Download,
  Laptop,
  Puzzle,
  Smartphone,
  Terminal,
} from 'lucide-react';

const CHROME_STORE_URL =
  'https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp';

export default function InAppDownloadsPage() {
  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 py-8 sm:py-14 space-y-8">
      {/* Direct Header */}
      <div className="space-y-1">
        <h1 className="text-2xl sm:text-3xl font-black text-[#181b14] tracking-tight">
          Apps &amp; Extensions
        </h1>
        <p className="text-xs sm:text-sm text-[#606458]">
          Install LaterBox on your devices to capture from anywhere into your library.
        </p>
      </div>

      {/* Direct Platform Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {/* iOS */}
        <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 flex flex-col justify-between space-y-5 shadow-2xs hover:border-[#181b14]/30 transition-all">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#181b14] text-white">
                <Apple className="w-5 h-5" />
              </span>
              <div>
                <h2 className="text-sm font-bold text-[#181b14]">iOS &amp; iPadOS</h2>
                <p className="text-[11px] text-[#7e8576]">App Store</p>
              </div>
            </div>
          </div>
          <div className="pt-2">
            <AppStoreButton size="default" theme="dark" />
          </div>
        </div>

        {/* Chrome Extension */}
        <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 flex flex-col justify-between space-y-5 shadow-2xs hover:border-[#181b14]/30 transition-all">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e6edb0] text-[#181b14]">
                <Puzzle className="w-5 h-5" />
              </span>
              <div>
                <h2 className="text-sm font-bold text-[#181b14]">Browser Extension</h2>
                <p className="text-[11px] text-[#7e8576]">Chromium Browsers</p>
              </div>
            </div>
          </div>
          <div className="flex items-center justify-between pt-2">
            <a
              href={CHROME_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
            >
              <Download className="w-3.5 h-3.5 text-[#e6edb0]" />
              <span>Add to Chrome</span>
            </a>
            <Link
              href="/extension/connect"
              className="text-xs font-bold text-[#606458] hover:text-[#181b14]"
            >
              Pair
            </Link>
          </div>
        </div>

        {/* Android */}
        <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 flex flex-col justify-between space-y-5 shadow-2xs hover:border-[#181b14]/30 transition-all">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ecf4df] text-[#465b2d]">
                <Smartphone className="w-5 h-5" />
              </span>
              <div>
                <h2 className="text-sm font-bold text-[#181b14]">Android</h2>
                <p className="text-[11px] text-[#7e8576]">Direct APK</p>
              </div>
            </div>
          </div>
          <div className="pt-2">
            <a
              href="/api/download/laterbox.apk"
              download="LaterBox.apk"
              className="w-full inline-flex items-center justify-center gap-1.5 px-3.5 py-2.5 rounded-xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
            >
              <Download className="w-3.5 h-3.5 text-[#e6edb0]" />
              <span>Download .apk</span>
            </a>
          </div>
        </div>
      </div>

      {/* Desktop Strip */}
      <div className="rounded-2xl bg-white border border-[#e4e0d5] px-5 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs text-[#606458]">
        <span className="font-bold text-[#181b14]">Desktop apps in progress:</span>
        <div className="flex flex-wrap items-center gap-2">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-[#faf8f5] border border-[#e9e6dd] text-[#181b14] font-medium">
            <Apple className="w-3.5 h-3.5" />
            <span>macOS (Beta)</span>
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
    </div>
  );
}
