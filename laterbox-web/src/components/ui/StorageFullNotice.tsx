// laterbox-web/src/components/ui/StorageFullNotice.tsx
'use client';

import Link from 'next/link';
import { useBilling } from '@/lib/store/BillingContext';
import { useAuth } from '@/lib/store/AuthContext';
import { formatStorageBytes, getStorageUsage } from '@/lib/billing/storage-usage';
import { AlertTriangle, ArrowUpRight, RefreshCcw } from 'lucide-react';

export function StorageFullNotice() {
  const { user } = useAuth();
  const { entitlement, refresh, loading } = useBilling();
  if (!user) return null;

  const usage = getStorageUsage(entitlement.storageUsedBytes, entitlement.storageLimitBytes);
  if (usage.level !== 'full') return null;

  return (
    <aside role="alert" aria-live="polite"
      className="fixed bottom-4 left-1/2 z-[100] w-[calc(100%-2rem)] max-w-xl -translate-x-1/2 rounded-2xl border border-[#d1c3b7] bg-white p-4 text-[#171711] shadow-[0_15px_55px_rgba(23,23,17,.2)] sm:p-5">
      <div className="flex items-start gap-3">
        <AlertTriangle className="mt-0.5 shrink-0 text-[#b75a31]" size={20} aria-hidden />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-black">Cloud storage full — changes paused</p>
          <p className="mt-1 text-xs leading-5 text-[#5d6458]">
            {usage.usedBytes != null && usage.limitBytes != null
              ? `${formatStorageBytes(usage.usedBytes)} of ${formatStorageBytes(usage.limitBytes)} used. `
              : ''}
            You can still open your library, permanently delete stored files, or change your plan.
          </p>
          <div className="mt-3 flex flex-wrap items-center gap-2">
            <Link href="/trash" className="rounded-lg bg-[#f0efe9] px-3 py-2 text-xs font-bold hover:bg-[#e6e4dc]">Free up space</Link>
            <Link href="/plans" className="inline-flex items-center gap-1 rounded-lg bg-[#171711] px-3 py-2 text-xs font-bold text-white hover:bg-[#32322c]">
              View plans <ArrowUpRight size={13} />
            </Link>
            <button type="button" onClick={() => void refresh()} disabled={loading}
              className="inline-flex items-center gap-1 rounded-lg px-2 py-2 text-xs font-semibold text-[#666a5f] hover:bg-[#f4f3ed] disabled:opacity-60">
              <RefreshCcw size={13} className={loading ? 'animate-spin' : ''} /> Recheck
            </button>
          </div>
        </div>
      </div>
    </aside>
  );
}
