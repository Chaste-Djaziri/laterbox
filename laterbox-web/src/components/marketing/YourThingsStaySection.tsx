'use client';

import React from 'react';
import { WifiOff, UserX, Monitor } from 'lucide-react';

export function YourThingsStaySection() {
  const cards = [
    {
      icon: <WifiOff className="w-5 h-5 text-[#171711]" />,
      title: '100% OFFLINE CORE',
      description: 'LaterBox works without an internet connection.',
    },
    {
      icon: <UserX className="w-5 h-5 text-[#171711]" />,
      title: 'NO ACCOUNT',
      description: 'Install it and start using it.',
    },
    {
      icon: <Monitor className="w-5 h-5 text-[#171711]" />,
      title: 'LOCAL-FIRST',
      description: 'Your tasks and references stay on your device.',
    },
  ];

  const guaranteePills = [
    'No AI lock-in',
    'No cloud dependency',
    'No unnecessary tracking',
    'Lightweight & fast',
    'Private by default',
  ];

  return (
    <section className="gsap-things-section py-24 sm:py-32 lg:py-36 bg-[#faf8f5] border-b border-[#e4e0d5] relative overflow-hidden">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 flex flex-col items-center text-center">
        {/* Section Headline */}
        <div className="gsap-things-heading space-y-1 sm:space-y-2">
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
            ON YOUR TERMS • PRIVATE BY DESIGN
          </span>
        </div>

        {/* 3 Core Architecture Cards */}
        <div className="gsap-things-grid w-full grid grid-cols-1 md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {cards.map((card, idx) => (
            <div
              key={idx}
              className="gsap-things-card rounded-3xl sm:rounded-[32px] bg-white border border-[#e8e4da] p-8 sm:p-9 text-left shadow-[0_4px_25px_rgba(0,0,0,0.03)] hover:shadow-[0_12px_36px_rgba(0,0,0,0.06)] hover:border-[#171711]/25 transition-all duration-300 flex flex-col justify-start group"
            >
              {/* Icon Container with signature green accent */}
              <div className="w-10 h-10 rounded-xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center mb-6 shadow-2xs group-hover:scale-105 transition-transform duration-200">
                {card.icon}
              </div>

              {/* Card Title */}
              <h3 className="text-xs sm:text-sm font-black tracking-wider uppercase text-[#171711] mb-2">
                {card.title}
              </h3>

              {/* Card Description */}
              <p className="text-sm sm:text-base text-[#6c6b63] font-medium leading-relaxed">
                {card.description}
              </p>
            </div>
          ))}
        </div>

        {/* Bottom Feature Guarantee Pills */}
        <div className="flex flex-wrap items-center justify-center gap-2.5 sm:gap-3 max-w-3xl mx-auto mt-12 sm:mt-16">
          {guaranteePills.map((pill, idx) => (
            <span
              key={idx}
              className="gsap-things-pill px-4 py-2 rounded-full bg-white border border-[#e4e0d5] text-[#171711] text-xs font-bold tracking-tight shadow-2xs hover:border-[#171711] transition-colors select-none"
            >
              {pill}
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}
