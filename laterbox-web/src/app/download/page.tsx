'use client';

import React, { useState, useEffect, useRef } from 'react';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { AndroidTesterModal } from '@/components/download/AndroidTesterModal';
import {
  Download,
  Apple,
  Laptop,
  Terminal,
  Puzzle,
  CheckCircle2,
  Users,
  Copy,
  Check,
  ChevronDown,
  ChevronUp,
  ExternalLink,
  Smartphone,
  Sparkles,
  ArrowRight,
  Search,
  Layers,
  FileCode,
} from 'lucide-react';

type PlatformId = 'macos' | 'ios' | 'android' | 'windows' | 'linux' | 'extensions';
type HistoryTab = 'all' | 'desktop' | 'mobile' | 'extensions';

function detectUserPlatform(): PlatformId {
  if (typeof window === 'undefined') return 'macos';
  const ua = window.navigator.userAgent || '';
  const platform = (window.navigator as any).userAgentData?.platform || window.navigator.platform || '';
  const maxTouchPoints = window.navigator.maxTouchPoints || 0;

  // iOS check (iPhone, iPod, iPad, iPad on iOS 13+ desktop UA)
  if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && maxTouchPoints > 1)) {
    return 'ios';
  }

  // Android check
  if (/Android/i.test(ua)) {
    return 'android';
  }

  // Windows check
  if (/Win/i.test(ua) || /Win/i.test(platform)) {
    return 'windows';
  }

  // Linux check (not android)
  if (/Linux/i.test(ua) || /Linux/i.test(platform)) {
    return 'linux';
  }

  // macOS check
  if (/Mac/i.test(ua) || /Mac/i.test(platform)) {
    return 'macos';
  }

  return 'macos';
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

