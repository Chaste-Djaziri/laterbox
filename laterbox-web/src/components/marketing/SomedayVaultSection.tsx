'use client';

import React, { useState } from 'react';

export function SomedayVaultSection() {
  const somedayCards = [
    { tag: 'WATCH', title: 'A documentary' },
    { tag: 'READ', title: 'Design Systems Handbook' },
    { tag: 'IDEA', title: 'Local-First Sync Architecture' },
    { tag: 'COURSE', title: 'Machine Learning from Scratch' },
    { tag: 'PROJECT', title: 'Personal Woodworking Studio' },
  ];

  const [currentIndex, setCurrentIndex] = useState(0);

  const handleNextCard = () => {
    setCurrentIndex((prev) => (prev + 1) % somedayCards.length);
  };

  const activeCard = somedayCards[currentIndex];

  return (
    <section className="bg-white text-[#171711] py-24 sm:py-36 px-6 sm:px-10 lg:px-16 border-t border-[#f0ede4] select-none overflow-hidden">
      <div className="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">
        {/* Left Column Text */}
        <div className="lg:col-span-7 space-y-6 sm:space-y-8 text-left">
          <h2 className="leading-none text-left">
            <span className="block text-5xl sm:text-6xl lg:text-7xl font-black text-[#171711] tracking-tight">
              Some things
            </span>
            <span className="block text-5xl sm:text-6xl lg:text-7xl font-serif italic text-[#171711] font-normal lowercase tracking-normal mt-1 sm:mt-2">
              don&apos;t need a deadline.
            </span>
          </h2>

          <div className="space-y-4 pt-2">
            <p className="text-base sm:text-lg text-[#6c6b63] font-medium leading-relaxed">
              A movie. A book. An idea. A course. A project you might return to.
            </p>
            <p className="text-base sm:text-lg text-[#6c6b63] font-medium leading-relaxed">
              Not everything needs a reminder. Some things just need somewhere safe to wait.
            </p>
          </div>
        </div>

        {/* Right Column Visual: Stacked Someday Deck */}
        <div className="lg:col-span-5 flex flex-col items-center justify-center">
          <div
            onClick={handleNextCard}
            className="flex flex-col items-center cursor-pointer group select-none transition-transform duration-300 hover:scale-[1.02]"
            title="Click to cycle Someday items"
          >
            {/* Layer 5 (top-most behind) */}
            <div className="w-48 sm:w-52 h-2.5 bg-white border-t border-x border-[#e4e0d5]/40 rounded-t-xl shadow-2xs group-hover:-translate-y-1.5 transition-transform duration-300" />
            {/* Layer 4 */}
            <div className="w-52 sm:w-56 h-2.5 bg-white border-t border-x border-[#e4e0d5]/50 rounded-t-xl shadow-2xs -mt-1 group-hover:-translate-y-1 transition-transform duration-300" />
            {/* Layer 3 */}
            <div className="w-56 sm:w-60 h-2.5 bg-white border-t border-x border-[#e4e0d5]/60 rounded-t-xl shadow-2xs -mt-1 group-hover:-translate-y-0.5 transition-transform duration-300" />
            {/* Layer 2 */}
            <div className="w-60 sm:w-64 h-2.5 bg-white border-t border-x border-[#e4e0d5]/70 rounded-t-xl shadow-2xs -mt-1" />

            {/* Front Active Card */}
            <div className="w-64 sm:w-72 rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] shadow-[0_15px_40px_rgba(0,0,0,0.06)] p-6 sm:p-7 relative z-10 transition-all duration-200 group-hover:shadow-[0_20px_50px_rgba(0,0,0,0.09)] group-hover:border-[#cfcac0]">
              <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] mb-2 block">
                {activeCard.tag}
              </span>
              <h3 className="text-base sm:text-lg font-bold text-[#171711] tracking-tight">
                {activeCard.title}
              </h3>
            </div>
          </div>

          {/* Someday Badge Underneath */}
          <div className="text-center mt-6 space-y-1">
            <span className="text-[10px] sm:text-[11px] font-black tracking-widest uppercase text-[#6c6b63] block">
              SOMEDAY.
            </span>
            <p className="text-xs text-[#9e9b92] font-medium">
              No deadline. Still remembered.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
