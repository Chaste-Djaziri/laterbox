// laterbox-web/src/components/marketing/HowItWorksStepsSection.tsx
'use client';

import React, { useState, useRef } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';

// Stylized LaterBox Inbox/Tray Icon adhering to the Web Theme palette (#171711, #e6edb0, #f7f5ee)
function LaterBoxInboxIcon({ className = 'w-16 h-16' }: { className?: string }) {
  return (
    <div className={`relative ${className} flex items-center justify-center select-none`}>
      <svg
        viewBox="0 0 72 64"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-sm"
      >
        {/* Envelope back container */}
        <rect x="12" y="14" width="48" height="40" rx="8" fill="#2e2e28" />

        {/* Paper sheet sticking out */}
        <rect x="18" y="8" width="36" height="22" rx="4" fill="#faf8f2" />
        {/* Paper note preview lines */}
        <line x1="24" y1="14" x2="48" y2="14" stroke="#e4e0d5" strokeWidth="2.5" strokeLinecap="round" />
        <line x1="24" y1="20" x2="38" y2="20" stroke="#e4e0d5" strokeWidth="2.5" strokeLinecap="round" />

        {/* Envelope front fold / pouch */}
        <path
          d="M12 28L36 43L60 28V46C60 50.4183 56.4183 54 52 54H20C15.5817 54 12 50.4183 12 46V28Z"
          fill="#171711"
        />

        {/* Subtle crease shadows on bottom corners */}
        <path d="M12 48L26 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />
        <path d="M60 48L46 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />

        {/* Circular Clock Badge in bottom right with Web Theme Accent (#e6edb0) */}
        <circle cx="52" cy="46" r="10.5" fill="#e6edb0" stroke="#171711" strokeWidth="2" />
        <circle cx="52" cy="46" r="1.5" fill="#171711" />
        {/* Clock Hands at 10:10 */}
        <line x1="52" y1="46" x2="52" y2="40.5" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
        <line x1="52" y1="46" x2="56.5" y2="46" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
      </svg>
    </div>
  );
}