export default function DownloadPage() {
  const [selectedPlatform, setSelectedPlatform] = useState<PlatformId>('macos');
  const [detectedPlatform, setDetectedPlatform] = useState<PlatformId | null>(null);
  const [downloadingFile, setDownloadingFile] = useState<string | null>(null);
  const [isAndroidModalOpen, setIsAndroidModalOpen] = useState(false);
  const [copiedCode, setCopiedCode] = useState(false);
  const [historyTab, setHistoryTab] = useState<HistoryTab>('all');
  const [expandedVersions, setExpandedVersions] = useState<Set<string>>(new Set(['1.0.48', '1.0.44', '1.0.12']));
  const [latestVersionTag, setLatestVersionTag] = useState<string>('1.0.57');
  const [releases, setReleases] = useState<GitHubRelease[]>([]);
  const [loadingReleases, setLoadingReleases] = useState<boolean>(true);
  const [releaseSearchQuery, setReleaseSearchQuery] = useState<string>('');

  const previousReleasesRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // 0. Auto-detect user device and select matching platform tab
    const detected = detectUserPlatform();
    setDetectedPlatform(detected);

    const urlParams = new URLSearchParams(window.location.search);
    const paramPlatform = urlParams.get('platform') as PlatformId | null;
    const hashPlatform = window.location.hash.replace('#', '') as PlatformId;

    const validPlatforms: PlatformId[] = ['macos', 'ios', 'android', 'windows', 'linux', 'extensions'];
    if (paramPlatform && validPlatforms.includes(paramPlatform)) {
      setSelectedPlatform(paramPlatform);
    } else if (hashPlatform && validPlatforms.includes(hashPlatform)) {
      setSelectedPlatform(hashPlatform);
    } else {
      setSelectedPlatform(detected);
    }

    // 1. Fetch current local build version info
    fetch(`/api/version?_t=${Date.now()}`)
      .then((res) => res.json() as Promise<{ version?: string }>)
      .then((data) => {
        if (data.version) {
          setLatestVersionTag(data.version);
        }
      })
      .catch(() => {});

    // 2. Fetch live releases from authenticated internal proxy with robust fallback
    setLoadingReleases(true);
    fetch('/api/releases')
      .then((res) => {
        if (!res.ok) throw new Error('API unavailable');
        return res.json() as Promise<GitHubRelease[]>;
      })
      .then((data) => {
        if (Array.isArray(data) && data.length > 0) {
          setReleases(data);
          const firstTag = data[0].tag_name.replace(/^v/, '');
          setLatestVersionTag(firstTag);
          // Expand first 2 releases by default
          const initialExpanded = new Set<string>();
          data.slice(0, 2).forEach((r) => initialExpanded.add(r.tag_name.replace(/^v/, '')));
          setExpandedVersions(initialExpanded);
        }
      })
      .catch(async () => {
        // Fallback: try fetching directly from public GitHub API
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
          // Both failed, use curated release list
        }

        const fallbackAssets = [
          { name: 'laterbox-macos-apple-silicon.dmg', browser_download_url: '/api/download/laterbox-macos-apple-silicon.dmg', size: 26650283 },
          { name: 'laterbox-macos-intel.dmg', browser_download_url: '/api/download/laterbox-macos-intel.dmg', size: 26650283 },
          { name: 'laterbox-macos-installer.pkg', browser_download_url: '/api/download/laterbox-macos-installer.pkg', size: 23386222 },
          { name: 'laterbox-macos-universal.zip', browser_download_url: '/api/download/laterbox-macos-universal.zip', size: 23408107 },
          { name: 'laterbox-ios.ipa', browser_download_url: '/api/download/laterbox-ios.ipa', size: 25415861 },
          { name: 'laterbox-android-release.apk', browser_download_url: '/api/download/laterbox-android-release.apk', size: 66794291 },
          { name: 'laterbox-android.apk', browser_download_url: '/api/download/laterbox-android.apk', size: 66794291 },
          { name: 'laterbox-windows-setup.exe', browser_download_url: '/api/download/laterbox-windows-setup.exe', size: 12863119 },
          { name: 'laterbox-windows-x64.zip', browser_download_url: '/api/download/laterbox-windows-x64.zip', size: 14988560 },
          { name: 'laterbox-linux-x64.tar.gz', browser_download_url: '/api/download/laterbox-linux-x64.tar.gz', size: 12703419 },
          { name: 'laterbox-linux-x64.zip', browser_download_url: '/api/download/laterbox-linux-x64.zip', size: 12715443 },
          { name: 'laterbox-chrome-extension.zip', browser_download_url: '/api/download/laterbox-chrome-extension.zip', size: 41255 },
          { name: 'laterbox-firefox-extension.zip', browser_download_url: '/api/download/laterbox-firefox-extension.zip', size: 41245 },
          { name: 'laterbox-safari-extension.zip', browser_download_url: '/api/download/laterbox-safari-extension.zip', size: 41219 },
        ];

        setReleases([
          {
            id: 48,
            tag_name: 'v1.0.48',
            name: 'LaterBox v1.0.48',
            body: 'Pro features upgrade, multi-platform sync speedups, and responsive landing improvements.',
            html_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/tag/v1.0.48',
            published_at: new Date(Date.now() - 3600000).toISOString(),
            assets: fallbackAssets,
          },
          {
            id: 44,
            tag_name: 'v1.0.44',
            name: 'LaterBox v1.0.44',
            body: 'macOS quick capture window layer fixes, YouTube metadata thumbnail resolver.',
            html_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/tag/v1.0.44',
            published_at: new Date(Date.now() - 86400000).toISOString(),
            assets: fallbackAssets,
          },
          {
            id: 12,
            tag_name: 'v1.0.12',
            name: 'LaterBox v1.0.12',
            body: 'Full standalone installer packaging for macOS Apple Silicon and Windows x64.',
            html_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/tag/v1.0.12',
            published_at: new Date(Date.now() - 172800000).toISOString(),
            assets: fallbackAssets,
          },
          {
            id: 11,
            tag_name: 'v1.0.11',
            name: 'LaterBox v1.0.11',
            body: 'Chrome and Firefox extension companion manifests and token exchange.',
            html_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/tag/v1.0.11',
            published_at: new Date(Date.now() - 259200000).toISOString(),
            assets: fallbackAssets,
          },
          {
            id: 10,
            tag_name: 'v1.0.10',
            name: 'LaterBox v1.0.10',
            body: 'Initial multi-platform production bundle release.',
            html_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/tag/v1.0.10',
            published_at: new Date(Date.now() - 345600000).toISOString(),
            assets: fallbackAssets,
          },
        ]);
        setExpandedVersions(new Set(['1.0.48', '1.0.44']));
      })
      .finally(() => {
        setLoadingReleases(false);
      });
  }, []);

  const toggleVersion = (versionNum: string) => {
    setExpandedVersions((prev) => {
      const next = new Set(prev);
      if (next.has(versionNum)) {
        next.delete(versionNum);
      } else {
        next.add(versionNum);
      }
      return next;
    });
  };

  const expandAllVersions = () => {
    const all = new Set<string>();
    releases.forEach((r) => all.add(r.tag_name.replace(/^v/, '')));
    setExpandedVersions(all);
  };

  const collapseAllVersions = () => {
    setExpandedVersions(new Set());
  };

  const triggerDownload = (filename: string, directUrl?: string) => {
    setDownloadingFile(filename);
    const downloadUrl = `/api/download/${encodeURIComponent(filename)}`;
    const link = document.createElement('a');
    link.href = downloadUrl;
    link.download = filename;
    link.setAttribute('download', filename);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setTimeout(() => {
      setDownloadingFile(null);
    }, 3500);
  };

  const handleCopyCode = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 2000);
  };

  const scrollToReleases = () => {
    previousReleasesRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const cliSnippet =
    selectedPlatform === 'windows'
      ? 'irm https://laterbox.dev/install.ps1 | iex'
      : 'curl -fsSL https://laterbox.dev/install.sh | bash';

  return (
    <div className="min-h-screen bg-[#f7f5ee] text-[#171711] flex flex-col selection:bg-[#171711] selection:text-white">
      <Header />
      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12 space-y-12 w-full flex-1">
        {/* Header Title Section */}
        <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
          <div>
            <h1 className="text-3xl sm:text-4xl font-extrabold text-[#171711] tracking-tight flex items-center gap-2">
              <span>Download LaterBox</span>
              <span className="w-1.5 h-6 rounded-full bg-gradient-to-b from-[#E7FF57] to-[#171711] inline-block animate-pulse" />
            </h1>
            <p className="text-xs sm:text-sm text-[#6c6b63] font-medium mt-1">
              Native desktop companions, mobile integrations, and 1-click browser extensions.
            </p>
          </div>

          <button
            type="button"
            onClick={scrollToReleases}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] shadow-2xs transition-all cursor-pointer shrink-0 self-start"
          >
            <span>View previous releases</span>
          </button>
        </div>

        {/* Platform Selector Segmented Pills */}
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={() => setSelectedPlatform('macos')}
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
              selectedPlatform === 'macos'
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-white hover:bg-[#ebe7dc] text-[#171711] border border-[#e4e0d5]'
            }`}
          >
            <Apple className="w-4 h-4" />
            <span>macOS</span>
            {detectedPlatform === 'macos' && (
              <span className={`text-[10px] font-black px-1.5 py-0.5 rounded-full ${selectedPlatform === 'macos' ? 'bg-[#E7FF57] text-[#171711]' : 'bg-[#e6edb0] text-[#171711]'}`}>
                Detected
              </span>
            )}
          </button>

          <button
            onClick={() => setSelectedPlatform('ios')}
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
              selectedPlatform === 'ios'
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-white hover:bg-[#ebe7dc] text-[#171711] border border-[#e4e0d5]'
            }`}
          >
            <Apple className="w-4 h-4" />
            <span>iOS</span>
            {detectedPlatform === 'ios' && (
              <span className={`text-[10px] font-black px-1.5 py-0.5 rounded-full ${selectedPlatform === 'ios' ? 'bg-[#E7FF57] text-[#171711]' : 'bg-[#e6edb0] text-[#171711]'}`}>
                Detected
              </span>
            )}
          </button>

          <button
            onClick={() => setSelectedPlatform('android')}
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
              selectedPlatform === 'android'
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-white hover:bg-[#ebe7dc] text-[#171711] border border-[#e4e0d5]'
            }`}
          >
            <Smartphone className="w-4 h-4" />
            <span>Android</span>
            {detectedPlatform === 'android' && (
              <span className={`text-[10px] font-black px-1.5 py-0.5 rounded-full ${selectedPlatform === 'android' ? 'bg-[#E7FF57] text-[#171711]' : 'bg-[#e6edb0] text-[#171711]'}`}>
                Detected
              </span>
            )}
          </button>

          <button
            onClick={() => setSelectedPlatform('windows')}
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
              selectedPlatform === 'windows'
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-white hover:bg-[#ebe7dc] text-[#171711] border border-[#e4e0d5]'
            }`}
          >
            <Laptop className="w-4 h-4" />
            <span>Windows</span>
            {detectedPlatform === 'windows' && (
              <span className={`text-[10px] font-black px-1.5 py-0.5 rounded-full ${selectedPlatform === 'windows' ? 'bg-[#E7FF57] text-[#171711]' : 'bg-[#e6edb0] text-[#171711]'}`}>
                Detected
              </span>
            )}
          </button>

          <button
            onClick={() => setSelectedPlatform('linux')}
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
              selectedPlatform === 'linux'
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-white hover:bg-[#ebe7dc] text-[#171711] border border-[#e4e0d5]'
            }`}
          >
            <Terminal className="w-4 h-4" />
            <span>Linux</span>
            {detectedPlatform === 'linux' && (
              <span className={`text-[10px] font-black px-1.5 py-0.5 rounded-full ${selectedPlatform === 'linux' ? 'bg-[#E7FF57] text-[#171711]' : 'bg-[#e6edb0] text-[#171711]'}`}>
                Detected
              </span>
            )}
          </button>

          <button
            onClick={() => setSelectedPlatform('extensions')}
            className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold transition-all cursor-pointer ${
              selectedPlatform === 'extensions'
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-white hover:bg-[#ebe7dc] text-[#171711] border border-[#e4e0d5]'
            }`}
          >
            <Puzzle className="w-4 h-4" />
            <span>Extensions</span>
          </button>
        </div>

        {/* Download notification banner if triggered */}
        {downloadingFile && (
          <div className="p-4 rounded-2xl bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-bold flex items-center justify-between animate-in fade-in shadow-2xs">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-[#171711]" />
              <span>Download started for {downloadingFile}. Check your browser downloads folder.</span>
            </div>
          </div>
        )}

        {/* Primary Platform Download Section */}
        <section className="space-y-4 pt-1">
          <div className="flex items-center gap-2.5">
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
              {selectedPlatform === 'ios'
                ? 'LaterBox for iOS'
                : selectedPlatform === 'android'
                ? 'LaterBox for Android'
                : selectedPlatform === 'extensions'
                ? 'LaterBox Browser Extensions'
                : 'LaterBox Desktop'}
            </h2>
            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
              v{latestVersionTag}
            </span>
          </div>

          {/* Dynamic Platform Card */}
          {selectedPlatform === 'macos' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <a
                  href="/api/download/laterbox-macos-apple-silicon.dmg"
                  download="laterbox-macos-apple-silicon.dmg"
                  onClick={() => setDownloadingFile('laterbox-macos-apple-silicon.dmg')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Apple className="w-4 h-4" />
                  <span>Download for Apple Silicon (.dmg)</span>
                </a>

                <a
                  href="/api/download/laterbox-macos-intel.dmg"
                  download="laterbox-macos-intel.dmg"
                  onClick={() => setDownloadingFile('laterbox-macos-intel.dmg')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Download for Intel (.dmg)</span>
                </a>

                <a
                  href="/api/download/laterbox-macos-installer.pkg"
                  download="laterbox-macos-installer.pkg"
                  onClick={() => setDownloadingFile('laterbox-macos-installer.pkg')}
                  className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-full bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>macOS Installer (.pkg)</span>
                </a>

                <a
                  href="/api/download/laterbox-macos-universal.zip"
                  download="laterbox-macos-universal.zip"
                  onClick={() => setDownloadingFile('laterbox-macos-universal.zip')}
                  className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-full bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Universal (.zip)</span>
                </a>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Minimum Requirements</p>
                <p>macOS 12 (Monterey) or later (Apple Silicon M1/M2/M3/M4 or Intel)</p>
              </div>
            </div>
          )}

          {selectedPlatform === 'ios' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <a
                  href="/api/download/laterbox-ios.ipa"
                  download="laterbox-ios.ipa"
                  onClick={() => setDownloadingFile('laterbox-ios.ipa')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Apple className="w-4 h-4 text-[#E7FF57]" />
                  <span>Download iOS App (.ipa)</span>
                </a>

                <a
                  href="https://testflight.apple.com/join/Gwk1yArJ"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <ExternalLink className="w-4 h-4 text-[#6c6b63]" />
                  <span>Join TestFlight Beta</span>
                </a>
              </div>

              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] text-xs space-y-2 text-[#6c6b63]">
                <p className="font-bold text-[#171711]">Installing the .ipa on iOS devices:</p>
                <ul className="list-disc pl-5 space-y-1 text-[11px]">
                  <li><strong>Sideloading:</strong> Install directly using AltStore, SideStore, Sideloadly, Scarlet, or TrollStore.</li>
                  <li><strong>Native Share Extension:</strong> LaterBox includes the iOS native Share Sheet extension so you can save links, text, and files directly from Safari and any app.</li>
                  <li><strong>Requires:</strong> iOS 15.0 or later on iPhone or iPad.</li>
                </ul>
              </div>
            </div>
          )}

          {selectedPlatform === 'android' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() => setIsAndroidModalOpen(true)}
                  className="inline-flex items-center gap-2.5 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-extrabold shadow-sm hover:shadow-md transition-all cursor-pointer group"
                >
                  <Smartphone className="w-4 h-4 text-[#E7FF57]" />
                  <span>Google Play Closed Beta (Recommended)</span>
                  <ArrowRight className="w-3.5 h-3.5 text-white/70 group-hover:translate-x-0.5 transition-transform" />
                </button>

                <a
                  href="/api/download/laterbox-android-release.apk"
                  download="laterbox-android-release.apk"
                  onClick={() => setDownloadingFile('laterbox-android-release.apk')}
                  className="inline-flex items-center gap-2 px-5 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <Download className="w-4 h-4 text-[#6c6b63]" />
                  <span>Download Release APK (.apk)</span>
                </a>

                <a
                  href="/api/download/laterbox-android.apk"
                  download="laterbox-android.apk"
                  onClick={() => setDownloadingFile('laterbox-android.apk')}
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-full bg-transparent hover:bg-[#ebe7dc] text-[#6c6b63] text-xs font-medium transition-all cursor-pointer"
                >
                  <span>Standard APK</span>
                </a>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Minimum Requirements</p>
                <p>Android 8.0 (Oreo) or later • Google Play Closed Beta testing group or direct APK sideload</p>
              </div>
            </div>
          )}

          {selectedPlatform === 'windows' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <a
                  href="/api/download/laterbox-windows-setup.exe"
                  download="laterbox-windows-setup.exe"
                  onClick={() => setDownloadingFile('laterbox-windows-setup.exe')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Laptop className="w-4 h-4" />
                  <span>Download for Windows x64 (.exe)</span>
                </a>

                <a
                  href="/api/download/laterbox-windows-x64.zip"
                  download="laterbox-windows-x64.zip"
                  onClick={() => setDownloadingFile('laterbox-windows-x64.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Portable (.zip)</span>
                </a>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Minimum Requirements</p>
                <p>Windows 10 or Windows 11 (64-bit architecture)</p>
              </div>
            </div>
          )}

          {selectedPlatform === 'linux' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <a
                  href="/api/download/laterbox-linux-x64.tar.gz"
                  download="laterbox-linux-x64.tar.gz"
                  onClick={() => setDownloadingFile('laterbox-linux-x64.tar.gz')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Terminal className="w-4 h-4" />
                  <span>Download for Linux x64 (.tar.gz)</span>
                </a>

                <a
                  href="/api/download/laterbox-linux-x64.zip"
                  download="laterbox-linux-x64.zip"
                  onClick={() => setDownloadingFile('laterbox-linux-x64.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Portable (.zip)</span>
                </a>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Minimum Requirements</p>
                <p>Ubuntu 20.04+, Debian 11+, Fedora 36+, or Arch Linux (x86_64)</p>
              </div>
            </div>
          )}

          {selectedPlatform === 'extensions' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <a
                  href="/api/download/laterbox-chrome-extension.zip"
                  download="laterbox-chrome-extension.zip"
                  onClick={() => setDownloadingFile('laterbox-chrome-extension.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Puzzle className="w-4 h-4" />
                  <span>Chrome / Chromium (.zip)</span>
                </a>

                <a
                  href="/api/download/laterbox-firefox-extension.zip"
                  download="laterbox-firefox-extension.zip"
                  onClick={() => setDownloadingFile('laterbox-firefox-extension.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Firefox (.zip)</span>
                </a>

                <a
                  href="/api/download/laterbox-safari-extension.zip"
                  download="laterbox-safari-extension.zip"
                  onClick={() => setDownloadingFile('laterbox-safari-extension.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <Apple className="w-4 h-4" />
                  <span>Safari (.zip)</span>
                </a>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Supported Browsers</p>
                <p>Google Chrome, Brave, Microsoft Edge, Opera, Vivaldi, Mozilla Firefox 109+, and Safari 15+</p>
              </div>
            </div>
          )}
        </section>

        <div className="border-b border-[#e4e0d5]" />

        {/* LaterBox CLI / Quick Script Install Section */}
        <section className="space-y-4">
          <div className="flex items-center gap-2.5">
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
              LaterBox CLI & Quick Scripts
            </h2>
            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
              latest
            </span>
          </div>

          <p className="text-xs sm:text-sm text-[#6c6b63] max-w-2xl">
            Work with LaterBox directly from your terminal. Launch quick capture with a global shortcut and save links or notes instantly without leaving your workflow.
          </p>

          <div className="space-y-2">
            <div className="flex items-center gap-2 text-xs font-bold text-[#171711]">
              {selectedPlatform === 'windows' ? (
                <>
                  <Laptop className="w-3.5 h-3.5" />
                  <span>Windows (PowerShell)</span>
                </>
              ) : (
                <>
                  <Apple className="w-3.5 h-3.5" />
                  <span>macOS & Linux</span>
                </>
              )}
            </div>

            <div className="relative flex items-center justify-between p-3.5 sm:p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] font-mono text-xs text-[#171711]">
              <code className="truncate mr-4">{cliSnippet}</code>
              <button
                type="button"
                onClick={() => handleCopyCode(cliSnippet)}
                className="p-1.5 rounded-lg hover:bg-[#ebe7dc] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer shrink-0"
                title="Copy command"
              >
                {copiedCode ? <Check className="w-4 h-4 text-emerald-600" /> : <Copy className="w-4 h-4" />}
              </button>
            </div>
          </div>
        </section>

        <div className="border-b border-[#e4e0d5]" />

        {/* Browser Extensions Cards Grid */}
        <section className="space-y-4">
          <div className="flex items-center gap-2.5">
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
              LaterBox for Browsers
            </h2>
            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
              v{latestVersionTag}
            </span>
          </div>

          <p className="text-xs sm:text-sm text-[#6c6b63] max-w-2xl">
            Bring LaterBox autonomous saving capabilities directly into Chrome, Brave, Edge, Firefox, and Safari.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-1">
            <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between">
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
              <a
                href="/api/download/laterbox-chrome-extension.zip"
                download="laterbox-chrome-extension.zip"
                onClick={() => setDownloadingFile('laterbox-chrome-extension.zip')}
                className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-2xs transition-all cursor-pointer"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Chrome Extension (.zip)</span>
              </a>
            </div>

            <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between">
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
              <a
                href="/api/download/laterbox-firefox-extension.zip"
                download="laterbox-firefox-extension.zip"
                onClick={() => setDownloadingFile('laterbox-firefox-extension.zip')}
                className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Firefox Extension (.zip)</span>
              </a>
            </div>

            <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-3 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between mb-2">
                  <div className="w-10 h-10 rounded-xl bg-[#e6edb0] flex items-center justify-center">
                    <Apple className="w-5 h-5 text-[#171711]" />
                  </div>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[#171711]">
                    Safari Web Ext
                  </span>
                </div>
                <h3 className="text-base font-bold text-[#171711]">Apple Safari</h3>
                <p className="text-xs text-[#6c6b63] mt-1">
                  Safari Web Extension bundle for macOS and iOS Safari toolbar & sidepanel.
                </p>
              </div>
              <a
                href="/api/download/laterbox-safari-extension.zip"
                download="laterbox-safari-extension.zip"
                onClick={() => setDownloadingFile('laterbox-safari-extension.zip')}
                className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Safari Extension (.zip)</span>
              </a>
            </div>
          </div>
        </section>

        {/* Previous Releases History & All Assets Section */}
        <section ref={previousReleasesRef} className="space-y-6 pt-8 border-t border-[#e4e0d5]">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h2 className="text-2xl font-black text-[#171711] tracking-tight flex items-center gap-2">
                <Layers className="w-5 h-5 text-[#171711]" />
                <span>All Release Assets & History</span>
              </h2>
              <p className="text-xs text-[#6c6b63] mt-1">
                Browse and download all historical builds, package archives, and browser companion extensions.
              </p>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={expandAllVersions}
                className="px-3 py-1.5 rounded-lg bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] transition-all shadow-2xs cursor-pointer"
              >
                Expand All
              </button>
              <button
                type="button"
                onClick={collapseAllVersions}
                className="px-3 py-1.5 rounded-lg bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] transition-all shadow-2xs cursor-pointer"
              >
                Collapse All
              </button>
              <a
                href="https://github.com/Chaste-Djaziri/laterbox/releases"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold transition-all shadow-2xs"
              >
                <span>GitHub Releases</span>
                <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          </div>

          {/* Filter Toolbar & Category Tabs */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#e4e0d5] pb-3">
            <div className="flex flex-wrap items-center gap-4 sm:gap-6">
              <button
                type="button"
                onClick={() => setHistoryTab('all')}
                className={`text-xs sm:text-sm font-bold pb-2 transition-colors relative cursor-pointer ${
                  historyTab === 'all' ? 'text-[#171711]' : 'text-[#9e9b92] hover:text-[#171711]'
                }`}
              >
                <span>All Assets</span>
                {historyTab === 'all' && (
                  <div className="absolute bottom-[-13px] left-0 right-0 h-0.5 bg-[#171711]" />
                )}
              </button>

              <button
                type="button"
                onClick={() => setHistoryTab('desktop')}
                className={`text-xs sm:text-sm font-bold pb-2 transition-colors relative cursor-pointer ${
                  historyTab === 'desktop' ? 'text-[#171711]' : 'text-[#9e9b92] hover:text-[#171711]'
                }`}
              >
                <span>Desktop (macOS, Windows, Linux)</span>
                {historyTab === 'desktop' && (
                  <div className="absolute bottom-[-13px] left-0 right-0 h-0.5 bg-[#171711]" />
                )}
              </button>

              <button
                type="button"
                onClick={() => setHistoryTab('mobile')}
                className={`text-xs sm:text-sm font-bold pb-2 transition-colors relative cursor-pointer ${
                  historyTab === 'mobile' ? 'text-[#171711]' : 'text-[#9e9b92] hover:text-[#171711]'
                }`}
              >
                <span>Mobile (iOS & Android)</span>
                {historyTab === 'mobile' && (
                  <div className="absolute bottom-[-13px] left-0 right-0 h-0.5 bg-[#171711]" />
                )}
              </button>

              <button
                type="button"
                onClick={() => setHistoryTab('extensions')}
                className={`text-xs sm:text-sm font-bold pb-2 transition-colors relative cursor-pointer ${
                  historyTab === 'extensions' ? 'text-[#171711]' : 'text-[#9e9b92] hover:text-[#171711]'
                }`}
              >
                <span>Extensions</span>
                {historyTab === 'extensions' && (
                  <div className="absolute bottom-[-13px] left-0 right-0 h-0.5 bg-[#171711]" />
                )}
              </button>
            </div>

            {/* Quick Search Input */}
            <div className="relative w-full sm:w-64">
              <Search className="w-3.5 h-3.5 text-[#9e9b92] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={releaseSearchQuery}
                onChange={(e) => setReleaseSearchQuery(e.target.value)}
                placeholder="Filter files or versions..."
                className="w-full pl-8 pr-3 py-1.5 rounded-xl bg-white border border-[#e4e0d5] text-xs text-[#171711] placeholder:text-[#9e9b92] focus:outline-none focus:border-[#171711] shadow-2xs"
              />
            </div>
          </div>

          {/* Loading Skeleton */}
          {loadingReleases && (
            <div className="space-y-4 py-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="p-5 rounded-2xl bg-white border border-[#e4e0d5] animate-pulse space-y-3">
                  <div className="h-4 bg-[#ebe7dc] rounded w-1/3" />
                  <div className="h-8 bg-[#f7f5ee] rounded w-full" />
                </div>
              ))}
            </div>
          )}

          {/* Empty State */}
          {!loadingReleases && releases.length === 0 && (
            <div className="p-8 rounded-3xl bg-white border border-[#e4e0d5] text-center space-y-3">
              <p className="text-sm font-bold text-[#171711]">No releases loaded</p>
              <p className="text-xs text-[#6c6b63]">You can view and download all releases directly on GitHub.</p>
              <a
                href="https://github.com/Chaste-Djaziri/laterbox/releases"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#171711] text-white text-xs font-bold"
              >
                <span>Open GitHub Releases</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          )}

          {/* Versions List */}
          {!loadingReleases && releases.length > 0 && (
            <div className="space-y-4">
              {releases.map((rel, idx) => {
                const versionNum = rel.tag_name.replace(/^v/, '');
                const isExpanded = expandedVersions.has(versionNum);

                const filteredAssets = rel.assets.filter((asset) => {
                  // Tab category filter
                  let matchesTab = true;
                  if (historyTab === 'desktop') {
                    matchesTab =
                      asset.name.includes('macos') ||
                      asset.name.includes('windows') ||
                      asset.name.includes('linux');
                  } else if (historyTab === 'mobile') {
                    matchesTab = asset.name.includes('ios') || asset.name.includes('android');
                  } else if (historyTab === 'extensions') {
                    matchesTab = asset.name.includes('extension');
                  }

                  // Search query filter
                  let matchesQuery = true;
                  if (releaseSearchQuery.trim()) {
                    const q = releaseSearchQuery.toLowerCase();
                    matchesQuery =
                      asset.name.toLowerCase().includes(q) ||
                      versionNum.toLowerCase().includes(q) ||
                      Boolean(rel.name && rel.name.toLowerCase().includes(q));
                  }

                  return matchesTab && matchesQuery;
                });

                // If search query is active and nothing matches this release, hide it
                if (releaseSearchQuery.trim() && filteredAssets.length === 0) {
                  return null;
                }

                return (
                  <div
                    key={rel.tag_name}
                    className="rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] overflow-hidden shadow-2xs transition-all hover:border-[#cfdb84]"
                  >
                    {/* Header Row */}
                    <div
                      onClick={() => toggleVersion(versionNum)}
                      className="p-4 sm:p-5 flex items-center justify-between cursor-pointer group bg-white hover:bg-[#fbf9f4] transition-colors select-none"
                    >
                      <div className="flex flex-wrap items-center gap-3 sm:gap-4">
                        <div className="flex items-center gap-2">
                          <span className="px-2.5 py-1 rounded-lg bg-[#171711] text-white text-xs font-mono font-bold">
                            v{versionNum}
                          </span>
                          {idx === 0 && (
                            <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
                              Latest Release
                            </span>
                          )}
                        </div>

                        <span className="text-xs text-[#9e9b92] font-semibold hidden sm:inline">
                          {new Date(rel.published_at).toLocaleDateString(undefined, {
                            year: 'numeric',
                            month: 'short',
                            day: 'numeric',
                          })}
                        </span>

                        <span className="text-[11px] text-[#6c6b63] font-medium">
                          {filteredAssets.length} asset{filteredAssets.length === 1 ? '' : 's'}
                        </span>
                      </div>

                      <div className="flex items-center gap-3">
                        <a
                          href={rel.html_url || `https://github.com/Chaste-Djaziri/laterbox/releases/tag/${rel.tag_name}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(e) => e.stopPropagation()}
                          className="hidden sm:inline-flex items-center gap-1 text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] px-2.5 py-1 rounded-lg hover:bg-[#ebe7dc] transition-all"
                        >
                          <span>GitHub Release</span>
                          <ExternalLink className="w-3 h-3" />
                        </a>

                        <div className="p-1.5 rounded-xl bg-[#f7f5ee] group-hover:bg-[#ebe7dc] text-[#171711] transition-colors">
                          {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                        </div>
                      </div>
                    </div>

                    {/* Expanded Content */}
                    {isExpanded && (
                      <div className="p-4 sm:p-5 pt-0 border-t border-[#f0ede4] space-y-4 animate-in fade-in duration-150">
                        {/* Release Notes Preview */}
                        {rel.body && (
                          <div className="p-3.5 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] text-xs text-[#6c6b63] leading-relaxed">
                            <span className="font-bold text-[#171711] block mb-1">Release Highlights:</span>
                            <p className="line-clamp-3">{rel.body}</p>
                          </div>
                        )}

                        {/* Assets Grid */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2.5">
                          {filteredAssets.map((asset) => {
                            const sizeFormatted = asset.size
                              ? asset.size > 1024 * 1024
                                ? `${(asset.size / (1024 * 1024)).toFixed(1)} MB`
                                : `${(asset.size / 1024).toFixed(1)} KB`
                              : undefined;

                            // Select matching icon
                            let AssetIcon = Download;
                            if (asset.name.includes('macos') || asset.name.includes('apple') || asset.name.includes('.dmg') || asset.name.includes('.pkg')) {
                              AssetIcon = Apple;
                            } else if (asset.name.includes('windows') || asset.name.includes('.exe')) {
                              AssetIcon = Laptop;
                            } else if (asset.name.includes('linux') || asset.name.includes('.tar.gz')) {
                              AssetIcon = Terminal;
                            } else if (asset.name.includes('ios') || asset.name.includes('android') || asset.name.includes('.apk') || asset.name.includes('.ipa') || asset.name.includes('.aab')) {
                              AssetIcon = Smartphone;
                            } else if (asset.name.includes('extension')) {
                              AssetIcon = Puzzle;
                            }

                            return (
                              <a
                                key={asset.name}
                                href={asset.browser_download_url}
                                download={asset.name}
                                onClick={() => setDownloadingFile(asset.name)}
                                className="flex items-center justify-between p-3 rounded-2xl bg-[#faf8f2] hover:bg-[#f2efe4] border border-[#e4e0d5] hover:border-[#171711] transition-all group/item shadow-2xs text-left cursor-pointer"
                              >
                                <div className="flex items-center gap-2.5 min-w-0 pr-2">
                                  <div className="p-2 rounded-xl bg-white border border-[#e4e0d5] group-hover/item:bg-[#e6edb0] transition-colors shrink-0">
                                    <AssetIcon className="w-3.5 h-3.5 text-[#171711]" />
                                  </div>
                                  <div className="truncate">
                                    <p className="text-xs font-bold text-[#171711] font-mono truncate">
                                      {asset.name}
                                    </p>
                                    {sizeFormatted && (
                                      <span className="text-[10px] text-[#9e9b92] font-mono">
                                        {sizeFormatted}
                                      </span>
                                    )}
                                  </div>
                                </div>
                                <span className="px-2 py-1 rounded-lg bg-white border border-[#e4e0d5] text-[10px] font-bold text-[#171711] group-hover/item:bg-[#171711] group-hover/item:text-white transition-colors shrink-0 font-mono">
                                  Download
                                </span>
                              </a>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </section>
      </main>

      {/* Android Tester Modal */}
      <AndroidTesterModal
        isOpen={isAndroidModalOpen}
        onClose={() => setIsAndroidModalOpen(false)}
        onDownloadApk={() => triggerDownload('laterbox-android.apk')}
      />

      <Footer />
    </div>
  );
}
