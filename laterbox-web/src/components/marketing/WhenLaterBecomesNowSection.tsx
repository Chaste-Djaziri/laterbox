'use client';

import React, { useState } from 'react';

export function WhenLaterBecomesNowSection() {
  const [actionStatus, setActionStatus] = useState<string | null>(null);

  const handleOpen = () => {
    setActionStatus('opened');
    setTimeout(() => setActionStatus(null), 3500);
  };

  const handleNotYet = () => {
    setActionStatus('snoozed');
    setTimeout(() => setActionStatus(null), 3500);
  };

  return (
    <section className="bg-[#171715] text-white py-24 sm:py-36 px-4 sm:px-6 relative overflow-hidden select-none border-t border-[#2a2a27]">
      {/* Subtle Ambient Radial Glow behind the headline (Web Theme Accent #e6edb0) */}
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[450px] bg-[#e6edb0]/[0.07] blur-[120px] pointer-events-none rounded-full" />

      <div className="max-w-4xl mx-auto text-center relative z-10 space-y-12 sm:space-y-16">
        {/* Headline */}
        <h2 className="leading-none">
          <span className="block text-5xl sm:text-7xl lg:text-8xl font-black text-white tracking-tight">
            When later
          </span>
          <span className="block text-5xl sm:text-7xl lg:text-8xl font-serif italic text-[#e6edb0] font-normal lowercase tracking-normal leading-tight mt-1 sm:mt-2">
            becomes now.
          </span>
        </h2>

        {/* Center Mockup Card */}
        <div className="max-w-md w-full mx-auto rounded-[28px] sm:rounded-3xl bg-[#232321] border border-[#333330] p-7 sm:p-8 shadow-[0_30px_90px_rgba(0,0,0,0.6)] text-left transition-all duration-300 hover:border-[#444440] hover:shadow-[0_35px_100px_rgba(0,0,0,0.7)] group">
          {/* Top Tag adhering to Web Theme */}
          <span className="text-[10px] sm:text-[11px] font-black tracking-widest uppercase text-[#e6edb0] mb-3.5 block">
            RETURNED FROM LATERBOX
          </span>

          {/* Subtitle */}
          <span className="text-[10px] sm:text-[11px] font-bold tracking-wider uppercase text-[#8e8d87] mb-1.5 block">
            YOU LEFT THIS FOR TODAY
          </span>

          {/* Main Title */}
          <h3 className="text-xl sm:text-2xl font-bold text-white tracking-tight mb-1 block">
            Finish Website Design
          </h3>

          {/* Attachment Context */}
          <span className="text-sm text-[#8e8d87] font-medium mb-6 block">
            Website.psd
          </span>

          {/* Scheduled Time */}
          <span className="text-xs font-semibold text-[#6c6b63] mb-4 block">
            10:00 AM
          </span>

          {/* Action Buttons */}
          <div className="flex items-center gap-3 pt-1">
            <button
              type="button"
              onClick={handleOpen}
              className="bg-[#e6edb0] hover:bg-[#d8e09e] text-[#171711] font-black text-xs py-2.5 px-4 rounded-xl shadow-sm transition-all active:scale-95 cursor-pointer"
            >
              {actionStatus === 'opened' ? 'OPENED ✓' : '[ OPEN & DO ]'}
            </button>
            <button
              type="button"
              onClick={handleNotYet}
              className="text-[#8e8d87] hover:text-white font-bold text-xs py-2.5 px-3 rounded-xl transition-all active:scale-95 hover:bg-white/5 cursor-pointer"
            >
              {actionStatus === 'snoozed' ? 'SNOOZED FOR 1H' : '[ NOT YET ]'}
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
