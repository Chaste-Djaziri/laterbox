// laterbox-web/src/components/marketing/ScrollConvergenceSection.tsx
'use client';

import React, { useRef, useState, useEffect } from 'react';
import Image from 'next/image';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';

interface FloatingItem {
  id: string;
  label: string;
  icon: React.ReactNode;
  initialX: number; // base desktop offset in px
  initialY: number;
  badgeStyle: string;
  cardStyle?: string;
}

const items: FloatingItem[] = [
  {
    id: 'invoice',
    label: 'Send Invoice',
    initialX: 0,
    initialY: -280,
    badgeStyle: 'border-t-4 border-[#ff6422]',
    icon: (
      <svg className="w-5 h-5 sm:w-6 sm:h-6 text-[#ff6422] shrink-0" viewBox="0 0 24 24" fill="currentColor">
        <circle cx="12" cy="7" r="3.5" />
        <circle cx="6.5" cy="16" r="3.5" />
        <circle cx="17.5" cy="16" r="3.5" />
      </svg>
    ),
  },
  {
    id: 'screenshot',
    label: 'Screenshot.png',
    initialX: -390,
    initialY: -160,
    badgeStyle: 'border-l-4 border-[#22c55e]',
    icon: (
      <svg className="w-5 h-5 sm:w-6 sm:h-6 text-[#22c55e] shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
        <circle cx="12" cy="12" r="3" />
        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
      </svg>
    ),
  },
  {
    id: 'quicknote',
    label: 'Quick Note',
    initialX: 380,
    initialY: -160,
    cardStyle: 'bg-[#fefce8] border-[#fef08a]',
    badgeStyle: 'border-l-4 border-[#f59e0b]',
    icon: (
      <span className="w-5 h-5 sm:w-6 sm:h-6 rounded-md bg-[#f59e0b] text-white font-black text-xs sm:text-sm flex items-center justify-center shrink-0">
        N
      </span>
    ),
  },
  {
    id: 'youtube',
    label: 'YouTube link',
    initialX: -470,
    initialY: 15,
    badgeStyle: 'border-l-4 border-[#ff0000]',
    icon: (
      <svg className="w-5 h-5 sm:w-6 sm:h-6 text-[#ff0000] shrink-0" viewBox="0 0 24 24" fill="currentColor">
        <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
      </svg>
    ),
  },
  {
    id: 'browser',
    label: 'Browser tab',
    initialX: 470,
    initialY: 15,
    badgeStyle: 'border-l-4 border-[#2563eb]',
    icon: (
      <svg className="w-5 h-5 sm:w-6 sm:h-6 text-[#2563eb] shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
        <circle cx="12" cy="12" r="10" />
        <circle cx="12" cy="12" r="4" />
        <line x1="4.93" y1="4.93" x2="9.17" y2="9.17" />
        <line x1="14.83" y1="14.83" x2="19.07" y2="19.07" />
        <line x1="14.83" y1="9.17" x2="19.07" y2="4.93" />
        <line x1="4.93" y1="19.07" x2="9.17" y2="14.83" />
      </svg>
    ),
  },
  {
    id: 'clientfolder',
    label: 'Client Folder',
    initialX: -370,
    initialY: 200,
    badgeStyle: 'border-l-4 border-[#eab308]',
    icon: (
      <svg className="w-5 h-5 sm:w-6 sm:h-6 text-[#eab308] shrink-0" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12.01 1.485L5.73 12.36h12.55l-6.27-10.875zM4.78 14.01L1.64 19.45c-.4.69-.4 1.54 0 2.23l.11.19 6.27-10.86H1.64c-.9 0-1.64.74-1.64 1.64v1.36h4.78zm14.44 0H8.02l-3.14 5.43 3.14 5.43h11.2c.9 0 1.64-.74 1.64-1.64V15.65c0-.9-.74-1.64-1.64-1.64z" />
      </svg>
    ),
  },
  {
    id: 'pdf',
    label: 'PDF',
    initialX: 360,
    initialY: 200,
    badgeStyle: 'border-l-4 border-[#ef4444]',
    icon: (
      <svg className="w-5 h-5 sm:w-6 sm:h-6 text-[#ef4444] shrink-0" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-9.5 8.5h-1V14H7V8.5h2.5c1.4 0 2 .6 2 1.5s-.6 1.5-2 1.5zm6.5 2H14v1.5h-1.5V8.5H16c1.4 0 2 .6 2 1.5s-.6 1.5-2 1.5h-1.5V12H16v1.5zm-5-3.5h-1V9.5h1c.6 0 1 .2 1 .5s-.4.5-1 .5z" />
      </svg>
    ),
  },
  {
    id: 'website',
    label: 'Website.psd',
    initialX: 0,
    initialY: 290,
    badgeStyle: 'border-l-4 border-[#0284c7]',
    icon: (
      <span className="w-5 h-5 sm:w-6 sm:h-6 rounded-md bg-[#001e36] text-[#38bdf8] font-black text-xs sm:text-sm flex items-center justify-center shrink-0">
        Ps
      </span>
    ),
  },
];