export function HowItWorksStepsSection() {
  const [selectedWhen, setSelectedWhen] = useState<string>('Tomorrow');
  const [step4Action, setStep4Action] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const card1Ref = useRef<HTMLDivElement>(null);
  const card2Ref = useRef<HTMLDivElement>(null);
  const card3Ref = useRef<HTMLDivElement>(null);
  const card4Ref = useRef<HTMLDivElement>(null);

  const whenOptions = ['Later Today', 'Tomorrow', 'This Weekend', 'Someday'];

  // Add subtle layered depth scale as subsequent cards stack over earlier cards
  useGSAP(
    () => {
      if (typeof window === 'undefined') return;
      const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      if (prefersReducedMotion) return;

      gsap.registerPlugin(ScrollTrigger);

      // Card 1 scales slightly when Card 2 arrives
      if (card1Ref.current && card2Ref.current) {
        gsap.to(card1Ref.current, {
          scrollTrigger: {
            trigger: card2Ref.current,
            start: 'top 75%',
            end: 'top 20%',
            scrub: true,
          },
          scale: 0.94,
          opacity: 0.8,
          ease: 'power1.out',
        });
      }

      // Card 2 scales slightly when Card 3 arrives
      if (card2Ref.current && card3Ref.current) {
        gsap.to(card2Ref.current, {
          scrollTrigger: {
            trigger: card3Ref.current,
            start: 'top 75%',
            end: 'top 20%',
            scrub: true,
          },
          scale: 0.95,
          opacity: 0.85,
          ease: 'power1.out',
        });
      }

      // Card 3 scales slightly when Card 4 arrives
      if (card3Ref.current && card4Ref.current) {
        gsap.to(card3Ref.current, {
          scrollTrigger: {
            trigger: card4Ref.current,
            start: 'top 75%',
            end: 'top 20%',
            scrub: true,
          },
          scale: 0.96,
          opacity: 0.9,
          ease: 'power1.out',
        });
      }
    },
    { scope: containerRef }
  );

  return (
    <section
      id="how-it-works"
      ref={containerRef}
      className="relative bg-[#f8f7f2] border-t border-[#ede8de] py-20 sm:py-28 text-left select-none overflow-visible"
    >
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Eyebrow & Title */}
        <div className="text-center max-w-2xl mx-auto mb-14 sm:mb-20">
          <span className="inline-flex items-center px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black tracking-widest uppercase mb-4 shadow-2xs">
            HOW IT WORKS
          </span>
          <h2 className="text-3xl sm:text-5xl lg:text-6xl font-black text-[#171711] tracking-tight leading-tight">
            Four simple steps. <br className="hidden sm:inline" />Zero mental clutter.
          </h2>
        </div>

        {/* Stacked Cards Deck */}
        <div className="relative space-y-24 sm:space-y-40 pb-16 sm:pb-28">
          {/* ============================================================ */}
          {/* STEP 01 CARD: DROP IT. */}
          {/* ============================================================ */}
          <div
            style={{ top: 'calc(10vh + 0px)' }}
            className="sticky z-10 will-change-transform"
          >
            <div
              ref={card1Ref}
              className="rounded-3xl sm:rounded-[36px] bg-white border border-[#e4e0d5] shadow-[0_20px_60px_rgba(0,0,0,0.06)] p-7 sm:p-12 lg:p-16 min-h-[440px] sm:min-h-[500px] flex items-center transition-all duration-300"
            >
              <div className="grid grid-cols-1 md:grid-cols-12 gap-8 md:gap-14 items-center w-full">
                {/* Left Column Text */}
                <div className="md:col-span-6 space-y-4">
                  <span className="inline-flex items-center px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black tracking-widest uppercase">
                    STEP 01
                  </span>
                  <h3 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-none">
                    DROP IT.
                  </h3>
                  <div className="pt-2 text-base sm:text-lg font-medium text-[#6c6b63] leading-relaxed space-y-1">
                    <p>Files.</p>
                    <p>Links.</p>
                    <p>Tasks.</p>
                    <p>Ideas.</p>
                    <p>Anything.</p>
                  </div>
                </div>

                {/* Right Column Visual */}
                <div className="md:col-span-6 flex flex-col items-center justify-center relative min-h-[220px]">
                  {/* Floating Invoice.pdf card */}
                  <div className="rounded-2xl bg-white border border-[#e4e0d5] shadow-[0_15px_40px_rgba(0,0,0,0.07)] px-5 py-3.5 flex items-center gap-3 mb-8 -rotate-[3deg] hover:rotate-0 transition-transform duration-300 animate-bounce [animation-duration:3s]">
                    <div className="w-8 h-8 rounded-lg bg-[#faf8f2] border border-[#e4e0d5] flex items-center justify-center shrink-0">
                      <svg
                        className="w-4 h-4 text-[#171711]"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      >
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                        <polyline points="14 2 14 8 20 8" />
                        <line x1="16" y1="13" x2="8" y2="13" />
                        <line x1="16" y1="17" x2="8" y2="17" />
                        <polyline points="10 9 9 9 8 9" />
                      </svg>
                    </div>
                    <span className="font-bold text-sm text-[#171711] tracking-tight">Invoice.pdf</span>
                  </div>

                  {/* LaterBox Inbox Target */}
                  <div className="flex flex-col items-center gap-2">
                    <LaterBoxInboxIcon className="w-14 h-14" />
                    <span className="text-xs font-semibold text-[#9e9b92] tracking-wide">
                      Drop Here
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ============================================================ */}
          {/* STEP 02 CARD: CHOOSE WHEN. */}
          {/* ============================================================ */}
          <div
            style={{ top: 'calc(10vh + 22px)' }}
            className="sticky z-20 will-change-transform"
          >
            <div
              ref={card2Ref}
              className="rounded-3xl sm:rounded-[36px] bg-white border border-[#e4e0d5] shadow-[0_22px_65px_rgba(0,0,0,0.08)] p-7 sm:p-12 lg:p-16 min-h-[440px] sm:min-h-[500px] flex items-center transition-all duration-300"
            >
              <div className="grid grid-cols-1 md:grid-cols-12 gap-8 md:gap-14 items-center w-full">
                {/* Left Column Text */}
                <div className="md:col-span-6 space-y-4">
                  <span className="inline-flex items-center px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black tracking-widest uppercase">
                    STEP 02
                  </span>
                  <h3 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-none">
                    CHOOSE WHEN.
                  </h3>
                  <div className="pt-2 text-base sm:text-lg font-medium text-[#6c6b63] leading-relaxed space-y-1">
                    <p>Later today.</p>
                    <p>Tomorrow.</p>
                    <p>Weekend.</p>
                    <p>Someday.</p>
                    <p>Or whenever you want.</p>
                  </div>
                </div>

                {/* Right Column Visual: When Picker Modal */}
                <div className="md:col-span-6 flex items-center justify-center">
                  <div className="rounded-3xl bg-white border border-[#f0ede4] p-6 sm:p-7 shadow-[0_25px_70px_-15px_rgba(0,0,0,0.08)] w-64 sm:w-72 space-y-2">
                    <p className="text-[10px] font-black tracking-wider uppercase text-[#9e9b92] mb-3 px-1">
                      WHEN DO YOU NEED IT?
                    </p>

                    <div className="space-y-1.5">
                      {whenOptions.map((opt) => {
                        const isSelected = selectedWhen === opt;
                        return (
                          <button
                            key={opt}
                            type="button"
                            onClick={() => setSelectedWhen(opt)}
                            className={`w-full text-left px-3.5 py-2.5 rounded-xl transition-all flex items-center justify-between text-sm cursor-pointer ${
                              isSelected
                                ? 'bg-[#171711] text-white font-bold shadow-md'
                                : 'text-[#6c6b63] font-semibold hover:bg-[#faf8f2] hover:text-[#171711]'
                            }`}
                          >
                            <span>{opt}</span>
                            {isSelected && (
                              <span className="text-[10px] font-bold bg-[#e6edb0] text-[#171711] px-2 py-0.5 rounded-md tracking-wide">
                                Enter
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ============================================================ */}
          {/* STEP 03 CARD: FORGET ABOUT IT. */}
          {/* ============================================================ */}
          <div
            style={{ top: 'calc(10vh + 44px)' }}
            className="sticky z-30 will-change-transform"
          >
            <div
              ref={card3Ref}
              className="rounded-3xl sm:rounded-[36px] bg-white border border-[#e4e0d5] shadow-[0_24px_70px_rgba(0,0,0,0.09)] p-7 sm:p-12 lg:p-16 min-h-[440px] sm:min-h-[500px] flex items-center transition-all duration-300"
            >
              <div className="grid grid-cols-1 md:grid-cols-12 gap-8 md:gap-14 items-center w-full">
                {/* Left Column Text */}
                <div className="md:col-span-6 space-y-4">
                  <span className="inline-flex items-center px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black tracking-widest uppercase">
                    STEP 03
                  </span>
                  <h3 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.05]">
                    FORGET ABOUT <br />
                    IT.
                  </h3>
                  <p className="pt-2 text-base sm:text-lg font-medium text-[#6c6b63] leading-relaxed">
                    Get it out of your head without losing it.
                  </p>
                </div>

                {/* Right Column Visual: Safely Stored Status */}
                <div className="md:col-span-6 flex flex-col items-center justify-center relative min-h-[220px]">
                  <div className="absolute w-28 h-28 bg-[#e6edb0]/35 rounded-full blur-2xl pointer-events-none" />
                  <LaterBoxInboxIcon className="w-16 h-16 relative z-10" />
                  <div className="rounded-full bg-white border border-[#e4e0d5]/80 shadow-[0_8px_30px_rgba(0,0,0,0.06)] px-6 py-2.5 text-xs sm:text-sm font-semibold text-[#171711] mt-6 relative z-10">
                    Safely stored for later.
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ============================================================ */}
          {/* STEP 04 CARD: IT COMES BACK. */}
          {/* ============================================================ */}
          <div
            style={{ top: 'calc(10vh + 66px)' }}
            className="sticky z-40 will-change-transform"
          >
            <div
              ref={card4Ref}
              className="rounded-3xl sm:rounded-[36px] bg-white border border-[#e4e0d5] shadow-[0_26px_75px_rgba(0,0,0,0.11)] p-7 sm:p-12 lg:p-16 min-h-[440px] sm:min-h-[500px] flex items-center transition-all duration-300"
            >
              <div className="grid grid-cols-1 md:grid-cols-12 gap-8 md:gap-14 items-center w-full">
                {/* Left Column Text */}
                <div className="md:col-span-6 space-y-4">
                  <span className="inline-flex items-center px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black tracking-widest uppercase">
                    STEP 04
                  </span>
                  <h3 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.05]">
                    IT COMES <br />
                    BACK.
                  </h3>
                  <p className="pt-2 text-base sm:text-lg font-medium text-[#6c6b63] leading-relaxed">
                    Right when you need it.
                  </p>
                </div>

                {/* Right Column Visual: Returned Notification Card */}
                <div className="md:col-span-6 flex items-center justify-center">
                  <div className="rounded-3xl bg-white border border-[#f0ede4] p-6 sm:p-7 shadow-[0_25px_70px_-15px_rgba(0,0,0,0.08)] w-72 sm:w-80 space-y-4">
                    <div>
                      <span className="text-[10px] font-black tracking-widest uppercase text-[#6c6b63] block mb-2">
                        RETURNED FROM LATERBOX
                      </span>
                      <h4 className="text-base sm:text-lg font-black text-[#171711] tracking-tight">
                        ClientFeedback.pdf
                      </h4>
                      <p className="text-xs text-[#9e9b92] font-medium mt-1">
                        You left this for today
                      </p>
                    </div>

                    {/* Action Buttons styled in Web Theme Tokens */}
                    <div className="flex items-center gap-2.5 pt-1">
                      <button
                        type="button"
                        onClick={() => setStep4Action('opened')}
                        className="flex-1 bg-[#171711] hover:bg-black text-white font-black text-xs py-2.5 px-3.5 rounded-xl shadow-xs transition-all active:scale-95 text-center cursor-pointer"
                      >
                        {step4Action === 'opened' ? 'OPENED ✓' : '[ OPEN & DO ]'}
                      </button>
                      <button
                        type="button"
                        onClick={() => setStep4Action('snoozed')}
                        className="bg-[#f4f2eb] hover:bg-[#e9e6dd] text-[#6c6b63] hover:text-[#171711] font-bold text-xs py-2.5 px-4 rounded-xl border border-[#e4e0d5] transition-all active:scale-95 text-center cursor-pointer"
                      >
                        {step4Action === 'snoozed' ? 'SNOOZED' : '[ SNOOZE ]'}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
