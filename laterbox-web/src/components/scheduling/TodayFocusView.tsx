'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { Archive, ArrowRight, CalendarClock, Check, Clock3, Inbox, RotateCcw } from 'lucide-react';
import { useItems } from '@/lib/store/ItemContext';
import type { LaterBoxItem } from '@/lib/supabase/types';
import { returnLabel, todayFocusItems } from '@/lib/utils/schedule';
import { ExactScheduleModal } from '@/components/scheduling/ExactScheduleModal';

export function TodayFocusView() {
  const { items, now, loading, keepItem, archiveItem, reschedule } = useItems();
  const { overdue, returningToday } = useMemo(() => todayFocusItems(items, now), [items, now]);
  const [scheduleTarget, setScheduleTarget] = useState<LaterBoxItem | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const act = async (item: LaterBoxItem, action: 'keep' | 'dismiss') => {
    if (busyId) return;
    setBusyId(item.id);
    setError(null);
    try {
      if (action === 'keep') await keepItem(item.id);
      else await archiveItem(item.id);
    } catch {
      setError('The action could not be saved. Please try again.');
    } finally {
      setBusyId(null);
    }
  };

  const group = (title: string, list: LaterBoxItem[], overdueGroup: boolean) => {
    if (!list.length) return null;
    return (
      <section aria-label={title} className="space-y-3">
        <div className="flex items-center gap-2">
          <span className={overdueGroup
            ? 'h-2 w-2 rounded-full bg-amber-500'
            : 'h-2 w-2 rounded-full bg-[#93a750]'} aria-hidden="true" />
          <h2 className="text-sm font-bold text-[#171711]">{title}</h2>
          <span className="rounded-full bg-[#ece9df] px-2.5 py-0.5 text-xs font-semibold text-[#6c6b63]">{list.length}</span>
        </div>
        <div className="grid gap-3">
          {list.map(item => (
            <article key={item.id} className="rounded-2xl border border-[#e4e0d5] bg-white p-4 shadow-xs sm:p-5">
              <div className="flex min-w-0 items-start justify-between gap-3">
                <div className="min-w-0 space-y-2">
                  <Link href={'/item/' + encodeURIComponent(item.id)}
                    className="group inline-flex max-w-full items-center gap-2 font-bold text-[#171711] hover:underline">
                    <span className="truncate">{item.metadata?.title || item.title || 'Untitled item'}</span>
                    <ArrowRight className="h-3.5 w-3.5 shrink-0 opacity-50 group-hover:opacity-100" />
                  </Link>
                  <div className="flex flex-wrap items-center gap-2 text-xs text-[#6c6b63]">
                    <CalendarClock className="h-3.5 w-3.5" aria-hidden="true" />
                    <time dateTime={item.return_at || undefined}>{returnLabel(item.return_at)}</time>
                    {item.metadata?.domain && (
                      <span className="max-w-44 truncate border-l border-[#e4e0d5] pl-2">{item.metadata.domain}</span>
                    )}
                  </div>
                </div>
                <span className={overdueGroup
                  ? 'shrink-0 rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-bold text-amber-800'
                  : 'shrink-0 rounded-full bg-[#e6edb0]/70 px-2.5 py-1 text-[11px] font-bold text-[#4c532d]'}>
                  {overdueGroup ? 'Overdue' : 'Today'}
                </span>
              </div>
              {item.metadata?.description && (
                <p className="mt-2 line-clamp-2 text-xs leading-relaxed text-[#6c6b63]">{item.metadata.description}</p>
              )}
              <div className="mt-4 flex flex-wrap gap-2">
                <button type="button" disabled={busyId !== null}
                  onClick={() => void act(item, 'keep')}
                  className="inline-flex items-center gap-1.5 rounded-xl bg-[#e6edb0] px-3.5 py-2 text-xs font-bold text-[#171711] hover:bg-[#dce5a2] disabled:opacity-50">
                  <Check className="h-3.5 w-3.5" /> Keep
                </button>
                <button type="button" disabled={busyId !== null}
                  onClick={() => { setError(null); setScheduleTarget(item); }}
                  className="inline-flex items-center gap-1.5 rounded-xl border border-[#e4e0d5] bg-[#faf9f5] px-3.5 py-2 text-xs font-bold text-[#171711] hover:bg-[#f0ede4] disabled:opacity-50">
                  <RotateCcw className="h-3.5 w-3.5" /> Reschedule
                </button>
                <button type="button" disabled={busyId !== null}
                  title="Dismiss moves this item to Archive, not Trash"
                  onClick={() => void act(item, 'dismiss')}
                  className="inline-flex items-center gap-1.5 rounded-xl border border-[#e4e0d5] px-3.5 py-2 text-xs font-bold text-[#6c6b63] hover:bg-[#faf9f5] disabled:opacity-50">
                  <Archive className="h-3.5 w-3.5" /> Dismiss
                </button>
              </div>
            </article>
          ))}
        </div>
      </section>
    );
  };

  const count = overdue.length + returningToday.length;

  return (
    <main className="h-full min-h-0 overflow-y-auto bg-[#f7f5ee] px-4 pb-10 pt-6 sm:px-7">
      <div className="mx-auto max-w-4xl space-y-6">
        <header className="space-y-3">
          <div className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-[#6c6b63] ring-1 ring-[#e4e0d5]">
            <Clock3 className="h-3.5 w-3.5" /> Your returns
          </div>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="text-2xl font-extrabold tracking-tight text-[#171711] sm:text-3xl">Today</h1>
              <p className="mt-1 text-sm text-[#6c6b63]">A moment for what you saved.</p>
            </div>
            {!loading && <span className="rounded-2xl border border-[#e4e0d5] bg-white px-4 py-2 text-sm font-bold text-[#171711]">
              {count} {count === 1 ? 'return' : 'returns'}
            </span>}
          </div>
        </header>

        {error && <p role="alert" className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-800">{error}</p>}

        {loading ? (
          <div role="status" className="rounded-2xl bg-white p-12 text-center text-sm text-[#6c6b63]">
            Loading your returns…
          </div>
        ) : count === 0 ? (
          <div className="flex flex-col items-center gap-3 rounded-2xl border border-[#e4e0d5] bg-white px-5 py-14 text-center">
            <span className="rounded-full bg-[#e6edb0] p-4"><Inbox className="h-7 w-7 text-[#171711]" /></span>
            <h2 className="text-lg font-bold text-[#171711]">All caught up</h2>
            <p className="max-w-sm text-sm text-[#6c6b63]">Nothing overdue or returning today. Scheduled items will appear here when their day arrives.</p>
            <Link href="/inbox" className="mt-2 text-sm font-bold text-[#171711] underline underline-offset-4">Back to Inbox</Link>
          </div>
        ) : (
          <div className="space-y-7">
            {group('Overdue', overdue, true)}
            {group('Returning today', returningToday, false)}
            <p className="text-xs text-[#77756d]">Dismiss moves an item to Archive, not Trash. Keep saves it in your library.</p>
          </div>
        )}
      </div>
      {scheduleTarget && (
        <ExactScheduleModal
          count={1}
          initialValue={scheduleTarget.return_at}
          onClose={() => setScheduleTarget(null)}
          onConfirm={async iso => {
            await reschedule(scheduleTarget.id, iso);
            setScheduleTarget(null);
          }}
        />
      )}
    </main>
  );
}
