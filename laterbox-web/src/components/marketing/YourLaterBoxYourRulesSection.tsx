'use client';

import React, { useState } from 'react';
import {
  Link2,
  FileText,
  CheckSquare,
  Lightbulb,
  Clock,
  Search,
} from 'lucide-react';

// Stylized LaterBox Inbox/Tray Icon adhering to the Web Theme palette
function LaterBoxTrayLogo({ className = 'w-16 h-16' }: { className?: string }) {
  return (
    <div className={`relative ${className} shrink-0 flex items-center justify-center select-none`}>
      <svg
        viewBox="0 0 72 64"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-md"
      >
        {/* Envelope back container */}
        <rect x="12" y="14" width="48" height="40" rx="8" fill="#2e2e28" />

        {/* Paper sheet sticking out */}
        <rect x="18" y="8" width="36" height="22" rx="4" fill="#faf8f2" />
        <line x1="24" y1="14" x2="48" y2="14" stroke="#e4e0d5" strokeWidth="2.5" strokeLinecap="round" />
        <line x1="24" y1="20" x2="38" y2="20" stroke="#e4e0d5" strokeWidth="2.5" strokeLinecap="round" />

        {/* Envelope front fold / pouch */}
        <path
          d="M12 28L36 43L60 28V46C60 50.4183 56.4183 54 52 54H20C15.5817 54 12 50.4183 12 46V28Z"
          fill="#171711"
        />

        {/* Crease shadows */}
        <path d="M12 48L26 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />
        <path d="M60 48L46 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />

        {/* Circular Clock Badge in bottom right with web theme accent */}
        <circle cx="52" cy="46" r="10.5" fill="#e6edb0" stroke="#171711" strokeWidth="2" />
        <circle cx="52" cy="46" r="1.5" fill="#171711" />
        <line x1="52" y1="46" x2="52" y2="40.5" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
        <line x1="52" y1="46" x2="56.5" y2="46" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
      </svg>
    </div>
  );
}

