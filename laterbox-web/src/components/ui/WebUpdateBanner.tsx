'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import Image from 'next/image';
import { X, RefreshCw, Loader2 } from 'lucide-react';

interface VersionPayload {
  app?: string;
  version?: string;
  buildTime?: string;
  timestamp?: number;
}

export function WebUpdateBanner() {
  const [hasUpdate, setHasUpdate] = useState(false);
  const [isDismissed, setIsDismissed] = useState(false);
  const [isReloading, setIsReloading] = useState(false);

  const initialPayloadRef = useRef<string | null>(null);
  const initializedRef = useRef(false);

  const checkForUpdate = useCallback(async (isInitial = false) => {
    try {
      const res = await fetch(`/api/version?_t=${Date.now()}`, {
        cache: 'no-store',
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          Pragma: 'no-cache',
        },
      });

      if (!res.ok) return;

      const data: VersionPayload = await res.json();
      const payloadString = JSON.stringify({
        version: data.version,
        buildTime: data.buildTime,
      });

      if (!initializedRef.current || isInitial) {
        initialPayloadRef.current = payloadString;
        initializedRef.current = true;
      } else if (
        initialPayloadRef.current !== null &&
        payloadString !== initialPayloadRef.current
      ) {
        setHasUpdate(true);
      }
    } catch {
      // Ignore network errors during polling
    }
  }, []);

  useEffect(() => {
    // Initial check
    checkForUpdate(true);

    // Periodic polling every 45 seconds
    const interval = setInterval(() => {
      checkForUpdate(false);
    }, 45000);

    // Check on window focus / tab visibility change
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        checkForUpdate(false);
      }
    };

    window.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('focus', handleVisibilityChange);

    return () => {
      clearInterval(interval);
      window.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', handleVisibilityChange);
    };
  }, [checkForUpdate]);

  const handleDismiss = () => {
    setIsDismissed(true);
  };

  const handleReload = async () => {
    setIsReloading(true);

    try {
      // 1. Clear caches if available
      if (typeof window !== 'undefined' && 'caches' in window) {
        const cacheKeys = await caches.keys();
        await Promise.all(cacheKeys.map((key) => caches.delete(key)));
      }

      // 2. Unregister service workers if any
      if (typeof navigator !== 'undefined' && 'serviceWorker' in navigator) {
        const registrations = await navigator.serviceWorker.getRegistrations();
        await Promise.all(registrations.map((reg) => reg.unregister()));
      }
    } catch {
      // Proceed with reload even if clearing caches fails
    }

    // 3. Hard reload bypassing browser cache
    if (typeof window !== 'undefined') {
      const url = new URL(window.location.href);
      url.searchParams.set('_lb_v', Date.now().toString());
      window.location.replace(url.toString());
    }
  };

  if (!hasUpdate || isDismissed) {
    return null;
  }

  return (
    <aside
      aria-label="Application update available"
      className="fixed bottom-5 sm:bottom-6 right-4 sm:right-6 z-50 max-w-[calc(100vw-2rem)] sm:max-w-[380px] w-full animate-in slide-in-from-bottom-6 fade-in duration-300 pointer-events-auto"
    >
      <div className="bg-[#171711] text-white border border-white/15 rounded-3xl p-5 sm:p-6 shadow-2xl shadow-black/50 space-y-3.5 backdrop-blur-md">
        {/* Header */}
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-9 h-9 rounded-xl bg-[#E7FF57] text-[#171711] p-1.5 flex items-center justify-center shrink-0 border border-[#d0db84]">
              <Image
                src="/branding/laterbox-icon.png"
                alt="laterbox"
                width={24}
                height={24}
                className="object-contain"
              />
            </div>
            <h3 className="text-sm sm:text-base font-bold text-white tracking-tight truncate">
              Update available
            </h3>
          </div>

          <button
            type="button"
            onClick={handleDismiss}
            disabled={isReloading}
            className="p-1 text-[#a1a19a] hover:text-white rounded-lg transition-colors cursor-pointer shrink-0 disabled:opacity-50"
            title="Dismiss update notification"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body Description */}
        <p className="text-xs sm:text-[13px] text-[#c7c6bc] leading-relaxed">
          A new version of laterbox has been deployed. Reload now to apply the latest updates without cache.
        </p>

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-2 pt-1">
          <button
            type="button"
            onClick={handleDismiss}
            disabled={isReloading}
            className="px-3.5 py-2 text-xs font-semibold text-[#a1a19a] hover:text-white transition-colors cursor-pointer rounded-xl disabled:opacity-50"
          >
            Later
          </button>

          <button
            type="button"
            onClick={handleReload}
            disabled={isReloading}
            className="inline-flex items-center justify-center gap-1.5 px-4 py-2 text-xs font-bold text-[#171711] bg-[#E7FF57] hover:bg-[#d8f044] active:bg-[#cbe237] rounded-xl shadow-xs transition-all cursor-pointer disabled:opacity-75"
          >
            {isReloading ? (
              <>
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
                <span>Updating…</span>
              </>
            ) : (
              <>
                <RefreshCw className="w-3.5 h-3.5" />
                <span>Reload & update</span>
              </>
            )}
          </button>
        </div>
      </div>
    </aside>
  );
}
