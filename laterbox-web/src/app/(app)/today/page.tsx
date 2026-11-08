// laterbox-web/src/app/(app)/today/page.tsx
'use client';

import { useEffect, useMemo, useState } from 'react';
import { Clock3 } from 'lucide-react';
import { DashboardView } from '@/components/inbox/DashboardView';
import { useItems } from '@/lib/store/ItemContext';
import { recentInboxArrivals } from '@/lib/utils/schedule';

export default function TodayPage() {
  const { items, loading } = useItems();
  const [clock, setClock] = useState(() => new Date());

  useEffect(() => {
    const refresh = () => setClock(new Date());
    const interval = window.setInterval(refresh, 60_000);
    window.addEventListener('focus', refresh);
    document.addEventListener('visibilitychange', refresh);
    return () => {
      window.clearInterval(interval);
      window.removeEventListener('focus', refresh);
      document.removeEventListener('visibilitychange', refresh);
    };
  }, []);

  const arrivals = useMemo(() => recentInboxArrivals(items, clock), [items, clock]);

  return (
    <DashboardView
      title="Today"
      items={arrivals}
      loading={loading}
      sortByInboxArrival
      topBanner={
        <div className="mb-3 flex shrink-0 flex-wrap items-center justify-between gap-2 rounded-2xl border border-[#e4e7d8] bg-[#f4f7e9] px-4 py-3 text-[#4d6240]">
          <div className="flex items-center gap-2.5">
            <Clock3 className="h-4 w-4 shrink-0" aria-hidden="true" />
            <p className="text-xs leading-5 sm:text-sm">
              <strong className="font-extrabold">Last 24 hours.</strong>{' '}
              Items that arrived in your Inbox, including scheduled returns.
            </p>
          </div>
          {!loading && (
            <span className="rounded-full bg-[#e6edb0] px-3 py-1 text-xs font-extrabold tabular-nums text-[#33452b]">
              {arrivals.length} {arrivals.length === 1 ? 'arrival' : 'arrivals'}
            </span>
          )}
        </div>
      }
    />
  );
}
