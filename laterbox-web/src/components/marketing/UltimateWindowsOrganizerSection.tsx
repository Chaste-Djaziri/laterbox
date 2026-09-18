'use client';

import React, { useState } from 'react';

interface TabContent {
  id: string;
  label: string;
  title: string;
  description: React.ReactNode;
}

export function UltimateWindowsOrganizerSection() {
  const tabs: TabContent[] = [
    {
      id: 'CAPTURE',
      label: 'CAPTURE',
      title: 'Instant Local Capture',
      description: (
        <>
          Stop losing track of important files and links. With LaterBox, simply press{' '}
          <strong className="font-bold text-[#171711]">Ctrl + Shift + L</strong> to bring up
          the global quick capture interface from anywhere in Windows. You can paste URLs, drop
          heavy PSDs, or type quick notes. Everything is securely referenced on your local machine
          instantly, eliminating cloud upload wait times and keeping your workflow completely
          uninterrupted.
        </>
      ),
    },
    {
      id: 'SCHEDULE',
      label: 'SCHEDULE',
      title: 'Effortless Resurfacing Presets',
      description: (
        <>
          Decide when your items return with zero friction. Choose natural scheduling presets like{' '}
          <strong className="font-bold text-[#171711]">Later Today</strong>,{' '}
          <strong className="font-bold text-[#171711]">Tomorrow</strong>, or{' '}
          <strong className="font-bold text-[#171711]">Weekend</strong>, or pick a precise custom date and
          time. LaterBox keeps your current desktop clean without letting postponed tasks slip through the
          cracks.
        </>
      ),
    },
    {
      id: 'RETURN',
      label: 'RETURN',
      title: 'Non-Intrusive Timed Delivery',
      description: (
        <>
          When the appointed time arrives, LaterBox quietly surfaces the exact item directly in your
          daily view and system tray. No noisy bells or aggressive alarms—just a calm, actionable prompt
          ready for execution.
        </>
      ),
    },
    {
      id: 'OPEN & DO',
      label: 'OPEN & DO',
      title: 'Direct 1-Click Launching',
      description: (
        <>
          Don&apos;t just read a reminder—jump directly into action. Launch URLs in your default browser,
          reveal local folders directly inside Windows Explorer, or open heavy project files in Photoshop,
          Figma, or VS Code with a single tap.
        </>
      ),
    },
    {
      id: 'SNOOZE',
      label: 'SNOOZE',
      title: 'Guilt-Free Delay Controls',
      description: (
        <>
          Caught in the middle of deep flow when an item surfaces? Easily snooze it for 1 hour, later
          this evening, or push it to next week with one keystroke without cluttering your inbox or
          breaking concentration.
        </>
      ),
    },
    {
      id: 'SEARCH',
      label: 'SEARCH',
      title: 'Sub-10ms Local SQLite Omnisearch',
      description: (
        <>
          Search across thousands of saved links, notes, tags, and file attachments in real time.
          Everything runs entirely on your local machine using embedded SQLite—zero cloud round trips, zero
          latency, and complete privacy.
        </>
      ),
    },
    {
      id: 'HISTORY',
      label: 'HISTORY',
      title: 'Comprehensive Action Log',
      description: (
        <>
          Access an immutable log of everything you&apos;ve completed, archived, or postponed. Filter by
          category, domain, or completion date to see your productive rhythm without endless archived to-do
          debris.
        </>
      ),
    },
    {
      id: 'SOMEDAY',
      label: 'SOMEDAY',
      title: 'Pressure-Free Someday Vault',
      description: (
        <>
          Store long-term inspirations, movie recommendations, books to read, and side-project concepts
          with zero deadline pressure. Items stay completely hidden from your daily view until you
          intentionally choose to explore them.
        </>
      ),
    },
  ];

  const [activeTabId, setActiveTabId] = useState<string>('CAPTURE');
  const activeTab = tabs.find((t) => t.id === activeTabId) || tabs[0];

  return (
    <section className="py-24 sm:py-32 lg:py-36 bg-[#f7f5ee] border-b border-[#e4e0d5] relative overflow-hidden">
      <div className="max-w-5xl mx-auto px-4 sm:px-6">
        {/* Section Headline */}
        <h2 className="text-3xl sm:text-5xl lg:text-[54px] font-black tracking-tight text-[#171711] text-center mb-12 sm:mb-16 leading-tight">
          The Ultimate Windows Productivity Organizer
        </h2>

        {/* Two-Column Windows Mockup Card */}
        <div className="w-full max-w-4xl mx-auto bg-white rounded-3xl sm:rounded-[32px] border border-[#e4e0d5] shadow-[0_20px_60px_rgba(0,0,0,0.06)] overflow-hidden flex flex-col md:flex-row transition-all">
          {/* Left Sidebar Navigation */}
          <div className="w-full md:w-56 lg:w-60 border-b md:border-b-0 md:border-r border-[#ece8df] py-6 sm:py-8 flex flex-row md:flex-col overflow-x-auto md:overflow-visible scrollbar-none shrink-0 bg-white select-none">
            {tabs.map((tab) => {
              const isActive = tab.id === activeTabId;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setActiveTabId(tab.id)}
                  className={`relative py-3 sm:py-3.5 px-6 sm:px-8 text-left transition-colors duration-150 cursor-pointer whitespace-nowrap text-[11px] sm:text-xs tracking-widest font-bold uppercase flex items-center justify-between ${
                    isActive
                      ? 'text-[#171711] font-black bg-[#f7f5ee]/60'
                      : 'text-[#8c897f] hover:text-[#171711]'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    {isActive && <span className="w-1.5 h-1.5 rounded-full bg-[#b8cb46]" />}
                    <span>{tab.label}</span>
                  </div>

                  {/* Active Indicator Bar */}
                  {isActive && (
                    <span className="hidden md:block absolute right-0 top-0 bottom-0 w-[3px] bg-[#171711]" />
                  )}
                  {isActive && (
                    <span className="block md:hidden absolute left-4 right-4 bottom-0 h-[2px] bg-[#171711]" />
                  )}
                </button>
              );
            })}
          </div>

          {/* Right Content Area */}
          <div className="flex-1 p-8 sm:p-12 lg:p-16 flex flex-col justify-center min-h-[340px] sm:min-h-[400px]">
            <div key={activeTab.id} className="animate-in fade-in duration-200">
              <h3 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#171711] mb-5">
                {activeTab.title}
              </h3>
              <p className="text-sm sm:text-[15px] leading-relaxed text-[#6c6b63] font-normal max-w-xl">
                {activeTab.description}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
