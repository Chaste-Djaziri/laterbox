'use client';

import React from 'react';
import Link from 'next/link';
import { AppShell } from '@/components/layout/AppShell';
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
} from 'lucide-react';

export default function TutorialPage() {
  const guides = [
    {
      title: '1. Quick Capture from Anywhere',
      icon: <Zap className="w-6 h-6 text-[#171711]" />,
      content:
        'Save any link, YouTube video, note, or file attachment. On web or desktop, press ⌘+K (or click "Save Item" in the sidebar) to open the quick capture dialog.',
    },
    {
      title: '2. Install Browser Extensions',
      icon: <Puzzle className="w-6 h-6 text-[#171711]" />,
      content:
        'Download the Chrome, Brave, or Firefox extension from the Apps page to capture any active tab or highlighted text selection with a single click.',
    },
    {
      title: '3. Keyboard Navigation',
      icon: <Keyboard className="w-6 h-6 text-[#171711]" />,
      content:
        'Use standard hotkeys to speed up your workflow: ⌘+K opens quick capture, ⌘+Enter saves immediately, and Esc closes dialogs.',
    },
    {
      title: '4. Organizing with Collections',
      icon: <FolderPlus className="w-6 h-6 text-[#171711]" />,
      content:
        'Create custom collections in your Library to group related articles, research material, recipes, or project files.',
    },
    {
      title: '5. Annotations & Notes',
      icon: <StickyNote className="w-6 h-6 text-[#171711]" />,
      content:
        'Open any saved item to add personal notes with real-time auto-save. Notes are indexed and searchable directly from Deep Search.',
    },
    {
      title: '6. Deep Search & Instant Filters',
      icon: <Search className="w-6 h-6 text-[#171711]" />,
      content:
        'Filter your inbox by Articles, Videos, Music, Notes, or Starred items, and search through titles, domains, notes, and highlights instantly.',
    },
  ];

  return (
    <AppShell>
      <div className="max-w-4xl mx-auto px-6 sm:px-8 py-7 sm:py-9 space-y-8">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-xs font-bold border border-[#d0db84] mb-3">
            <Compass className="w-3.5 h-3.5" />
            <span>Getting Started Guide</span>
          </div>
          <h1 className="text-3xl font-black text-[#171711] tracking-tight">
            Mastering LaterBox
          </h1>
          <p className="text-sm text-[#6c6b63] font-medium mt-0.5 max-w-2xl">
            Everything you need to know about capturing, reading, syncing, and organizing your knowledge base.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {guides.map((g, idx) => (
            <div
              key={idx}
              className="p-6 rounded-3xl bg-white border border-[#e4e0d5] shadow-2xs flex items-start gap-4"
            >
              <div className="w-11 h-11 rounded-2xl bg-[#e6edb0] flex items-center justify-center shrink-0 border border-[#d0db84]">
                {g.icon}
              </div>
              <div className="space-y-1.5 min-w-0">
                <h3 className="text-base font-bold text-[#171711]">{g.title}</h3>
                <p className="text-xs text-[#6c6b63] leading-relaxed">{g.content}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Quick Action Navigation */}
        <div className="p-6 sm:p-7 rounded-3xl bg-[#ebe7dc]/50 border border-[#e4e0d5] flex flex-wrap items-center justify-between gap-4">
          <div>
            <h3 className="text-sm font-extrabold text-[#171711]">Ready to capture across all your devices?</h3>
            <p className="text-xs text-[#6c6b63]">Download the desktop companion or browser extension.</p>
          </div>
          <div className="flex items-center gap-3">
            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white hover:bg-[#f7f5ee] border border-[#e4e0d5] text-[#171711] text-xs font-bold transition-all shadow-2xs"
            >
              <Download className="w-4 h-4" />
              <span>Get Apps</span>
            </Link>
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all"
            >
              <span>Go to Inbox</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>
    </AppShell>
  );
}
