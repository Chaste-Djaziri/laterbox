'use client';

import React, { useState, useEffect, useRef } from 'react';

type AnimationPhase = 'empty' | 'typing' | 'scheduled' | 'saved';

export function OneShortcutAwaySection() {
  const fullText = 'Send final invoice';
  const [phase, setPhase] = useState<AnimationPhase>('empty');
  const [displayedText, setDisplayedText] = useState<string>('');
  const [activePill, setActivePill] = useState<string>('Tomorrow');
  const [isManualOverride, setIsManualOverride] = useState<boolean>(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Auto-play animation cycle
  useEffect(() => {
    if (isManualOverride) return;

    let timeoutId: NodeJS.Timeout;

    if (phase === 'empty') {
      setDisplayedText('');
      setActivePill('Tomorrow');
      timeoutId = setTimeout(() => {
        setPhase('typing');
      }, 1400);
    } else if (phase === 'typing') {
      let charIndex = 0;
      const typingInterval = setInterval(() => {
        charIndex += 1;
        setDisplayedText(fullText.slice(0, charIndex));
        if (charIndex >= fullText.length) {
          clearInterval(typingInterval);
          timeoutId = setTimeout(() => {
            setPhase('scheduled');
          }, 400);
        }
      }, 70);

      return () => {
        clearInterval(typingInterval);
        clearTimeout(timeoutId);
      };
    } else if (phase === 'scheduled') {
      timeoutId = setTimeout(() => {
        setPhase('saved');
      }, 1500);
    } else if (phase === 'saved') {
      timeoutId = setTimeout(() => {
        setPhase('empty');
      }, 2200);
    }

    return () => clearTimeout(timeoutId);
  }, [phase, isManualOverride]);

  // Handle user manual interaction with pills
  const handlePillClick = (pill: string) => {
    setIsManualOverride(true);
    setActivePill(pill);
    setPhase('saved');
    setTimeout(() => {
      setIsManualOverride(false);
      setPhase('empty');
    }, 2400);
  };

  const scheduleOptions = ['Later Today', 'Tomorrow', 'Weekend', 'Someday'];

  return (
    <section
      ref={containerRef}
      className="py-24 sm:py-32 lg:py-36 bg-[#f7f5ee] border-b border-[#e4e0d5] relative overflow-hidden"
    >
      <div className="max-w-5xl mx-auto px-4 sm:px-6 flex flex-col items-center text-center">
        {/* Top Floating Keyboard Shortcut Pill */}
        <div className="inline-flex items-center justify-center px-4 sm:px-5 py-2 sm:py-2.5 rounded-xl sm:rounded-2xl bg-white border border-[#e4e0d5] shadow-[0_2px_12px_rgba(0,0,0,0.04)] mb-8 sm:mb-12 transition-transform duration-300 hover:scale-105 select-none">
          <span className="font-mono text-xs sm:text-sm font-semibold tracking-wider text-[#171711]">
            CTRL + SHIFT + L
          </span>
        </div>

        {/* Quick Capture Floating Card Stage */}
        <div className="w-full flex items-center justify-center min-h-[190px] sm:min-h-[220px] mb-12 sm:mb-16">
          <div
            className="relative w-full max-w-[440px] sm:max-w-[480px] min-h-[160px] sm:min-h-[170px] rounded-2xl sm:rounded-[26px] bg-white border-2 border-[#171711] shadow-[0_20px_60px_rgba(230,237,176,0.35),0_6px_20px_rgba(0,0,0,0.04)] overflow-hidden transition-all duration-300"
          >
            {/* Quick Capture Input & Schedule Content */}
            <div className="p-5 sm:p-6 flex flex-col justify-between min-h-[160px] sm:min-h-[170px] text-left">
              <div>
                {/* Top prompt label */}
                <p className="text-[11px] sm:text-xs font-semibold text-[#8c897f] select-none mb-2">
                  What do you want to deal with later?
                </p>

                {/* Simulated / Live Input */}
                <div className="flex items-center min-h-[32px] sm:min-h-[36px]">
                  <span className="text-lg sm:text-xl font-medium text-[#171711] tracking-tight">
                    {displayedText}
                  </span>
                  {/* Blinking Caret */}
                  <span className="inline-block w-[2px] h-5 sm:h-6 bg-[#171711] ml-1 animate-pulse" />
                </div>
              </div>

              {/* Schedule options pills */}
              <div
                className={`flex flex-wrap items-center gap-1.5 sm:gap-2 pt-3 transition-opacity duration-300 ${
                  phase === 'scheduled' || displayedText.length > 0 ? 'opacity-100' : 'opacity-0 pointer-events-none'
                }`}
              >
                {scheduleOptions.map((opt) => {
                  const isSelected = activePill === opt;
                  return (
                    <button
                      key={opt}
                      type="button"
                      onClick={() => handlePillClick(opt)}
                      className={`text-[11px] sm:text-xs font-semibold px-3 sm:px-3.5 py-1.5 rounded-full transition-all duration-200 cursor-pointer ${
                        isSelected
                          ? 'bg-[#e6edb0] text-[#171711] font-bold shadow-xs scale-102 border border-[#171711]/20'
                          : 'bg-[#f4f3ed] text-[#4a4940] hover:bg-[#e9e7df]'
                      }`}
                    >
                      {opt}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Slide-Up Green Color Fill Overlay (Revealing "SAVED.") */}
            <div
              onClick={() => {
                setPhase('empty');
                setIsManualOverride(false);
              }}
              className={`absolute inset-0 bg-[#e6edb0] flex flex-col items-center justify-center transition-transform duration-500 ease-out z-20 cursor-pointer select-none ${
                phase === 'saved' ? 'translate-y-0' : 'translate-y-full pointer-events-none'
              }`}
            >
              <span className="text-sm sm:text-base font-black tracking-widest text-[#171711]">
                SAVED.
              </span>
            </div>
          </div>
        </div>

        {/* Section Headline */}
        <div className="space-y-1 sm:space-y-2">
          <h2 className="text-4xl sm:text-6xl md:text-7xl lg:text-[76px] font-black tracking-tight text-[#171711] leading-none">
            LaterBox is always
          </h2>
          <p className="font-serif italic font-normal text-3xl sm:text-5xl md:text-6xl lg:text-[68px] text-[#171711] leading-tight">
            one shortcut away.
          </p>
        </div>
      </div>
    </section>
  );
}
