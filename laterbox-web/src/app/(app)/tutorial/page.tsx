'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  Compass,
  Sparkles,
  Command,
  Plus,
  Puzzle,
  Laptop,
  CheckCircle2,
  ExternalLink,
  BookOpen,
  ArrowRight,
  Database,
  ShieldCheck,
  Search,
  Inbox,
  Zap,
  Bookmark,
  Share2,
  Copy,
  Check,
} from 'lucide-react';
import { APP_VERSION } from '@/lib/version';

export default function InAppGuidePage() {
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const copyShortcut = (keyCombination: string, id: string) => {
    navigator.clipboard.writeText(keyCombination);
    setCopiedKey(id);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const keyboardShortcuts = [
    { key: '⌘ K / /', action: 'Global Spotlight Search', desc: 'Search title, content, AI summaries, and tags instantly' },
    { key: '⌘ N', action: 'New Quick Capture', desc: 'Open the in-app quick capture modal from anywhere' },
    { key: '⌥ Space', action: 'Desktop Global Tray', desc: 'Summon LaterBox spotlight without switching windows' },
    { key: 'J / ↓', action: 'Next Item', desc: 'Move focus down your active inbox queue' },
    { key: 'K / ↑', action: 'Previous Item', desc: 'Move focus up your active inbox queue' },
    { key: 'E', action: 'Archive Item', desc: 'Mark current item as read and move to library' },
    { key: 'Backspace', action: 'Delete Item', desc: 'Move item to trash' },
    { key: 'Enter / O', action: 'Open Original URL', desc: 'Launch the source link in a new browser tab' },
    { key: 'Esc', action: 'Close Modal', desc: 'Dismiss active dialog or search overlay' },
  ];

  const captureMethods = [
    {
      icon: <Laptop className="w-5 h-5 text-amber-600" />,
      title: 'Global Desktop Hotkey (⌥Space)',
      badge: 'Desktop App',
      description: 'Press Option+Space anywhere on your Mac or Windows PC to summon a distraction-free spotlight capture bar.',
    },
    {
      icon: <Puzzle className="w-5 h-5 text-blue-600" />,
      title: '1-Click Browser Extension',
      badge: 'Chrome / Firefox / Safari',
      description: 'Click the LaterBox browser button or press Alt+L on any webpage to save articles, videos, or full pages.',
    },
    {
      icon: <Share2 className="w-5 h-5 text-purple-600" />,
      title: 'Native Mobile Share Sheet',
      badge: 'iOS & Android',
      description: 'Tap Share from Safari, Chrome, YouTube, Twitter, or Reddit on mobile and select LaterBox to save in 1 tap.',
    },
    {
      icon: <Plus className="w-5 h-5 text-emerald-600" />,
      title: 'In-App Quick Capture (⌘N)',
      badge: 'Web App',
      description: 'Press ⌘N or click the "+" button in your sidebar to paste links, code snippets, notes, or ideas.',
    },
  ];

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-6 border-b border-[#e5e0d3] dark:border-[#2e2d27]">
        <div>
          <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-[#ebe7dc] dark:bg-[#282723] text-xs font-semibold text-[#6c6b63] dark:text-[#a09e94] mb-2">
            <Compass className="w-3.5 h-3.5 text-amber-600" />
            <span>Interactive Toolkit & Workflow Guide</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-[#171711] dark:text-[#f4f2ea] tracking-tight">
            User Guide & Quickstart
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] dark:text-[#a09e94] mt-1 max-w-xl">
            Master rapid bookmarking, offline SQLite vault sync, and keyboard workflows in LaterBox.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href="/downloads"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold text-white bg-[#171711] dark:bg-[#383731] hover:bg-[#282723] transition-all shadow-xs"
          >
            <Laptop className="w-4 h-4" />
            <span>Download Desktop App</span>
          </Link>
          <a
            href="https://docs.laterbox.dev"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl text-xs sm:text-sm font-semibold text-[#6c6b63] dark:text-[#a09e94] bg-[#ebe7dc]/70 dark:bg-[#282723] hover:text-[#171711] dark:hover:text-[#f4f2ea] transition-colors"
          >
            <span>Full Docs</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </a>
        </div>
      </div>

      {/* 4 Ways to Capture Cards */}
      <div className="space-y-4">
        <h2 className="text-lg font-bold text-[#171711] dark:text-[#f4f2ea] flex items-center gap-2">
          <Zap className="w-4 h-4 text-amber-600" />
          <span>4 Ways to Capture Content</span>
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {captureMethods.map((method, idx) => (
            <div
              key={idx}
              className="p-5 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-3"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-[#ebe7dc]/60 dark:bg-[#282723]">
                    {method.icon}
                  </div>
                  <h3 className="font-bold text-sm text-[#171711] dark:text-[#f4f2ea]">{method.title}</h3>
                </div>
                <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md bg-[#ebe7dc] dark:bg-[#282723] text-[#6c6b63] dark:text-[#a09e94]">
                  {method.badge}
                </span>
              </div>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] leading-relaxed">
                {method.description}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* Keyboard Shortcuts Matrix */}
      <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-5">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-[#171711] text-amber-400">
              <Command className="w-4 h-4" />
            </div>
            <div>
              <h2 className="font-bold text-base text-[#171711] dark:text-[#f4f2ea]">Keyboard Shortcuts</h2>
              <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Blazing fast navigation without touching your mouse</p>
            </div>
          </div>
          <span className="text-xs font-mono px-2 py-1 rounded bg-[#ebe7dc] dark:bg-[#282723] text-[#6c6b63] dark:text-[#a09e94]">
            macOS & Windows
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pt-2">
          {keyboardShortcuts.map((sc, idx) => (
            <div
              key={idx}
              className="flex items-center justify-between p-3 rounded-xl bg-[#ebe7dc]/30 dark:bg-[#171713] border border-[#e5e0d3]/70 dark:border-[#282721] group hover:border-[#d5cfc0] dark:hover:border-[#383731] transition-all"
            >
              <div className="space-y-0.5">
                <div className="text-xs font-bold text-[#171711] dark:text-[#f4f2ea]">{sc.action}</div>
                <div className="text-[11px] text-[#6c6b63] dark:text-[#a09e94]">{sc.desc}</div>
              </div>
              <button
                onClick={() => copyShortcut(sc.key, `sc-${idx}`)}
                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white dark:bg-[#282723] border border-[#e5e0d3] dark:border-[#383731] text-xs font-mono font-bold text-[#171711] dark:text-[#f4f2ea] shadow-2xs hover:bg-[#ebe7dc] transition-colors cursor-pointer"
                title="Copy shortcut"
              >
                <span>{sc.key}</span>
                {copiedKey === `sc-${idx}` ? (
                  <Check className="w-3 h-3 text-emerald-500" />
                ) : (
                  <Copy className="w-3 h-3 opacity-40 group-hover:opacity-100 transition-opacity" />
                )}
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Extension Connector Banner */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-amber-500/10 via-orange-500/5 to-transparent border border-amber-500/20 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="space-y-1">
          <div className="flex items-center gap-2 text-amber-700 dark:text-amber-400 font-bold text-sm">
            <Puzzle className="w-4 h-4" />
            <span>Connect Browser Extension</span>
          </div>
          <p className="text-xs text-[#6c6b63] dark:text-[#a09e94] max-w-lg">
            Already installed the Chrome, Firefox, or Safari extension? Link it to your logged-in LaterBox account in 3 seconds.
          </p>
        </div>
        <Link
          href="/extension/connect"
          className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-xs whitespace-nowrap shadow-xs"
        >
          <span>Open Extension Linker</span>
          <ArrowRight className="w-3.5 h-3.5" />
        </Link>
      </div>

      {/* Local-First SQLite & Sync Overview */}
      <div className="p-6 rounded-2xl bg-white dark:bg-[#1e1e19] border border-[#e5e0d3] dark:border-[#2e2d27] shadow-xs space-y-4">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-emerald-500/10 text-emerald-700 dark:text-emerald-400">
            <Database className="w-4 h-4" />
          </div>
          <div>
            <h2 className="font-bold text-base text-[#171711] dark:text-[#f4f2ea]">Local-First Architecture</h2>
            <p className="text-xs text-[#6c6b63] dark:text-[#a09e94]">Offline SQLite cache + Supabase Edge synchronization</p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2 text-xs">
          <div className="p-3.5 rounded-xl bg-[#ebe7dc]/30 dark:bg-[#171713] space-y-1.5">
            <div className="font-bold text-[#171711] dark:text-[#f4f2ea] flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
              <span>Full Offline Access</span>
            </div>
            <p className="text-[#6c6b63] dark:text-[#a09e94]">
              Read, search, filter, and queue new bookmarks on trains or planes without an internet connection.
            </p>
          </div>

          <div className="p-3.5 rounded-xl bg-[#ebe7dc]/30 dark:bg-[#171713] space-y-1.5">
            <div className="font-bold text-[#171711] dark:text-[#f4f2ea] flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
              <span>Instant Local Search</span>
            </div>
            <p className="text-[#6c6b63] dark:text-[#a09e94]">
              Indexed with SQLite FTS5 for sub-millisecond query results across titles, summaries, and URLs.
            </p>
          </div>

          <div className="p-3.5 rounded-xl bg-[#ebe7dc]/30 dark:bg-[#171713] space-y-1.5">
            <div className="font-bold text-[#171711] dark:text-[#f4f2ea] flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
              <span>Automatic Reconciliation</span>
            </div>
            <p className="text-[#6c6b63] dark:text-[#a09e94]">
              Queued offline mutations automatically replay and merge when connectivity returns.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