export function YourLaterBoxYourRulesSection() {
  const [activeRule, setActiveRule] = useState<string>('Close to System Tray');

  const rulesList = [
    'Launch at Windows Startup',
    'Close to System Tray',
    'Light / Dark / System Theme',
    'Global Quick Capture Shortcut',
    'Reminders',
    'Local Data',
  ];

  return (
    <section className="bg-white text-[#171711] py-24 sm:py-36 px-6 sm:px-10 lg:px-16 border-t border-[#f0ede4] select-none overflow-hidden">
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
        {/* ============================================================ */}
        {/* Left Column: Headline & Rules List */}
        {/* ============================================================ */}
        <div className="lg:col-span-5 space-y-8 text-left">
          <h2 className="leading-none text-left">
            <span className="block text-5xl sm:text-6xl lg:text-7xl font-black text-[#171711] tracking-tight">
              Your LaterBox.
            </span>
            <span className="block text-5xl sm:text-6xl lg:text-7xl font-serif italic text-[#171711] font-normal tracking-normal mt-1 sm:mt-2">
              Your rules.
            </span>
          </h2>

          {/* Rules / Preferences List */}
          <div className="pt-4 divide-y divide-[#f0ede4] border-t border-b border-[#f0ede4]">
            {rulesList.map((rule) => {
              const isActive = activeRule === rule;

              return (
                <button
                  key={rule}
                  type="button"
                  onClick={() => setActiveRule(rule)}
                  className="w-full py-4 flex items-center gap-3 text-left transition-colors group cursor-pointer"
                >
                  <span
                    className={`w-2 h-2 rounded-full transition-colors ${
                      isActive ? 'bg-[#171711]' : 'bg-[#c4c0b5] group-hover:bg-[#171711]'
                    }`}
                  />
                  <span
                    className={`text-sm sm:text-base font-semibold tracking-tight transition-colors ${
                      isActive ? 'text-[#171711] font-bold' : 'text-[#6c6b63] group-hover:text-[#171711]'
                    }`}
                  >
                    {rule}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* ============================================================ */}
        {/* Right Column: Isometric 3D Perspective Visual */}
        {/* ============================================================ */}
        <div className="lg:col-span-7 relative flex items-center justify-center min-h-[460px] sm:min-h-[520px]">
          {/* Subtle Ambient Radial Canvas */}
          <div className="absolute inset-0 bg-[#faf8f2] rounded-3xl -z-10 border border-[#f0ede4]/80" />

          {/* Tilted Perspective Desktop App Window */}
          <div
            style={{
              transform: 'perspective(1200px) rotateX(8deg) rotateY(-12deg) rotateZ(-3deg)',
            }}
            className="w-[92%] sm:w-[88%] rounded-2xl bg-white border border-[#e4e0d5] shadow-2xl p-4 sm:p-5 text-left pointer-events-none select-none transition-transform duration-500"
          >
            {/* Window Top Mini Bar */}
            <div className="flex items-center justify-between pb-3 border-b border-[#f0ede4] mb-3 text-[10px] text-[#9e9b92]">
              <div className="flex items-center gap-2">
                <span className="font-bold text-[#171711]">LaterBox</span>
              </div>
              <div className="px-3 py-1 rounded-full bg-[#faf8f5] border border-[#e4e0d5] flex items-center gap-1">
                <Search className="w-2.5 h-2.5 text-[#9e9b92]" />
                <span>Search or type a command...</span>
                <kbd className="px-1 py-0.2 rounded bg-[#ebe7dc] text-[8px] font-mono text-[#171711]">Ctrl+K</kbd>
              </div>
            </div>

            {/* Window Inner Mini Dashboard */}
            <div>
              <p className="font-black text-xs sm:text-sm text-[#171711]">Good morning, Abhishek.</p>
              <p className="text-[10px] text-[#9e9b92] mb-3">Here is what needs your attention.</p>

              <div className="grid grid-cols-2 gap-2 mb-3">
                <div className="p-2 rounded-xl bg-[#faf8f5] border border-[#f0ede4]">
                  <span className="text-[8px] font-black text-[#9e9b92] block">RETURNED TODAY</span>
                  <span className="text-xs font-bold text-[#171711] flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#171711]" /> 3 Items
                  </span>
                </div>
                <div className="p-2 rounded-xl bg-[#faf8f5] border border-[#f0ede4]">
                  <span className="text-[8px] font-black text-[#9e9b92] block">WAITING IN INBOX</span>
                  <span className="text-xs font-bold text-[#171711] flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#9e9b92]" /> 2 Items
                  </span>
                </div>
              </div>

              {/* Items Preview */}
              <div className="space-y-1.5">
                <div className="p-2 rounded-xl bg-white border border-[#f0ede4] flex items-center justify-between text-[10px]">
                  <span className="font-bold text-[#171711]">ClientFeedback.pdf</span>
                  <span className="text-[#6c6b63] font-semibold">Tomorrow, 10:00 AM</span>
                </div>
                <div className="p-2 rounded-xl bg-white border border-[#f0ede4] flex items-center justify-between text-[10px]">
                  <span className="font-bold text-[#171711]">Design Inspiration.psd</span>
                  <span className="text-[#6c6b63] font-semibold">Today, 03:00 PM</span>
                </div>
              </div>
            </div>
          </div>

          {/* ========================================================== */}
          {/* Foreground Illustration: Source Nodes -> Dotted Lines -> Tray */}
          {/* ========================================================== */}
          <div className="absolute -bottom-2 left-4 sm:left-8 z-20 flex flex-col items-center">
            {/* 4 Floating Source Nodes */}
            <div className="relative w-40 h-28 mb-1">
              {/* Node 1: Links */}
              <div className="absolute top-0 right-4 flex items-center gap-1 px-2 py-1 rounded-lg bg-[#faf8f2] border border-[#e4e0d5] text-[9px] font-bold text-[#171711] shadow-xs">
                <Link2 className="w-3 h-3 text-[#171711]" />
                <span>Links</span>
              </div>

              {/* Node 2: Files */}
              <div className="absolute top-8 left-0 flex items-center gap-1 px-2 py-1 rounded-lg bg-[#faf8f2] border border-[#e4e0d5] text-[9px] font-bold text-[#171711] shadow-xs">
                <FileText className="w-3 h-3 text-[#171711]" />
                <span>Files</span>
              </div>

              {/* Node 3: Tasks */}
              <div className="absolute bottom-6 left-6 flex items-center gap-1 px-2 py-1 rounded-lg bg-[#faf8f2] border border-[#e4e0d5] text-[9px] font-bold text-[#171711] shadow-xs">
                <CheckSquare className="w-3 h-3 text-[#171711]" />
                <span>Tasks</span>
              </div>

              {/* Node 4: Ideas */}
              <div className="absolute bottom-0 right-2 flex items-center gap-1 px-2 py-1 rounded-lg bg-[#faf8f2] border border-[#e4e0d5] text-[9px] font-bold text-[#171711] shadow-xs">
                <Lightbulb className="w-3 h-3 text-[#171711]" />
                <span>Ideas</span>
              </div>

              {/* SVG Connecting Dotted Curves */}
              <svg
                viewBox="0 0 160 110"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="absolute inset-0 w-full h-full pointer-events-none"
              >
                {/* Curves connecting to tray */}
                <path d="M125 15 Q 100 60, 90 100" stroke="#9e9b92" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.6" />
                <path d="M40 45 Q 65 75, 80 100" stroke="#9e9b92" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.6" />
                <path d="M55 75 Q 70 90, 80 105" stroke="#9e9b92" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.6" />
                <path d="M110 95 Q 95 105, 90 105" stroke="#9e9b92" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.6" />
              </svg>
            </div>

            {/* Center LaterBox Tray */}
            <div className="relative">
              <LaterBoxTrayLogo className="w-18 h-18 sm:w-20 sm:h-20" />
            </div>

            {/* Script Text Underneath */}
            <div className="text-center mt-2">
              <p className="font-serif italic text-xs sm:text-sm text-[#171711] leading-tight">
                Capture now. <br />
                Get it back later.
              </p>
            </div>
          </div>

          {/* Dotted Timeline Arc leading right */}
          <div className="absolute bottom-6 right-6 sm:right-12 pointer-events-none hidden sm:flex items-center gap-3">
            <svg width="120" height="30" viewBox="0 0 120 30" fill="none">
              <path d="M10 20 Q 60 5, 110 20" stroke="#9e9b92" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.6" />
              <circle cx="60" cy="12" r="2.5" fill="#171711" />
            </svg>
            <div className="w-6 h-6 rounded-full bg-white border border-[#e4e0d5] shadow-xs flex items-center justify-center">
              <Clock className="w-3.5 h-3.5 text-[#171711]" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
