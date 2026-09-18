'use client';

import React, { useEffect, useRef, useState } from 'react';
import Image from 'next/image';

interface FloatingItem {
  id: string;
  label: string;
  icon: React.ReactNode;
  initialX: number; // base desktop offset in px
  initialY: number;
  badgeStyle: string;
  cardStyle?: string;
}

export function ScrollConvergenceSection() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const [progress, setProgress] = useState(0);
  const [scaleFactor, setScaleFactor] = useState(1);

  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;
      if (width < 480) {
        setScaleFactor(0.48);
      } else if (width < 640) {
        setScaleFactor(0.62);
      } else if (width < 1024) {
        setScaleFactor(0.82);
      } else {
        setScaleFactor(1);
      }
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    let ticking = false;

    const onScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          if (!sectionRef.current) {
            ticking = false;
            return;
          }
          const rect = sectionRef.current.getBoundingClientRect();
          const windowHeight = window.innerHeight;
          const totalDistance = rect.height - windowHeight;

          if (totalDistance > 0) {
            const current = -rect.top;
            const p = Math.min(Math.max(current / totalDistance, 0), 1);
            setProgress(p);
          }
          ticking = false;
        });
        ticking = true;
      }
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  // Floating Items matching the screenshots
  const items: FloatingItem[] = [
    {
      id: 'invoice',
      label: 'Send Invoice',
      initialX: 0,
      initialY: -210,
      badgeStyle: 'border-t-4 border-[#ff6422]',
      icon: (
        <svg className="w-4 h-4 text-[#ff6422]" viewBox="0 0 24 24" fill="currentColor">
          <circle cx="12" cy="7" r="3.5" />
          <circle cx="6.5" cy="16" r="3.5" />
          <circle cx="17.5" cy="16" r="3.5" />
        </svg>
      ),
    },
    {
      id: 'screenshot',
      label: 'Screenshot.png',
      initialX: -280,
      initialY: -130,
      badgeStyle: 'border-l-4 border-[#22c55e]',
      icon: (
        <svg className="w-4 h-4 text-[#22c55e]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
        </svg>
      ),
    },
    {
      id: 'quicknote',
      label: 'Quick Note',
      initialX: 270,
      initialY: -130,
      cardStyle: 'bg-[#fefce8] border-[#fef08a]',
      badgeStyle: 'border border-[#fde047]',
      icon: (
        <span className="w-4 h-4 rounded bg-[#f59e0b] text-white font-black text-[9px] flex items-center justify-center">
          N
        </span>
      ),
    },
    {
      id: 'youtube',
      label: 'YouTube link',
      initialX: -330,
      initialY: 10,
      badgeStyle: '',
      icon: (
        <svg className="w-4 h-4 text-[#ff0000]" viewBox="0 0 24 24" fill="currentColor">
          <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
        </svg>
      ),
    },
    {
      id: 'browser',
      label: 'Browser tab',
      initialX: 330,
      initialY: 10,
      badgeStyle: '',
      icon: (
        <svg className="w-4 h-4 text-[#2563eb]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
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
      initialX: -260,
      initialY: 170,
      badgeStyle: 'border-l-4 border-[#eab308]',
      icon: (
        <svg className="w-4 h-4 text-[#eab308]" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12.01 1.485L5.73 12.36h12.55l-6.27-10.875zM4.78 14.01L1.64 19.45c-.4.69-.4 1.54 0 2.23l.11.19 6.27-10.86H1.64c-.9 0-1.64.74-1.64 1.64v1.36h4.78zm14.44 0H8.02l-3.14 5.43 3.14 5.43h11.2c.9 0 1.64-.74 1.64-1.64V15.65c0-.9-.74-1.64-1.64-1.64z" />
        </svg>
      ),
    },
    {
      id: 'pdf',
      label: 'PDF',
      initialX: 250,
      initialY: 170,
      badgeStyle: 'border-l-4 border-[#ef4444]',
      icon: (
        <svg className="w-4 h-4 text-[#ef4444]" viewBox="0 0 24 24" fill="currentColor">
          <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-9.5 8.5h-1V14H7V8.5h2.5c1.4 0 2 .6 2 1.5s-.6 1.5-2 1.5zm6.5 2H14v1.5h-1.5V8.5H16c1.4 0 2 .6 2 1.5s-.6 1.5-2 1.5h-1.5V12H16v1.5zm-5-3.5h-1V9.5h1c.6 0 1 .2 1 .5s-.4.5-1 .5z" />
        </svg>
      ),
    },
    {
      id: 'website',
      label: 'Website.psd',
      initialX: 0,
      initialY: 240,
      badgeStyle: 'border-l-4 border-[#0284c7]',
      icon: (
        <span className="w-4 h-4 rounded bg-[#001e36] text-[#38bdf8] font-black text-[9px] flex items-center justify-center">
          Ps
        </span>
      ),
    },
  ];

  // Animation calculation logic:
  // Phase 1 (progress 0.0 - 0.4): First text "Later shouldn't mean lost."
  // Phase 2 (progress 0.15 - 0.72): Items converge towards center (0, 0)
  // Phase 3 (progress 0.65 - 1.0): Final text & LaterBox icon "ONE PLACE FOR EVERYTHING LATER."

  // Stage 1 Text: Opacity fades out between 0.18 and 0.45
  const stage1Opacity = progress < 0.18 ? 1 : Math.max(0, 1 - (progress - 0.18) / 0.25);
  const stage1Scale = 1 - progress * 0.15;

  // Convergence factor for floating items (0 = outer, 1 = centered)
  const convergeFactor = progress < 0.15 ? 0 : Math.min(1, (progress - 0.15) / 0.55);
  // Ease-in-out curve
  const easeConverge = convergeFactor < 0.5 ? 2 * convergeFactor * convergeFactor : -1 + (4 - 2 * convergeFactor) * convergeFactor;

  // Items fade out when they reach the center (around progress 0.62 - 0.76)
  const itemsOpacity = progress < 0.58 ? 1 : Math.max(0, 1 - (progress - 0.58) / 0.14);
  const itemsScale = Math.max(0.2, 1 - easeConverge * 0.6);

  // Stage 2: Final text fades in from 0.68 to 0.88
  const stage2Opacity = progress < 0.68 ? 0 : Math.min(1, (progress - 0.68) / 0.2);
  const stage2Scale = 0.85 + stage2Opacity * 0.15;

  return (
    <section ref={sectionRef} className="relative h-[260vh] bg-[#f7f5ee]">
      {/* Sticky Fullscreen Canvas */}
      <div className="sticky top-0 h-screen w-full flex items-center justify-center overflow-hidden px-4 select-none">
        {/* Background Ambient Glow */}
        <div className="absolute w-[500px] h-[500px] rounded-full bg-[#e6edb0]/30 blur-3xl pointer-events-none -z-10" />

        {/* ------------------------------------------------------------- */}
        {/* STAGE 1: "Later shouldn't mean lost." */}
        {/* ------------------------------------------------------------- */}
        <div
          style={{
            opacity: stage1Opacity,
            transform: `scale(${stage1Scale})`,
            pointerEvents: stage1Opacity <= 0.05 ? 'none' : 'auto',
          }}
          className="absolute text-center max-w-2xl mx-auto px-4 z-10 transition-transform duration-75"
        >
          <h2 className="text-4xl sm:text-6xl lg:text-7xl font-black text-[#171711] tracking-tight leading-[1.08]">
            Later shouldn&apos;t <br />
            mean lost.
          </h2>
        </div>

        {/* ------------------------------------------------------------- */}
        {/* CONVERGING FLOATING CARDS */}
        {/* ------------------------------------------------------------- */}
        <div
          style={{
            opacity: itemsOpacity,
            pointerEvents: itemsOpacity <= 0.05 ? 'none' : 'auto',
          }}
          className="absolute inset-0 flex items-center justify-center pointer-events-none z-20"
        >
          {items.map((item) => {
            const currentX = item.initialX * scaleFactor * (1 - easeConverge);
            const currentY = item.initialY * scaleFactor * (1 - easeConverge);

            return (
              <div
                key={item.id}
                style={{
                  transform: `translate3d(${currentX}px, ${currentY}px, 0) scale(${itemsScale})`,
                }}
                className={`absolute inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-white border border-[#e4e0d5] shadow-lg shadow-black/[0.04] text-xs font-semibold text-[#171711] whitespace-nowrap transition-transform duration-75 ${
                  item.cardStyle || ''
                } ${item.badgeStyle || ''}`}
              >
                {item.icon}
                <span className="font-medium tracking-tight">{item.label}</span>
              </div>
            );
          })}
        </div>

        {/* ------------------------------------------------------------- */}
        {/* STAGE 2: "ONE PLACE FOR EVERYTHING LATER." + LaterBox Logo */}
        {/* ------------------------------------------------------------- */}
        <div
          style={{
            opacity: stage2Opacity,
            transform: `scale(${stage2Scale})`,
            pointerEvents: stage2Opacity <= 0.05 ? 'none' : 'auto',
          }}
          className="absolute text-center max-w-3xl mx-auto px-4 z-30 transition-transform duration-75 flex flex-col items-center justify-center space-y-5"
        >
          {/* LaterBox Brand Icon */}
          <div className="w-16 h-16 sm:w-20 sm:h-20 relative rounded-2xl overflow-hidden shadow-lg shadow-black/5 bg-[#e6edb0] p-3 flex items-center justify-center">
            <Image
              src="/branding/laterbox-icon.png"
              alt="LaterBox"
              fill
              sizes="(max-width: 640px) 64px, 80px"
              className="object-contain p-1.5"
            />
          </div>

          <h2 className="text-3xl sm:text-5xl lg:text-6xl font-black text-[#171711] tracking-tight uppercase leading-[1.08]">
            One place for <br />
            everything later.
          </h2>
        </div>
      </div>
    </section>
  );
}
