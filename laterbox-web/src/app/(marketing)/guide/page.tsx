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
} from 'lucide-react';

export default function GuidePage() {
  const [activeTab, setActiveTab] = useState<'basics' | 'platforms' | 'shortcuts' | 'faq'>('basics');
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const workflowSteps = [
    {
      step: '01',
      title: '1-Tap Universal Capture',
      badge: 'Capture Anywhere',
      desc: 'Save any article, YouTube video, Spotify track, X/Twitter thread, PDF, image, or quick thought. Use our browser extension, mobile share sheet, desktop global hotkey, or web app.',
      icon: <Zap className="w-6 h-6 text-[#171711]" />,
      features: ['Browser Extension (Chrome, Firefox, Safari)', 'Native iOS & Android Share Sheet', 'Desktop Global Hotkeys (⌘+K)', 'Drag & Drop Attachments'],
    },
    {
      step: '02',
      title: 'Autonomous AI Enrichment',
      badge: 'Smart Metadata',
      desc: 'LaterBox automatically extracts high-resolution preview covers, author info, estimated read time, favicons, structured summaries, and auto-tags your content for instant retrieval.',
      icon: <Sparkles className="w-6 h-6 text-[#171711]" />,
      features: ['Automatic Hero Cover Art Extraction', 'Clean Readability Content Extraction', 'Domain & Favicon Identification', 'Smart Type Detection (Article, Video, Audio, Note)'],
    },
    {
      step: '03',
      title: 'Distraction-Free Reader & Media Embeds',
      badge: 'Pure Focus',
      desc: 'Read articles in a clean, ad-free reader mode with adjustable typography. Watch YouTube videos and listen to Spotify podcasts directly inside LaterBox without tracking or distractions.',
      icon: <PlayCircle className="w-6 h-6 text-[#171711]" />,
      features: ['Clean Reader Mode with Dark/Light Themes', 'Native YouTube & Vimeo Inline Players', 'Embedded Spotify Audio & Podcasts', 'Markdown Annotations & Quotes'],
    },
    {
      step: '04',
      title: 'Deep Search & Smart Collections',
      badge: 'Effortless Organization',
      desc: 'Group items into custom collections for research, recipes, or projects. Find any saved item in milliseconds by title, URL, content body, notes, or category filters.',
      icon: <FolderPlus className="w-6 h-6 text-[#171711]" />,
      features: ['Custom Visual Collections & Folders', 'Instant Media Filters (Articles, Videos, Audio, Notes)', 'Real-Time Full-Text Deep Search', 'Starred & Read State Archiving'],
    },
  ];

  const platformGuides = [
    {
      name: 'Mobile Apps (iOS & Android)',
      icon: <Smartphone className="w-6 h-6 text-[#171711]" />,
      tag: 'Share Sheet Support',
      desc: 'Save articles, links, and documents straight from Safari, Chrome, Twitter, YouTube, or any app using the native OS share sheet.',
      steps: [
        'Open any link or media in your mobile browser or app.',
        'Tap the native Share button (iOS Share Sheet / Android Share).',
        'Select LaterBox from the list of apps.',
        'The item is saved immediately to your inbox with full offline caching.',
      ],
      linkText: 'Get Mobile App',
      linkUrl: '/download',
    },
    {
      name: 'Browser Extensions (Chrome, Brave, Firefox, Safari)',
      icon: <Puzzle className="w-6 h-6 text-[#171711]" />,
      tag: '1-Click Tab Capture',
      desc: 'Save active tabs, bookmarks, or highlighted text selections directly to LaterBox without opening the app.',
      steps: [
        'Install the extension from the download page.',
        'Click the LaterBox puzzle icon in your browser toolbar to connect.',
        'Press the extension icon or hotkey anytime to capture the active page.',
        'Right-click any selected text to save it as a highlighted quote note.',
      ],
      linkText: 'Install Extension',
      linkUrl: '/download',
    },
    {
      name: 'Desktop Apps (macOS, Windows, Linux)',
      icon: <Laptop className="w-6 h-6 text-[#171711]" />,
      tag: 'Native Performance',
      desc: 'Fast desktop companion with menu bar / system tray integration, local SQLite database, and instant global hotkey access.',
      steps: [
        'Download and install the native desktop build for macOS, Windows, or Linux.',
        'Use the global hotkey (⌘+K / Ctrl+K) to open the Quick Capture dialog anywhere.',
        'Access your saved library offline with instant sub-millisecond search.',
        'Keep in the menu bar/tray for background synchronization.',
      ],
      linkText: 'Download Desktop',
      linkUrl: '/download',
    },
    {
      name: 'Web Application (PWA & Cloud)',
      icon: <Globe2 className="w-6 h-6 text-[#171711]" />,
      tag: 'Zero-Install Access',
      desc: 'Fully featured progressive web app accessible from any modern browser with guest mode or Supabase account sync.',
      steps: [
        'Visit laterbox.dev from any device or browser.',
        'Click Launch App to use instant local storage or Sign In to sync across devices.',
        'Install as a PWA on your home screen or desktop for a standalone app experience.',
        'Enjoy full reading, searching, note-taking, and collection management.',
      ],
      linkText: 'Launch Web App',
      linkUrl: '/inbox',
    },
  ];

  const shortcuts = [
    { key: '⌘ + K  /  Ctrl + K', action: 'Open Quick Capture dialog from anywhere' },
    { key: '⌘ + Enter  /  Ctrl + Enter', action: 'Save and submit current capture item' },
    { key: '⌘ + F  /  /', action: 'Focus Deep Search input bar' },
    { key: 'Esc', action: 'Close reader modal, search drawer, or active dialog' },
    { key: '⌘ + Shift + S', action: 'Toggle Star / Favorite on selected item' },
    { key: '⌘ + Shift + A', action: 'Toggle Read / Unread archive state' },
    { key: 'J / K  or  ↓ / ↑', action: 'Navigate between inbox items' },
    { key: 'Space', action: 'Open selected item in Reader Mode' },
  ];

  const faqs = [
    {
      q: 'How does mobile sharing work with LaterBox?',
      a: 'On both iOS and Android, LaterBox registers as a native share destination. Whenever you view an article, video, tweet, or PDF in any browser or app, tap Share and select LaterBox. The link and attachments are staged into LaterBox storage instantly and synced to your library.',
    },
    {
      q: 'Can I use LaterBox offline?',
      a: 'Yes! LaterBox is built offline-first. Mobile, desktop, and web apps store your entire library and metadata locally. When an internet connection is restored, changes automatically synchronize via Supabase in the background.',
    },
    {
      q: 'How do I connect the browser extension to my account?',
      a: 'After installing the Chrome, Firefox, or Safari extension, open the web app at laterbox.dev/inbox or visit laterbox.dev/extension/connect. Click "Connect Extension" to link the extension in 1 second without typing complex API keys.',
    },
    {
      q: 'Does LaterBox support media embeds like YouTube and Spotify?',
      a: 'Yes. When you save a YouTube or Vimeo link, LaterBox renders a distraction-free player. For Spotify tracks and podcast episodes, LaterBox embeds an interactive audio player so you can listen while taking notes.',
    },
    {
      q: 'Where is my data stored and is it private?',
      a: 'Your data is 100% yours. We do not sell your browsing habits or reading history. Data is stored on your device and synchronized securely through encrypted Supabase cloud databases. You can export your library anytime.',
    },
  ];

  return (
    <div className="w-full flex-1">
      {/* Hero Header */}
      <section className="relative pt-12 sm:pt-16 pb-12 sm:pb-16 overflow-hidden border-b border-[#e4e0d5]/60 bg-gradient-to-b from-[#f7f5ee] to-[#ece7dc]/40">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-extrabold mb-4 shadow-2xs">
            <Compass className="w-3.5 h-3.5" />
            <span>Complete User Guide & Knowledge Base</span>
          </div>
          <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight text-[#171711] mb-4">
            Master Every Feature in LaterBox
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] font-medium max-w-2xl mx-auto leading-relaxed">
            Everything you need to know about capturing from any device, AI enrichment, distraction-free reading, and organizing your personal knowledge base.
          </p>

          {/* Tab Navigation Switcher */}
          <div className="flex flex-wrap items-center justify-center gap-2 mt-8 max-w-2xl mx-auto p-1.5 rounded-2xl bg-white/80 border border-[#e4e0d5] shadow-xs">
            {[
              { id: 'basics', label: 'How It Works', icon: <Sparkles className="w-4 h-4" /> },
              { id: 'platforms', label: 'Platforms & Setup', icon: <Laptop className="w-4 h-4" /> },
              { id: 'shortcuts', label: 'Keyboard Shortcuts', icon: <Keyboard className="w-4 h-4" /> },
              { id: 'faq', label: 'FAQ & Tips', icon: <HelpCircle className="w-4 h-4" /> },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all ${
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
        {/* TAB 1: HOW IT WORKS */}
        {activeTab === 'basics' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                The 4 Pillars of LaterBox
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Designed from the ground up to replace fragmented bookmarks and chaotic tabs with a permanent digital memory.
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

            {/* Visual Action Banner */}
            <div className="p-7 rounded-3xl bg-[#171711] text-white flex flex-col sm:flex-row items-center justify-between gap-6 shadow-md">
              <div className="space-y-1 text-center sm:text-left">
                <h3 className="text-lg font-bold">Ready to try it out?</h3>
                <p className="text-xs text-[#9e9b92]">Launch the web app in your browser or install on your devices.</p>
              </div>
              <div className="flex items-center gap-3 shrink-0">
                <Link
                  href="/download"
                  className="px-4 py-2.5 rounded-xl bg-white/10 hover:bg-white/20 text-white text-xs font-bold transition-all border border-white/10"
                >
                  Download Apps
                </Link>
                <Link
                  href="/inbox"
                  className="px-5 py-2.5 rounded-xl bg-[#e6edb0] hover:bg-[#d9e29a] text-[#171711] text-xs font-extrabold transition-all shadow-xs flex items-center gap-1.5"
                >
                  <span>Launch Web App</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: PLATFORMS & SETUP */}
        {activeTab === 'platforms' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                Available on All Your Devices
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Install LaterBox across your phone, tablet, computer, and web browser for unified real-time syncing.
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

        {/* TAB 3: KEYBOARD SHORTCUTS */}
        {activeTab === 'shortcuts' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                Keyboard Shortcuts Cheat Sheet
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Navigate and organize your inbox at the speed of thought with built-in desktop and web shortcuts.
              </p>
            </div>

            <div className="rounded-3xl bg-white border border-[#e4e0d5] shadow-xs overflow-hidden">
              <div className="p-5 bg-[#f7f5ee] border-b border-[#e4e0d5] flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Keyboard className="w-5 h-5 text-[#171711]" />
                  <span className="text-sm font-bold text-[#171711]">Essential Navigation Keys</span>
                </div>
                <span className="text-xs font-medium text-[#6c6b63]">Works in Web & Desktop App</span>
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

            <div className="p-6 rounded-3xl bg-[#ebe7dc]/50 border border-[#e4e0d5] flex items-center gap-4">
              <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center shrink-0">
                <Sparkles className="w-5 h-5 text-[#171711]" />
              </div>
              <div className="text-xs text-[#6c6b63] leading-relaxed">
                <strong className="text-[#171711]">Pro Tip:</strong> On desktop, you can customize your global hotkey in Settings to trigger quick capture even when LaterBox is minimized in the background.
              </div>
            </div>
          </div>
        )}

        {/* TAB 4: FAQ & TROUBLESHOOTING */}
        {activeTab === 'faq' && (
          <div className="space-y-10 animate-fade-in">
            <div>
              <h2 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight mb-2">
                Frequently Asked Questions
              </h2>
              <p className="text-sm text-[#6c6b63]">
                Answers to common questions about syncing, extensions, mobile setup, and security.
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
                      className="w-full p-5 sm:p-6 text-left flex items-center justify-between gap-4 font-bold text-[#171711] text-sm sm:text-base"
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
