'use client';

import React from 'react';
import { WifiOff, UserX, Monitor } from 'lucide-react';

export function YourThingsStaySection() {
  const cards = [
    {
      icon: <WifiOff className="w-5 h-5 text-[#ff541c]" />,
      title: '100% OFFLINE CORE',
      description: 'LaterBox works without an internet connection.',
    },
    {
      icon: <UserX className="w-5 h-5 text-[#ff541c]" />,
      title: 'NO ACCOUNT',
      description: 'Install it and start using it.',
    },
    {
      icon: <Monitor className="w-5 h-5 text-[#ff541c]" />,
      title: 'LOCAL-FIRST',
      description: 'Your tasks and references stay on your device.',
    },
  ];

  const guaranteePills = [
    'No AI required',
    'No cloud dependency',
    'No unnecessary tracking',
    'Lightweight',
    'Built for Windows',
  ];

  return (
    <section className="py-24 sm:py-32 lg:py-36 bg-[#faf8f5] border-b border-[#e4e0d5] relative overflow-hidden">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 flex flex-col items-center text-center">
        {/* Section Headline */}
        <div className="space-y-1 sm:space-y-2">
          <h2 className="text-4xl sm:text-6xl md:text-7xl lg:text-[76px] font-black tracking-tight text-[#171711] leading-none">
            Your things stay
          </h2>
          <p className="font-serif italic font-normal text-3xl sm:text-5xl md:text-6xl lg:text-[68px] text-[#171711] leading-tight">
            where they belong.
          </p>
        </div>

        {/* Black Badge */}
        <div className="mt-6 sm:mt-8 mb-12 sm:mb-16">
          <span className="inline-flex items-center px-4 sm:px-5 py-2 rounded-full bg-[#171711] text-white text-[11px] sm:text-xs font-black tracking-widest uppercase shadow-xs select-none">
            ON YOUR COMPUTER.
          </span>
        </div>

        {/* 3 Core Architecture Cards */}
        <div className="w-full grid grid-cols-1 md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {cards.map((card, idx) => (
            <div
              key={idx}
              className="rounded-3xl sm:rounded-[32px] bg-white border border-[#e8e4da] p-8 sm:p-9 text-left shadow-[0_4px_25px_rgba(0,0,0,0.03)] hover:shadow-[0_12px_36px_rgba(0,0,0,0.06)] hover:border-[#171711]/25 transition-all duration-300 flex flex-col justify-start group"
            >
              {/* Icon Container with subtle peach/coral tint */}
              <div className="w-12 h-12 rounded-2xl bg-[#fff2ec] flex items-center justify-center mb-6 transition-transform group-hover:scale-105 duration-200">
                {card.icon}
              </div>

              {/* Title */}
              <h3 className="text-sm sm:text-[15px] font-black tracking-wider uppercase text-[#171711] mb-2.5">
                {card.title}
              </h3>

              {/* Description */}
              <p className="text-xs sm:text-sm text-[#737168] leading-relaxed font-normal">
                {card.description}
              </p>
            </div>
          ))}
        </div>

        {/* Guarantee Pills Row */}
        <div className="flex flex-wrap items-center justify-center gap-2.5 sm:gap-3.5 max-w-4xl mx-auto mt-12 sm:mt-16">
          {guaranteePills.map((pill, idx) => (
            <div
              key={idx}
              className="px-4 sm:px-5 py-2 sm:py-2.5 rounded-full bg-white border border-[#e4e0d5] text-xs sm:text-[13px] font-medium text-[#6c6b63] shadow-2xs hover:border-[#171711] hover:text-[#171711] hover:shadow-xs transition-all select-none cursor-default"
            >
              {pill}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
