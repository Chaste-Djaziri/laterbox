'use client';

import React, { useState } from 'react';
import {
  Sparkles,
  Clock,
  Sun,
  Moon,
  Monitor,
  WifiOff,
  Database,
  FolderOpen,
  Tag,
  ShieldCheck,
  Check,
  Search,
  Lock,
  Download,
  FileText,
  CheckCircle2,
  ArrowRight,
  Zap,
  Bookmark,
  Share2,
} from 'lucide-react';

const rulesList = [
  {
    name: 'Global Quick Capture',
    category: 'Capture & Input',
    description: 'Save in a split second using keyboard shortcuts or extensions without interrupting what you are doing.',
  },
  {
    name: 'Scheduled Returns',
    category: 'Smart Reminders',
    description: 'Choose when items reappear: Tonight, Tomorrow, Next Week, or a custom date.',
  },
  {
    name: 'Light, Dark & System Theme',
    category: 'Appearance',
    description: 'Clean white canvas in daylight, graphite texture in dark mode, or follow system theme automatically.',
  },
  {
    name: 'Offline-First Core',
    category: 'Performance',
    description: 'Save, search, and view your personal library anytime, even when you have no connection.',
  },
  {
    name: 'Collections & Smart Tags',
    category: 'Organization',
    description: 'Keep your research, reading lists, and project references structured and easy to retrieve.',
  },
  {
    name: 'Private & Local-First',
    category: 'Privacy & Security',
    description: 'Zero behavioral tracking. Your references belong to you and stay on your devices.',
  },
];

