'use client';

import React, { useState, useEffect, useRef } from 'react';

// Stylized LaterBox Inbox/Tray Icon matching the brand screenshots
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
        <rect x="12" y="14" width="48" height="40" rx="8" fill="#ff7a45" />

        {/* Paper sheet sticking out */}
        <rect x="18" y="8" width="36" height="22" rx="4" fill="#fff9f5" />
        {/* Paper note preview lines */}
        <line x1="24" y1="14" x2="48" y2="14" stroke="#ffdec9" strokeWidth="2.5" strokeLinecap="round" />
        <line x1="24" y1="20" x2="38" y2="20" stroke="#ffdec9" strokeWidth="2.5" strokeLinecap="round" />

        {/* Envelope front fold / pouch */}
        <path
          d="M12 28L36 43L60 28V46C60 50.4183 56.4183 54 52 54H20C15.5817 54 12 50.4183 12 46V28Z"
          fill="#ff541c"
        />

        {/* Subtle crease shadows on bottom corners */}
        <path d="M12 48L26 36" stroke="#d9410f" strokeWidth="1.5" strokeOpacity="0.4" />
        <path d="M60 48L46 36" stroke="#d9410f" strokeWidth="1.5" strokeOpacity="0.4" />

        {/* Circular Clock Badge in bottom right */}
        <circle cx="52" cy="46" r="10.5" fill="#ff541c" stroke="#ffffff" strokeWidth="2.5" />
        <circle cx="52" cy="46" r="1.5" fill="#ffffff" />
        {/* Clock Hands at 10:10 */}
        <line x1="52" y1="46" x2="52" y2="40.5" stroke="#ffffff" strokeWidth="2" strokeLinecap="round" />
        <line x1="52" y1="46" x2="56.5" y2="46" stroke="#ffffff" strokeWidth="2" strokeLinecap="round" />
      </svg>
    </div>
  );
}

