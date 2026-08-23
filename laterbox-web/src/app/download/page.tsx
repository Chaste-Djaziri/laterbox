'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Header } from '@/components/layout/Header';
import {
  Download,
  Apple,
  Laptop,
  Smartphone,
  Puzzle,
  CheckCircle2,
  ExternalLink,
  ChevronDown,
  ChevronUp,
  FileArchive,
  ArrowRight,
  ShieldCheck,
} from 'lucide-react';

export default function DownloadPage() {
  const [downloadingFile, setDownloadingFile] = useState<string | null>(null);

  const triggerDownload = (filename: string) => {
    setDownloadingFile(filename);
    const downloadUrl = `https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/${filename}`;
    window.location.href = downloadUrl;
    setTimeout(() => setDownloadingFile(null), 3000);
  };

  const platforms = [
    {
      name: 'macOS',
      icon: <Apple className="w-8 h-8 text-zinc-900 dark:text-white" />,
      desc: 'Universal build for Apple Silicon (M1/M2/M3/M4) and Intel Macs.',
      badge: 'Recommended for Mac',
      actions: [
        { label: 'Download .dmg', filename: 'laterbox-macos.dmg', primary: true },
        { label: 'Download .pkg', filename: 'laterbox-macos-installer.pkg', primary: false },
        { label: 'Universal .zip', filename: 'laterbox-macos-universal.zip', primary: false },
      ],
    },
    {
      name: 'Windows',
      icon: <Laptop className="w-8 h-8 text-blue-500" />,
      desc: 'Native desktop application for Windows 10 and 11 (64-bit).',
      badge: 'Native App',
      actions: [
        { label: 'Installer (.exe)', filename: 'laterbox-windows-setup.exe', primary: true },
        { label: 'Portable (.zip)', filename: 'laterbox-windows-x64.zip', primary: false },
      ],
    },
    {
      name: 'Android',
      icon: <Smartphone className="w-8 h-8 text-emerald-500" />,
      desc: 'Native Android APK with system share sheet integration and offline queue.',
      badge: 'Mobile App',
      actions: [
        { label: 'Download .apk', filename: 'laterbox-android.apk', primary: true },
      ],
    },
    {
      name: 'Browser Extensions',
      icon: <Puzzle className="w-8 h-8 text-amber-500" />,
      desc: 'Capture links, articles, and text highlights with 1 click from Chrome, Brave, Edge & Firefox.',
      badge: 'Universal Add-on',
      actions: [
        { label: 'Chrome Extension (.zip)', filename: 'laterbox-chrome-extension.zip', primary: true },
        { label: 'Firefox Extension (.zip)', filename: 'laterbox-firefox-extension.zip', primary: false },
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100">
      <Header />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 py-12 sm:py-16 space-y-12">
        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 text-xs font-bold border border-emerald-200/80 dark:border-emerald-800/60">
            <Download className="w-3.5 h-3.5" />
            <span>Latest Release • Free & Open-Source</span>
          </div>
          <h1 className="text-4xl sm:text-5xl font-black tracking-tight text-zinc-900 dark:text-white">
            Download laterbox for all your devices
          </h1>
          <p className="text-base text-zinc-600 dark:text-zinc-400">
            Install the native desktop apps, mobile companion, and browser extensions for lightning-fast 1-second capture.
          </p>
        </div>

        {/* Download notification banner if triggered */}
        {downloadingFile && (
          <div className="p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-950/80 border border-emerald-300 dark:border-emerald-700 text-emerald-800 dark:text-emerald-200 text-xs font-bold flex items-center justify-between animate-in fade-in">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>Download started for {downloadingFile}. Check your browser downloads.</span>
            </div>
          </div>
        )}

        {/* Platform Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {platforms.map((p) => (
            <div
              key={p.name}
              className="p-7 sm:p-8 rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 hover:border-emerald-500/50 hover:shadow-xl transition-all duration-200 flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-5">
                  <div className="w-14 h-14 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center">
                    {p.icon}
                  </div>
                  <span className="px-3 py-1 rounded-full text-[11px] font-bold bg-zinc-100 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300">
                    {p.badge}
                  </span>
                </div>
                <h3 className="text-2xl font-black text-zinc-900 dark:text-white mb-2">{p.name}</h3>
                <p className="text-sm text-zinc-500 dark:text-zinc-400 leading-relaxed mb-6">
                  {p.desc}
                </p>
              </div>

              <div className="flex flex-wrap gap-2.5 pt-4 border-t border-zinc-100 dark:border-zinc-800">
                {p.actions.map((act) => (
                  <button
                    key={act.filename}
                    onClick={() => triggerDownload(act.filename)}
                    className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold transition-all ${
                      act.primary
                        ? 'bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white shadow-sm'
                        : 'bg-zinc-100 dark:bg-zinc-800 hover:bg-zinc-200 dark:hover:bg-zinc-700 text-zinc-800 dark:text-zinc-200'
                    }`}
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>{act.label}</span>
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>

        {/* Quick Extension Install Guide */}
        <section className="p-8 rounded-3xl bg-zinc-100/70 dark:bg-zinc-900/60 border border-zinc-200/80 dark:border-zinc-800 space-y-4">
          <div className="flex items-center gap-3">
            <Puzzle className="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
            <h2 className="text-xl font-extrabold text-zinc-900 dark:text-white">
              How to install the Chrome & Firefox Extensions
            </h2>
          </div>
          <ol className="list-decimal list-inside space-y-2 text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed">
            <li>Download the extension ZIP file above and unzip it to a folder.</li>
            <li>Open <code className="px-1.5 py-0.5 rounded bg-zinc-200 dark:bg-zinc-800 font-mono text-xs">chrome://extensions</code> in Chrome or Brave.</li>
            <li>Enable <strong>Developer mode</strong> in the top-right corner.</li>
            <li>Click <strong>Load unpacked</strong> and select the unzipped extension directory.</li>
            <li>Click the laterbox icon in your browser toolbar to connect and start capturing!</li>
          </ol>
        </section>
      </main>
    </div>
  );
}