export function YourLaterBoxYourRulesSection() {
  const [activeRule, setActiveRule] = useState<string>(rulesList[0].name);

  // Interactive state for the showcases
  const [schedulePreset, setSchedulePreset] = useState<'tonight' | 'tomorrow' | 'weekend' | 'someday'>('tomorrow');
  const [themeMode, setThemeMode] = useState<'light' | 'dark' | 'system'>('light');
  const [selectedTag, setSelectedTag] = useState<string>('typography');
  const [capturedSaved, setCapturedSaved] = useState<boolean>(true);

  const selectedRule = rulesList.find((r) => r.name === activeRule) || rulesList[0];

  return (
    <section className="gsap-rules-section bg-white text-[#171711] py-24 sm:py-36 px-6 sm:px-10 lg:px-16 border-t border-[#f0ede4] select-none overflow-hidden">
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
        {/* ============================================================ */}
        {/* Left Column: Headline & Rules List */}
        {/* ============================================================ */}
        <div className="gsap-rules-text lg:col-span-5 space-y-8 text-left">
          <h2 className="leading-none text-left">
            <span className="block text-5xl sm:text-6xl lg:text-7xl font-black text-[#171711] tracking-tight">
              Your LaterBox.
            </span>
            <span className="block text-5xl sm:text-6xl lg:text-7xl font-serif italic text-[#171711] font-normal tracking-normal mt-1 sm:mt-2">
              Your rules.
            </span>
          </h2>

          {/* Active Rule Explainer Banner */}
          <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] transition-all">
            <div className="flex items-center gap-2 mb-1.5 text-xs font-bold text-[#171711]">
              <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
              <span>{selectedRule.name}</span>
            </div>
            <p className="text-xs sm:text-sm text-[#6c6b63] leading-relaxed">
              {selectedRule.description}
            </p>
          </div>

          {/* Rules / Preferences List */}
          <div className="pt-2 divide-y divide-[#f0ede4] border-t border-b border-[#f0ede4]">
            {rulesList.map((rule) => {
              const isActive = activeRule === rule.name;

              return (
                <button
                  key={rule.name}
                  type="button"
                  onClick={() => setActiveRule(rule.name)}
                  className="w-full py-3.5 flex items-center justify-between text-left transition-colors group cursor-pointer"
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`w-2 h-2 rounded-full transition-colors ${
                        isActive ? 'bg-[#171711]' : 'bg-[#c4c0b5] group-hover:bg-[#171711]'
                      }`}
                    />
                    <span
                      className={`text-sm sm:text-base tracking-tight transition-colors ${
                        isActive ? 'text-[#171711] font-bold' : 'text-[#6c6b63] group-hover:text-[#171711]'
                      }`}
                    >
                      {rule.name}
                    </span>
                  </div>
                  {isActive && (
                    <span className="text-[10px] font-black uppercase tracking-wider text-[#171711] px-2.5 py-0.5 rounded-full bg-[#e6edb0]">
                      Active
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* ============================================================ */}
        {/* Right Column: Interactive Preferences & Studio Showcase */}
        {/* ============================================================ */}
        <div className="gsap-rules-visual lg:col-span-7 relative">
          {/* Studio Frame Card */}
          <div className="relative w-full rounded-3xl bg-[#faf8f5] border border-[#e4e0d5] p-3 sm:p-5 shadow-[0_20px_60px_-15px_rgba(23,23,17,0.08)] transition-all">
            {/* Window Top Navigation Bar */}
            <div className="flex items-center justify-between px-3 py-2.5 mb-4 rounded-2xl bg-white border border-[#e7e4d8] text-xs">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[#e8a39f]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#eed79b]" />
                <span className="w-2.5 h-2.5 rounded-full bg-[#b5d697]" />
                <span className="ml-2 font-mono text-[11px] font-bold text-[#868379]">
                  LaterBox / {selectedRule.category}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#eef3db] text-[10px] font-bold text-[#455b2d]">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#5d8531] animate-pulse" />
                  <span>Live Studio</span>
                </span>
              </div>
            </div>

            {/* Dynamic Interactive Panel Body */}
            <div className="min-h-[420px] sm:min-h-[460px] flex flex-col justify-center">
              {/* ------------------------------------------------------ */}
              {/* Case 1: Global Quick Capture */}
              {/* ------------------------------------------------------ */}
              {activeRule === 'Global Quick Capture' && (
                <div className="space-y-4">
                  {/* Floating Shortcut Pill */}
                  <div className="flex items-center justify-between px-4 py-2.5 rounded-2xl bg-white border border-[#e4e0d5]">
                    <div className="flex items-center gap-2">
                      <Zap className="w-4 h-4 text-[#829953]" />
                      <span className="text-xs font-bold text-[#171711]">Global Quick Shortcut</span>
                    </div>
                    <kbd className="px-2.5 py-1 rounded-lg bg-[#f0ede4] border border-[#dcd7cb] font-mono text-[11px] font-bold text-[#171711] shadow-2xs">
                      Ctrl + Alt + L
                    </kbd>
                  </div>

                  {/* Quick Capture Simulated Dialog */}
                  <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-sm space-y-4 text-left">
                    <div className="flex items-center justify-between border-b border-[#f0ede4] pb-3">
                      <div className="flex items-center gap-2">
                        <span className="w-7 h-7 rounded-xl bg-[#e6edb0] flex items-center justify-center text-xs font-black">
                          LB
                        </span>
                        <div>
                          <p className="text-xs font-bold text-[#171711]">Save to LaterBox</p>
                          <p className="text-[10px] text-[#868379]">Active browser tab detected</p>
                        </div>
                      </div>
                      <span className="text-[10px] font-mono text-[#868379]">v2.4 Offline</span>
                    </div>

                    <div className="p-3 rounded-xl bg-[#faf8f5] border border-[#e7e4d8]">
                      <p className="text-xs font-mono text-[#5b6354] truncate">
                        https://github.com/features/actions/ci-cd-workflow
                      </p>
                      <p className="mt-1 text-sm font-bold text-[#171711] truncate">
                        GitHub Actions · Automation and modern CI/CD practices
                      </p>
                    </div>

                    <div>
                      <label className="block text-[10px] font-bold uppercase tracking-wider text-[#868379] mb-2">
                        Return when
                      </label>
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                        {(['tonight', 'tomorrow', 'weekend', 'someday'] as const).map((preset) => (
                          <button
                            key={preset}
                            type="button"
                            onClick={() => setSchedulePreset(preset)}
                            className={`py-2 px-2.5 rounded-xl border text-center font-bold capitalize transition-all ${
                              schedulePreset === preset
                                ? 'bg-[#171711] text-[#e6edb0] border-[#171711] shadow-xs'
                                : 'bg-white text-[#6c6b63] border-[#e4e0d5] hover:border-[#cfc9ba]'
                            }`}
                          >
                            {preset}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div className="flex items-center justify-between pt-2">
                      <button
                        type="button"
                        onClick={() => setCapturedSaved(!capturedSaved)}
                        className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#e6edb0] text-[#171711] text-xs font-bold shadow-xs hover:bg-[#d8e39d] transition-colors"
                      >
                        <Check className="w-3.5 h-3.5" />
                        <span>{capturedSaved ? 'Saved to Inbox (0.2s)' : 'Save Now'}</span>
                      </button>
                      <span className="text-[10px] text-[#868379] font-medium">
                        Instant capture · No distraction
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* ------------------------------------------------------ */}
              {/* Case 2: Scheduled Returns */}
              {/* ------------------------------------------------------ */}
              {activeRule === 'Scheduled Returns' && (
                <div className="space-y-4">
                  <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-sm text-left space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Clock className="w-4 h-4 text-[#829953]" />
                        <h4 className="text-sm font-bold text-[#171711]">When do you want it back?</h4>
                      </div>
                      <span className="text-[10px] font-bold text-[#71874f] px-2 py-0.5 rounded-full bg-[#f0f6e4]">
                        Smart Return
                      </span>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                      {[
                        { id: 'tonight', label: 'Later Today', time: '5:00 PM', desc: 'When the workday wraps up' },
                        { id: 'tomorrow', label: 'Tomorrow Morning', time: '9:00 AM', desc: 'First thing in your fresh inbox' },
                        { id: 'weekend', label: 'This Weekend', time: 'Saturday 10:00 AM', desc: 'Peaceful Saturday morning read' },
                        { id: 'someday', label: 'Someday Vault', time: 'No deadline', desc: 'Safely parked in the reference archive' },
                      ].map((item) => {
                        const selected = schedulePreset === item.id;
                        return (
                          <button
                            key={item.id}
                            type="button"
                            onClick={() => setSchedulePreset(item.id as typeof schedulePreset)}
                            className={`p-3.5 rounded-2xl border text-left transition-all cursor-pointer ${
                              selected
                                ? 'bg-[#171711] text-white border-[#171711] shadow-md'
                                : 'bg-[#faf8f5] text-[#171711] border-[#e7e4d8] hover:border-[#171711]'
                            }`}
                          >
                            <div className="flex items-center justify-between mb-1">
                              <span className="text-xs font-bold">{item.label}</span>
                              <span
                                className={`text-[10px] font-mono px-2 py-0.5 rounded-md ${
                                  selected ? 'bg-white/15 text-[#e6edb0]' : 'bg-white text-[#737066]'
                                }`}
                              >
                                {item.time}
                              </span>
                            </div>
                            <p className={`text-[11px] leading-relaxed ${selected ? 'text-white/70' : 'text-[#737066]'}`}>
                              {item.desc}
                            </p>
                          </button>
                        );
                      })}
                    </div>

                    {/* Returning item mockup */}
                    <div className="p-3.5 rounded-xl bg-[#faf8f5] border border-[#e4e0d5] flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2.5">
                        <FileText className="w-4 h-4 text-[#171711]" />
                        <div>
                          <p className="font-bold text-[#171711]">Quarterly_Tax_Review.pdf</p>
                          <p className="text-[10px] text-[#868379]">Scheduled for {schedulePreset}</p>
                        </div>
                      </div>
                      <span className="px-3 py-1 rounded-lg bg-[#e6edb0] text-[10px] font-bold text-[#171711]">
                        Auto-Restores
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* ------------------------------------------------------ */}
              {/* Case 3: Light, Dark & System Theme */}
              {/* ------------------------------------------------------ */}
              {activeRule === 'Light, Dark & System Theme' && (
                <div className="space-y-4">
                  {/* Theme Switcher Bar */}
                  <div className="flex items-center justify-center gap-2 p-1.5 rounded-2xl bg-white border border-[#e4e0d5]">
                    {[
                      { id: 'light', label: 'Light', icon: Sun },
                      { id: 'dark', label: 'Dark', icon: Moon },
                      { id: 'system', label: 'System', icon: Monitor },
                    ].map(({ id, label, icon: Icon }) => (
                      <button
                        key={id}
                        type="button"
                        onClick={() => setThemeMode(id as typeof themeMode)}
                        className={`flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                          themeMode === id
                            ? 'bg-[#171711] text-[#e6edb0] shadow-xs'
                            : 'text-[#6c6b63] hover:text-[#171711]'
                        }`}
                      >
                        <Icon size={14} />
                        <span>{label}</span>
                      </button>
                    ))}
                  </div>

                  {/* Adaptive Theme Card Preview */}
                  <div
                    className={`rounded-2xl p-6 border transition-all text-left space-y-4 shadow-sm ${
                      themeMode === 'dark'
                        ? 'bg-[#171711] border-[#2c2b25] text-white'
                        : 'bg-white border-[#e4e0d5] text-[#171711]'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span
                          className={`w-3 h-3 rounded-full ${
                            themeMode === 'dark' ? 'bg-[#e6edb0]' : 'bg-[#171711]'
                          }`}
                        />
                        <h4 className="text-sm font-bold">
                          {themeMode === 'dark' ? 'Obsidian Dark' : 'Warm Daylight Cream'}
                        </h4>
                      </div>
                      <span
                        className={`text-[10px] px-2 py-0.5 rounded-md font-mono ${
                          themeMode === 'dark' ? 'bg-white/10 text-[#e6edb0]' : 'bg-[#faf8f5] text-[#737066]'
                        }`}
                      >
                        {themeMode === 'dark' ? '#171711 canvas' : '#f7f5ee canvas'}
                      </span>
                    </div>

                    <div
                      className={`p-4 rounded-xl border ${
                        themeMode === 'dark'
                          ? 'bg-[#22211b] border-[#333229]'
                          : 'bg-[#faf8f5] border-[#eae6da]'
                      }`}
                    >
                      <p className="text-xs font-bold">Article: Designing Calm Interfaces</p>
                      <p
                        className={`mt-1 text-[11px] leading-relaxed ${
                          themeMode === 'dark' ? 'text-white/60' : 'text-[#6c6b63]'
                        }`}
                      >
                        High-contrast typography tuned for readability without screen fatigue.
                      </p>
                    </div>

                    <div className="flex items-center justify-between text-xs pt-1">
                      <span className={themeMode === 'dark' ? 'text-white/60' : 'text-[#737066]'}>
                        Theme synced automatically
                      </span>
                      <span
                        className={`font-bold px-3 py-1 rounded-lg ${
                          themeMode === 'dark'
                            ? 'bg-[#e6edb0] text-[#171711]'
                            : 'bg-[#171711] text-white'
                        }`}
                      >
                        Looks gorgeous
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* ------------------------------------------------------ */}
              {/* Case 4: Offline-First Core */}
              {/* ------------------------------------------------------ */}
              {activeRule === 'Offline-First Core' && (
                <div className="space-y-4">
                  <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-sm text-left space-y-4">
                    <div className="flex items-center justify-between border-b border-[#f0ede4] pb-3">
                      <div className="flex items-center gap-2">
                        <WifiOff className="w-4 h-4 text-[#8a5b3a]" />
                        <span className="text-xs font-bold text-[#171711]">Airplane / No Connection</span>
                      </div>
                      <span className="px-2.5 py-1 rounded-full bg-[#eef3db] text-[10px] font-bold text-[#455b2d]">
                        Local Engine Active
                      </span>
                    </div>

                    <div className="grid grid-cols-2 gap-3 text-left">
                      <div className="p-3.5 rounded-xl bg-[#faf8f5] border border-[#e7e4d8]">
                        <div className="flex items-center gap-1.5 text-[10px] font-bold text-[#7e8574] uppercase tracking-wider mb-1">
                          <Database size={13} /> Local IndexedDB
                        </div>
                        <p className="text-lg font-black text-[#171711]">412 items</p>
                        <p className="text-[10px] text-[#717868]">Stored on this device</p>
                      </div>

                      <div className="p-3.5 rounded-xl bg-[#faf8f5] border border-[#e7e4d8]">
                        <div className="flex items-center gap-1.5 text-[10px] font-bold text-[#7e8574] uppercase tracking-wider mb-1">
                          <Search size={13} /> Search Speed
                        </div>
                        <p className="text-lg font-black text-[#171711]">1.8 ms</p>
                        <p className="text-[10px] text-[#717868]">Instant zero-network query</p>
                      </div>
                    </div>

                    <div className="p-3.5 rounded-xl bg-[#faf8f5] border border-[#e4e0d5] space-y-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-bold text-[#171711]">Saved offline moments ago</span>
                        <span className="text-[10px] font-mono text-[#829953] font-bold">✓ Ready</span>
                      </div>
                      <p className="text-[11px] text-[#6c6b63] leading-relaxed">
                        Full-text search, reading, and notes work 100% disconnected. When WiFi reconnects, changes sync smoothly in the background.
                      </p>
                    </div>
                  </div>
                </div>
              )}

              {/* ------------------------------------------------------ */}
              {/* Case 5: Collections & Smart Tags */}
              {/* ------------------------------------------------------ */}
              {activeRule === 'Collections & Smart Tags' && (
                <div className="space-y-4">
                  <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-sm text-left space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <FolderOpen className="w-4 h-4 text-[#829953]" />
                        <h4 className="text-sm font-bold text-[#171711]">Structured Reference Library</h4>
                      </div>
                      <span className="text-[10px] font-mono text-[#868379]">3 Collections</span>
                    </div>

                    <div className="grid grid-cols-3 gap-2">
                      {[
                        { name: 'Research', count: '14 items', icon: Bookmark },
                        { name: 'Inspiration', count: '29 items', icon: Sparkles },
                        { name: 'Receipts', count: '8 items', icon: FileText },
                      ].map((col) => (
                        <div key={col.name} className="p-3 rounded-xl bg-[#faf8f5] border border-[#e7e4d8] text-left">
                          <col.icon className="w-4 h-4 text-[#171711] mb-2" />
                          <p className="text-xs font-bold text-[#171711] truncate">{col.name}</p>
                          <p className="text-[10px] text-[#868379]">{col.count}</p>
                        </div>
                      ))}
                    </div>

                    <div>
                      <p className="text-[10px] font-bold uppercase tracking-wider text-[#868379] mb-2">
                        Smart Tags Filter
                      </p>
                      <div className="flex flex-wrap gap-1.5">
                        {['typography', 'ci-cd', 'design-systems', 'reading', 'tax-2026'].map((tag) => (
                          <button
                            key={tag}
                            type="button"
                            onClick={() => setSelectedTag(tag)}
                            className={`px-3 py-1 rounded-lg text-xs font-bold transition-all ${
                              selectedTag === tag
                                ? 'bg-[#171711] text-[#e6edb0]'
                                : 'bg-[#faf8f5] text-[#6c6b63] border border-[#e4e0d5] hover:text-[#171711]'
                            }`}
                          >
                            #{tag}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div className="p-3 rounded-xl bg-[#faf8f5] border border-[#e4e0d5] flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <Tag className="w-3.5 h-3.5 text-[#829953]" />
                        <span className="text-xs text-[#171711]">
                          Active Filter: <strong className="font-bold">#{selectedTag}</strong>
                        </span>
                      </div>
                      <span className="text-[10px] text-[#868379]">6 matches</span>
                    </div>
                  </div>
                </div>
              )}

              {/* ------------------------------------------------------ */}
              {/* Case 6: Private & Local-First */}
              {/* ------------------------------------------------------ */}
              {activeRule === 'Private & Local-First' && (
                <div className="space-y-4">
                  <div className="rounded-2xl bg-white border border-[#e4e0d5] p-5 shadow-sm text-left space-y-4">
                    <div className="flex items-center justify-between border-b border-[#f0ede4] pb-3">
                      <div className="flex items-center gap-2">
                        <ShieldCheck className="w-4 h-4 text-[#4e7d2d]" />
                        <span className="text-xs font-bold text-[#171711]">Privacy Architecture</span>
                      </div>
                      <span className="px-2.5 py-0.5 rounded-full bg-[#f0f6e4] text-[10px] font-bold text-[#455b2d]">
                        Zero Tracking
                      </span>
                    </div>

                    <div className="space-y-2 text-xs">
                      <div className="p-3 rounded-xl bg-[#faf8f5] border border-[#e7e4d8] flex items-center justify-between">
                        <span className="text-[#6c6b63]">Ad Trackers & Pixels</span>
                        <strong className="font-mono text-[#4e7d2d] font-bold">0 Detected</strong>
                      </div>
                      <div className="p-3 rounded-xl bg-[#faf8f5] border border-[#e7e4d8] flex items-center justify-between">
                        <span className="text-[#6c6b63]">Storage Encryption</span>
                        <strong className="font-mono text-[#171711] font-bold">AES-256 On-Device</strong>
                      </div>
                      <div className="p-3 rounded-xl bg-[#faf8f5] border border-[#e7e4d8] flex items-center justify-between">
                        <span className="text-[#6c6b63]">Data Portability</span>
                        <strong className="font-mono text-[#171711] font-bold">1-Click JSON/ZIP Export</strong>
                      </div>
                    </div>

                    <div className="flex items-center justify-between pt-2">
                      <div className="flex items-center gap-1.5 text-xs text-[#6c6b63]">
                        <Lock className="w-3.5 h-3.5 text-[#171711]" />
                        <span>Your references never leave your control</span>
                      </div>
                      <button
                        type="button"
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#d9dece] bg-white text-xs font-bold text-[#171711] hover:bg-[#faf8f5] shadow-2xs"
                      >
                        <Download size={13} />
                        <span>Export Data</span>
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Bottom Status Ticker */}
            <div className="mt-4 pt-3 border-t border-[#e7e4d8] flex items-center justify-between text-[11px] text-[#868379] px-2">
              <span className="flex items-center gap-1.5">
                <CheckCircle2 size={13} className="text-[#6e8a3f]" />
                <span>LaterBox v2.4 Engine</span>
              </span>
              <span className="font-mono text-[10px]">Ready for macOS, iOS & Web</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
