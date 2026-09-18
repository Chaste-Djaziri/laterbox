'use client';

import React from 'react';

export function WontForgetItLaterSection() {
  return (
    <section className="py-28 sm:py-36 lg:py-44 bg-[#faf8f5] border-b border-[#e4e0d5] relative overflow-hidden">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 flex flex-col items-center justify-center text-center select-none">
        {/* Main 4-line Statement */}
        <div className="space-y-1 sm:space-y-2">
          {/* Black Sans-Serif lines */}
          <h2 className="text-4xl sm:text-6xl md:text-7xl lg:text-[76px] font-black tracking-tight text-[#171711] leading-[1.08]">
            You don&apos;t need to
            <br />
            do everything now.
          </h2>

          {/* Serif Italic lines */}
          <p className="font-serif italic font-normal text-3xl sm:text-5xl md:text-6xl lg:text-[68px] leading-[1.12] text-[#171711] pt-1 sm:pt-2">
            You just need to know
            <br />
            you won&apos;t forget it later.
          </p>
        </div>

        {/* Tagline */}
        <p className="text-xs sm:text-sm font-medium text-[#737168] tracking-wide mt-8 sm:mt-10">
          That&apos;s what LaterBox is for.
        </p>

        {/* Signature Green Accent Divider Bar */}
        <div className="w-16 sm:w-20 h-[3px] bg-[#cfdb84] rounded-full mx-auto mt-6 sm:mt-7" />
      </div>
    </section>
  );
}
