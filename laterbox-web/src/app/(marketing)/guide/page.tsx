'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import {
  Compass,
  ArrowRight,
  Puzzle,
  Keyboard,
  FolderPlus,
  StickyNote,
  Zap,
  Download,
  Search,
  Sparkles,
  Smartphone,
  Laptop,
  Globe2,
  ShieldCheck,
  PlayCircle,
  CheckCircle2,
  HelpCircle,
  ChevronDown,
  Layers,
  Share2,
  ExternalLink,
  BookOpen,
  Clock,
  CalendarDays,
  Archive,
  Inbox,
  FileText,
  Music2,
  RotateCcw,
  Check,
  Command,
} from 'lucide-react';

export default function GuidePage() {
  const [activeTab, setActiveTab] = useState<'workflow' | 'formats' | 'shortcuts' | 'platforms' | 'faq'>('workflow');
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const workflowSteps = [
    {
      step: '01',
      title: 'Drop it now (Universal Quick Capture)',
      badge: 'Zero Friction',
      desc: 'Capture links, design files, PDF documents, YouTube videos, Spotify music, or quick thoughts the millisecond they cross your mind. Use the global shortcut, browser extension, or drag & drop.',
      icon: <Zap className="w-6 h-6 text-[#171711]" />,
      features: [
        'Web & Mac Shortcut: Control + Option + L (⌃⌥L)',
        '1-Click Browser Extension (Chrome, Firefox, Safari)',
        'Native iOS & Android System Share Sheet',
        'Direct Drag & Drop Quick Drop Zone on Home Dashboard',
      ],
    },
    {
      step: '02',
      title: 'Choose when it should return',
      badge: 'Intentional Scheduling',
      desc: 'Never let saved items turn into an overwhelming, endless graveyard. Choose exactly when you want to deal with it: Later Today, Tomorrow morning, This Weekend, or the Someday Vault.',
      icon: <Clock className="w-6 h-6 text-[#171711]" />,
      features: [
        'One-Click Schedule Presets (Later Today, Tomorrow, Weekend)',
        'Someday Vault for zero-deadline reading & inspiration',
        'Custom Date & Time Selector for precise deadlines',
        'Auto-tags and metadata extraction for effortless context',
      ],
    },
    {
      step: '03',
      title: 'Forget about it (Out of Sight, Out of Mind)',
      badge: 'Mental Clarity',
      desc: 'Deferred items disappear from your daily view and are stored 100% locally in your private SQLite core. Close your browser tabs without fear of losing anything or cluttering your head.',
      icon: <ShieldCheck className="w-6 h-6 text-[#171711]" />,
      features: [
        '100% Offline-First SQLite & Local Vault Storage',
        'Zero Browser Tab Clutter & Zero Cognitive Drag',
        'Works completely offline without mandatory accounts',
        'Export your entire library as JSON anytime in Settings',
      ],
    },
    {
      step: '04',
      title: 'It comes back when you are ready',
      badge: 'Calm Execution',
      desc: 'Right on schedule, items return into Today and Waiting For You. Open the actual file or URL with native actions, write notes, complete the task, or snooze it with one click.',
      icon: <RotateCcw className="w-6 h-6 text-[#171711]" />,
      features: [
        'Resurfaces in Today and Waiting For You dashboard timeline',
        'Native Launch Actions for files, YouTube links, and Spotify tracks',
        'Rich multi-platform visual previews (Photoshop, PDF, Video, Audio)',
        'Quick 1-Click Snooze presets if you need more time',
      ],
    },
  ];

  const formatCards = [
    {
      type: 'Design Files',
      badge: '• Design File',
      tagColor: 'bg-[#001e36] text-[#31a8ff]',
      brand: 'Adobe Photoshop / Figma',
      desc: 'Vibrant artwork canvas with Adobe Ps squircle, file size indicators, and one-click direct application opening.',
      example: 'ClientLandingPage_v3.psd',
      details: '14.2 MB • Design Asset',
      tags: ['#design', '#ui', '#inspiration'],
    },
    {
      type: 'PDF Documents',
      badge: '• PDF Document',
      tagColor: 'bg-red-100 text-red-600',
      brand: 'Adobe Acrobat / Document Sheet',
      desc: 'Simulated document preview with page lines, red PDF squircle, page count, and interactive in-app reader viewer.',
      example: 'Q3_Financial_Review.pdf',
      details: '8 Pages • Corporate Report',
      tags: ['#feedback', '#product', '#finance'],
    },
    {
      type: 'Video Links',
      badge: '▶ Video',
      tagColor: 'bg-red-50 text-red-600',
      brand: 'YouTube / Vimeo',
      desc: 'High-definition thumbnail cover art with play overlay, duration badge, domain pill, and distraction-free viewing.',
      example: 'Distributed Edge Computing Architecture',
      details: '24 min • youtube.com',
      tags: ['#video', '#engineering', '#tech'],
    },
    {
      type: 'Audio & Music',
      badge: '♪ Music',
      tagColor: 'bg-emerald-50 text-emerald-700',
      brand: 'Spotify / Apple Podcasts',
      desc: 'Album artwork canvas with floating circular play button, artist and track info, and direct Spotify integration.',
      example: 'Good Days — SZA (SOS)',
      details: 'Single • spotify.com',
      tags: ['#music', '#chill', '#focus'],
    },
    {
      type: 'Handwritten Notes',
      badge: '• Note',
      tagColor: 'bg-[#ebe7dc] text-[#171711]',
      brand: 'Private Vault Note',
      desc: 'Paper-textured note squircle, clean bullet formatting, and interactive markdown note editor with offline persistence.',
      example: 'Ideas for Weekend Hackathon Project',
      details: 'Personal Thought • 3 min read',
      tags: ['#ideas', '#notes', '#sideproject'],
    },
    {
      type: 'Curated Articles',
      badge: 'Article',
      tagColor: 'bg-[#ebe7dc] text-[#6c6b63]',
      brand: 'Notion / Web Publications',
      desc: 'Brand favicon, reading time estimation, author attribution, and clean reader mode without ads or cookie popups.',
      example: 'The Power of a Focused Life',
      details: 'Notion Publication • 7 min read',
      tags: ['#productivity', '#mindset', '#reading'],
    },
  ];

  const shortcuts = [
    { key: '⌃ + ⌥ + L  /  Ctrl + Alt + L', action: 'Open Multi-Step Quick Capture dialog from anywhere' },
    { key: '⌘ + K  /  Ctrl + K', action: 'Open Spotlight Search Modal or focus active page search bar' },
    { key: '⌘ + Enter  /  Ctrl + Enter', action: 'Save and schedule current item immediately' },
    { key: '↑  /  ↓', action: 'Navigate up and down between items in Search Modal' },
    { key: 'Enter (↵)', action: 'Open highlighted item or navigate to destination view' },
    { key: 'Esc', action: 'Close active modal, search drawer, or dismiss dialog' },
    { key: '⌘ + F  /  /', action: 'Focus Deep Search input bar on the page' },
    { key: '⌘ + Shift + S', action: 'Toggle Star / Favorite status on selected item' },
    { key: '⌘ + Shift + A', action: 'Toggle Archive / Done state on selected item' },
    { key: 'Space', action: 'Quick view or preview active item' },
  ];

  const platformGuides = [
    {
      name: 'Web Application (PWA & Local Mode)',
      icon: <Globe2 className="w-6 h-6 text-[#171711]" />,
      tag: 'Zero Install Required',
      desc: 'Instant, offline-capable application accessible in any modern browser. Supports guest mode with local IndexedDB/SQLite storage.',
      steps: [
        'Open laterbox.dev in any modern web browser (Chrome, Safari, Edge, Firefox).',
        'Press ⌃⌥L (Control+Option+L) on Mac or Ctrl+Alt+L on PC to capture anytime.',
        'Press ⌘K (Ctrl+K) to launch the Spotlight Search Modal or focus the page search bar.',
        'Install as a Progressive Web App (PWA) on your desktop for a native window feel.',
      ],
      linkText: 'Launch Web App',
      linkUrl: '/home',
    },
    {
      name: 'Browser Extensions (Chrome, Brave, Firefox, Safari)',
      icon: <Puzzle className="w-6 h-6 text-[#171711]" />,
      tag: '1-Click Tab Capture',
      desc: 'Save tabs, articles, highlighted quotes, and media directly into your return queue without switching away from your workflow.',
      steps: [
        'Install the LaterBox Extension from the Downloads page.',
        'Click the puzzle icon in your browser toolbar to link with LaterBox.',
        'Click the LaterBox button anytime on any web page to stage it into your vault.',
        'Right-click selected text to save it as a highlighted quote note.',
      ],
      linkText: 'Get Browser Extension',
      linkUrl: '/download',
    },
    {
      name: 'Desktop Apps (macOS, Windows, Linux)',
      icon: <Laptop className="w-6 h-6 text-[#171711]" />,
      tag: 'Native Performance',
      desc: 'Blazing-fast desktop client with system tray/menu bar integration, local SQLite core, and global hotkeys across all windows.',
      steps: [
        'Download and run the installer for macOS (DMG), Windows (Setup.exe), or Linux.',
        'Use the global hotkey to summon Quick Capture above whatever app you are working in.',
        'Keep LaterBox minimized to the system tray for zero-drag background return alerts.',
        'All data is stored directly on your hard drive with sub-10ms query speeds.',
      ],
      linkText: 'Download Desktop Builds',
      linkUrl: '/download',
    },
    {
      name: 'Mobile Apps (iOS & Android)',
      icon: <Smartphone className="w-6 h-6 text-[#171711]" />,
      tag: 'Native Share Sheet',
      desc: 'Send links, documents, and videos into LaterBox straight from Safari, YouTube, Twitter/X, or Reddit with native share sheets.',
      steps: [
        'Install the iOS app or Android build onto your smartphone or tablet.',
        'When viewing any link, file, or photo, tap the native Share button.',
        'Select LaterBox from the list of sharing destinations.',
        'Pick when you want the item to return (Today, Tomorrow, Weekend, or Someday).',
      ],
      linkText: 'Set Up Mobile Companion',
      linkUrl: '/download',
    },
  ];

  const faqs = [
    {
      q: 'How does scheduling and resurfacing work in LaterBox?',
      a: 'When you save an item, you choose when it should come back: Later Today (resurfaces in your afternoon review), Tomorrow morning (ready for your morning coffee), This Weekend (for longer reads or personal projects), or the Someday Vault (for reading lists and creative ideas with zero deadline pressure). Until that time arrives, the item is completely hidden from your daily view so you can focus on what is in front of you.',
    },
    {
      q: 'What is the difference between Command+K and Control+Option+L?',
      a: 'Control + Option + L (⌃⌥L on Mac, Ctrl+Alt+L on Windows) is the dedicated shortcut to open the Quick Capture modal, allowing you to paste a link, write a note, attach a file, and choose its return schedule. Command + K (⌘K on Mac, Ctrl+K on Windows) is the dedicated Search shortcut: if an on-page search bar is present (in Inbox, Library, Today, Upcoming, or Deep Search), it focuses the input immediately; on views without a search bar (like the Home dashboard), it opens the global Spotlight Search Modal with real-time vault search and quick navigation.',
    },
    {
      q: 'How does Guest Mode work? Can I clear sample demo items?',
      a: 'LaterBox is 100% offline-first and requires no account to use. In Guest Mode, your data is stored securely in your browser local storage. If you want to explore with a clean slate, click the "Clear Demo Cards (Start Fresh)" button on the Inbox or Home page. You can restore the sample items anytime with one click.',
    },
    {
      q: 'Can I use LaterBox completely offline without an internet connection?',
      a: 'Yes! LaterBox was designed from day one with an offline-first architecture. All your saved items, schedules, notes, and collections live in your local database. You can capture, search, read notes, and organize your vault on airplanes, trains, or off-grid. When internet connectivity is restored, cloud synchronization seamlessly updates.',
    },
    {
      q: 'Where are my files and private notes stored?',
      a: 'Your data stays on your machine. We do not sell your reading habits, track your browsing history, or feed your notes to public AI models. All local storage is encrypted, and cloud synchronization (if you sign in) runs through secure, private Supabase databases.',
    },
    {
      q: 'How do rich multi-platform card formats work?',
      a: 'LaterBox automatically inspects the content you save and renders it using signature native formats: Photoshop (.psd) and design files get visual gradient art cards with Adobe Ps squircles; PDFs get realistic document previews with interactive readers; YouTube videos get thumbnail covers with inline players; Spotify tracks get album artwork with play buttons; and personal notes get warm paper squircles with structured checklists.',
    },
  ];

  return (
    <div className="w-full flex-1">
      {/* Hero Header */}
      <section className="relative pt-12 sm:pt-16 pb-12 sm:pb-16 overflow-hidden border-b border-[#e4e0d5]/60 bg-gradient-to-b from-[#f7f5ee] to-[#ece7dc]/40">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black mb-4 shadow-2xs">
            <Compass className="w-3.5 h-3.5" />
            <span>Complete LaterBox Guide & Knowledge Base</span>
          </div>
          <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight text-[#171711] mb-4">
            Master Every Feature in LaterBox
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] font-medium max-w-2xl mx-auto leading-relaxed">
            Drop it now. Choose when. Forget about it. Learn how to capture across any device, schedule intentional returns, search your vault with ⌘K, and keep a clean mind.
          </p>

          {/* Tab Navigation Switcher */}
          <div className="flex flex-wrap items-center justify-center gap-1.5 mt-8 max-w-3xl mx-auto p-1.5 rounded-2xl bg-white/80 border border-[#e4e0d5] shadow-xs">
            {[
              { id: 'workflow', label: 'How It Works', icon: <Sparkles className="w-4 h-4" /> },
              { id: 'formats', label: 'Rich Formats', icon: <Layers className="w-4 h-4" /> },
              { id: 'shortcuts', label: 'Keyboard Shortcuts', icon: <Keyboard className="w-4 h-4" /> },
              { id: 'platforms', label: 'Platforms & Setup', icon: <Laptop className="w-4 h-4" /> },
              { id: 'faq', label: 'FAQ & Philosophy', icon: <HelpCircle className="w-4 h-4" /> },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all cursor-pointer ${
                  activeTab === tab.id
                    ? 'bg-[#171711] text-white shadow-xs'
                    : 'text-[#6c6b63] hover:text-[#171711] hover:bg-[#f7f5ee]'
                }`}
              >
                {tab.icon}
                <span>{tab.label}</span>
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* Main Content Area */}
      <main className="max-w-5xl mx-auto px-4 sm:px-6 py-10 sm:py-14 w-full space-y-12">
        {/* TAB 1: THE 4 PILLARS WORKFLOW */}
        {activeTab === 'workflow' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black mb-2">
                <span>The Calm Return Philosophy</span>
              </div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                The 4 Pillars of LaterBox
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Designed from the ground up to replace open-tab clutter and neglected bookmark graveyards with a quiet, reliable return system.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {workflowSteps.map((s, idx) => (
                <div
                  key={idx}
                  className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] shadow-xs hover:border-[#171711]/30 transition-all flex flex-col justify-between"
                >
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center">
                        {s.icon}
                      </div>
                      <span className="text-xs font-black px-2.5 py-1 rounded-full bg-[#f7f5ee] border border-[#e4e0d5] text-[#6c6b63]">
                        {s.badge}
                      </span>
                    </div>

                    <div>
                      <span className="text-xs font-black text-[#6c6b63] tracking-widest block mb-1">
                        STEP {s.step}
                      </span>
                      <h3 className="text-lg font-bold text-[#171711]">{s.title}</h3>
                      <p className="text-xs sm:text-sm text-[#6c6b63] leading-relaxed mt-2">
                        {s.desc}
                      </p>
                    </div>

                    <div className="pt-3 border-t border-[#f0ece1] space-y-2">
                      {s.features.map((feat, fIdx) => (
                        <div key={fIdx} className="flex items-center gap-2 text-xs font-medium text-[#171711]">
                          <CheckCircle2 className="w-3.5 h-3.5 text-[#34C759] shrink-0" />
                          <span>{feat}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Bottom Action Banner */}
            <div className="p-7 rounded-3xl bg-[#171711] text-white flex flex-col sm:flex-row items-center justify-between gap-6 shadow-md">
              <div className="space-y-1 text-center sm:text-left">
                <h3 className="text-lg font-bold">Ready to declutter your mind?</h3>
                <p className="text-xs text-[#9e9b92]">Launch LaterBox instantly in your browser or explore the desktop app.</p>
              </div>
              <div className="flex items-center gap-3 shrink-0">
                <Link
                  href="/download"
                  className="px-4 py-2.5 rounded-xl bg-white/10 hover:bg-white/20 text-white text-xs font-bold transition-all border border-white/10"
                >
                  Download Apps
                </Link>
                <Link
                  href="/home"
                  className="px-5 py-2.5 rounded-xl bg-[#e6edb0] hover:bg-[#d9e29a] text-[#171711] text-xs font-extrabold transition-all shadow-xs flex items-center gap-1.5"
                >
                  <span>Open LaterBox</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: MULTI-PLATFORM RICH FORMATS */}
        {activeTab === 'formats' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black mb-2">
                <span>Tailored Card Experiences</span>
              </div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                Multi-Platform Visual Format System
              </h2>
              <p className="text-sm text-[#6c6b63]">
                LaterBox identifies what you save and renders high-fidelity visual cards across Inbox, Today, Upcoming, and the Item Details page.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {formatCards.map((fmt, idx) => (
                <div
                  key={idx}
                  className="p-6 rounded-3xl bg-white border border-[#e4e0d5] shadow-xs flex flex-col justify-between hover:border-[#171711]/40 transition-all"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className={`text-[11px] font-black px-2.5 py-1 rounded-full ${fmt.tagColor}`}>
                        {fmt.badge}
                      </span>
                      <span className="text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider">
                        {fmt.brand}
                      </span>
                    </div>

                    <div>
                      <h3 className="text-base font-bold text-[#171711]">{fmt.type}</h3>
                      <p className="text-xs text-[#6c6b63] leading-relaxed mt-1">{fmt.desc}</p>
                    </div>

                    <div className="p-3.5 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] space-y-1">
                      <span className="text-xs font-bold text-[#171711] truncate block">{fmt.example}</span>
                      <span className="text-[11px] text-[#9e9b92] block">{fmt.details}</span>
                    </div>

                    <div className="flex items-center gap-1.5 flex-wrap pt-1">
                      {fmt.tags.map((tag) => (
                        <span key={tag} className="text-[10px] font-mono text-[#6c6b63] bg-[#ebe7dc] px-2 py-0.5 rounded">
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="p-6 rounded-3xl bg-[#ebe7dc]/50 border border-[#e4e0d5] flex items-center gap-4">
              <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center shrink-0">
                <Sparkles className="w-5 h-5 text-[#171711]" />
              </div>
              <div className="text-xs text-[#6c6b63] leading-relaxed">
                <strong className="text-[#171711]">Consistent Across All Views:</strong> Every item maintains its rich format preview whether you inspect it on the Home dashboard timeline, in your Inbox grid, or open its full details page at <code className="text-[#171711] bg-white px-1.5 py-0.5 rounded font-mono">/item/[id]</code>.
              </div>
            </div>
          </div>
        )}

        {/* TAB 3: KEYBOARD SHORTCUTS */}
        {activeTab === 'shortcuts' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black mb-2">
                <span>Speed of Thought</span>
              </div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                Keyboard Shortcuts Cheat Sheet
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Control LaterBox without reaching for your mouse. Capture, schedule, search, and navigate in milliseconds.
              </p>
            </div>

            {/* Main Shortcut Cards Showcase */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-5 rounded-2xl bg-white border-2 border-[#171711] shadow-xs space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black uppercase tracking-wider text-[#9e9b92]">Universal Capture</span>
                  <span className="px-2 py-0.5 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black">Summon Modal</span>
                </div>
                <h3 className="text-base font-bold text-[#171711]">Control + Option + L</h3>
                <p className="text-xs text-[#6c6b63] leading-relaxed">
                  Opens the multi-step Quick Capture modal from anywhere on web and Mac (<kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono font-bold text-[#171711]">⌃⌥L</kbd>, or <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono font-bold text-[#171711]">Ctrl+Alt+L</kbd> on PC).
                </p>
              </div>

              <div className="p-5 rounded-2xl bg-white border-2 border-[#171711] shadow-xs space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black uppercase tracking-wider text-[#9e9b92]">Omnisearch & Focus</span>
                  <span className="px-2 py-0.5 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black">Spotlight Palette</span>
                </div>
                <h3 className="text-base font-bold text-[#171711]">Command + K / Ctrl + K</h3>
                <p className="text-xs text-[#6c6b63] leading-relaxed">
                  Focuses the active on-page search bar if available (in Inbox, Library, Today, Deep Search), or summons the Spotlight Search Modal.
                </p>
              </div>
            </div>

            {/* Complete Shortcuts Table */}
            <div className="rounded-3xl bg-white border border-[#e4e0d5] shadow-xs overflow-hidden">
              <div className="p-5 bg-[#f7f5ee] border-b border-[#e4e0d5] flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Keyboard className="w-5 h-5 text-[#171711]" />
                  <span className="text-sm font-bold text-[#171711]">Complete Keyboard Reference</span>
                </div>
                <span className="text-xs font-medium text-[#6c6b63]">Web, Desktop & PWA</span>
              </div>

              <div className="divide-y divide-[#f0ece1]">
                {shortcuts.map((sc, idx) => (
                  <div
                    key={idx}
                    className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-[#f7f5ee]/50 transition-colors"
                  >
                    <span className="text-sm text-[#171711] font-medium">{sc.action}</span>
                    <kbd className="px-3 py-1.5 rounded-lg bg-[#ebe7dc] border border-[#d8d3c5] text-[#171711] font-mono text-xs font-bold shadow-2xs self-start sm:self-auto">
                      {sc.key}
                    </kbd>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* TAB 4: PLATFORMS & SETUP */}
        {activeTab === 'platforms' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black mb-2">
                <span>Unified Ecosystem</span>
              </div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                Available on All Your Devices
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Install LaterBox across your computer, phone, tablet, and browser for unified real-time syncing.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {platformGuides.map((p, idx) => (
                <div
                  key={idx}
                  className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] shadow-xs flex flex-col justify-between"
                >
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center">
                        {p.icon}
                      </div>
                      <span className="text-xs font-black px-2.5 py-1 rounded-full bg-[#f7f5ee] border border-[#e4e0d5] text-[#171711]">
                        {p.tag}
                      </span>
                    </div>

                    <div>
                      <h3 className="text-lg font-bold text-[#171711]">{p.name}</h3>
                      <p className="text-xs sm:text-sm text-[#6c6b63] leading-relaxed mt-1">
                        {p.desc}
                      </p>
                    </div>

                    <div className="bg-[#f7f5ee] rounded-2xl p-4 border border-[#e4e0d5]/80 space-y-2.5">
                      <span className="text-xs font-bold text-[#171711] block">Setup & Usage:</span>
                      <ol className="space-y-2 text-xs text-[#6c6b63]">
                        {p.steps.map((step, sIdx) => (
                          <li key={sIdx} className="flex items-start gap-2">
                            <span className="w-4 h-4 rounded-full bg-[#e6edb0] text-[#171711] font-bold text-[10px] flex items-center justify-center shrink-0 mt-0.5">
                              {sIdx + 1}
                            </span>
                            <span className="leading-snug">{step}</span>
                          </li>
                        ))}
                      </ol>
                    </div>
                  </div>

                  <div className="pt-4 mt-4 border-t border-[#f0ece1]">
                    <Link
                      href={p.linkUrl}
                      className="inline-flex items-center gap-1.5 text-xs font-bold text-[#171711] hover:text-[#6c6b63] transition-colors"
                    >
                      <span>{p.linkText}</span>
                      <ArrowRight className="w-3.5 h-3.5" />
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 5: FAQ & TROUBLESHOOTING */}
        {activeTab === 'faq' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black mb-2">
                <span>Frequently Asked Questions</span>
              </div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                Everything You Need to Know
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Learn about scheduling, offline storage, privacy, and how LaterBox keeps your data local.
              </p>
            </div>

            <div className="space-y-3">
              {faqs.map((faq, idx) => {
                const isOpen = openFaq === idx;
                return (
                  <div
                    key={idx}
                    className="rounded-2xl bg-white border border-[#e4e0d5] shadow-xs overflow-hidden transition-all"
                  >
                    <button
                      onClick={() => setOpenFaq(isOpen ? null : idx)}
                      className="w-full p-5 sm:p-6 text-left flex items-center justify-between gap-4 font-bold text-[#171711] text-sm sm:text-base cursor-pointer"
                    >
                      <span>{faq.q}</span>
                      <ChevronDown
                        className={`w-5 h-5 text-[#6c6b63] shrink-0 transition-transform duration-200 ${
                          isOpen ? 'rotate-180 text-[#171711]' : ''
                        }`}
                      />
                    </button>
                    {isOpen && (
                      <div className="px-5 sm:px-6 pb-6 pt-1 text-xs sm:text-sm text-[#6c6b63] leading-relaxed border-t border-[#f0ece1]">
                        {faq.a}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
