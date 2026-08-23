'use client';

import React from 'react';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import {
  Compass,
  ArrowRight,
  Puzzle,
  Keyboard,
  FolderPlus,
  StickyNote,
  Sparkles,
  Zap,
} from 'lucide-react';

export default function TutorialPage() {
  const guides = [
    {
      title: '1. Quick Capture from Anywhere',
      icon: <Zap className="w-6 h-6 text-emerald-500" />,
      content:
        'Save any link, YouTube video, or text snippet. On web or desktop, press ⌘+K or click the "+" button in the sidebar to open the quick capture dialog.',
    },
    {
      title: '2. Install Browser Extensions',
      icon: <Puzzle className="w-6 h-6 text-amber-500" />,
      content:
        'Download the Chrome or Firefox extension from the Downloads page to capture any active tab or highlighted text selection with a single click.',
    },
    {
      title: '3. Keyboard Navigation',
      icon: <Keyboard className="w-6 h-6 text-blue-500" />,
      content:
        'Use standard hotkeys to speed up your workflow. ⌘+K opens capture, ⌘+Enter saves immediately, and Esc closes dialogs.',
    },
    {
      title: '4. Organizing with Collections',
      icon: <FolderPlus className="w-6 h-6 text-purple-500" />,
      content:
        'Create custom collections in your Library to group related articles, research material, recipes, or YouTube playlists.',
    },
    {
      title: '5. Annotations & Notes',
      icon: <StickyNote className="w-6 h-6 text-rose-500" />,
      content:
        'Open any saved item to add personal notes with real-time auto-save. Notes are searchable directly from the Deep Search page.',
    },
  ];

  return (
    <div className="min-h-screen bg-zinc-50 dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100">
      <Header />

      <main className="max-w-4xl mx-auto px-4 sm:px-6 py-12 sm:py-16 space-y-10">
        <div className="text-center space-y-3">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300 text-xs font-bold border border-emerald-200 dark:border-emerald-800">
            <Compass className="w-3.5 h-3.5" />
            <span>Getting Started Guide</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-zinc-900 dark:text-white">
            Mastering laterbox
          </h1>
          <p className="text-sm text-zinc-500 dark:text-zinc-400 max-w-xl mx-auto">
            Everything you need to know about capturing, reading, and organizing your content library.
          </p>
        </div>

        <div className="space-y-6">
          {guides.map((g, idx) => (
            <div
              key={idx}
              className="p-6 sm:p-7 rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 shadow-sm flex items-start gap-5"
            >
              <div className="w-12 h-12 rounded-2xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center shrink-0">
                {g.icon}
              </div>
              <div className="space-y-2">
                <h3 className="text-lg font-bold text-zinc-900 dark:text-zinc-100">{g.title}</h3>
                <p className="text-sm text-zinc-600 dark:text-zinc-400 leading-relaxed">{g.content}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="text-center pt-4">
          <Link
            href="/inbox"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-bold shadow-md transition-all"
          >
            <span>Go to My Inbox</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </main>
    </div>
  );
}
