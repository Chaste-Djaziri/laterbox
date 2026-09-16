'use client';
import { useState } from 'react';
import { createPortal } from 'react-dom';
import { Clock, X } from 'lucide-react';
import { useItems } from '@/lib/store/ItemContext';
import type { LaterBoxItem } from '@/lib/supabase/types';
import { ReturnTimePicker } from './ReturnTimePicker';

export function RescheduleAction({ item }: { item: LaterBoxItem }) {
  const { reschedule } = useItems();
  const [open, setOpen] = useState(false);
  const [value, setValue] = useState<string | null>(item.return_at ?? null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  return <>
    <button type="button" className="w-full flex items-center gap-2.5 px-3.5 py-2 text-left hover:bg-[#ebe7dc]/50"
      onClick={event => { event.stopPropagation(); setValue(item.return_at ?? null); setError(''); setOpen(true); }}>
      <Clock size={14} /> Choose return time
    </button>
    {open && createPortal(<div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4"
      onClick={event => { event.stopPropagation(); if (!saving) setOpen(false); }}>
      <div role="dialog" aria-modal="true" aria-label="Choose return time" className="w-full max-w-lg rounded-2xl border border-[#e4e0d5] bg-[#f7f5ee] p-6 space-y-5"
        onClick={event => event.stopPropagation()}>
        <div className="flex justify-between items-center"><h2 className="font-bold">Choose return time</h2>
          <button aria-label="Close" disabled={saving} onClick={() => setOpen(false)}><X size={18} /></button></div>
        <ReturnTimePicker value={value} onChange={setValue} disabled={saving} />
        {error && <p role="alert" className="text-sm text-red-700">{error}</p>}
        <button className="rounded-xl bg-[#171711] text-white px-4 py-2 text-sm font-bold" disabled={saving}
          onClick={async () => { setSaving(true); try { await reschedule(item.id, value); setOpen(false); }
            catch { setError('Could not save this return time. Try again.'); } finally { setSaving(false); } }}>Save return time</button>
      </div>
    </div>, document.body)}
  </>;
}