export function HowItWorksStepsSection() {
  const [activeStep, setActiveStep] = useState<number>(1);
  const [selectedWhen, setSelectedWhen] = useState<string>('Tomorrow');
  const [step4Action, setStep4Action] = useState<string | null>(null);

  const step1Ref = useRef<HTMLDivElement>(null);
  const step2Ref = useRef<HTMLDivElement>(null);
  const step3Ref = useRef<HTMLDivElement>(null);
  const step4Ref = useRef<HTMLDivElement>(null);

  // Scroll listener / observer to highlight the step closest to viewport center
  useEffect(() => {
    const stepRefs = [step1Ref, step2Ref, step3Ref, step4Ref];

    const handleScroll = () => {
      const viewportCenter = window.innerHeight * 0.45;
      let closestStep = 1;
      let minDistance = Infinity;

      stepRefs.forEach((ref, index) => {
        if (ref.current) {
          const rect = ref.current.getBoundingClientRect();
          const stepCenter = rect.top + rect.height / 2;
          const distance = Math.abs(stepCenter - viewportCenter);
          if (distance < minDistance) {
            minDistance = distance;
            closestStep = index + 1;
          }
        }
      });

      setActiveStep(closestStep);
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll(); // Initial check

    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  const whenOptions = ['Later Today', 'Tomorrow', 'This Weekend', 'Someday'];

  return (
    <section className="bg-white border-t border-[#f0ede4] text-left select-none overflow-hidden">
      <div className="max-w-6xl mx-auto px-6 sm:px-10 lg:px-16">
        {/* ============================================================ */}
        {/* STEP 01: DROP IT. */}
        {/* ============================================================ */}
        <div
          ref={step1Ref}
          className={`grid grid-cols-1 md:grid-cols-12 gap-10 md:gap-16 items-center min-h-[75vh] sm:min-h-[85vh] py-20 sm:py-28 transition-all duration-500 ${
            activeStep === 1 ? 'opacity-100' : 'opacity-30'
          }`}
        >
          {/* Left Column Text */}
          <div className="md:col-span-6 space-y-4">
            <span className="text-xs font-black tracking-widest uppercase text-[#ff541c] block">
              STEP 01
            </span>
            <h2 className="text-5xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-none">
              DROP IT.
            </h2>
            <div className="pt-2 text-base sm:text-lg font-medium text-[#6c6b63] leading-relaxed space-y-1">
              <p>Files.</p>
              <p>Links.</p>
              <p>Tasks.</p>
              <p>Ideas.</p>
              <p>Anything.</p>
            </div>
          </div>

          {/* Right Column Visual */}
          <div className="md:col-span-6 flex flex-col items-center justify-center relative min-h-[260px]">
            {/* Floating Invoice.pdf card */}
            <div className="rounded-2xl bg-white border border-[#e4e0d5] shadow-[0_15px_40px_rgba(0,0,0,0.07)] px-4 py-3 flex items-center gap-3 mb-8 -rotate-[3deg] hover:rotate-0 transition-transform duration-300 animate-bounce [animation-duration:3s]">
              {/* PDF Document Icon */}
              <div className="w-8 h-8 rounded-lg bg-red-50 border border-red-100 flex items-center justify-center shrink-0">
                <svg
                  className="w-4 h-4 text-[#ef4444]"
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

        {/* ============================================================ */}
        {/* STEP 02: CHOOSE WHEN. */}
        {/* ============================================================ */}
        <div
          ref={step2Ref}
          className={`grid grid-cols-1 md:grid-cols-12 gap-10 md:gap-16 items-center min-h-[75vh] sm:min-h-[85vh] py-20 sm:py-28 transition-all duration-500 ${
            activeStep === 2 ? 'opacity-100' : 'opacity-30'
          }`}
        >
          {/* Left Column Text */}
          <div className="md:col-span-6 space-y-4">
            <span className="text-xs font-black tracking-widest uppercase text-[#ff541c] block">
              STEP 02
            </span>
            <h2 className="text-5xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-none">
              CHOOSE WHEN.
            </h2>
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
                      className={`w-full text-left px-3.5 py-2.5 rounded-xl transition-all flex items-center justify-between text-sm ${
                        isSelected
                          ? 'bg-[#ff541c] text-white font-bold shadow-md shadow-[#ff541c]/25'
                          : 'text-[#6c6b63] font-semibold hover:bg-[#faf8f2]'
                      }`}
                    >
                      <span>{opt}</span>
                      {isSelected && (
                        <span className="text-[10px] font-bold bg-white/20 text-white px-2 py-0.5 rounded-md tracking-wide">
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

        {/* ============================================================ */}
        {/* STEP 03: FORGET ABOUT IT. */}
        {/* ============================================================ */}
        <div
          ref={step3Ref}
          className={`grid grid-cols-1 md:grid-cols-12 gap-10 md:gap-16 items-center min-h-[75vh] sm:min-h-[85vh] py-20 sm:py-28 transition-all duration-500 ${
            activeStep === 3 ? 'opacity-100' : 'opacity-30'
          }`}
        >
          {/* Left Column Text */}
          <div className="md:col-span-6 space-y-4">
            <span className="text-xs font-black tracking-widest uppercase text-[#ff541c] block">
              STEP 03
            </span>
            <h2 className="text-5xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.05]">
              FORGET ABOUT <br />
              IT.
            </h2>
            <p className="pt-2 text-base sm:text-lg font-medium text-[#6c6b63] leading-relaxed">
              Get it out of your head without losing it.
            </p>
          </div>

          {/* Right Column Visual: Safely Stored Status */}
          <div className="md:col-span-6 flex flex-col items-center justify-center relative min-h-[220px]">
            {/* Soft Ambient Glow */}
            <div className="absolute w-28 h-28 bg-[#ff541c]/15 rounded-full blur-2xl pointer-events-none" />

            {/* Inbox Icon */}
            <LaterBoxInboxIcon className="w-16 h-16 relative z-10" />

            {/* Floating Confirmation Pill */}
            <div className="rounded-full bg-white border border-[#e4e0d5]/80 shadow-[0_8px_30px_rgba(0,0,0,0.06)] px-6 py-2.5 text-xs sm:text-sm font-semibold text-[#6c6b63] mt-6 relative z-10">
              Safely stored for later.
            </div>
          </div>
        </div>

        {/* ============================================================ */}
        {/* STEP 04: IT COMES BACK. */}
        {/* ============================================================ */}
        <div
          ref={step4Ref}
          className={`grid grid-cols-1 md:grid-cols-12 gap-10 md:gap-16 items-center min-h-[75vh] sm:min-h-[85vh] py-20 sm:py-28 transition-all duration-500 ${
            activeStep === 4 ? 'opacity-100' : 'opacity-30'
          }`}
        >
          {/* Left Column Text */}
          <div className="md:col-span-6 space-y-4">
            <span className="text-xs font-black tracking-widest uppercase text-[#ff541c] block">
              STEP 04
            </span>
            <h2 className="text-5xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.05]">
              IT COMES <br />
              BACK.
            </h2>
            <p className="pt-2 text-base sm:text-lg font-medium text-[#6c6b63] leading-relaxed">
              Right when you need it.
            </p>
          </div>

          {/* Right Column Visual: Returned Notification Card */}
          <div className="md:col-span-6 flex items-center justify-center">
            <div className="rounded-3xl bg-white border border-[#f0ede4] p-6 sm:p-7 shadow-[0_25px_70px_-15px_rgba(0,0,0,0.08)] w-72 sm:w-80 space-y-4">
              <div>
                <span className="text-[10px] font-black tracking-widest uppercase text-[#ff541c] block mb-2">
                  RETURNED FROM LATERBOX
                </span>
                <h3 className="text-base sm:text-lg font-black text-[#171711] tracking-tight">
                  ClientFeedback.pdf
                </h3>
                <p className="text-xs text-[#9e9b92] font-medium mt-1">
                  You left this for today
                </p>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2.5 pt-1">
                <button
                  type="button"
                  onClick={() => setStep4Action('opened')}
                  className="flex-1 bg-[#ff541c] hover:bg-[#e64610] text-white font-black text-xs py-2.5 px-3.5 rounded-xl shadow-xs transition-all active:scale-95 text-center cursor-pointer"
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
    </section>
  );
}
