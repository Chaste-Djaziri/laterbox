'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Download,
  Apple,
  Laptop,
  Terminal,
  Puzzle,
  Smartphone,
  CheckCircle2,
  Copy,
  Check,
  ExternalLink,
  Sparkles,
  Zap,
  ShieldCheck,
  HardDrive,
  RefreshCw,
} from 'lucide-react';
import { APP_VERSION } from '@/lib/version';

type PlatformId = 'macos' | 'windows' | 'linux' | 'android' | 'ios' | 'extensions';

function detectUserPlatform(): PlatformId {
  if (typeof window === 'undefined') return 'macos';
  const ua = window.navigator.userAgent || '';
  const platform = (window.navigator as any).userAgentData?.platform || window.navigator.platform || '';
  const maxTouchPoints = window.navigator.maxTouchPoints || 0;

  if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && maxTouchPoints > 1)) return 'ios';
  if (/Android/i.test(ua)) return 'android';
  if (/Win/i.test(ua) || /Win/i.test(platform)) return 'windows';
  if (/Linux/i.test(ua) || /Linux/i.test(platform)) return 'linux';
  if (/Mac/i.test(ua) || /Mac/i.test(platform)) return 'macos';
  return 'macos';
}

interface GitHubRelease {
  tag_name: string;
  name?: string;
  published_at?: string;
  assets?: { name: string; browser_download_url: string; size?: number }[];
}