export function ScrollConvergenceSection() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const stage1Ref = useRef<HTMLDivElement>(null);
  const stage2Ref = useRef<HTMLDivElement>(null);
  const cardRefs = useRef<(HTMLDivElement | null)[]>([]);
  const [scaleFactor, setScaleFactor] = useState(1);

  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;
      if (width < 480) {
        setScaleFactor(0.46);
      } else if (width < 640) {
        setScaleFactor(0.60);
      } else if (width < 1024) {
        setScaleFactor(0.80);
      } else {
        setScaleFactor(1);
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useGSAP(
    () => {
      if (typeof window === 'undefined') return;

      const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      if (prefersReducedMotion) return;

      gsap.registerPlugin(ScrollTrigger);

      // Create a smooth, GPU-accelerated scrubbed timeline
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: sectionRef.current,
          start: 'top top',
          end: 'bottom bottom',
          scrub: 1.1, // Buttery smooth momentum scrub
        },
      });

      // 1. Stage 1 Text: "Later shouldn't mean lost." recedes & fades out
      tl.to(
        stage1Ref.current,
        {
          opacity: 0,
          scale: 0.88,
          duration: 0.35,
          ease: 'power2.inOut',
        },
        0
      );

      // 2. Large Floating Cards: Converge gracefully into center point (0, 0)
      cardRefs.current.forEach((cardEl, idx) => {
        if (!cardEl) return;
        const item = items[idx];
        const startX = item.initialX * scaleFactor;
        const startY = item.initialY * scaleFactor;

        tl.fromTo(
          cardEl,
          {
            x: startX,
            y: startY,
            scale: 1,
            opacity: 1,
          },
          {
            x: 0,
            y: 0,
            scale: 0.18,
            opacity: 0,
            duration: 0.60,
            ease: 'power2.inOut',
          },
          0.08
        );
      });

      // 3. Stage 2: LaterBox monogram cube & "ONE PLACE FOR EVERYTHING LATER." emerges
      tl.fromTo(
        stage2Ref.current,
        {
          opacity: 0,
          scale: 0.80,
        },
        {
          opacity: 1,
          scale: 1,
          duration: 0.35,
          ease: 'power2.out',
        },
        0.62
      );
    },
    { scope: sectionRef, dependencies: [scaleFactor] }
  );

  return (
    <section ref={sectionRef} className="relative h-[280vh] bg-[#f7f5ee]">
      {/* Sticky Fullscreen Canvas */}
      <div className="sticky top-0 h-screen w-full flex items-center justify-center overflow-hidden px-4 select-none">
        {/* Background Ambient Glow */}
        <div className="absolute w-[600px] h-[600px] rounded-full bg-[#e6edb0]/35 blur-3xl pointer-events-none -z-10" />

        {/* ------------------------------------------------------------- */}
        {/* STAGE 1: "Later shouldn't mean lost." */}
        {/* ------------------------------------------------------------- */}
        <div
          ref={stage1Ref}
          className="absolute text-center max-w-3xl mx-auto px-4 z-10 will-change-transform"
        >
          <h2 className="text-4xl sm:text-6xl lg:text-7xl font-black text-[#171711] tracking-tight leading-[1.08]">
            Later shouldn&apos;t <br />
            mean lost.
          </h2>
        </div>

        {/* ------------------------------------------------------------- */}
        {/* CONVERGING LARGE FLOATING CARDS */}
        {/* ------------------------------------------------------------- */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-20">
          {items.map((item, index) => {
            const startX = item.initialX * scaleFactor;
            const startY = item.initialY * scaleFactor;

            return (
              <div
                key={item.id}
                ref={(el) => {
                  cardRefs.current[index] = el;
                }}
                style={{
                  transform: `translate3d(${startX}px, ${startY}px, 0)`,
                }}
                className={`absolute inline-flex items-center gap-3 sm:gap-4 px-5 py-3 sm:px-7 sm:py-4.5 rounded-2xl sm:rounded-3xl bg-white/95 backdrop-blur-md border border-[#e4e0d5] shadow-[0_16px_40px_rgba(0,0,0,0.07)] text-sm sm:text-lg font-bold text-[#171711] whitespace-nowrap will-change-transform ${
                  item.cardStyle || ''
                } ${item.badgeStyle || ''}`}
              >
                {item.icon}
                <span className="font-bold tracking-tight text-[#171711]">{item.label}</span>
              </div>
            );
          })}
        </div>

        {/* ------------------------------------------------------------- */}
        {/* STAGE 2: "ONE PLACE FOR EVERYTHING LATER." + LaterBox Logo */}
        {/* ------------------------------------------------------------- */}
        <div
          ref={stage2Ref}
          style={{ opacity: 0 }}
          className="absolute text-center max-w-3xl mx-auto px-4 z-30 flex flex-col items-center justify-center space-y-6 will-change-transform pointer-events-none"
        >
          {/* LaterBox Brand Icon */}
          <div className="w-20 h-20 sm:w-24 sm:h-24 relative rounded-2xl sm:rounded-3xl overflow-hidden shadow-[0_16px_40px_rgba(0,0,0,0.08)] border border-[#cbd79c] bg-[#e6edb0] p-3 flex items-center justify-center">
            <Image
              src="/branding/laterbox-icon.png"
              alt="LaterBox"
              fill
              sizes="(max-width: 640px) 80px, 96px"
              className="object-contain p-2"
            />
          </div>

          <h2 className="text-3xl sm:text-6xl lg:text-7xl font-black text-[#171711] tracking-tight uppercase leading-[1.06]">
            One place for <br />
            everything later.
          </h2>
        </div>
      </div>
    </section>
  );
}
