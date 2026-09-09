'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/lib/store/AuthContext';
import {
  Sparkles,
  ArrowRight,
  Download,
  Compass,
  PlayCircle,
  Play,
  Layers,
  Zap,
  ShieldCheck,
  Globe2,
  Smartphone,
  Laptop,
  Puzzle,
  CheckCircle2,
  XCircle,
  Command,
  Search,
  Bookmark,
  FileText,
  BookOpen,
  Video,
  Music,
  Code2,
  Terminal,
  ExternalLink,
  ChevronDown,
  Check,
  FolderHeart,
  Folder,
  Eye,
  Keyboard,
  Clock,
  Palette,
  CornerDownLeft,
  X,
} from 'lucide-react';

export default function LandingPage() {
  const { continueAsGuest } = useAuth();
  const [activeTab, setActiveTab] = useState<'quick-capture' | 'media' | 'reader' | 'collections'>('quick-capture');
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  const toggleFaq = (idx: number) => {
    setOpenFaq(openFaq === idx ? null : idx);
  };

  const proFeatures = [
    {
      icon: <Command className="w-6 h-6 text-[#171711]" />,
      badge: 'Spotlight Speed',
      title: 'Global Quick Capture Hotkey',
      description:
        'Trigger LaterBox from anywhere with ⌥ Space (macOS/Linux) or Ctrl+Alt+Space (Windows). Capture links, selected text, or attachments without interrupting your flow.',
    },
    {
      icon: <Sparkles className="w-6 h-6 text-[#171711]" />,
      badge: 'Autonomous AI',
      title: 'Smart Enrichment & Covers',
      description:
        'Instantly extracts high-res video thumbnails, article titles, favicons, site authors, and schema classification without server delays or fragile scraping.',
    },
    {
      icon: <PlayCircle className="w-6 h-6 text-[#171711]" />,
      badge: 'Distraction-Free',
      title: 'Native Media & Video Player',
      description:
        'Watch YouTube, Vimeo, and Twitch streams or stream Spotify and podcasts directly inside LaterBox with zero ads, tracking cookies, or suggested distractions.',
    },
    {
      icon: <Zap className="w-6 h-6 text-[#171711]" />,
      badge: '0ms Latency',
      title: 'Offline-First SQLite Architecture',
      description:
        'Instantaneous UI updates powered by local SQLite & IndexedDB cache. Everything is available offline and syncs seamlessly in the background with Supabase.',
    },
    {
      icon: <FolderHeart className="w-6 h-6 text-[#171711]" />,
      badge: 'Custom Curation',
      title: 'Collections, Tags & Markdown Notes',
      description:
        'Attach personal markdown notes, highlight takeaways, and organize items into custom color-coded collections, category filters, and starred vaults.',
    },
    {
      icon: <ShieldCheck className="w-6 h-6 text-[#171711]" />,
      badge: '100% Sovereign',
      title: 'Zero Tracking & Complete Export',
      description:
        'Your knowledge vault belongs entirely to you. No tracking pixels, no behavioral profiling, and 1-click full JSON & Markdown export anytime.',
    },
  ];

  const comparisonRows = [
    {
      feature: 'Global System Hotkey (Desktop)',
      laterbox: 'Native ⌥ Space / Ctrl+Alt+Space popup',
      others: 'Requires browser to be open & focused',
      isPro: true,
    },
    {
      feature: 'Embedded Media Player (YouTube/Spotify)',
      laterbox: 'Ad-free embedded player in app',
      others: 'Redirects to distracting external web pages',
      isPro: true,
    },
    {
      feature: 'Offline-First Local Storage',
      laterbox: 'Local SQLite / IndexedDB with 0ms load',
      others: 'Requires active connection for every tap',
      isPro: true,
    },
    {
      feature: 'Distraction-Free Reader & Markdown Notes',
      laterbox: 'Clean typography + instant note taking',
      others: 'Basic link saving with no markdown support',
      isPro: true,
    },
    {
      feature: 'Universal Cross-Platform Ecosystem',
      laterbox: 'macOS, Windows, Linux, iOS, Android & Extensions',
      others: 'Single browser or walled ecosystem lock-in',
      isPro: true,
    },
    {
      feature: 'Data Ownership & Privacy',
      laterbox: 'Zero ads, zero telemetry, full 1-click export',
      others: 'Algorithmic feed suggestions & data monetization',
      isPro: true,
    },
  ];

  const shortcuts = [
    { keys: ['⌥', 'Space'], label: 'Summon Quick Capture (Mac/Linux)' },
    { keys: ['Ctrl', 'Alt', 'Space'], label: 'Summon Quick Capture (Windows)' },
    { keys: ['⌘ / Ctrl', 'Shift', 'S'], label: 'Save Current Browser Tab' },
    { keys: ['⌘ / Ctrl', 'K'], label: 'Global Omnisearch & Filters' },
    { keys: ['⌘ / Ctrl', 'Enter'], label: 'Submit & Save in Quick Capture' },
    { keys: ['Esc'], label: 'Dismiss Quick Capture Window' },
  ];

  const faqs = [
    {
      q: 'How does the offline-first architecture work?',
      a: 'LaterBox writes and queries all items directly to a local, high-speed database (SQLite on Desktop & Mobile, IndexedDB on Web). You get instant (<10ms) responses with no loading spinners. When you are connected, changes sync smoothly to your private Supabase cloud vault.',
    },
    {
      q: 'Can I watch YouTube and listen to podcasts directly inside LaterBox?',
      a: 'Yes! When you save a YouTube video, Vimeo link, or Spotify podcast, LaterBox enriches it with the media metadata and gives you an embedded native player. You can watch or listen directly without ads, sidebar recommendations, or comment distraction.',
    },
    {
      q: 'What browser extensions and platforms are supported?',
      a: 'LaterBox is available across macOS (Apple Silicon & Intel), Windows 10/11, Linux (Debian/Ubuntu/AppImage), iOS (App Store / TestFlight), Android (Google Play Closed Beta & APK), and Browser Extensions for Chrome, Brave, Edge, and Firefox.',
    },
    {
      q: 'Is my data private and can I export it?',
      a: 'Absolutely. We do not track your reading habits, sell advertising, or share data with third parties. You can export your entire collection to structured JSON or Markdown files at any time with a single click.',
    },
    {
      q: 'Can I try LaterBox without creating an account?',
      a: 'Yes! Click "Try Guest Mode" or "Launch Web App" to test drive the complete LaterBox experience locally in your browser sandbox without providing any email or credentials.',
    },
  ];

  return (
    <div className="selection:bg-[#171711] selection:text-white">
      {/* Hero Section */}
      <section className="relative pt-12 sm:pt-20 pb-16 sm:pb-24 overflow-hidden">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center relative z-10">
          {/* Pro Pill Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-extrabold mb-8 shadow-xs">
            <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
            <span>LaterBox Pro • Built for Power Users, Developers & Curators</span>
          </div>

          {/* Main Hero Heading */}
          <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.06] mb-6">
            The save-for-later tool <br />
            <span className="text-[#6c6b63]">designed for speed, media & focus.</span>
          </h1>

          {/* Subheading */}
          <p className="max-w-2xl mx-auto text-base sm:text-xl text-[#6c6b63] leading-relaxed mb-10">
            One shortcut to capture anything from any browser, app, or clipboard. Automatic high-res covers, native video playback, clean distraction-free reading, and 0ms offline search.
          </p>

          {/* Action CTAs */}
          <div className="flex flex-wrap items-center justify-center gap-3.5">
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-7 py-3.5 rounded-full bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-extrabold text-sm sm:text-base shadow-sm transition-all duration-150 group"
            >
              <span>Launch Web App Free</span>
              <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
            </Link>

            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] hover:bg-[#ebe7dc]/50 font-bold text-sm sm:text-base shadow-xs transition-all"
            >
              <Download className="w-4 h-4 text-[#171711]" />
              <span>Download Desktop & Mobile</span>
            </Link>

            <Link
              href="/inbox"
              onClick={() => continueAsGuest()}
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-[#ebe7dc]/70 text-[#171711] hover:bg-[#ebe7dc] font-bold text-sm sm:text-base transition-all"
            >
              <Compass className="w-4 h-4 text-[#6c6b63]" />
              <span>Try Guest Sandbox</span>
            </Link>
          </div>

          {/* ============================================================ */}
          {/* Interactive Pro App Simulator Container */}
          {/* ============================================================ */}
          <div className="mt-14 sm:mt-20 max-w-4xl mx-auto rounded-3xl bg-white border border-[#e4e0d5] shadow-xl overflow-hidden text-left">
            {/* Window Top Bar & Interactive Tab Selector */}
            <div className="flex flex-wrap items-center justify-between gap-3 px-4 sm:px-6 py-3.5 border-b border-[#e4e0d5] bg-[#faf8f2]">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-[#ff5f56]" />
                <div className="w-3 h-3 rounded-full bg-[#ffbd2e]" />
                <div className="w-3 h-3 rounded-full bg-[#27c93f]" />
                <span className="hidden sm:inline-block ml-3 text-xs font-mono text-[#9e9b92]">
                  laterbox.app
                </span>
              </div>

              {/* Tab navigation */}
              <div className="flex items-center gap-1 bg-[#ebe7dc]/70 p-1 rounded-xl text-xs font-bold text-[#6c6b63]">
                <button
                  type="button"
                  onClick={() => setActiveTab('quick-capture')}
                  className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition-all ${
                    activeTab === 'quick-capture'
                      ? 'bg-white text-[#171711] shadow-xs'
                      : 'hover:text-[#171711]'
                  }`}
                >
                  <Zap className="w-3.5 h-3.5" />
                  <span>Quick Capture</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab('media')}
                  className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition-all ${
                    activeTab === 'media'
                      ? 'bg-white text-[#171711] shadow-xs'
                      : 'hover:text-[#171711]'
                  }`}
                >
                  <PlayCircle className="w-3.5 h-3.5" />
                  <span>Media & Video</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab('reader')}
                  className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition-all ${
                    activeTab === 'reader'
                      ? 'bg-white text-[#171711] shadow-xs'
                      : 'hover:text-[#171711]'
                  }`}
                >
                  <BookOpen className="w-3.5 h-3.5" />
                  <span>Reader & Notes</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab('collections')}
                  className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition-all ${
                    activeTab === 'collections'
                      ? 'bg-white text-[#171711] shadow-xs'
                      : 'hover:text-[#171711]'
                  }`}
                >
                  <Folder className="w-3.5 h-3.5" />
                  <span>Collections</span>
                </button>
              </div>
            </div>

            {/* Interactive Preview Canvas */}
            <div className="p-5 sm:p-7 bg-[#fbf9f4] min-h-[320px] flex items-center justify-center">
              {/* TAB 1: QUICK CAPTURE SIMULATOR */}
              {activeTab === 'quick-capture' && (
                <div className="w-full max-w-xl mx-auto rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-lg space-y-4 animate-in fade-in duration-200">
                  <div className="flex items-center justify-between border-b border-[#f0ede4] pb-3">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded-lg bg-[#e6edb0] flex items-center justify-center">
                        <Command className="w-3.5 h-3.5 text-[#171711]" />
                      </div>
                      <span className="text-xs font-black tracking-tight text-[#171711]">
                        LATERBOX QUICK CAPTURE
                      </span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[10px] font-mono text-[#9e9b92]">
                      <span className="px-1.5 py-0.5 rounded bg-[#f0ede4] text-[#171711] font-bold">
                        ⌥ Space
                      </span>
                      <span>anywhere</span>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center gap-2 p-3 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] text-sm text-[#171711] font-mono select-all">
                      <Code2 className="w-4 h-4 text-[#6c6b63] shrink-0" />
                      <span className="truncate">https://github.com/flutter/flutter</span>
                    </div>
                    <div className="flex items-center justify-between pt-1">
                      <div className="flex items-center gap-2 text-xs text-[#6c6b63]">
                        <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
                        <span>Auto-detected: Repository • 165k stars</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-[11px] text-[#9e9b92]">Press ⌘ Enter to save</span>
                        <div className="px-3.5 py-1.5 rounded-full bg-[#171711] text-white text-xs font-bold shadow-2xs">
                          Save Link
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 2: NATIVE MEDIA & VIDEO CARD */}
              {activeTab === 'media' && (
                <div className="w-full max-w-xl mx-auto rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-lg space-y-4 animate-in fade-in duration-200">
                  <div className="relative aspect-video rounded-xl bg-[#171711] overflow-hidden flex items-center justify-center group cursor-pointer">
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
                    <div className="w-12 h-12 rounded-full bg-[#e6edb0] flex items-center justify-center text-[#171711] shadow-lg transition-transform group-hover:scale-110">
                      <Play className="w-5 h-5 fill-current ml-0.5" />
                    </div>
                    <div className="absolute bottom-3 left-3 right-3 text-white">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-red-600 text-white flex items-center gap-1">
                          <Video className="w-3 h-3" />
                          <span>YouTube</span>
                        </span>
                      </div>
                      <span className="text-xs font-bold truncate block">
                        Building Distributed Edge Apps with Cloudflare & Supabase
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-xs text-[#6c6b63]">
                    <div className="flex items-center gap-1.5">
                      <PlayCircle className="w-3.5 h-3.5 text-[#171711]" />
                      <span>Watch in distraction-free player</span>
                    </div>
                    <span className="font-semibold text-[#171711]">No ads • No tracking</span>
                  </div>
                </div>
              )}

              {/* TAB 3: READER & NOTES */}
              {activeTab === 'reader' && (
                <div className="w-full max-w-xl mx-auto rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-lg space-y-3.5 animate-in fade-in duration-200">
                  <div className="flex items-center justify-between border-b border-[#f0ede4] pb-2">
                    <div className="flex items-center gap-2">
                      <BookOpen className="w-4 h-4 text-[#171711]" />
                      <span className="text-xs font-bold text-[#171711]">Distraction-Free Reader</span>
                    </div>
                    <div className="flex items-center gap-1 text-[11px] text-[#6c6b63]">
                      <Clock className="w-3 h-3" />
                      <span>4 min read • 850 words</span>
                    </div>
                  </div>
                  <h4 className="text-base font-black text-[#171711]">
                    The Philosophy of Local-First Software Architecture
                  </h4>
                  <p className="text-xs text-[#6c6b63] leading-relaxed line-clamp-3">
                    Local-first software combines the collaboration advantages of the cloud with the ownership, offline resilience, and blazing responsiveness of traditional desktop applications...
                  </p>
                  <div className="p-3 rounded-xl bg-[#e6edb0]/40 border border-[#d0db84] text-xs text-[#171711] font-medium flex items-start gap-2">
                    <Bookmark className="w-3.5 h-3.5 text-[#171711] shrink-0 mt-0.5" />
                    <span>Personal Note: Review Drift SQLite implementation for cross-platform replication.</span>
                  </div>
                </div>
              )}

              {/* TAB 4: COLLECTIONS & FILTERS */}
              {activeTab === 'collections' && (
                <div className="w-full max-w-xl mx-auto rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-lg space-y-4 animate-in fade-in duration-200">
                  <div className="flex flex-wrap items-center gap-2 text-xs font-bold text-[#6c6b63] pb-1">
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#171711] text-white">
                      <Layers className="w-3 h-3" />
                      <span>All Items (142)</span>
                    </span>
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#ebe7dc] text-[#171711]">
                      <FileText className="w-3 h-3" />
                      <span>Articles (68)</span>
                    </span>
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#ebe7dc] text-[#171711]">
                      <Video className="w-3 h-3" />
                      <span>Videos (42)</span>
                    </span>
                    <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#ebe7dc] text-[#171711]">
                      <Bookmark className="w-3 h-3" />
                      <span>Starred (18)</span>
                    </span>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                    <div className="p-3 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] font-semibold text-[#171711] flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Palette className="w-3.5 h-3.5 text-[#171711]" />
                        <span>Design Inspiration</span>
                      </div>
                      <span className="text-[10px] font-mono text-[#9e9b92]">34 items</span>
                    </div>
                    <div className="p-3 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] font-semibold text-[#171711] flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Terminal className="w-3.5 h-3.5 text-[#171711]" />
                        <span>Startups & Engineering</span>
                      </div>
                      <span className="text-[10px] font-mono text-[#9e9b92]">52 items</span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/* Pro Metrics & Performance Bar */}
      {/* ============================================================ */}
      <section className="py-12 border-y border-[#e4e0d5] bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center divide-y md:divide-y-0 md:divide-x divide-[#e4e0d5]">
            <div className="pt-4 md:pt-0">
              <div className="text-3xl sm:text-4xl font-black text-[#171711] mb-1 font-mono">
                &lt; 10ms
              </div>
              <p className="text-xs sm:text-sm font-semibold text-[#6c6b63]">
                Instant Local SQLite Search
              </p>
            </div>
            <div className="pt-4 md:pt-0">
              <div className="text-3xl sm:text-4xl font-black text-[#171711] mb-1 font-mono">
                100%
              </div>
              <p className="text-xs sm:text-sm font-semibold text-[#6c6b63]">
                Offline-First Resilience
              </p>
            </div>
            <div className="pt-4 md:pt-0">
              <div className="text-3xl sm:text-4xl font-black text-[#171711] mb-1 font-mono">
                7 Platforms
              </div>
              <p className="text-xs sm:text-sm font-semibold text-[#6c6b63]">
                Desktop, Mobile & Extensions
              </p>
            </div>
            <div className="pt-4 md:pt-0">
              <div className="text-3xl sm:text-4xl font-black text-[#171711] mb-1 font-mono">
                0 Trackers
              </div>
              <p className="text-xs sm:text-sm font-semibold text-[#6c6b63]">
                Total Privacy & Sovereignty
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/* Pro Feature Matrix Grid */}
      {/* ============================================================ */}
      <section id="features" className="py-24 max-w-6xl mx-auto px-4 sm:px-6">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#ebe7dc] text-[#171711] text-xs font-bold mb-4">
            <Zap className="w-3.5 h-3.5 text-[#171711]" />
            <span>The Pro Toolkit</span>
          </div>
          <h2 className="text-3xl sm:text-5xl font-black tracking-tight text-[#171711] mb-5">
            Engineered for power users who hate tab overload.
          </h2>
          <p className="text-base sm:text-lg text-[#6c6b63] leading-relaxed">
            Stop losing articles, videos, and documentation in dozens of messy browser tabs. LaterBox gives you a unified, blazing-fast personal knowledge vault.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {proFeatures.map((feat, idx) => (
            <div
              key={idx}
              className="p-7 rounded-3xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-lg transition-all duration-300 flex flex-col justify-between group"
            >
              <div>
                <div className="flex items-center justify-between mb-5">
                  <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] flex items-center justify-center transition-transform group-hover:scale-105">
                    {feat.icon}
                  </div>
                  <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wider bg-[#f7f5ee] border border-[#e4e0d5] text-[#6c6b63]">
                    {feat.badge}
                  </span>
                </div>
                <h3 className="text-lg font-extrabold text-[#171711] mb-2.5">
                  {feat.title}
                </h3>
                <p className="text-sm text-[#6c6b63] leading-relaxed">
                  {feat.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ============================================================ */}
      {/* Why LaterBox vs Others (Comparison Section) */}
      {/* ============================================================ */}
      <section className="py-20 bg-[#ebe7dc]/40 border-y border-[#e4e0d5]">
        <div className="max-w-5xl mx-auto px-4 sm:px-6">
          <div className="text-center max-w-2xl mx-auto mb-14">
            <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711] mb-4">
              Why LaterBox vs traditional bookmarks
            </h2>
            <p className="text-sm sm:text-base text-[#6c6b63]">
              Browser bookmarks and open tabs were built in the 1990s. LaterBox is designed for the modern multimedia web.
            </p>
          </div>

          <div className="rounded-3xl bg-white border border-[#e4e0d5] shadow-md overflow-hidden">
            <div className="grid grid-cols-1 md:grid-cols-12 border-b border-[#e4e0d5] bg-[#faf8f2] p-4 sm:p-5 text-xs font-extrabold text-[#6c6b63] uppercase tracking-wider">
              <div className="md:col-span-4">Capability</div>
              <div className="md:col-span-4 text-[#171711] flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-[#171711]" />
                <span>LaterBox Pro</span>
              </div>
              <div className="md:col-span-4 hidden md:block">Browser Tabs / Standard Tools</div>
            </div>

            <div className="divide-y divide-[#f0ede4]">
              {comparisonRows.map((row, idx) => (
                <div
                  key={idx}
                  className="grid grid-cols-1 md:grid-cols-12 p-4 sm:p-5 text-sm gap-2 md:gap-4 items-center hover:bg-[#faf8f2]/50 transition-colors"
                >
                  <div className="md:col-span-4 font-bold text-[#171711]">
                    {row.feature}
                  </div>
                  <div className="md:col-span-4 flex items-center gap-2 text-[#171711] font-semibold">
                    <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                    <span>{row.laterbox}</span>
                  </div>
                  <div className="md:col-span-4 flex items-center gap-2 text-[#9e9b92] text-xs sm:text-sm">
                    <XCircle className="w-4 h-4 text-rose-500 shrink-0" />
                    <span>{row.others}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/* Keyboard Shortcuts Cheat Sheet */}
      {/* ============================================================ */}
      <section className="py-20 max-w-5xl mx-auto px-4 sm:px-6">
        <div className="text-center max-w-2xl mx-auto mb-14">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-xs font-bold mb-4">
            <Keyboard className="w-3.5 h-3.5" />
            <span>Keyboard-First Workflow</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711] mb-3">
            Navigate at the speed of thought.
          </h2>
          <p className="text-sm sm:text-base text-[#6c6b63]">
            Never take your hands off the keyboard. LaterBox comes pre-configured with lightning-fast desktop and web hotkeys.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {shortcuts.map((sc, idx) => (
            <div
              key={idx}
              className="p-4 rounded-2xl bg-white border border-[#e4e0d5] flex items-center justify-between shadow-xs hover:border-[#171711] transition-all"
            >
              <div className="flex items-center gap-2.5">
                {idx === 0 && <Command className="w-4 h-4 text-[#171711] shrink-0" />}
                {idx === 1 && <Laptop className="w-4 h-4 text-[#171711] shrink-0" />}
                {idx === 2 && <Puzzle className="w-4 h-4 text-[#171711] shrink-0" />}
                {idx === 3 && <Search className="w-4 h-4 text-[#171711] shrink-0" />}
                {idx === 4 && <CornerDownLeft className="w-4 h-4 text-[#171711] shrink-0" />}
                {idx === 5 && <X className="w-4 h-4 text-[#171711] shrink-0" />}
                <span className="text-xs font-medium text-[#6c6b63]">{sc.label}</span>
              </div>
              <div className="flex items-center gap-1 shrink-0">
                {sc.keys.map((k, kIdx) => (
                  <kbd
                    key={kIdx}
                    className="px-2 py-1 rounded bg-[#ebe7dc] border border-[#d8d4c9] text-xs font-mono font-bold text-[#171711] shadow-2xs"
                  >
                    {k}
                  </kbd>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ============================================================ */}
      {/* All-Platform Ecosystem Showcase */}
      {/* ============================================================ */}
      <section className="py-16 border-y border-[#e4e0d5] bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 text-center">
          <p className="text-xs font-bold uppercase tracking-widest text-[#9e9b92] mb-8">
            One Unified Vault Across All Your Devices
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
            <Link
              href="/download"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Laptop className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">macOS & Windows</span>
              <span className="text-xs text-[#6c6b63]">DMG, PKG, EXE & Inno Setup</span>
            </Link>

            <Link
              href="/download"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Smartphone className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">iOS & Android</span>
              <span className="text-xs text-[#6c6b63]">App Store & Google Play Beta</span>
            </Link>

            <Link
              href="/download"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Puzzle className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">Browser Extensions</span>
              <span className="text-xs text-[#6c6b63]">Chrome, Firefox & Safari MV3</span>
            </Link>

            <Link
              href="/inbox"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Globe2 className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">Cloud Web App</span>
              <span className="text-xs text-[#6c6b63]">Zero install, instant access</span>
            </Link>
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/* Pro FAQ Accordion */}
      {/* ============================================================ */}
      <section className="py-20 max-w-4xl mx-auto px-4 sm:px-6">
        <div className="text-center mb-14">
          <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711] mb-3">
            Frequently asked questions
          </h2>
          <p className="text-sm text-[#6c6b63]">
            Everything you need to know about LaterBox features and data architecture.
          </p>
        </div>

        <div className="space-y-3">
          {faqs.map((faq, idx) => (
            <div
              key={idx}
              className="rounded-2xl bg-white border border-[#e4e0d5] overflow-hidden transition-all"
            >
              <button
                type="button"
                onClick={() => toggleFaq(idx)}
                className="w-full p-5 text-left flex items-center justify-between font-bold text-[#171711] text-sm sm:text-base cursor-pointer hover:bg-[#faf8f2]"
              >
                <span>{faq.q}</span>
                <ChevronDown
                  className={`w-4 h-4 text-[#6c6b63] transition-transform duration-200 ${
                    openFaq === idx ? 'rotate-180 text-[#171711]' : ''
                  }`}
                />
              </button>
              {openFaq === idx && (
                <div className="px-5 pb-5 text-sm text-[#6c6b63] leading-relaxed border-t border-[#f0ede4] pt-3">
                  {faq.a}
                </div>
              )}
            </div>
          ))}
        </div>
      </section>

      {/* ============================================================ */}
      {/* High-Converting Bottom Command Center CTA Banner */}
      {/* ============================================================ */}
      <section className="py-16 max-w-5xl mx-auto px-4 sm:px-6">
        <div className="relative rounded-3xl bg-[#171711] p-8 sm:p-14 text-center text-white shadow-2xl overflow-hidden border border-[#2e2d28]">
          <div className="relative z-10 max-w-2xl mx-auto space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 text-xs font-mono text-[#ebe7dc]">
              <span>v1.0 • Ready for Production</span>
            </div>
            <h2 className="text-3xl sm:text-5xl font-black tracking-tight leading-[1.1]">
              Ready to tame your bookmark overload forever?
            </h2>
            <p className="text-sm sm:text-base text-[#c4c0b5]">
              Get started in seconds. Use the web app immediately or download our lightweight native desktop and mobile clients.
            </p>
            <div className="flex flex-wrap items-center justify-center gap-3.5 pt-2">
              <Link
                href="/inbox"
                className="px-8 py-4 rounded-full bg-[#e6edb0] text-[#171711] hover:bg-[#d8e09e] font-extrabold text-sm sm:text-base shadow-sm transition-all cursor-pointer"
              >
                Launch Web App Free
              </Link>
              <Link
                href="/download"
                className="px-8 py-4 rounded-full bg-white/10 hover:bg-white/20 text-white font-bold text-sm sm:text-base transition-all"
              >
                Download All Apps
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
