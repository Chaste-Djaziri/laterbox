'use client';

import React, { useState } from 'react';

// Stylized LaterBox Inbox/Tray Icon adhering to the Web Theme palette
function LaterBoxInboxSmallIcon({ className = 'w-6 h-6' }: { className?: string }) {
  return (
    <div className={`relative ${className} shrink-0 flex items-center justify-center select-none`}>
      <svg
        viewBox="0 0 72 64"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-2xs"
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

        {/* Crease line */}
        <path d="M12 48L26 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />
        <path d="M60 48L46 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />

        {/* Circular Clock Badge in bottom right */}
        <circle cx="52" cy="46" r="10.5" fill="#e6edb0" stroke="#171711" strokeWidth="2" />
        <circle cx="52" cy="46" r="1.5" fill="#171711" />
        <line x1="52" y1="46" x2="52" y2="40.5" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
        <line x1="52" y1="46" x2="56.5" y2="46" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
      </svg>
    </div>
  );
}

export function NotAnotherTodoListSection() {
  const [activeRow, setActiveRow] = useState<number | null>(null);

  const capabilityRows = [
    {
      category: 'FILES',
      item: 'ClientPoster.psd',
      action: 'OPEN IN PHOTOSHOP',
      feedback: 'Opening Photoshop...',
    },
    {
      category: 'LINKS',
      item: 'YouTube Video',
      action: 'OPEN IN BROWSER',
      feedback: 'Opening browser...',
    },
    {
      category: 'FOLDERS',
      item: 'Client Project',
      action: 'OPEN IN EXPLORER',
      feedback: 'Opening explorer...',
    },
    {
      category: 'TASKS',
      item: 'Send Invoice',
      action: 'DO IT',
      feedback: 'Ready to complete!',
    },
    {
      category: 'IDEAS',
      item: 'Short Film Concept',
      action: 'REMEMBER IT',
      feedback: 'Recalled from vault!',
    },
  ];

  const handleActionClick = (idx: number) => {
    setActiveRow(idx);
    setTimeout(() => {
      setActiveRow((cur) => (cur === idx ? null : cur));
    }, 2500);
  };

  return (
    <section className="bg-white text-[#171711] py-24 sm:py-32 px-4 sm:px-6 relative overflow-hidden select-none border-t border-[#f0ede4]">
      <div className="max-w-4xl mx-auto text-center">
        {/* Headline */}
        <h2 className="leading-none text-center">
          <span className="block text-5xl sm:text-7xl lg:text-8xl font-black text-[#171711] tracking-tight">
            Not another
          </span>
          <span className="block text-5xl sm:text-7xl lg:text-8xl font-serif italic text-[#171711] font-normal lowercase tracking-normal mt-1 sm:mt-2">
            to-do list.
          </span>
        </h2>

        {/* Subtitle */}
        <div className="text-center text-sm sm:text-base md:text-lg text-[#6c6b63] font-medium leading-relaxed max-w-lg mx-auto mt-6 mb-12 sm:mb-16">
          <p>LaterBox doesn&apos;t just remind you what to do.</p>
          <p>It brings back the actual thing.</p>
        </div>

        {/* 5 Demonstration Rows */}
        <div className="space-y-3.5 sm:space-y-4 max-w-3xl mx-auto">
          {capabilityRows.map((row, idx) => {
            const isTriggered = activeRow === idx;

            return (
              <div
                key={row.category}
                className="w-full rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] shadow-[0_2px_15px_rgba(0,0,0,0.02)] hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] hover:border-[#171711] transition-all px-5 sm:px-8 py-4 sm:py-5 flex items-center justify-between gap-3 sm:gap-6 group"
              >
                {/* Category Label */}
                <div className="w-16 sm:w-24 shrink-0 text-left">
                  <span className="text-[10px] sm:text-xs font-black tracking-widest uppercase text-[#9e9b92] group-hover:text-[#171711] transition-colors">
                    {row.category}
                  </span>
                </div>

                {/* Center Pipeline: Item Name -> LaterBox Tray -> Arrow */}
                <div className="flex items-center justify-center gap-2.5 sm:gap-4 flex-1 min-w-0">
                  <span className="font-bold text-sm sm:text-base text-[#171711] truncate tracking-tight">
                    {row.item}
                  </span>

                  {/* Flow Arrow */}
                  <svg
                    className="w-3.5 h-3.5 text-[#c4c0b5] shrink-0"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M5 12h14" />
                    <path d="M12 5l7 7-7 7" />
                  </svg>

                  {/* LaterBox Tray Icon */}
                  <LaterBoxInboxSmallIcon className="w-5 h-5 sm:w-6 sm:h-6" />

                  {/* Flow Arrow */}
                  <svg
                    className="w-3.5 h-3.5 text-[#c4c0b5] shrink-0"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M5 12h14" />
                    <path d="M12 5l7 7-7 7" />
                  </svg>
                </div>

                {/* Action Launch Pill Button */}
                <div className="shrink-0">
                  <button
                    type="button"
                    onClick={() => handleActionClick(idx)}
                    className={`px-3.5 sm:px-4 py-1.5 sm:py-2 rounded-full font-black text-[10px] sm:text-[11px] tracking-wider uppercase transition-all duration-200 cursor-pointer ${
                      isTriggered
                        ? 'bg-[#171711] text-white shadow-xs'
                        : 'bg-[#f4f2eb] hover:bg-[#171711] text-[#171711] hover:text-white'
                    }`}
                  >
                    {isTriggered ? row.feedback : row.action}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
