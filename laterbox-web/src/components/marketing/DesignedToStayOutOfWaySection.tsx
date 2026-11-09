// laterbox-web/src/components/marketing/DesignedToStayOutOfWaySection.tsx
'use client';

import React from 'react';
import Link from 'next/link';
import { ArrowRight, EyeOff, BellOff, Sparkles } from 'lucide-react';
import { APP_ORIGIN } from '@/lib/auth/config';

export function DesignedToStayOutOfWaySection() {
  const pillars = [
    {
      icon: <EyeOff className="w-6 h-6 text-[#171711]" />,
      badge: 'Unobtrusive',
      title: 'Never steals your focus',
      description:
        'Save any link, article, or fleeting idea in a second. LaterBox operates quietly in the background without modal takeovers or breaking your concentration.',
    },
    {
      icon: <BellOff className="w-6 h-6 text-[#171711]" />,
      badge: 'Intentional',
      title: 'Zero notification fatigue',
      description:
        'No relentless reminder pings, guilt streaks, or badge counters. When you defer an item, it quietly retreats until the exact time you chose.',
    },
    {
      icon: <Sparkles className="w-6 h-6 text-[#171711]" />,
      badge: 'Clutter-Free',
      title: 'A clean slate every morning',
      description:
        'Only items scheduled for today appear in your active inbox. The rest stays safely archived in your Someday vault or library until you need it.',
    },
  ];

  return (
    <section className="gsap-stay-section overflow-hidden border-t border-[#e4e0d5] bg-[#faf8f5] px-4 py-24 text-[#171711] sm:px-6 sm:py-36 lg:px-8">
      <div className="mx-auto max-w-6xl text-center">
        <h2 className="gsap-stay-heading text-center leading-none">
          <span className="block text-5xl font-black tracking-tight text-[#171711] sm:text-7xl lg:text-8xl">
            Designed to stay
          </span>
          <span className="mt-1 block font-serif text-5xl font-normal italic lowercase tracking-normal text-[#171711] sm:mt-2 sm:text-7xl lg:text-8xl">
            out of your way.
          </span>
        </h2>
        <p className="gsap-stay-subheading mx-auto mt-6 max-w-xl text-sm leading-7 text-[#6c6b63] sm:text-base">
          Software shouldn&apos;t feel like a second job. LaterBox gives your mind permission to let go of open tabs and unread links.
        </p>

        {/* 3 Pillars Grid */}
        <div className="mt-14 sm:mt-18 grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8 text-left">
          {pillars.map((pillar, idx) => (
            <div
              key={idx}
              className="gsap-stay-card rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-9 shadow-xs hover:border-[#171711]/40 hover:shadow-md transition-all duration-300 flex flex-col justify-between"
            >
              <div>
                <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] border border-[#d2de8a] flex items-center justify-center mb-6 shadow-2xs">
                  {pillar.icon}
                </div>
                <span className="inline-block px-3 py-1 rounded-full bg-[#f4f2ea] text-[#6c6b63] text-[10px] font-black uppercase tracking-wider mb-3">
                  {pillar.badge}
                </span>
                <h3 className="text-xl sm:text-2xl font-black tracking-tight text-[#171711] mb-3">
                  {pillar.title}
                </h3>
                <p className="text-sm leading-relaxed text-[#6c6b63]">
                  {pillar.description}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Action Link to the Sandbox / Launch */}
        <div className="gsap-stay-cta mt-12 flex flex-wrap items-center justify-center gap-4">
          <a
            href="#live-guest-sandbox"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs sm:text-sm font-extrabold shadow-sm transition-all"
          >
            <span>Try Interactive Sandbox</span>
            <ArrowRight className="w-4 h-4" />
          </a>
          <Link
            href={`${APP_ORIGIN}/inbox?guest=1`}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white border border-[#e4e0d5] text-[#171711] hover:bg-[#ebe7dc]/50 text-xs sm:text-sm font-bold shadow-2xs transition-all"
          >
            <span>Launch Web App Free</span>
          </Link>
        </div>
      </div>
    </section>
  );
}
