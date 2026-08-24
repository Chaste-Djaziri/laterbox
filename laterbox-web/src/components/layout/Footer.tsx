'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import {
  Download,
  Laptop,
  Smartphone,
  Puzzle,
  Globe2,
  Sparkles,
  ShieldCheck,
  Terminal,
  ExternalLink,
  Zap,
  ArrowUpRight,
  BookOpen,
  Keyboard,
  Layers,
  FileText,
  Lock,
  Activity,
} from 'lucide-react';
import { APP_VERSION } from '@/lib/version';

export function Footer() {
  const currentYear = new Date().getFullYear();
  const [systemStatus, setSystemStatus] = useState<{
    status: 'operational' | 'degraded' | 'outage';
    label: string;
    indicator: 'emerald' | 'amber' | 'rose';
    statusPageUrl: string;
  }>({
    status: 'operational',
    label: 'All Systems Operational',
    indicator: 'emerald',
    statusPageUrl: 'https://status.laterbox.dev',
  });

  useEffect(() => {
    let isMounted = true;
    fetch('/api/system-status')
      .then(async (res) => {
        if (!res.ok) return null;
        const data = (await res.json()) as {
          status?: 'operational' | 'degraded' | 'outage';
          label?: string;
          indicator?: 'emerald' | 'amber' | 'rose';
          statusPageUrl?: string;
        };
        return data;
      })
      .then((data) => {
        if (isMounted && data?.label) {
          setSystemStatus({
            status: data.status || 'operational',
            label: data.label || 'All Systems Operational',
            indicator: data.indicator || 'emerald',
            statusPageUrl: data.statusPageUrl || 'https://status.laterbox.dev',
          });
        }
      })
      .catch(() => {
        // Fallback default remains operational
      });

    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <footer className="border-t border-[#e4e0d5] bg-[#faf8f2] text-xs text-[#6c6b63] mt-auto">
      {/* Main Top Footer Grid */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 sm:py-20">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-10 lg:gap-8">
          {/* Brand Column (Spans 2 columns on large screens) */}
          <div className="lg:col-span-2 space-y-5">
            <Link href="/" className="flex items-center gap-3 group">
              <div className="w-9 h-9 relative rounded-xl overflow-hidden bg-[#e6edb0] p-1.5 shrink-0 shadow-2xs transition-transform group-hover:scale-105">
                <Image
                  src="/branding/laterbox-icon.png"
                  alt="laterbox"
                  fill
                  sizes="36px"
                  className="object-contain p-0.5"
                />
              </div>
              <span className="text-xl font-black tracking-tight text-[#171711]">
                laterbox
              </span>
            </Link>

            <p className="text-sm text-[#6c6b63] leading-relaxed max-w-sm">
              The high-speed, save-for-later personal knowledge vault. Capture links, articles, and media from any device with zero friction, instant offline access, and automatic AI enrichment.
            </p>

            {/* System Status & Version Pill */}
            <div className="flex flex-wrap items-center gap-3 pt-2">
              <a
                href={systemStatus.statusPageUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white border border-[#e4e0d5] text-[11px] font-semibold text-[#171711] shadow-2xs hover:border-[#171711] transition-all group cursor-pointer"
                title="View Live Status on Better Stack (status.laterbox.dev)"
              >
                <span
                  className={`w-2 h-2 rounded-full animate-pulse ${
                    systemStatus.indicator === 'rose'
                      ? 'bg-rose-500'
                      : systemStatus.indicator === 'amber'
                      ? 'bg-amber-500'
                      : 'bg-emerald-500'
                  }`}
                />
                <span>{systemStatus.label}</span>
                <ArrowUpRight className="w-3 h-3 text-[#9e9b92] group-hover:text-[#171711] transition-colors" />
              </a>
              <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#ebe7dc] text-[11px] font-mono font-bold text-[#171711]">
                <span>v{APP_VERSION}</span>
              </div>
            </div>

            {/* Community Links */}
            <div className="flex items-center gap-3 pt-2">
              <a
                href="https://github.com/Chaste-Djaziri/laterbox"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white border border-[#e4e0d5] hover:border-[#171711] hover:text-[#171711] text-[#6c6b63] font-semibold transition-all shadow-2xs"
              >
                <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                  <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
                </svg>
                <span>GitHub</span>
                <ArrowUpRight className="w-3 h-3 text-[#9e9b92]" />
              </a>
              <a
                href="https://groups.google.com/g/laterbox-testers"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white border border-[#e4e0d5] hover:border-[#171711] hover:text-[#171711] text-[#6c6b63] font-semibold transition-all shadow-2xs"
              >
                <Smartphone className="w-3.5 h-3.5" />
                <span>Android Beta</span>
                <ArrowUpRight className="w-3 h-3 text-[#9e9b92]" />
              </a>
            </div>
          </div>

          {/* Column 1: Product */}
          <div className="space-y-4">
            <p className="text-xs font-bold uppercase tracking-wider text-[#171711]">
              Product
            </p>
            <ul className="space-y-2.5">
              <li>
                <Link
                  href="/inbox"
                  className="hover:text-[#171711] transition-colors flex items-center gap-1.5"
                >
                  <span>Launch Web App</span>
                  <span className="px-1.5 py-0.2 rounded bg-[#e6edb0] text-[#171711] text-[9px] font-bold">
                    Free
                  </span>
                </Link>
              </li>
              <li>
                <Link
                  href="/#features"
                  className="hover:text-[#171711] transition-colors"
                >
                  Pro Toolkit
                </Link>
              </li>
              <li>
                <Link
                  href="/#how-it-works"
                  className="hover:text-[#171711] transition-colors"
                >
                  How It Works
                </Link>
              </li>
              <li>
                <Link
                  href="/guide"
                  className="hover:text-[#171711] transition-colors"
                >
                  Spotlight Hotkeys
                </Link>
              </li>
              <li>
                <Link
                  href="/tutorial"
                  className="hover:text-[#171711] transition-colors"
                >
                  Interactive Tutorial
                </Link>
              </li>
              <li>
                <Link
                  href="/inbox"
                  className="hover:text-[#171711] transition-colors"
                >
                  Guest Sandbox
                </Link>
              </li>
            </ul>
          </div>

          {/* Column 2: Platforms & Downloads */}
          <div className="space-y-4">
            <p className="text-xs font-bold uppercase tracking-wider text-[#171711]">
              Downloads
            </p>
            <ul className="space-y-2.5">
              <li>
                <Link
                  href="/download?platform=macos"
                  className="hover:text-[#171711] transition-colors flex items-center justify-between"
                >
                  <span>macOS (DMG / PKG)</span>
                </Link>
              </li>
              <li>
                <Link
                  href="/download?platform=windows"
                  className="hover:text-[#171711] transition-colors"
                >
                  Windows (Inno Setup)
                </Link>
              </li>
              <li>
                <Link
                  href="/download?platform=linux"
                  className="hover:text-[#171711] transition-colors"
                >
                  Linux (.tar.gz / .zip)
                </Link>
              </li>
              <li>
                <Link
                  href="/download?platform=ios"
                  className="hover:text-[#171711] transition-colors"
                >
                  iOS (TestFlight)
                </Link>
              </li>
              <li>
                <Link
                  href="/download?platform=android"
                  className="hover:text-[#171711] transition-colors"
                >
                  Android (Google Play)
                </Link>
              </li>
              <li>
                <Link
                  href="/download?platform=extensions"
                  className="hover:text-[#171711] transition-colors"
                >
                  Chrome / Firefox Extension
                </Link>
              </li>
            </ul>
          </div>

          {/* Column 3: Developers & CLI */}
          <div className="space-y-4">
            <p className="text-xs font-bold uppercase tracking-wider text-[#171711]">
              Developers
            </p>
            <ul className="space-y-2.5">
              <li>
                <a
                  href="/install.sh"
                  target="_blank"
                  className="hover:text-[#171711] transition-colors flex items-center gap-1.5"
                >
                  <Terminal className="w-3.5 h-3.5 text-[#171711]" />
                  <span>install.sh (Mac/Linux)</span>
                </a>
              </li>
              <li>
                <a
                  href="/install.ps1"
                  target="_blank"
                  className="hover:text-[#171711] transition-colors flex items-center gap-1.5"
                >
                  <Terminal className="w-3.5 h-3.5 text-[#171711]" />
                  <span>install.ps1 (Windows)</span>
                </a>
              </li>
              <li>
                <Link
                  href="/extension/connect"
                  className="hover:text-[#171711] transition-colors"
                >
                  Token Key Connect
                </Link>
              </li>
              <li>
                <a
                  href="https://github.com/Chaste-Djaziri/laterbox/releases"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-[#171711] transition-colors flex items-center gap-1"
                >
                  <span>GitHub Releases</span>
                  <ArrowUpRight className="w-3 h-3 text-[#9e9b92]" />
                </a>
              </li>
              <li>
                <a
                  href="https://status.laterbox.dev"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="hover:text-[#171711] transition-colors flex items-center gap-1.5"
                >
                  <Activity className="w-3.5 h-3.5 text-emerald-600" />
                  <span>Status (status.laterbox.dev)</span>
                  <ArrowUpRight className="w-3 h-3 text-[#9e9b92]" />
                </a>
              </li>
              <li>
                <Link
                  href="/docs"
                  className="hover:text-[#171711] transition-colors flex items-center gap-1.5"
                >
                  <BookOpen className="w-3.5 h-3.5 text-[#171711]" />
                  <span>Docs (docs.laterbox.dev)</span>
                </Link>
              </li>
              <li>
                <Link
                  href="/docs/system-architecture"
                  className="hover:text-[#171711] transition-colors"
                >
                  System Architecture
                </Link>
              </li>
            </ul>
          </div>

          {/* Column 4: Legal & Privacy */}
          <div className="space-y-4">
            <p className="text-xs font-bold uppercase tracking-wider text-[#171711]">
              Privacy & Legal
            </p>
            <ul className="space-y-2.5">
              <li>
                <Link
                  href="/privacy"
                  className="hover:text-[#171711] transition-colors flex items-center gap-1.5"
                >
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                  <span>Privacy Policy</span>
                </Link>
              </li>
              <li>
                <Link
                  href="/terms"
                  className="hover:text-[#171711] transition-colors"
                >
                  Terms of Service
                </Link>
              </li>
              <li>
                <span className="text-[#6c6b63] flex items-center gap-1">
                  <Lock className="w-3 h-3 text-[#171711]" />
                  <span>Zero Data Tracking</span>
                </span>
              </li>
              <li>
                <span className="text-[#6c6b63]">
                  Offline-First Local Vault
                </span>
              </li>
              <li>
                <span className="text-[#6c6b63]">
                  1-Click JSON/MD Export
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      {/* Bottom Sub-Footer Bar */}
      <div className="border-t border-[#e4e0d5] bg-[#f7f5ee] py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 text-[#6c6b63]">
            <div className="w-4 h-4 relative rounded bg-[#e6edb0] p-0.5 shrink-0">
              <Image
                src="/branding/laterbox-icon.png"
                alt="laterbox"
                fill
                sizes="16px"
                className="object-contain"
              />
            </div>
            <span className="font-extrabold text-[#171711]">laterbox</span>
            <span className="text-[#9e9b92]">•</span>
            <span>© {currentYear} laterbox. Engineered for speed, privacy & focus.</span>
          </div>

          <div className="flex items-center gap-6 text-[11px] font-semibold text-[#6c6b63]">
            <a
              href="https://status.laterbox.dev"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-[#171711] transition-colors flex items-center gap-1 font-bold text-emerald-700"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              <span>Status</span>
              <ArrowUpRight className="w-2.5 h-2.5 text-[#9e9b92]" />
            </a>
            <Link href="/privacy" className="hover:text-[#171711] transition-colors">
              Privacy
            </Link>
            <Link href="/terms" className="hover:text-[#171711] transition-colors">
              Terms
            </Link>
            <Link href="/docs" className="hover:text-[#171711] transition-colors">
              Documentation
            </Link>
            <Link href="/download" className="hover:text-[#171711] transition-colors">
              All Platforms
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
