'use client';

import React, { useState, useEffect, useMemo, useRef } from 'react';
import Link from 'next/link';
import { AndroidTesterModal } from '@/components/download/AndroidTesterModal';
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
  Search,
  ChevronDown,
  ChevronUp,
  FileCode,
  Calendar,
  Layers,
  ArrowRight,
  Package,
} from 'lucide-react';
import { APP_VERSION } from '@/lib/version';

type PlatformId = 'macos' | 'windows' | 'linux' | 'android' | 'ios' | 'extensions';
type HistoryTab = 'all' | 'desktop' | 'mobile' | 'extensions';

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

function formatBytes(bytes?: number): string {
  if (!bytes || bytes <= 0) return 'Direct Asset';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}

interface ReleaseAsset {
  name: string;
  browser_download_url: string;
  size?: number;
}

interface GitHubRelease {
  id?: number;
  tag_name: string;
  name?: string;
  published_at: string;
  body?: string;
  html_url?: string;
  assets: ReleaseAsset[];
}

export default function InAppDownloadsPage() {
  const [selectedPlatform, setSelectedPlatform] = useState<PlatformId>('macos');
  const [detectedPlatform, setDetectedPlatform] = useState<PlatformId>('macos');
  const [downloadingFile, setDownloadingFile] = useState<string | null>(null);
  const [isAndroidModalOpen, setIsAndroidModalOpen] = useState(false);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);
  const [historyTab, setHistoryTab] = useState<HistoryTab>('all');
  const [expandedVersions, setExpandedVersions] = useState<Set<string>>(new Set());
  const [releases, setReleases] = useState<GitHubRelease[]>([]);
  const [loadingReleases, setLoadingReleases] = useState<boolean>(true);
  const [releaseSearchQuery, setReleaseSearchQuery] = useState<string>('');
  const [latestVersionTag, setLatestVersionTag] = useState<string>(APP_VERSION);

  const previousReleasesRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const detected = detectUserPlatform();
    setDetectedPlatform(detected);
    setSelectedPlatform(detected);

    const fallbackAssets: ReleaseAsset[] = [
      { name: 'laterbox-macos-apple-silicon.dmg', browser_download_url: '/api/download/laterbox-macos-apple-silicon.dmg', size: 26650283 },
      { name: 'laterbox-macos-intel.dmg', browser_download_url: '/api/download/laterbox-macos-intel.dmg', size: 26650283 },
      { name: 'laterbox-macos-installer.pkg', browser_download_url: '/api/download/laterbox-macos-installer.pkg', size: 23386222 },
      { name: 'laterbox-macos-universal.zip', browser_download_url: '/api/download/laterbox-macos-universal.zip', size: 23408107 },
      { name: 'laterbox-windows-setup.exe', browser_download_url: '/api/download/laterbox-windows-setup.exe', size: 12863119 },
      { name: 'laterbox-windows-x64.zip', browser_download_url: '/api/download/laterbox-windows-x64.zip', size: 14988560 },
      { name: 'laterbox-linux-x64.tar.gz', browser_download_url: '/api/download/laterbox-linux-x64.tar.gz', size: 12703419 },
      { name: 'laterbox-linux-x64.zip', browser_download_url: '/api/download/laterbox-linux-x64.zip', size: 12715443 },
      { name: 'laterbox-linux.AppImage', browser_download_url: '/api/download/laterbox-linux.AppImage', size: 12703419 },
      { name: 'laterbox-linux.deb', browser_download_url: '/api/download/laterbox-linux.deb', size: 12703419 },
      { name: 'laterbox-android.apk', browser_download_url: '/api/download/laterbox-android.apk', size: 66794291 },
      { name: 'laterbox-android-release.apk', browser_download_url: '/api/download/laterbox-android-release.apk', size: 66794291 },
      { name: 'laterbox-ios.ipa', browser_download_url: '/api/download/laterbox-ios.ipa', size: 25415861 },
      { name: 'laterbox-chrome-extension.zip', browser_download_url: '/api/download/laterbox-chrome-extension.zip', size: 41255 },
      { name: 'laterbox-firefox-extension.zip', browser_download_url: '/api/download/laterbox-firefox-extension.zip', size: 41245 },
      { name: 'laterbox-safari-extension.zip', browser_download_url: '/api/download/laterbox-safari-extension.zip', size: 41219 },
    ];

    setLoadingReleases(true);
    fetch('/api/releases')
      .then(async (res) => {
        if (!res.ok) throw new Error('API unavailable');
        return (await res.json()) as GitHubRelease[];
      })
      .then((data) => {
        if (Array.isArray(data) && data.length > 0) {
          setReleases(data);
          const firstTag = data[0].tag_name.replace(/^v/, '');
          setLatestVersionTag(firstTag);
          const initialExpanded = new Set<string>();
          data.slice(0, 2).forEach((r) => initialExpanded.add(r.tag_name.replace(/^v/, '')));
          setExpandedVersions(initialExpanded);
        }
      })
      .catch(async () => {
        try {
          const directRes = await fetch('https://api.github.com/repos/Chaste-Djaziri/laterbox/releases?per_page=30');
          if (directRes.ok) {
            const directData = (await directRes.json()) as GitHubRelease[];
            if (Array.isArray(directData) && directData.length > 0) {
              const mapped = directData.map((rel) => ({
                id: rel.id,
                tag_name: rel.tag_name,
                name: rel.name || rel.tag_name,
                body: rel.body,
                html_url: rel.html_url || `https://github.com/Chaste-Djaziri/laterbox/releases/tag/${rel.tag_name}`,
                published_at: rel.published_at,
                assets: (rel.assets || []).map((a) => ({
                  name: a.name,
                  size: a.size,
                  browser_download_url: `/api/download/${encodeURIComponent(a.name)}`,
                })),
              }));
              setReleases(mapped);
              const initialExpanded = new Set<string>();
              mapped.slice(0, 2).forEach((r) => initialExpanded.add(r.tag_name.replace(/^v/, '')));
              setExpandedVersions(initialExpanded);
              return;
            }
          }
        } catch {
          // Fallback
        }

        setReleases([
          {
            id: 80,
            tag_name: `v${APP_VERSION}`,
            name: `LaterBox v${APP_VERSION}`,
            body: 'Full offline SQLite synchronization, instantaneous spotlight capture, and browser extension companion pairing.',
            html_url: `https://github.com/Chaste-Djaziri/laterbox/releases/tag/v${APP_VERSION}`,
            published_at: new Date().toISOString(),
            assets: fallbackAssets,
          },
          {
            id: 48,
            tag_name: 'v1.0.48',
            name: 'LaterBox v1.0.48',
            body: 'Pro features upgrade, multi-platform sync speedups, and responsive landing improvements.',
            html_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/tag/v1.0.48',
            published_at: new Date(Date.now() - 86400000).toISOString(),
            assets: fallbackAssets,
          },
        ]);
        setExpandedVersions(new Set([APP_VERSION, '1.0.48']));
      })
      .finally(() => {
        setLoadingReleases(false);
      });
  }, []);

  const copyToClipboard = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const handleDownload = (url: string, filename: string) => {
    setDownloadingFile(filename);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(() => setDownloadingFile(null), 2500);
  };

  const toggleVersion = (versionNum: string) => {
    setExpandedVersions((prev) => {
      const next = new Set(prev);
      if (next.has(versionNum)) next.delete(versionNum);
      else next.add(versionNum);
      return next;
    });
  };

  // Find latest asset for quick download
  const latestRelease = releases[0];
  const findAsset = (pattern: RegExp): ReleaseAsset | undefined => {
    if (!latestRelease || !latestRelease.assets) return undefined;
    return latestRelease.assets.find((a) => pattern.test(a.name));
  };

  // Filtered releases for history tab & search query
  const filteredReleases = useMemo(() => {
    let list = releases;
    if (releaseSearchQuery.trim()) {
      const q = releaseSearchQuery.toLowerCase().trim();
      list = list.filter(
        (r) =>
          r.tag_name.toLowerCase().includes(q) ||
          (r.name && r.name.toLowerCase().includes(q)) ||
          (r.body && r.body.toLowerCase().includes(q)) ||
          r.assets.some((a) => a.name.toLowerCase().includes(q))
      );
    }

    if (historyTab === 'all') return list;

    return list.map((rel) => {
      let filteredAssets = rel.assets;
      if (historyTab === 'desktop') {
        filteredAssets = rel.assets.filter((a) => /macos|windows|linux|\.dmg|\.pkg|\.exe|\.deb|\.AppImage/i.test(a.name));
      } else if (historyTab === 'mobile') {
        filteredAssets = rel.assets.filter((a) => /android|ios|\.apk|\.ipa/i.test(a.name));
      } else if (historyTab === 'extensions') {
        filteredAssets = rel.assets.filter((a) => /extension|\.crx|\.xpi/i.test(a.name));
      }
      return { ...rel, assets: filteredAssets };
    }).filter((r) => r.assets.length > 0);
  }, [releases, historyTab, releaseSearchQuery]);

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
            <span>Official Native Clients • v{latestVersionTag}</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-[#171711] dark:text-[#f4f2ea] tracking-tight">
            Apps & Downloads
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] dark:text-[#a09e94] mt-1 max-w-xl">
            Download verified native builds with offline-first SQLite sync, global ⌥Space quick capture, and extension pairing.
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
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" title="Your detected platform" />
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
                  <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">macOS 12 Monterey or later • Universal Build</p>
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/apple-silicon\.dmg/i)?.browser_download_url || '/api/download/laterbox-macos-apple-silicon.dmg',
                      'laterbox-macos-apple-silicon.dmg'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all cursor-pointer shadow-xs"
                >
                  <span className="flex items-center gap-2">
                    {downloadingFile === 'laterbox-macos-apple-silicon.dmg' ? (
                      <RefreshCw className="w-4 h-4 animate-spin text-amber-400" />
                    ) : (
                      <Download className="w-4 h-4 text-amber-400" />
                    )}
                    <span>Apple Silicon (M1/M2/M3/M4)</span>
                  </span>
                  <span className="text-xs text-white/70 font-mono">
                    {formatBytes(findAsset(/apple-silicon\.dmg/i)?.size || 26650283)}
                  </span>
                </button>

                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/intel\.dmg/i)?.browser_download_url || '/api/download/laterbox-macos-intel.dmg',
                      'laterbox-macos-intel.dmg'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] hover:bg-[#e0dbcd] dark:hover:bg-[#33322d] text-[#171711] dark:text-[#f4f2ea] font-semibold text-xs transition-all cursor-pointer"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-3.5 h-3.5" />
                    <span>Intel x64 Mac (.dmg)</span>
                  </span>
                  <span className="text-xs text-[#6c6b63] dark:text-[#a09e94] font-mono">
                    {formatBytes(findAsset(/intel\.dmg/i)?.size || 26650283)}
                  </span>
                </button>
              </div>

              <div className="pt-2 text-xs text-[#6c6b63] dark:text-[#a09e94] space-y-1.5">
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>Global Quick Capture shortcut (⌥Space)</span>
                </p>
                <p className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                  <span>Menu Bar tray with sub-millisecond local search</span>
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
                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/windows-setup\.exe/i)?.browser_download_url || '/api/download/laterbox-windows-setup.exe',
                      'laterbox-windows-setup.exe'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all cursor-pointer shadow-xs"
                >
                  <span className="flex items-center gap-2">
                    {downloadingFile === 'laterbox-windows-setup.exe' ? (
                      <RefreshCw className="w-4 h-4 animate-spin text-blue-400" />
                    ) : (
                      <Download className="w-4 h-4 text-blue-400" />
                    )}
                    <span>Download Windows Setup (.exe)</span>
                  </span>
                  <span className="text-xs text-white/70 font-mono">
                    {formatBytes(findAsset(/windows-setup\.exe/i)?.size || 12863119)}
                  </span>
                </button>

                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/windows-x64\.zip/i)?.browser_download_url || '/api/download/laterbox-windows-x64.zip',
                      'laterbox-windows-x64.zip'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] hover:bg-[#e0dbcd] dark:hover:bg-[#33322d] text-[#171711] dark:text-[#f4f2ea] font-semibold text-xs transition-all cursor-pointer"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-3.5 h-3.5" />
                    <span>Portable Standalone Zip (.zip)</span>
                  </span>
                  <span className="text-xs text-[#6c6b63] dark:text-[#a09e94] font-mono">
                    {formatBytes(findAsset(/windows-x64\.zip/i)?.size || 14988560)}
                  </span>
                </button>
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
                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/\.AppImage|linux-x64\.tar\.gz/i)?.browser_download_url || '/api/download/laterbox-linux.AppImage',
                      'laterbox-linux.AppImage'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all cursor-pointer shadow-xs"
                >
                  <span className="flex items-center gap-2">
                    {downloadingFile === 'laterbox-linux.AppImage' ? (
                      <RefreshCw className="w-4 h-4 animate-spin text-orange-400" />
                    ) : (
                      <Download className="w-4 h-4 text-orange-400" />
                    )}
                    <span>Download Linux AppImage</span>
                  </span>
                  <span className="text-xs text-white/70 font-mono">
                    {formatBytes(findAsset(/\.AppImage|linux-x64\.tar\.gz/i)?.size || 12703419)}
                  </span>
                </button>

                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/\.deb/i)?.browser_download_url || '/api/download/laterbox-linux.deb',
                      'laterbox-linux.deb'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] hover:bg-[#e0dbcd] dark:hover:bg-[#33322d] text-[#171711] dark:text-[#f4f2ea] font-semibold text-xs transition-all cursor-pointer"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-3.5 h-3.5" />
                    <span>Debian / Ubuntu Package (.deb)</span>
                  </span>
                  <span className="text-xs text-[#6c6b63] dark:text-[#a09e94] font-mono">
                    {formatBytes(findAsset(/\.deb/i)?.size || 12703419)}
                  </span>
                </button>
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
                  <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Android 8.0 Oreo or higher • Arm64 & x86</p>
                </div>
              </div>

              <div className="space-y-2 pt-2">
                <button
                  onClick={() => setIsAndroidModalOpen(true)}
                  className="w-full flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all cursor-pointer shadow-xs"
                >
                  <span className="flex items-center gap-2">
                    <Sparkles className="w-4 h-4 text-emerald-400" />
                    <span>Join Android Testers on Google Play</span>
                  </span>
                  <ArrowRight className="w-4 h-4" />
                </button>

                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/android.*\.apk/i)?.browser_download_url || '/api/download/laterbox-android.apk',
                      'laterbox-android.apk'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all cursor-pointer shadow-xs"
                >
                  <span className="flex items-center gap-2">
                    {downloadingFile === 'laterbox-android.apk' ? (
                      <RefreshCw className="w-4 h-4 animate-spin text-amber-600" />
                    ) : (
                      <Download className="w-4 h-4 text-amber-600" />
                    )}
                    <span>Download Standalone APK</span>
                  </span>
                  <span className="text-xs text-[#6c6b63] dark:text-[#a09e94] font-mono">
                    {formatBytes(findAsset(/android.*\.apk/i)?.size || 66794291)}
                  </span>
                </button>

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
                Google Play Closed Testing Track
              </h4>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] leading-relaxed">
                Join the official Google Play testing track to receive automatic updates directly from the Play Store without manual APK installs.
              </p>
              <div className="space-y-2">
                <a
                  href="https://play.google.com/apps/testing/pro.micorp.laterbox"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] dark:bg-[#383731] text-white font-bold text-xs hover:bg-[#282723] transition-colors"
                >
                  <span>Join Android Testers on Google Play</span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </a>
              </div>
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

              <div className="space-y-2 pt-2">
                <a
                  href="https://testflight.apple.com/join/laterbox"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-between px-4 py-3 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-sm transition-all shadow-xs"
                >
                  <span className="flex items-center gap-2">
                    <Sparkles className="w-4 h-4 text-purple-400" />
                    <span>Join Apple TestFlight Beta</span>
                  </span>
                  <ExternalLink className="w-4 h-4" />
                </a>

                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/ios.*\.ipa/i)?.browser_download_url || '/api/download/laterbox-ios.ipa',
                      'laterbox-ios.ipa'
                    )
                  }
                  className="w-full flex items-center justify-between px-4 py-2.5 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] hover:bg-[#e0dbcd] dark:hover:bg-[#33322d] text-[#171711] dark:text-[#f4f2ea] font-semibold text-xs transition-all cursor-pointer"
                >
                  <span className="flex items-center gap-2">
                    <Download className="w-3.5 h-3.5" />
                    <span>Direct IPA Package (.ipa)</span>
                  </span>
                  <span className="text-xs text-[#6c6b63] dark:text-[#a09e94] font-mono">
                    {formatBytes(findAsset(/ios.*\.ipa/i)?.size || 25415861)}
                  </span>
                </button>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-[#ebe7dc]/40 dark:bg-[#1a1a15] border border-[#e5e0d3] dark:border-[#2e2d27] space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-[#6c6b63] dark:text-[#a09e94]">
                Install as iPhone / iPad PWA
              </h4>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                1. Open <strong>app.laterbox.dev</strong> in Safari on your iPhone or iPad.
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
              <div className="space-y-2 pt-1">
                <a
                  href="https://chromewebstore.google.com/detail/laterbox/laterbox"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl bg-[#171711] text-white font-bold text-xs hover:bg-[#282723] transition-colors"
                >
                  <span>Install from Chrome Web Store</span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </a>
                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/chrome-extension\.zip/i)?.browser_download_url || '/api/download/laterbox-chrome-extension.zip',
                      'laterbox-chrome-extension.zip'
                    )
                  }
                  className="w-full flex items-center justify-center gap-1.5 py-2 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] text-[#171711] dark:text-[#f4f2ea] text-xs font-semibold cursor-pointer"
                >
                  <Download className="w-3 h-3" />
                  <span>Manual .zip ({formatBytes(findAsset(/chrome-extension\.zip/i)?.size || 41255)})</span>
                </button>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-2 font-bold text-[#171711] dark:text-[#f4f2ea]">
                <Puzzle className="w-5 h-5 text-orange-600" />
                <span>Mozilla Firefox</span>
              </div>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                Firefox Add-ons store extension compatible with Firefox Desktop & Mobile.
              </p>
              <div className="space-y-2 pt-1">
                <a
                  href="https://addons.mozilla.org/firefox/addon/laterbox"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl bg-[#171711] text-white font-bold text-xs hover:bg-[#282723] transition-colors"
                >
                  <span>Install from Firefox Add-ons</span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </a>
                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/firefox-extension\.zip/i)?.browser_download_url || '/api/download/laterbox-firefox-extension.zip',
                      'laterbox-firefox-extension.zip'
                    )
                  }
                  className="w-full flex items-center justify-center gap-1.5 py-2 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] text-[#171711] dark:text-[#f4f2ea] text-xs font-semibold cursor-pointer"
                >
                  <Download className="w-3 h-3" />
                  <span>Manual .zip ({formatBytes(findAsset(/firefox-extension\.zip/i)?.size || 41245)})</span>
                </button>
              </div>
            </div>

            <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
              <div className="flex items-center gap-2 font-bold text-[#171711] dark:text-[#f4f2ea]">
                <Puzzle className="w-5 h-5 text-indigo-600" />
                <span>Apple Safari</span>
              </div>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
                Bundled automatically inside the macOS native client for Safari.
              </p>
              <div className="space-y-2 pt-1">
                <Link
                  href="/extension/connect"
                  className="flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl bg-[#171711] text-white font-bold text-xs hover:bg-[#282723] transition-colors"
                >
                  <span>Connect Installed Extension</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
                <button
                  onClick={() =>
                    handleDownload(
                      findAsset(/safari-extension\.zip/i)?.browser_download_url || '/api/download/laterbox-safari-extension.zip',
                      'laterbox-safari-extension.zip'
                    )
                  }
                  className="w-full flex items-center justify-center gap-1.5 py-2 rounded-xl bg-[#ebe7dc] dark:bg-[#282723] text-[#171711] dark:text-[#f4f2ea] text-xs font-semibold cursor-pointer"
                >
                  <Download className="w-3 h-3" />
                  <span>Manual .zip ({formatBytes(findAsset(/safari-extension\.zip/i)?.size || 41219)})</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Previous Releases History Table */}
      <div ref={previousReleasesRef} className="space-y-4 pt-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div>
            <h2 className="text-lg font-bold text-[#171711] dark:text-[#f4f2ea] flex items-center gap-2">
              <Package className="w-4 h-4 text-amber-600" />
              <span>Release History & Direct Assets</span>
            </h2>
            <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">
              Browse previous builds, release changelogs, and binary asset downloads.
            </p>
          </div>

          <div className="flex items-center gap-2">
            <div className="relative">
              <Search className="w-3.5 h-3.5 text-[#6c6b63] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search releases or files..."
                value={releaseSearchQuery}
                onChange={(e) => setReleaseSearchQuery(e.target.value)}
                className="pl-8 pr-3 py-1.5 text-xs rounded-xl bg-[#ebe7dc]/50 dark:bg-[#282723] border border-[#e5e0d3] dark:border-[#2e2d27] text-[#171711] dark:text-[#f4f2ea] placeholder:text-[#6c6b63] focus:outline-hidden focus:border-[#171711] w-48 sm:w-60"
              />
            </div>
          </div>
        </div>

        {/* Release History Tabs */}
        <div className="flex items-center gap-1 border-b border-[#e5e0d3] dark:border-[#2e2d27] pb-2 text-xs">
          {(['all', 'desktop', 'mobile', 'extensions'] as HistoryTab[]).map((tab) => (
            <button
              key={tab}
              onClick={() => setHistoryTab(tab)}
              className={`px-3 py-1 rounded-lg font-bold capitalize transition-colors cursor-pointer ${
                historyTab === tab
                  ? 'bg-[#171711] text-white dark:bg-[#383731]'
                  : 'text-[#6c6b63] dark:text-[#a09e94] hover:text-[#171711] dark:hover:text-[#f4f2ea]'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* Release List Accordion */}
        <div className="space-y-3">
          {loadingReleases ? (
            <div className="p-8 text-center text-xs text-[#6c6b63] dark:text-[#a09e94] flex items-center justify-center gap-2">
              <RefreshCw className="w-4 h-4 animate-spin text-amber-600" />
              <span>Fetching live release assets from GitHub...</span>
            </div>
          ) : filteredReleases.length === 0 ? (
            <div className="p-8 text-center text-xs text-[#6c6b63] dark:text-[#a09e94]">
              No release assets matched your search query.
            </div>
          ) : (
            filteredReleases.map((rel) => {
              const versionClean = rel.tag_name.replace(/^v/, '');
              const isExpanded = expandedVersions.has(versionClean);
              const formattedDate = new Date(rel.published_at).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
              });

              return (
                <div
                  key={rel.tag_name}
                  className="rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs overflow-hidden"
                >
                  <button
                    onClick={() => toggleVersion(versionClean)}
                    className="w-full flex items-center justify-between p-4 text-left hover:bg-[#ebe7dc]/30 dark:hover:bg-[#282723]/30 transition-colors cursor-pointer"
                  >
                    <div className="flex items-center gap-3">
                      <div className="px-2.5 py-1 rounded-lg bg-[#ebe7dc] dark:bg-[#282723] font-mono text-xs font-bold text-[#171711] dark:text-[#f4f2ea]">
                        {rel.tag_name}
                      </div>
                      <div>
                        <div className="text-xs font-bold text-[#171711] dark:text-[#f4f2ea] flex items-center gap-2">
                          <span>{rel.name || rel.tag_name}</span>
                        </div>
                        <div className="text-[11px] text-[#6c6b63] dark:text-[#a09e94] flex items-center gap-2 mt-0.5">
                          <span className="flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            <span>{formattedDate}</span>
                          </span>
                          <span>•</span>
                          <span>{rel.assets.length} binary assets</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2">
                      <span className="text-xs font-semibold text-[#6c6b63] dark:text-[#a09e94]">
                        {isExpanded ? 'Hide Assets' : 'Show Assets'}
                      </span>
                      {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                    </div>
                  </button>

                  {isExpanded && (
                    <div className="p-4 pt-0 border-t border-[#e5e0d3]/50 dark:border-[#2e2d27]/50 space-y-3">
                      {rel.body && (
                        <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] pt-3 leading-relaxed">
                          {rel.body}
                        </p>
                      )}

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-2">
                        {rel.assets.map((asset) => (
                          <div
                            key={asset.name}
                            className="flex items-center justify-between p-2.5 rounded-xl bg-[#ebe7dc]/30 dark:bg-[#171713] border border-[#e5e0d3]/60 dark:border-[#282721] text-xs"
                          >
                            <div className="min-w-0 pr-2">
                              <div className="font-mono font-medium text-[#171711] dark:text-[#f4f2ea] truncate text-xs">
                                {asset.name}
                              </div>
                              <div className="text-[10px] text-[#6c6b63] dark:text-[#a09e94]">
                                {formatBytes(asset.size)}
                              </div>
                            </div>
                            <button
                              onClick={() => handleDownload(asset.browser_download_url, asset.name)}
                              className="px-2.5 py-1 rounded-lg bg-[#171711] text-white hover:bg-[#282723] text-[11px] font-bold flex items-center gap-1 shrink-0 cursor-pointer shadow-2xs"
                            >
                              <Download className="w-3 h-3" />
                              <span>Download</span>
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Android Tester Modal */}
      <AndroidTesterModal
        isOpen={isAndroidModalOpen}
        onClose={() => setIsAndroidModalOpen(false)}
        onDownloadApk={() => handleDownload('/api/download/laterbox-android.apk', 'laterbox-android.apk')}
      />
    </div>
  );
}