export default function InAppDownloadsPage() {
  const [selectedPlatform, setSelectedPlatform] = useState<PlatformId>('macos');
  const [detectedPlatform, setDetectedPlatform] = useState<PlatformId>('macos');
  const [copiedKey, setCopiedKey] = useState<string | null>(null);
  const [release, setRelease] = useState<GitHubRelease | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const detected = detectUserPlatform();
    setDetectedPlatform(detected);
    setSelectedPlatform(detected);

    fetch('/api/releases')
      .then(async (res) => {
        if (!res.ok) return null;
        return (await res.json()) as GitHubRelease | GitHubRelease[] | null;
      })
      .then((data) => {
        if (data) {
          if (Array.isArray(data) && data.length > 0) {
            setRelease(data[0]);
          } else if ('tag_name' in data && data.tag_name) {
            setRelease(data);
          }
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const copyToClipboard = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const platforms = [
    { id: 'macos' as PlatformId, label: 'macOS', icon: <Apple className="w-4 h-4" /> },
    { id: 'windows' as PlatformId, label: 'Windows', icon: <Laptop className="w-4 h-4" /> },
    { id: 'linux' as PlatformId, label: 'Linux', icon: <Terminal className="w-4 h-4" /> },
    { id: 'android' as PlatformId, label: 'Android', icon: <Smartphone className="w-4 h-4" /> },
    { id: 'ios' as PlatformId, label: 'iOS', icon: <Smartphone className="w-4 h-4" /> },
    { id: 'extensions' as PlatformId, label: 'Extensions', icon: <Puzzle className="w-4 h-4" /> },
  ];

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-6 border-b border-[#e5e0d3] dark:border-[#2e2d27]">
        <div>
          <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-[#ebe7dc] dark:bg-[#282723] text-xs font-semibold text-[#6c6b63] dark:text-[#a09e94] mb-2">
            <Sparkles className="w-3.5 h-3.5 text-amber-600" />
            <span>Universal Native Clients • v{APP_VERSION}</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-[#171711] dark:text-[#f4f2ea] tracking-tight">
            Apps & Downloads
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] dark:text-[#a09e94] mt-1 max-w-xl">
            Supercharge your workflow with global ⌥Space quick capture, offline SQLite vault sync, and browser extensions.
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
            href="https://github.com/Chaste-Djaziri/laterbox/releases"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs sm:text-sm font-semibold text-[#6c6b63] dark:text-[#a09e94] bg-[#ebe7dc]/70 dark:bg-[#282723] hover:text-[#171711] dark:hover:text-[#f4f2ea] transition-colors"
          >
            <span>GitHub Releases</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </a>
        </div>
      </div>

      {/* Platform Navigation Tabs */}
      <div className="flex items-center gap-1.5 p-1.5 rounded-2xl bg-[#ebe7dc]/60 dark:bg-[#22211c] border border-[#e5e0d3] dark:border-[#2e2d27] overflow-x-auto">
        {platforms.map((p) => {
          const isActive = selectedPlatform === p.id;
          const isDetected = detectedPlatform === p.id;
          return (
            <button
              key={p.id}
              onClick={() => setSelectedPlatform(p.id)}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all whitespace-nowrap cursor-pointer ${
                isActive
                  ? 'bg-white dark:bg-[#2e2d27] text-[#171711] dark:text-[#f4f2ea] shadow-xs'
                  : 'text-[#6c6b63] dark:text-[#a09e94] hover:text-[#171711] dark:hover:text-[#f4f2ea]'
              }`}
            >
              {p.icon}
              <span>{p.label}</span>
              {isDetected && (
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" title="Detected platform" />
              )}
            </button>
          );
        })}
      </div>

      {/* Platform Content Panels */}
      <div className="space-y-6">
        {/* 1. macOS */}
        {selectedPlatform === 'macos' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-amber-500/10 flex items-center justify-center text-amber-700 dark:text-amber-400">
                  <Apple className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-[#171711] dark:text-[#f4f2ea]">macOS Apple Silicon & Intel</h3>
                  <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Universal DMG for macOS 12 Monterey or later</p>
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <a
                  href="/api/download/laterbox-macos-universal.dmg"
                  className="flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-4 h-4" />
                    <span>Download Universal DMG</span>
                  </span>
                  <span className="text-xs opacity-75">.dmg (ARM64 & x64)</span>
                </a>
              </div>

              <div className="pt-2 text-xs text-[#6c6b63] dark:text-[#a09e94] space-y-1.5">
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>Global Quick Capture shortcut (⌥Space)</span>
                </p>
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>Native macOS Menu Bar quick tray</span>
                </p>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-[#ebe7dc]/40 dark:bg-[#1a1a15] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-wider text-[#6c6b63] dark:text-[#a09e94]">
                Install via Terminal (Homebrew / Shell)
              </h4>

              <div className="space-y-3">
                <div>
                  <label className="text-xs font-medium text-[#6c6b63] dark:text-[#a09e94] mb-1 block">
                    One-line Quick Installer:
                  </label>
                  <div className="flex items-center justify-between p-3 rounded-xl bg-[#171711] text-emerald-400 font-mono text-xs overflow-x-auto">
                    <span>curl -fsSL https://laterbox.dev/install.sh | bash</span>
                    <button
                      onClick={() => copyToClipboard('curl -fsSL https://laterbox.dev/install.sh | bash', 'mac-curl')}
                      className="p-1 rounded text-white/70 hover:text-white cursor-pointer"
                      title="Copy command"
                    >
                      {copiedKey === 'mac-curl' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    </button>
                  </div>
                </div>

                <div>
                  <label className="text-xs font-medium text-[#6c6b63] dark:text-[#a09e94] mb-1 block">
                    Homebrew Cask:
                  </label>
                  <div className="flex items-center justify-between p-3 rounded-xl bg-[#171711] text-emerald-400 font-mono text-xs overflow-x-auto">
                    <span>brew install --cask laterbox</span>
                    <button
                      onClick={() => copyToClipboard('brew install --cask laterbox', 'mac-brew')}
                      className="p-1 rounded text-white/70 hover:text-white cursor-pointer"
                      title="Copy command"
                    >
                      {copiedKey === 'mac-brew' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 2. Windows */}
        {selectedPlatform === 'windows' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center text-blue-700 dark:text-blue-400">
                  <Laptop className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-[#171711] dark:text-[#f4f2ea]">Windows 10 / 11 (64-bit)</h3>
                  <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Native Windows executable installer with auto-updater</p>
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <a
                  href="/api/download/laterbox-windows-setup.exe"
                  className="flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-4 h-4" />
                    <span>Download Windows Installer</span>
                  </span>
                  <span className="text-xs opacity-75">.exe (x64)</span>
                </a>
              </div>

              <div className="pt-2 text-xs text-[#6c6b63] dark:text-[#a09e94] space-y-1.5">
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>Global Quick Capture hotkey (Alt+Space)</span>
                </p>
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>System Tray background minimization</span>
                </p>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-[#ebe7dc]/40 dark:bg-[#1a1a15] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-wider text-[#6c6b63] dark:text-[#a09e94]">
                PowerShell / Winget Quick Install
              </h4>

              <div className="space-y-3">
                <div>
                  <label className="text-xs font-medium text-[#6c6b63] dark:text-[#a09e94] mb-1 block">
                    PowerShell 1-Liner:
                  </label>
                  <div className="flex items-center justify-between p-3 rounded-xl bg-[#171711] text-emerald-400 font-mono text-xs overflow-x-auto">
                    <span>iwr -useb https://laterbox.dev/install.ps1 | iex</span>
                    <button
                      onClick={() => copyToClipboard('iwr -useb https://laterbox.dev/install.ps1 | iex', 'win-ps')}
                      className="p-1 rounded text-white/70 hover:text-white cursor-pointer"
                      title="Copy command"
                    >
                      {copiedKey === 'win-ps' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    </button>
                  </div>
                </div>

                <div>
                  <label className="text-xs font-medium text-[#6c6b63] dark:text-[#a09e94] mb-1 block">
                    Windows Package Manager (Winget):
                  </label>
                  <div className="flex items-center justify-between p-3 rounded-xl bg-[#171711] text-emerald-400 font-mono text-xs overflow-x-auto">
                    <span>winget install LaterBox.LaterBox</span>
                    <button
                      onClick={() => copyToClipboard('winget install LaterBox.LaterBox', 'win-winget')}
                      className="p-1 rounded text-white/70 hover:text-white cursor-pointer"
                      title="Copy command"
                    >
                      {copiedKey === 'win-winget' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 3. Linux */}
        {selectedPlatform === 'linux' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-orange-500/10 flex items-center justify-center text-orange-700 dark:text-orange-400">
                  <Terminal className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-[#171711] dark:text-[#f4f2ea]">Linux AppImage & Debian Package</h3>
                  <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Ubuntu, Fedora, Arch, Debian, and all major distros</p>
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <a
                  href="/api/download/laterbox-linux.AppImage"
                  className="flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-4 h-4" />
                    <span>Download AppImage</span>
                  </span>
                  <span className="text-xs opacity-75">.AppImage (x86_64)</span>
                </a>
                <a
                  href="/api/download/laterbox-linux.deb"
                  className="flex items-center justify-between px-4 py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] hover:bg-[#e0dbcd] dark:hover:bg-[#33322d] text-[#171711] dark:text-[#f4f2ea] font-semibold text-xs transition-all"
                >
                  <span>Debian / Ubuntu Package (.deb)</span>
                  <span className="text-xs text-[#6c6b63] dark:text-[#a09e94]">.deb</span>
                </a>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-[#ebe7dc]/40 dark:bg-[#1a1a15] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-wider text-[#6c6b63] dark:text-[#a09e94]">
                Install via Shell Script
              </h4>
              <div>
                <label className="text-xs font-medium text-[#6c6b63] dark:text-[#a09e94] mb-1 block">
                  Quick Linux Terminal Installer:
                </label>
                <div className="flex items-center justify-between p-3 rounded-xl bg-[#171711] text-emerald-400 font-mono text-xs overflow-x-auto">
                  <span>curl -fsSL https://laterbox.dev/install.sh | bash</span>
                  <button
                    onClick={() => copyToClipboard('curl -fsSL https://laterbox.dev/install.sh | bash', 'linux-curl')}
                    className="p-1 rounded text-white/70 hover:text-white cursor-pointer"
                    title="Copy command"
                  >
                    {copiedKey === 'linux-curl' ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 4. Android */}
        {selectedPlatform === 'android' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-700 dark:text-emerald-400">
                  <Smartphone className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-[#171711] dark:text-[#f4f2ea]">Android APK & Google Play Beta</h3>
                  <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Android 8.0 Oreo or higher</p>
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <a
                  href="/api/download/laterbox-android.apk"
                  className="flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-4 h-4" />
                    <span>Download Direct APK</span>
                  </span>
                  <span className="text-xs opacity-75">.apk</span>
                </a>
              </div>

              <div className="pt-2 text-xs text-[#6c6b63] dark:text-[#a09e94] space-y-1.5">
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>Native System Share Sheet listener</span>
                </p>
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>Offline SQLite Drift synchronization</span>
                </p>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-[#ebe7dc]/40 dark:bg-[#1a1a15] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-4">
              <h4 className="text-xs font-bold uppercase tracking-wider text-[#6c6b63] dark:text-[#a09e94]">
                Google Play Closed Testing Group
              </h4>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                Join our official Google Play tester group to receive automatic background updates directly from the Play Store.
              </p>
              <a
                href="https://groups.google.com/g/laterbox-testers"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] dark:bg-[#383731] text-white font-bold text-xs"
              >
                <span>Join Google Play Tester Group</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>
        )}

        {/* 5. iOS */}
        {selectedPlatform === 'ios' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-purple-500/10 flex items-center justify-center text-purple-700 dark:text-purple-400">
                  <Smartphone className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-[#171711] dark:text-[#f4f2ea]">iOS & iPadOS Beta</h3>
                  <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Apple TestFlight & Progressive Web App</p>
                </div>
              </div>

              <div className="space-y-3 pt-2">
                <a
                  href="https://testflight.apple.com/join/laterbox"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all"
                >
                  <span className="flex items-center gap-2">
                    <Sparkles className="w-4 h-4" />
                    <span>Join Apple TestFlight Beta</span>
                  </span>
                  <ExternalLink className="w-4 h-4" />
                </a>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-[#ebe7dc]/40 dark:bg-[#1a1a15] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-[#6c6b63] dark:text-[#a09e94]">
                Install as iPhone / iPad PWA
              </h4>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                1. Open <strong>app.laterbox.dev</strong> in Safari on your iOS device.
              </p>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                2. Tap the <strong>Share</strong> button in Safari toolbar.
              </p>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                3. Tap <strong>Add to Home Screen</strong> for a full-screen standalone app experience.
              </p>
            </div>
          </div>
        )}

        {/* 6. Browser Extensions */}
        {selectedPlatform === 'extensions' && (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-2 font-bold text-[#171711] dark:text-[#f4f2ea]">
                <Puzzle className="w-5 h-5 text-blue-600" />
                <span>Google Chrome & Brave</span>
              </div>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                Chrome Web Store Manifest V3 extension with 1-click URL & tab capture.
              </p>
              <a
                href="https://chromewebstore.google.com/detail/laterbox/laterbox"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl bg-[#171711] text-white font-bold text-xs hover:bg-[#282723] transition-colors"
              >
                <span>Install from Chrome Web Store</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>

            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-2 font-bold text-[#171711] dark:text-[#f4f2ea]">
                <Puzzle className="w-5 h-5 text-orange-600" />
                <span>Mozilla Firefox</span>
              </div>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                Firefox Add-ons store extension compatible with Firefox Desktop & Mobile.
              </p>
              <a
                href="https://addons.mozilla.org/firefox/addon/laterbox"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl bg-[#171711] text-white font-bold text-xs hover:bg-[#282723] transition-colors"
              >
                <span>Install from Firefox Add-ons</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>

            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-2 font-bold text-[#171711] dark:text-[#f4f2ea]">
                <Puzzle className="w-5 h-5 text-indigo-600" />
                <span>Apple Safari</span>
              </div>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                Bundled automatically inside the macOS native client for Safari.
              </p>
              <Link
                href="/extension/connect"
                className="flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] text-[#171711] dark:text-[#f4f2ea] font-bold text-xs hover:bg-[#e0dbcd] transition-colors"
              >
                <span>Connect Installed Extension</span>
              </Link>
            </div>
          </div>
        )}
      </div>

      {/* Feature Badges Card */}
      <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div className="flex items-start gap-3">
            <div className="p-2.5 rounded-xl bg-amber-500/10 text-amber-700 dark:text-amber-400 mt-0.5">
              <HardDrive className="w-4 h-4" />
            </div>
            <div>
              <h4 className="font-bold text-sm text-[#171711] dark:text-[#f4f2ea]">Offline-First Vault</h4>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-0.5">
                Every desktop and mobile app caches your entire vault in local SQLite for sub-millisecond search.
              </p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="p-2.5 rounded-xl bg-blue-500/10 text-blue-700 dark:text-blue-400 mt-0.5">
              <Zap className="w-4 h-4" />
            </div>
            <div>
              <h4 className="font-bold text-sm text-[#171711] dark:text-[#f4f2ea]">⌥Space Global Capture</h4>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-0.5">
                Summon the native spotlight tray anywhere on macOS & Windows without switching focus.
              </p>
            </div>
          </div>

          <div className="flex items-start gap-3">
            <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 mt-0.5">
              <ShieldCheck className="w-4 h-4" />
            </div>
            <div>
              <h4 className="font-bold text-sm text-[#171711] dark:text-[#f4f2ea]">Zero Lock-In</h4>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] mt-0.5">
                1-click JSON, Markdown, and SQLite exports at any time from your settings panel.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
