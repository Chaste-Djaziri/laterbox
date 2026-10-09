'use client';

import React, { useEffect, useState } from 'react';
import Image from 'next/image';

const MOBILE_UA = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|Mobile|Silk|Kindle/i;

function isMobileDevice(): boolean {
  if (typeof navigator === 'undefined') return false;
  if (MOBILE_UA.test(navigator.userAgent)) return true;
  // iPadOS 13+ reports a desktop Mac user agent.
  return navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
}

export function MobileBlockOverlay() {
  const [blocked, setBlocked] = useState(false);

  useEffect(() => {
    if (!isMobileDevice()) return;
    setBlocked(true);
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  if (!blocked) return null;

  return (
    <div
      id="mobile-block-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="mobile-block-title"
      className="fixed inset-0 z-[2147483647] flex items-center justify-center bg-[#f7f5ee] px-6 py-10 text-[#171711]"
    >
      <div className="w-full max-w-sm rounded-3xl border border-[#171711]/10 bg-white p-8 text-center shadow-[0_20px_60px_-20px_rgba(23,23,17,0.25)]">
        <Image
          src="/branding/laterbox-icon.png"
          alt="LaterBox"
          width={64}
          height={64}
          className="mx-auto mb-6 rounded-2xl"
          priority
        />
        <h2 id="mobile-block-title" className="mb-3 text-2xl font-semibold tracking-tight">
          Mobile apps are on the way
        </h2>
        <p className="mb-6 text-sm leading-relaxed text-[#171711]/70">
          Our iOS and Android apps are still in development. For now, please use a PC to
          access LaterBox.
        </p>
        <span className="inline-flex items-center gap-2 rounded-full bg-[#e6edb0] px-4 py-2 text-xs font-medium">
          <span className="h-2 w-2 animate-pulse rounded-full bg-[#171711]" />
          In development
        </span>
      </div>
    </div>
  );
}
