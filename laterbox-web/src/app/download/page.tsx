'use client';

import React, { useState, useEffect, useRef } from 'react';
import { AppShell } from '@/components/layout/AppShell';
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
} from 'lucide-react';

type PlatformId = 'macos' | 'windows' | 'linux' | 'android' | 'extensions';
type HistoryTab = 'desktop' | 'extensions';

interface ReleaseAsset {
  name: string;
  browser_download_url: string;
  size?: number;
}

interface GitHubRelease {
  id: number;
  tag_name: string;
  name: string;
  published_at: string;
  body?: string;
  assets: ReleaseAsset[];
}

export default function DownloadPage() {
  const [selectedPlatform, setSelectedPlatform] = useState<PlatformId>('macos');
  const [downloadingFile, setDownloadingFile] = useState<string | null>(null);
  const [isAndroidModalOpen, setIsAndroidModalOpen] = useState(false);
  const [copiedCode, setCopiedCode] = useState(false);
  const [historyTab, setHistoryTab] = useState<HistoryTab>('desktop');
  const [expandedVersion, setExpandedVersion] = useState<string | null>('1.0.2');
  const [latestVersionTag, setLatestVersionTag] = useState<string>('1.0.2');
  const [releases, setReleases] = useState<GitHubRelease[]>([]);

  const previousReleasesRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // 1. Fetch current local build version info
    fetch(`/api/version?_t=${Date.now()}`)
      .then((res) => res.json() as Promise<{ version?: string }>)
      .then((data) => {
        if (data.version) {
          setLatestVersionTag(data.version);
        }
      })
      .catch(() => {});

    // 2. Fetch live releases from GitHub API
    fetch('https://api.github.com/repos/Chaste-Djaziri/laterbox/releases')
      .then((res) => {
        if (!res.ok) throw new Error('API unavailable');
        return res.json();
      })
      .then((data: GitHubRelease[]) => {
        if (Array.isArray(data) && data.length > 0) {
          setReleases(data);
          const firstTag = data[0].tag_name.replace(/^v/, '');
          setLatestVersionTag(firstTag);
          setExpandedVersion(firstTag);
        }
      })
      .catch(() => {
        // Fallback release history
        setReleases([
          {
            id: 3,
            tag_name: 'v1.0.2',
            name: 'LaterBox v1.0.2',
            published_at: new Date().toISOString(),
            assets: [
              { name: 'laterbox-macos-apple-silicon.dmg', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-macos-apple-silicon.dmg' },
              { name: 'laterbox-macos-intel.dmg', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-macos-intel.dmg' },
              { name: 'laterbox-macos-installer.pkg', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-macos-installer.pkg' },
              { name: 'laterbox-windows-setup.exe', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-windows-setup.exe' },
              { name: 'laterbox-windows-x64.zip', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-windows-x64.zip' },
              { name: 'laterbox-linux-x64.tar.gz', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-linux-x64.tar.gz' },
              { name: 'laterbox-chrome-extension.zip', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-chrome-extension.zip' },
              { name: 'laterbox-firefox-extension.zip', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/laterbox-firefox-extension.zip' },
            ],
          },
          {
            id: 2,
            tag_name: 'v1.0.1',
            name: 'LaterBox v1.0.1',
            published_at: '2026-08-22T14:00:00Z',
            assets: [
              { name: 'laterbox-macos.dmg', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/download/v1.0.1/laterbox-macos.dmg' },
              { name: 'laterbox-windows-setup.exe', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/download/v1.0.1/laterbox-windows-setup.exe' },
              { name: 'laterbox-linux-x64.tar.gz', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/download/v1.0.1/laterbox-linux-x64.tar.gz' },
            ],
          },
          {
            id: 1,
            tag_name: 'v1.0.0',
            name: 'LaterBox v1.0.0 Initial Release',
            published_at: '2026-08-20T10:00:00Z',
            assets: [
              { name: 'laterbox-macos.dmg', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/download/v1.0.0/laterbox-macos.dmg' },
              { name: 'laterbox-windows-setup.exe', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/download/v1.0.0/laterbox-windows-setup.exe' },
              { name: 'laterbox-linux-x64.tar.gz', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/download/v1.0.0/laterbox-linux-x64.tar.gz' },
            ],
          },
        ]);
      });
  }, []);

  const triggerDownload = (filename: string, directUrl?: string) => {
    setDownloadingFile(filename);
    const downloadUrl = directUrl || `https://github.com/Chaste-Djaziri/laterbox/releases/latest/download/${filename}`;
    window.location.href = downloadUrl;
    setTimeout(() => setDownloadingFile(null), 3500);
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
      ? 'irm https://laterbox.micorp.pro/install.ps1 | iex'
      : 'curl -fsSL https://laterbox.micorp.pro/install.sh | bash';

  return (
    <AppShell>
      <div className="max-w-5xl mx-auto px-6 sm:px-8 py-8 sm:py-10 space-y-12">
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

        {/* Primary Desktop App Download Section */}
        <section className="space-y-4 pt-1">
          <div className="flex items-center gap-2.5">
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
              LaterBox Desktop
            </h2>
            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
              v{latestVersionTag}
            </span>
          </div>

          {/* Dynamic Platform Card */}
          {selectedPlatform === 'macos' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-macos-apple-silicon.dmg')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Apple className="w-4 h-4" />
                  <span>Download for Apple Silicon (.dmg)</span>
                </button>

                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-macos-intel.dmg')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Download for Intel (.dmg)</span>
                </button>

                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-macos-installer.pkg')}
                  className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-full bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>macOS Installer (.pkg)</span>
                </button>

                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-macos-universal.zip')}
                  className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-full bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Universal (.zip)</span>
                </button>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Minimum Requirements</p>
                <p>macOS 12 (Monterey) or later (Apple Silicon M1/M2/M3/M4 or Intel)</p>
              </div>
            </div>
          )}

          {selectedPlatform === 'windows' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-windows-setup.exe')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Laptop className="w-4 h-4" />
                  <span>Download for Windows x64 (.exe)</span>
                </button>

                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-windows-x64.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Portable (.zip)</span>
                </button>
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
                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-linux-x64.tar.gz')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Terminal className="w-4 h-4" />
                  <span>Download for Linux x64 (.tar.gz)</span>
                </button>

                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-linux-x64.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Portable (.zip)</span>
                </button>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Minimum Requirements</p>
                <p>Ubuntu 20.04+, Debian 11+, Fedora 36+, or Arch Linux (x86_64)</p>
              </div>
            </div>
          )}

          {selectedPlatform === 'android' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() => setIsAndroidModalOpen(true)}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Users className="w-4 h-4 text-[#E7FF57]" />
                  <span>Google Play Beta (Join Group)</span>
                </button>

                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-android.apk')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <Smartphone className="w-4 h-4" />
                  <span>Download .apk (Direct)</span>
                </button>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Minimum Requirements</p>
                <p>Android 8.0 (Oreo) or later with system share sheet support</p>
              </div>
            </div>
          )}

          {selectedPlatform === 'extensions' && (
            <div className="space-y-4">
              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-chrome-extension.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
                >
                  <Puzzle className="w-4 h-4" />
                  <span>Download Chrome Extension (.zip)</span>
                </button>

                <button
                  type="button"
                  onClick={() => triggerDownload('laterbox-firefox-extension.zip')}
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
                >
                  <span>Download Firefox Extension (.zip)</span>
                </button>
              </div>

              <div className="text-[11px] text-[#6c6b63]">
                <p className="font-semibold text-[#171711]">Supported Browsers</p>
                <p>Google Chrome, Brave, Microsoft Edge, Opera, Vivaldi, and Firefox 109+</p>
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

        {/* Browser Extensions Card */}
        <section className="space-y-4">
          <div className="flex items-center gap-2.5">
            <h2 className="text-xl sm:text-2xl font-bold text-[#171711]">
              LaterBox for Browsers
            </h2>
            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
              v0.1.1
            </span>
          </div>

          <p className="text-xs sm:text-sm text-[#6c6b63] max-w-2xl">
            Bring LaterBox autonomous saving capabilities directly into Chrome, Brave, Edge, and Firefox.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-1">
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
              <button
                type="button"
                onClick={() => triggerDownload('laterbox-chrome-extension.zip')}
                className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-2xs transition-all cursor-pointer"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Download Chrome Extension (.zip)</span>
              </button>
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
              <button
                type="button"
                onClick={() => triggerDownload('laterbox-firefox-extension.zip')}
                className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Download Firefox Extension (.zip)</span>
              </button>
            </div>
          </div>
        </section>

        {/* Previous Releases History Section (Screenshot 2) */}
        <section ref={previousReleasesRef} className="space-y-6 pt-6">
          <div className="flex items-center gap-6 border-b border-[#e4e0d5] pb-2">
            <button
              onClick={() => setHistoryTab('desktop')}
              className={`text-sm font-bold pb-2 transition-colors relative cursor-pointer ${
                historyTab === 'desktop' ? 'text-[#171711]' : 'text-[#9e9b92] hover:text-[#171711]'
              }`}
            >
              <span>LaterBox Desktop</span>
              {historyTab === 'desktop' && (
                <div className="absolute bottom-[-9px] left-0 right-0 h-0.5 bg-[#171711]" />
              )}
            </button>

            <button
              onClick={() => setHistoryTab('extensions')}
              className={`text-sm font-bold pb-2 transition-colors relative cursor-pointer ${
                historyTab === 'extensions' ? 'text-[#171711]' : 'text-[#9e9b92] hover:text-[#171711]'
              }`}
            >
              <span>Browser Extensions</span>
              {historyTab === 'extensions' && (
                <div className="absolute bottom-[-9px] left-0 right-0 h-0.5 bg-[#171711]" />
              )}
            </button>
          </div>

          {/* Versions Table / Accordion */}
          <div className="divide-y divide-[#e4e0d5]">
            {releases.map((rel) => {
              const versionNum = rel.tag_name.replace(/^v/, '');
              const isExpanded = expandedVersion === versionNum;

              return (
                <div key={rel.tag_name} className="py-4 space-y-4">
                  <div
                    onClick={() => setExpandedVersion(isExpanded ? null : versionNum)}
                    className="flex items-center justify-between cursor-pointer group py-1"
                  >
                    <div className="flex items-center gap-12 sm:gap-20">
                      <span className="text-xs text-[#9e9b92] font-semibold w-16">Version</span>
                      <span className="text-sm font-bold text-[#171711] font-mono">{versionNum}</span>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="text-[11px] text-[#9e9b92] hidden sm:inline">
                        {new Date(rel.published_at).toLocaleDateString()}
                      </span>
                      <div className="p-1 rounded-lg text-[#6c6b63] group-hover:text-[#171711]">
                        {isExpanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                      </div>
                    </div>
                  </div>

                  {/* Expanded Platform Asset Grid */}
                  {isExpanded && (
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 pt-2 pb-2 pl-4 sm:pl-32 animate-in fade-in">
                      {historyTab === 'desktop' ? (
                        <>
                          {/* macOS Assets */}
                          <div className="space-y-2.5">
                            <div className="flex items-center gap-1.5 text-xs font-bold text-[#171711]">
                              <Apple className="w-3.5 h-3.5" />
                              <span>macOS</span>
                            </div>
                            <div className="space-y-1.5">
                              <button
                                onClick={() => triggerDownload(`laterbox-macos-apple-silicon.dmg`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>macOS Apple Silicon (.dmg)</span>
                              </button>
                              <button
                                onClick={() => triggerDownload(`laterbox-macos-intel.dmg`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>macOS Intel (.dmg)</span>
                              </button>
                              <button
                                onClick={() => triggerDownload(`laterbox-macos-installer.pkg`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>macOS Installer (.pkg)</span>
                              </button>
                              <button
                                onClick={() => triggerDownload(`laterbox-macos-universal.zip`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>macOS Universal (.zip)</span>
                              </button>
                            </div>
                          </div>

                          {/* Windows Assets */}
                          <div className="space-y-2.5">
                            <div className="flex items-center gap-1.5 text-xs font-bold text-[#171711]">
                              <Laptop className="w-3.5 h-3.5" />
                              <span>Windows</span>
                            </div>
                            <div className="space-y-1.5">
                              <button
                                onClick={() => triggerDownload(`laterbox-windows-setup.exe`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>Windows x64 (.exe)</span>
                              </button>
                              <button
                                onClick={() => triggerDownload(`laterbox-windows-x64.zip`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>Windows Portable (.zip)</span>
                              </button>
                            </div>
                          </div>

                          {/* Linux Assets */}
                          <div className="space-y-2.5">
                            <div className="flex items-center gap-1.5 text-xs font-bold text-[#171711]">
                              <Terminal className="w-3.5 h-3.5" />
                              <span>Linux</span>
                            </div>
                            <div className="space-y-1.5">
                              <button
                                onClick={() => triggerDownload(`laterbox-linux-x64.tar.gz`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>Linux x64 (.tar.gz)</span>
                              </button>
                              <button
                                onClick={() => triggerDownload(`laterbox-linux-x64.zip`)}
                                className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                              >
                                <Download className="w-3.5 h-3.5 shrink-0" />
                                <span>Linux Portable (.zip)</span>
                              </button>
                            </div>
                          </div>
                        </>
                      ) : (
                        <>
                          {/* Extension Assets */}
                          <div className="space-y-2.5">
                            <div className="flex items-center gap-1.5 text-xs font-bold text-[#171711]">
                              <Puzzle className="w-3.5 h-3.5" />
                              <span>Chrome / Chromium</span>
                            </div>
                            <button
                              onClick={() => triggerDownload(`laterbox-chrome-extension.zip`)}
                              className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                            >
                              <Download className="w-3.5 h-3.5 shrink-0" />
                              <span>Chrome Extension (.zip)</span>
                            </button>
                          </div>

                          <div className="space-y-2.5">
                            <div className="flex items-center gap-1.5 text-xs font-bold text-[#171711]">
                              <Puzzle className="w-3.5 h-3.5" />
                              <span>Mozilla Firefox</span>
                            </div>
                            <button
                              onClick={() => triggerDownload(`laterbox-firefox-extension.zip`)}
                              className="flex items-center gap-1.5 text-xs text-[#6c6b63] hover:text-[#171711] hover:underline cursor-pointer"
                            >
                              <Download className="w-3.5 h-3.5 shrink-0" />
                              <span>Firefox Extension (.zip)</span>
                            </button>
                          </div>
                        </>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </section>
      </div>

      {/* Android Tester Modal */}
      <AndroidTesterModal
        isOpen={isAndroidModalOpen}
        onClose={() => setIsAndroidModalOpen(false)}
        onDownloadApk={() => triggerDownload('laterbox-android.apk')}
      />
    </AppShell>
  );
}
