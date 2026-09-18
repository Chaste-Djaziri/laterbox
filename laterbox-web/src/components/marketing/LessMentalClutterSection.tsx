'use client';

import React from 'react';

// Stylized LaterBox Tray/Folder Icon with Clock Badge
function LaterBoxTrayLogo({ className = 'w-16 h-16' }: { className?: string }) {
  return (
    <div className={`relative ${className} shrink-0 flex items-center justify-center select-none`}>
      <svg
        viewBox="0 0 72 64"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-[0_12px_28px_rgba(230,237,176,0.25)]"
      >
        {/* Envelope back paper sheet */}
        <rect x="16" y="8" width="40" height="30" rx="5" fill="#faf8f2" />
        <path d="M16 12L36 26L56 12" stroke="#e4e0d5" strokeWidth="2.5" strokeLinecap="round" />

        {/* Charcoal folder/pouch container */}
        <path
          d="M10 24C10 20.6863 12.6863 18 16 18H28L34 23H56C59.3137 23 62 25.6863 62 29V46C62 50.4183 58.4183 54 54 54H18C13.5817 54 10 50.4183 10 46V24Z"
          fill="#24231d"
        />

        {/* Crease / front pocket contour */}
        <path
          d="M10 32L36 46L62 32"
          stroke="#000000"
          strokeWidth="1.5"
          strokeOpacity="0.3"
        />

        {/* Circular Clock Badge in bottom right with signature green accent */}
        <circle cx="53" cy="46" r="10.5" fill="#e6edb0" stroke="#171711" strokeWidth="2.5" />
        <circle cx="53" cy="46" r="1.5" fill="#171711" />
        <line x1="53" y1="46" x2="53" y2="40.5" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
        <line x1="53" y1="46" x2="57.5" y2="46" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
      </svg>
    </div>
  );
}

export function LessMentalClutterSection() {
  const clutterItems = [
    'Tabs',
    'Bookmarks',
    'Notes',
    'Reminders',
    'Desktop clutter',
  ];

  return (
    <section className="py-24 sm:py-32 lg:py-36 bg-[#171711] text-white border-b border-[#2e2d28] relative overflow-hidden">
      {/* Subtle ambient background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[400px] bg-gradient-to-b from-[#2a2923]/40 to-transparent rounded-full blur-3xl pointer-events-none" />

      <div className="max-w-5xl mx-auto px-4 sm:px-6 relative z-10 flex flex-col items-center">
        {/* Visual Comparison: Clutter Stack vs LaterBox Tray Logo */}
        <div className="flex items-center justify-center gap-4 sm:gap-6 mb-12 sm:mb-16">
          {/* Left: Clutter pills stack */}
          <div className="flex flex-col gap-2 sm:gap-2.5">
            {clutterItems.map((item) => (
              <div
                key={item}
                className="w-36 sm:w-44 py-2 sm:py-2.5 px-3 sm:px-4 rounded-xl bg-[#22211b] border border-white/[0.08] text-xs sm:text-[13px] font-medium text-[#8c897f] text-center shadow-xs transition-all duration-300 hover:border-white/20 hover:text-[#d6d3c9] select-none"
              >
                {item}
              </div>
            ))}
          </div>

          {/* Center: "vs" divider */}
          <span className="font-serif italic text-xs sm:text-sm text-[#737168] mx-2 sm:mx-6 select-none">
            vs
          </span>

          {/* Right: LaterBox Tray Icon */}
          <div className="p-3 sm:p-4 rounded-2xl bg-white/[0.03] border border-white/10 shadow-2xl flex items-center justify-center transition-transform hover:scale-105 duration-300">
            <LaterBoxTrayLogo className="w-14 h-14 sm:w-16 sm:h-16" />
          </div>
        </div>

        {/* Section Headline */}
        <div className="text-center max-w-3xl mx-auto space-y-1 sm:space-y-2">
          <h2 className="text-4xl sm:text-6xl md:text-7xl lg:text-[76px] font-black tracking-tight leading-none text-white">
            Less mental clutter.
          </h2>
          <p className="font-serif italic font-normal text-3xl sm:text-5xl md:text-6xl lg:text-[68px] leading-tight text-white">
            Not more software clutter.
          </p>
          <p className="text-xs sm:text-sm md:text-base text-[#8c897f] max-w-xl mx-auto leading-relaxed pt-5 sm:pt-7 font-normal">
            LaterBox is designed to be a quiet utility — fast when you need it and out of the way when you don&apos;t.
          </p>
        </div>
      </div>
    </section>
  );
}
