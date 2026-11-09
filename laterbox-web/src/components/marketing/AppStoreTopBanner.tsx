// laterbox-web/src/components/marketing/AppStoreTopBanner.tsx
'use client';

import React, { useState, useEffect } from 'react';
import Image from 'next/image';
import { Star, X } from 'lucide-react';

const APP_STORE_URL = 'https://apps.apple.com/us/app/laterbox-save-for-later/id6804139119';
const STORAGE_KEY = 'laterbox_hide_appstore_banner';

export function AppStoreTopBanner() {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    // Only show if not previously dismissed in this session
    try {
      const dismissed = sessionStorage.getItem(STORAGE_KEY);
      if (!dismissed) {
        setIsVisible(true);
      }
    } catch {
      setIsVisible(true);
    }
  }, []);

  const handleDismiss = () => {
    setIsVisible(false);
    try {
      sessionStorage.setItem(STORAGE_KEY, 'true');
    } catch {
      // Ignore sessionStorage errors
    }
  };

  if (!isVisible) return null;

  return (
    <aside
      aria-label="LaterBox on Apple App Store"
      className="relative z-40 bg-[#12140f] text-white border-b border-[#252a1e] transition-all"
    >
      <div className="mx-auto flex max-w-[1320px] items-center justify-between gap-3 px-3 py-2 sm:px-6 sm:py-2.5">
        {/* Left: Dismiss + App Info */}
        <div className="flex items-center gap-2.5 sm:gap-3.5 min-w-0">
          <button
            type="button"
            onClick={handleDismiss}
            aria-label="Dismiss App Store banner"
            className="p-1 rounded-lg text-[#858d7c] hover:text-white hover:bg-white/10 transition-colors shrink-0 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>

          {/* App Icon in iOS Squircle */}
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="relative flex h-9 w-9 sm:h-10 sm:w-10 shrink-0 items-center justify-center overflow-hidden rounded-[10px] sm:rounded-xl border border-[#cbd79c]/40 bg-[#e6edb0] shadow-xs transition-transform hover:scale-105"
            aria-label="View LaterBox on Apple App Store"
          >
            <Image
              src="/branding/laterbox-icon.png"
              alt="LaterBox iOS App Icon"
              fill
              priority
              sizes="40px"
              className="object-contain p-1"
            />
          </a>

          {/* App Description */}
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <a
                href={APP_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="truncate font-extrabold text-xs sm:text-sm text-white hover:text-[#e6edb0] transition-colors"
              >
                LaterBox: Save For Later
              </a>
              <span className="hidden md:inline-flex items-center gap-0.5 px-2 py-0.5 rounded-full bg-[#20251a] text-[#cbd79c] text-[10px] font-bold">
                <Star className="w-2.5 h-2.5 fill-current" />
                5.0 on App Store
              </span>
            </div>
            <p className="truncate text-[11px] sm:text-xs text-[#959d8c]">
              <span className="sm:hidden">Offline bookmarks &amp; reading • Free</span>
              <span className="hidden sm:inline">Offline-first bookmark manager &amp; reading list for iOS &amp; iPadOS</span>
            </p>
          </div>
        </div>

        {/* Right: GET CTA */}
        <div className="flex items-center gap-2 shrink-0">
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-1.5 px-4 sm:px-5 py-1.5 sm:py-2 rounded-full bg-[#e6edb0] hover:bg-[#d8e396] active:bg-[#c9d67e] text-[#12140f] font-black text-xs tracking-wide shadow-xs transition-transform active:scale-95"
            aria-label="Get LaterBox on Apple App Store"
          >
            {/* Apple Logo SVG */}
            <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 170 170" aria-hidden="true">
              <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.7-3.07-7.65-7.85-11.87-14.34-5.77-8.91-10.28-18.78-13.55-29.61-3.26-10.83-4.9-21.2-4.9-31.12 0-14.82 3.65-27.08 10.96-36.78 7.3-9.7 16.59-14.65 27.87-14.85 4.8 0 10.1 1.25 15.9 3.75 5.79 2.5 9.7 3.8 11.72 3.9 1.63 0 5.8-1.4 12.52-4.2 6.72-2.8 12.3-4.05 16.74-3.75 12.73.6 22.86 5.3 30.38 14.1-11.08 6.7-16.5 15.86-16.27 27.48.24 9.04 3.74 16.82 10.5 23.35 6.75 6.52 14.86 10.21 24.32 11.07-2.12 6.31-4.77 12.73-7.95 19.27zM119.22 33.56c0-6.9 2.5-13.43 7.5-19.6 5-6.17 11.25-10.36 18.75-12.56.22 1.3.33 2.5.33 3.6 0 6.8-2.6 13.3-7.8 19.5-5.2 6.2-11.4 10.3-18.6 12.3-.11-1.1-.18-2.2-.18-3.24z" />
            </svg>
            <span>GET</span>
          </a>
        </div>
      </div>
    </aside>
  );
}

