'use client';

import React, { useState } from 'react';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { AndroidTesterModal } from '@/components/download/AndroidTesterModal';
import {
  Download,
  Apple,
  Laptop,
  Smartphone,
  Puzzle,
  CheckCircle2,
  Users,
} from 'lucide-react';

export default function DownloadPage() {
  const [downloadingFile, setDownloadingFile] = useState<string | null>(null);
  const [isAndroidModalOpen, setIsAndroidModalOpen] = useState(false);

  const triggerDownload = (filename: string) => {
    setDownloadingFile(filename);
    const downloadUrl = `https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/${filename}`;
    window.location.href = downloadUrl;
    setTimeout(() => setDownloadingFile(null), 3000);
  };

  const platforms = [
    {
      id: 'macos',
      name: 'macOS',
      icon: <Apple className="w-8 h-8 text-[#171711]" />,
      desc: 'Universal build for Apple Silicon (M1/M2/M3/M4) and Intel Macs.',
      badge: 'Recommended for Mac',
      actions: [
        { label: 'Download .dmg', filename: 'laterbox-macos.dmg', primary: true },
        { label: 'Download .pkg', filename: 'laterbox-macos-installer.pkg', primary: false },
        { label: 'Universal .zip', filename: 'laterbox-macos-universal.zip', primary: false },
      ],
    },
    {
      id: 'windows',
      name: 'Windows',
      icon: <Laptop className="w-8 h-8 text-[#171711]" />,
      desc: 'Native desktop application for Windows 10 and 11 (64-bit).',
      badge: 'Native App',
      actions: [
        { label: 'Installer (.exe)', filename: 'laterbox-windows-setup.exe', primary: true },
        { label: 'Portable (.zip)', filename: 'laterbox-windows-x64.zip', primary: false },
      ],
    },
    {
      id: 'android',
      name: 'Android',
      icon: <Smartphone className="w-8 h-8 text-[#171711]" />,
      desc: 'Google Play closed testing track and direct APK with system share sheet integration.',
      badge: 'Google Play Beta',
      isAndroid: true,
      actions: [
        { label: 'Download .apk', filename: 'laterbox-android.apk', primary: false },
      ],
    },
    {
      id: 'extensions',
      name: 'Browser Extensions',
      icon: <Puzzle className="w-8 h-8 text-[#171711]" />,
      desc: 'Capture links, articles, and text highlights with 1 click from Chrome, Brave, Edge & Firefox.',
      badge: 'Universal Add-on',
      actions: [
        { label: 'Chrome Extension (.zip)', filename: 'laterbox-chrome-extension.zip', primary: true },
        { label: 'Firefox Extension (.zip)', filename: 'laterbox-firefox-extension.zip', primary: false },
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-[#f7f5ee] text-[#171711]">
      <Header />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 py-12 sm:py-16 space-y-12">
        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#e6edb0] text-[#171711] text-xs font-bold border border-[#d0db84]">
            <Download className="w-3.5 h-3.5" />
            <span>Latest Release • Free & Open-Source</span>
          </div>
          <h1 className="text-4xl sm:text-5xl font-black tracking-tight text-[#171711]">
            Download laterbox for all your devices
          </h1>
          <p className="text-base text-[#6c6b63]">
            Install the native desktop apps, mobile companion, and browser extensions for lightning-fast 1-second capture.
          </p>
        </div>

        {/* Download notification banner if triggered */}
        {downloadingFile && (
          <div className="p-4 rounded-2xl bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-bold flex items-center justify-between animate-in fade-in">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-[#171711]" />
              <span>Download started for {downloadingFile}. Check your browser downloads.</span>
            </div>
          </div>
        )}

        {/* Platform Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {platforms.map((p) => (
            <div
              key={p.name}
              className="p-7 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-md transition-all duration-200 flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-5">
                  <div className="w-14 h-14 rounded-2xl bg-[#e6edb0] flex items-center justify-center">
                    {p.icon}
                  </div>
                  <span className="px-3 py-1 rounded-full text-[11px] font-bold bg-[#ebe7dc] text-[#171711]">
                    {p.badge}
                  </span>
                </div>
                <h3 className="text-2xl font-black text-[#171711] mb-2">{p.name}</h3>
                <p className="text-sm text-[#6c6b63] leading-relaxed mb-6">
                  {p.desc}
                </p>
              </div>

              <div className="flex flex-wrap gap-2.5 pt-4 border-t border-[#e4e0d5]">
                {p.isAndroid ? (
                  <>
                    <button
                      onClick={() => setIsAndroidModalOpen(true)}
                      className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-extrabold bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white shadow-xs transition-all cursor-pointer"
                    >
                      <Users className="w-3.5 h-3.5 text-[#e6edb0]" />
                      <span>Google Play Beta (Join Group)</span>
                    </button>
                    {p.actions.map((act) => (
                      <button
                        key={act.filename}
                        onClick={() => triggerDownload(act.filename)}
                        className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] transition-all cursor-pointer"
                      >
                        <Download className="w-3.5 h-3.5" />
                        <span>{act.label}</span>
                      </button>
                    ))}
                  </>
                ) : (
                  p.actions.map((act) => (
                    <button
                      key={act.filename}
                      onClick={() => triggerDownload(act.filename)}
                      className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                        act.primary
                          ? 'bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white shadow-xs'
                          : 'bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711]'
                      }`}
                    >
                      <Download className="w-3.5 h-3.5" />
                      <span>{act.label}</span>
                    </button>
                  ))
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Quick Extension Install Guide */}
        <section className="p-8 rounded-3xl bg-[#ebe7dc]/40 border border-[#e4e0d5] space-y-4">
          <div className="flex items-center gap-3">
            <Puzzle className="w-6 h-6 text-[#171711]" />
            <h2 className="text-xl font-extrabold text-[#171711]">
              How to install the Chrome & Firefox Extensions
            </h2>
          </div>
          <ol className="list-decimal list-inside space-y-2 text-sm text-[#6c6b63] leading-relaxed">
            <li>Download the extension ZIP file above and unzip it to a folder.</li>
            <li>Open <code className="px-1.5 py-0.5 rounded bg-[#ebe7dc] font-mono text-xs text-[#171711]">chrome://extensions</code> in Chrome or Brave.</li>
            <li>Enable <strong>Developer mode</strong> in the top-right corner.</li>
            <li>Click <strong>Load unpacked</strong> and select the unzipped extension directory.</li>
            <li>Click the laterbox icon in your browser toolbar to connect and start capturing!</li>
          </ol>
        </section>
      </main>

      <Footer />

      {/* Android Tester Modal */}
      <AndroidTesterModal
        isOpen={isAndroidModalOpen}
        onClose={() => setIsAndroidModalOpen(false)}
        onDownloadApk={() => triggerDownload('laterbox-android.apk')}
      />
    </div>
  );
}
