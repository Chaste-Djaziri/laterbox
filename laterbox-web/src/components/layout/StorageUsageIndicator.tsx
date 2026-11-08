// laterbox-web/src/components/layout/StorageUsageIndicator.tsx
'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import {
  AlertTriangle, ArrowUpRight, CheckCircle2, Cloud, HardDrive,
  RefreshCw, X,
} from 'lucide-react';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { formatStorageBytes, getStorageUsage } from '@/lib/billing/storage-usage';

const levelStyle = {
  unknown: { ring: '#acb4a2', badge: 'bg-[#9da69a]', panel: 'bg-[#f5f7f2] text-[#69756b]' },
  normal: { ring: '#8aa666', badge: 'bg-[#80a15a]', panel: 'bg-[#f2f7e9] text-[#496a33]' },
  warning: { ring: '#d49431', badge: 'bg-[#edaa42]', panel: 'bg-[#fff6e5] text-[#986113]' },
  critical: { ring: '#cc673e', badge: 'bg-[#dc7547]', panel: 'bg-[#fff0e8] text-[#a6472d]' },
  full: { ring: '#bc3e3e', badge: 'bg-[#d34b4b]', panel: 'bg-[#fff0f0] text-[#aa3434]' },
} as const;

export function StorageUsageIndicator() {
  const { user } = useAuth();
  const { entitlement, loading, error, refresh } = useBilling();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const isSignedIn = Boolean(user?.id);
  const usage = getStorageUsage(
    isSignedIn ? entitlement.storageUsedBytes : null,
    isSignedIn ? entitlement.storageLimitBytes : null,
  );
  const styles = levelStyle[usage.level];
  const isAlert = usage.level === 'warning' || usage.level === 'critical' || usage.level === 'full';
  const usageLabel = isSignedIn
    ? usage.percent === null
      ? 'Cloud storage usage unavailable'
      : `${usage.title}: ${formatStorageBytes(usage.usedBytes!)} of ${formatStorageBytes(usage.limitBytes!)} used, ${Math.round(usage.percent)}%`
    : 'Sign in to view cloud storage usage';

  useEffect(() => {
    if (!open) return;
    const onOutside = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    };
    const onEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setOpen(false);
    };
    document.addEventListener('pointerdown', onOutside);
    document.addEventListener('keydown', onEscape);
    return () => {
      document.removeEventListener('pointerdown', onOutside);
      document.removeEventListener('keydown', onEscape);
    };
  }, [open]);

  // Quota is measured by the server, so periodically refresh while the sidebar is visible.
  // BillingContext also refreshes on window focus and when the account changes.
  useEffect(() => {
    if (!isSignedIn) return;
    const interval = window.setInterval(() => {
      if (document.visibilityState === 'visible') void refresh();
    }, 120_000);
    return () => window.clearInterval(interval);
  }, [isSignedIn, refresh]);

  return (
    <div ref={rootRef} className="relative flex w-full items-center justify-center">
      <button
        type="button"
        title={usageLabel}
        aria-label={usageLabel}
        aria-haspopup="dialog"
        aria-expanded={open}
        onClick={() => {
          setOpen(value => !value);
          if (!open && isSignedIn) void refresh();
        }}
        className={`group relative flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#758a50] ${open ? 'border-[#d3df9e] bg-[#e6edb0]' : 'border-transparent hover:bg-white'}`}
      >
        <svg viewBox="0 0 48 48" className="absolute inset-1 h-[44px] w-[44px] -rotate-90" aria-hidden="true">
          <circle cx="24" cy="24" r="19" fill="none" stroke="#e1e5d9" strokeWidth="3.5" />
          {usage.percent !== null && (
            <circle cx="24" cy="24" r="19" fill="none" stroke={styles.ring} strokeWidth="3.5"
              strokeLinecap="round" strokeDasharray={`${Math.min(100, usage.percent) * 1.1938} 119.38`}
              className="transition-all duration-300" />
          )}
        </svg>
        <HardDrive size={21} strokeWidth={1.85} className={isAlert ? 'text-[#a45a30]' : 'text-[#737d68]'} aria-hidden="true" />
        {isAlert && (
          <span aria-hidden="true" className={`absolute -right-0.5 -top-0.5 flex size-4 items-center justify-center rounded-full border-2 border-[#f7f5ee] ${styles.badge}`}>
            <span className="text-[9px] font-black leading-none text-white">!</span>
          </span>
        )}
      </button>

      {open && (
        <section role="dialog" aria-label="Cloud storage usage"
          className="absolute bottom-0 left-[calc(100%+14px)] z-[100] w-[310px] max-w-[calc(100vw-120px)] overflow-hidden rounded-[22px] border border-[#e4e8de] bg-white text-[#1d251a] shadow-[0_18px_58px_rgba(25,34,20,.20)]">
          <div className="flex items-start justify-between gap-3 border-b border-[#edf0e9] p-5">
            <div>
              <p className="text-[10px] font-black uppercase tracking-[0.16em] text-[#88957d]">LaterBox cloud</p>
              <h2 className="mt-1 text-base font-black">Storage usage</h2>
            </div>
            <button type="button" aria-label="Close storage details" onClick={() => setOpen(false)}
              className="rounded-lg p-1.5 text-[#879283] hover:bg-[#f0f3e9] focus-visible:outline-2 focus-visible:outline-[#758a50]">
              <X size={17} />
            </button>
          </div>

          <div className="p-5">
            {!isSignedIn ? (
              <>
                <p className="text-sm leading-6 text-[#6b7667]">Sign in to sync your library and see your cloud storage quota.</p>
                <Link href="/login" onClick={() => setOpen(false)}
                  className="mt-5 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[#1d251a] px-4 py-3 text-xs font-black text-white">
                  Sign in <ArrowUpRight size={15}/>
                </Link>
              </>
            ) : (
              <>
                <div className="flex items-end justify-between gap-3">
                  <div>
                    <p className="text-[10px] font-bold uppercase tracking-wider text-[#929e8b]">Current plan</p>
                    <p className="mt-1 text-lg font-black">{(entitlement.storagePlan ?? 'free').toUpperCase()}</p>
                  </div>
                  <span className="text-right text-2xl font-black tabular-nums">{usage.percent === null ? '—' : `${Math.round(usage.percent)}%`}</span>
                </div>

                <div role="progressbar" aria-label="Cloud storage used"
                  aria-valuemin={0} aria-valuemax={100}
                  aria-valuenow={usage.percent === null ? undefined : Math.min(100, Math.round(usage.percent))}
                  aria-valuetext={usageLabel}
                  className="mt-4 h-2.5 w-full overflow-hidden rounded-full bg-[#edf0e8]">
                  <div className="h-full rounded-full transition-all duration-300"
                    style={{ width: `${Math.min(100, usage.percent ?? 0)}%`, backgroundColor: styles.ring }} />
                </div>
                <div className="mt-2 flex items-center justify-between gap-2 text-[11px] tabular-nums text-[#7c8974]">
                  <span>{usage.usedBytes === null ? 'Usage unavailable' : `${formatStorageBytes(usage.usedBytes)} used`}</span>
                  <span>{usage.limitBytes === null ? 'Limit unavailable' : `${formatStorageBytes(usage.limitBytes)} total`}</span>
                </div>

                <div className={`mt-5 rounded-xl px-3 py-3 ${styles.panel}`} role={isAlert ? 'alert' : 'status'}>
                  <div className="flex items-start gap-2.5">
                    {isAlert ? <AlertTriangle size={17} className="mt-0.5 shrink-0"/> : usage.level === 'normal' ? <CheckCircle2 size={17} className="mt-0.5 shrink-0"/> : <Cloud size={17} className="mt-0.5 shrink-0"/>}
                    <div>
                      <p className="text-xs font-black">{usage.title}</p>
                      <p className="mt-1 text-[11px] leading-5">{usage.description}</p>
                    </div>
                  </div>
                </div>

                {error && <p className="mt-3 text-[11px] text-[#9c6d46]">Showing the latest available usage. Refresh failed.</p>}

                <div className="mt-5 flex items-center gap-2">
                  <button type="button" onClick={() => void refresh()} disabled={loading}
                    aria-label="Refresh cloud storage usage"
                    className="inline-flex h-10 items-center justify-center gap-1.5 rounded-xl border border-[#dbe3d1] px-3 text-xs font-bold text-[#4c5e45] transition hover:bg-[#f0f5e9] disabled:opacity-50">
                    <RefreshCw size={14} className={loading ? 'animate-spin' : ''}/> Refresh
                  </button>
                  <Link href="/plans" onClick={() => setOpen(false)}
                    className="inline-flex h-10 flex-1 items-center justify-center gap-1.5 rounded-xl bg-[#1d251a] px-3 text-xs font-black text-white transition hover:bg-[#34402b]">
                    {isAlert ? 'Get more space' : 'View plans'} <ArrowUpRight size={14}/>
                  </Link>
                </div>
              </>
            )}
          </div>
        </section>
      )}
    </div>
  );
}
