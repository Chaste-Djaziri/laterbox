'use client';

import { useEffect, useId, useRef, useState } from 'react';
import { CalendarDays, ChevronLeft, ChevronRight, Clock, Loader2, X } from 'lucide-react';

export function ExactScheduleModal({ count, initialValue, onClose, onConfirm }: {
  count: number;
  initialValue?: string | null;
  onClose: () => void;
  onConfirm: (iso: string) => Promise<void>;
}) {
  const [selected, setSelected] = useState(() => {
    const previous = initialValue ? new Date(initialValue) : null;
    return previous && previous > new Date() ? previous : new Date(Date.now() + 3600000);
  });
  const [month, setMonth] = useState(() => new Date(selected.getFullYear(), selected.getMonth(), 1));
  const [time, setTime] = useState(() => `${String(selected.getHours()).padStart(2, '0')}:${String(selected.getMinutes()).padStart(2, '0')}`);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const dialog = useRef<HTMLDialogElement>(null);
  const heading = useId();
  const timeId = useId();

  useEffect(() => { dialog.current?.showModal(); }, []);

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const firstDay = (month.getDay() + 6) % 7;
  const days = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
  const [hours, minutes] = time.split(':').map(Number);
  const scheduled = new Date(selected.getFullYear(), selected.getMonth(), selected.getDate(), hours, minutes);
  const valid = Boolean(time) && Number.isFinite(scheduled.getTime()) && scheduled > new Date();
  const zone = Intl.DateTimeFormat().resolvedOptions().timeZone;
  const previousMonthDisabled = month.getFullYear() === today.getFullYear() && month.getMonth() === today.getMonth();

  return (
    <dialog ref={dialog} aria-labelledby={heading}
      onCancel={event => { if (busy) event.preventDefault(); else onClose(); }}
      onClose={onClose}
      className="fixed inset-0 m-auto w-[calc(100%-2rem)] max-w-md max-h-[calc(100dvh-2rem)] overflow-y-auto rounded-3xl border border-[#e4e0d5] bg-[#faf9f5] p-0 text-[#171711] shadow-2xl backdrop:bg-black/40 backdrop:backdrop-blur-sm">
      <form onSubmit={async event => {
        event.preventDefault();
        if (busy) return;
        if (!valid) { setError('Choose a date and time in the future.'); return; }
        setBusy(true); setError('');
        try { await onConfirm(scheduled.toISOString()); }
        catch { setError('We couldn’t update the schedule. Please try again.'); }
        finally { setBusy(false); }
      }}>
        <div className="flex items-start gap-3 border-b border-[#e4e0d5] p-5">
          <div className="rounded-2xl bg-[#e6edb0] p-3"><CalendarDays className="h-5 w-5" /></div>
          <div className="flex-1"><h2 id={heading} className="text-lg font-bold">Choose a return time</h2>
            <p className="mt-1 text-xs text-[#6c6b63]">Schedule {count === 1 ? 'this item' : `${count} selected items`} for later.</p></div>
          <button type="button" onClick={onClose} disabled={busy} aria-label="Close scheduling" className="rounded-lg p-1.5 hover:bg-[#ebe7dc] disabled:opacity-50"><X className="h-4 w-4" /></button>
        </div>
        <fieldset disabled={busy} className="space-y-4 p-5 disabled:opacity-60">
          <div className="rounded-2xl border border-[#e4e0d5] bg-white p-4">
            <div className="mb-4 flex items-center justify-between">
              <button type="button" aria-label="Previous month" disabled={previousMonthDisabled}
                onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() - 1, 1))}
                className="rounded-lg p-2 hover:bg-[#f7f5ee] disabled:opacity-25"><ChevronLeft className="h-4 w-4" /></button>
              <p aria-live="polite" className="text-sm font-bold">{month.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}</p>
              <button type="button" aria-label="Next month" onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() + 1, 1))}
                className="rounded-lg p-2 hover:bg-[#f7f5ee]"><ChevronRight className="h-4 w-4" /></button>
            </div>
            <div className="grid grid-cols-7 gap-1 text-center">
              {['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map(day => <span key={day} className="pb-2 text-[10px] font-bold text-[#9e9b92]">{day}</span>)}
              {Array.from({ length: firstDay }, (_, index) => <span key={`blank-${index}`} />)}
              {Array.from({ length: days }, (_, index) => {
                const date = new Date(month.getFullYear(), month.getMonth(), index + 1);
                const active = date.toDateString() === selected.toDateString();
                return <button type="button" key={index} disabled={date < today} aria-pressed={active}
                  aria-label={date.toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
                  onClick={() => { setSelected(date); setError(''); }}
                  className={`aspect-square rounded-xl text-xs font-semibold disabled:opacity-25 ${active ? 'bg-[#171711] text-white' : 'hover:bg-[#f0ede4]'}`}>{index + 1}</button>;
              })}
            </div>
          </div>
          <div className="flex items-center justify-between gap-3 rounded-2xl border border-[#e4e0d5] bg-white p-4">
            <label htmlFor={timeId} className="flex items-center gap-2 text-sm font-bold"><Clock className="h-4 w-4" />Time</label>
            <input id={timeId} type="time" required value={time} onChange={event => { setTime(event.target.value); setError(''); }}
              className="rounded-lg border border-[#e4e0d5] bg-[#faf9f5] px-3 py-2 text-sm focus:outline-2 focus:outline-[#171711]" />
          </div>
          <div className="rounded-xl bg-[#e6edb0]/50 p-3" aria-live="polite">
            <p className="text-xs font-bold">{Number.isFinite(scheduled.getTime()) ? scheduled.toLocaleString(undefined, { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }) : 'Choose a time'}</p>
            <p className="mt-1 text-[10px] text-[#6c6b63]">Your local time · {zone}</p>
          </div>
          {error && <p role="alert" className="text-xs font-semibold text-red-700">{error}</p>}
        </fieldset>
        <div className="flex justify-end gap-2 border-t border-[#e4e0d5] p-4">
          <button type="button" onClick={onClose} disabled={busy} className="rounded-xl border border-[#e4e0d5] bg-white px-4 py-2.5 text-xs font-bold disabled:opacity-50">Cancel</button>
          <button type="submit" disabled={busy || !valid} className="flex items-center gap-2 rounded-xl bg-[#171711] px-4 py-2.5 text-xs font-bold text-white disabled:opacity-40">
            {busy && <Loader2 className="h-3.5 w-3.5 animate-spin" />} {busy ? 'Scheduling…' : 'Confirm schedule'}
          </button>
        </div>
      </form>
    </dialog>
  );
}
