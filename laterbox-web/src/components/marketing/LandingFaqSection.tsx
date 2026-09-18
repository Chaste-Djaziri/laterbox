'use client';

import React, { useState } from 'react';

interface FaqItem {
  id: string;
  q: string;
  a: string;
}

export function LandingFaqSection() {
  const [openIds, setOpenIds] = useState<Set<string>>(new Set(['is-free']));

  const toggleFaq = (id: string) => {
    setOpenIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const leftColumn: FaqItem[] = [
    {
      id: 'what-is-laterbox',
      q: 'What is LaterBox?',
      a: 'LaterBox is a calm, local-first productivity organizer that lets you quickly capture links, notes, files, and tasks with a single shortcut, then resurfaces them precisely when you are ready to deal with them.',
    },
    {
      id: 'requires-internet',
      q: 'Does LaterBox require an internet connection?',
      a: 'No. LaterBox is built with an offline-first SQLite core. All capture, search, and scheduling functions work completely offline without requiring an active internet connection.',
    },
    {
      id: 'need-account',
      q: 'Do I need an account?',
      a: 'No. You can download and start using the desktop application immediately without registering, creating a password, or giving away your personal email address.',
    },
    {
      id: 'upload-files',
      q: 'Does LaterBox upload my files?',
      a: 'No. All files, local directories, notes, and references remain strictly stored on your own local device. LaterBox never uploads or tracks your private files on remote cloud servers.',
    },
    {
      id: 'duplicate-files',
      q: 'Does LaterBox duplicate large files?',
      a: 'No. When you drop large files or project folders (like PSDs or video files), LaterBox stores lightweight local system references, preventing unwanted disk duplication while ensuring 1-click launching.',
    },
    {
      id: 'what-can-i-add',
      q: 'What can I add to LaterBox?',
      a: 'You can capture browser URLs, rich notes, code snippets, local documents, design files, project folders, and quick to-dos—all within the same unified quick capture bar.',
    },
    {
      id: 'add-files-folders',
      q: 'Can I add files and folders?',
      a: 'Yes. You can drag and drop any file or directory directly into LaterBox or summon quick capture to reference local folders for later execution.',
    },
  ];

  const rightColumn: FaqItem[] = [
    {
      id: 'save-links',
      q: 'Can I save links?',
      a: 'Yes. You can save URLs from any browser using our desktop shortcut, the browser extension, or by copying and pasting directly into the quick capture bar.',
    },
    {
      id: 'when-due',
      q: 'What happens when something is due?',
      a: 'When an item reaches its appointed return time, LaterBox quietly places it into your daily focus view and delivers a subtle desktop notification without disturbing your current concentration.',
    },
    {
      id: 'snooze-again',
      q: 'Can I snooze something again?',
      a: 'Yes. If you are in the middle of focused work when an item returns, you can easily snooze it for one hour, later today, tomorrow, or next week with a single click.',
    },
    {
      id: 'what-is-someday',
      q: 'What is Someday?',
      a: 'Someday is a dedicated, pressure-free vault for articles, videos, books, and long-term project ideas that do not need fixed deadlines, keeping them out of your daily sight until you deliberately choose to explore them.',
    },
    {
      id: 'is-free',
      q: 'Is LaterBox free?',
      a: 'Yes, the core LaterBox application is completely free to use.',
    },
    {
      id: 'supported-os',
      q: 'Which operating systems does LaterBox support?',
      a: 'LaterBox is available as a native application for Windows and macOS, as well as iOS, Android, and modern browser extensions (Chrome, Firefox, Safari).',
    },
  ];

  const renderItem = (item: FaqItem) => {
    const isOpen = openIds.has(item.id);
    return (
      <div key={item.id} className="border-b border-[#ece8df]">
        <button
          type="button"
          onClick={() => toggleFaq(item.id)}
          className="w-full py-4 sm:py-5 flex items-center justify-between text-left cursor-pointer group select-none"
        >
          <span className="font-bold text-sm sm:text-[15px] text-[#171711] pr-4 group-hover:text-black transition-colors">
            {item.q}
          </span>
          <span
            className={`shrink-0 text-xl font-light text-[#171711] transition-transform duration-200 leading-none ${
              isOpen ? 'rotate-45' : 'rotate-0'
            }`}
          >
            +
          </span>
        </button>
        {isOpen && (
          <div className="pb-4 pt-1 pr-6 text-xs sm:text-sm text-[#737168] leading-relaxed animate-in fade-in duration-200">
            {item.a}
          </div>
        )}
      </div>
    );
  };

  return (
    <section className="py-24 sm:py-32 lg:py-36 bg-[#faf8f5] border-b border-[#e4e0d5] relative overflow-hidden">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        {/* Section Heading */}
        <h2 className="text-4xl sm:text-6xl font-black tracking-tight text-[#171711] text-center mb-16 sm:mb-20">
          FAQ
        </h2>

        {/* 2-Column FAQ Accordion Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-12 lg:gap-x-16 border-t border-[#ece8df]">
          {/* Left Column */}
          <div className="flex flex-col">{leftColumn.map(renderItem)}</div>

          {/* Right Column */}
          <div className="flex flex-col">{rightColumn.map(renderItem)}</div>
        </div>
      </div>
    </section>
  );
}
