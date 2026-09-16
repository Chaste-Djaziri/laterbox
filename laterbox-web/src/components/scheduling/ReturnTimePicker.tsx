'use client';
import { useState } from 'react';
import { resolveReturnPreset, returnLabel, type ReturnPreset } from '@/lib/utils/schedule';
export function ReturnTimePicker({ value, onChange, disabled = false }: {
  value: string | null; onChange: (value: string | null) => void; disabled?: boolean;
}) {
  const [custom, setCustom] = useState(false);
  const [error, setError] = useState('');
  return <div className="space-y-2">
    <p className="text-xs font-bold text-[#6c6b63]">Choose when · {returnLabel(value)}</p>
    <div className="flex flex-wrap gap-1.5">
      {Object.entries({ now: 'Now', laterToday: 'Later today', tomorrow: 'Tomorrow', weekend: 'Weekend', someday: 'Someday' }).map(([key, label]) =>
        <button key={key} type="button" disabled={disabled} className="rounded-lg border border-[#e4e0d5] px-2.5 py-1.5 text-xs font-semibold hover:bg-[#e6edb0] disabled:opacity-50"
          onClick={() => { setError(''); setCustom(false); onChange(resolveReturnPreset(key as ReturnPreset)); }}>{label}</button>)}
      <button type="button" disabled={disabled} onClick={() => setCustom(!custom)} className="rounded-lg border border-[#e4e0d5] px-2.5 py-1.5 text-xs font-semibold">Custom…</button>
    </div>
    {custom && <label className="block text-xs">Return date and time<input type="datetime-local" disabled={disabled}
      className="block mt-1 rounded-lg border border-[#e4e0d5] p-2 w-full" onChange={event => {
        const date = new Date(event.target.value);
        if (!Number.isFinite(date.getTime()) || date <= new Date()) { setError('Choose a future time, or select Now.'); return; }
        setError(''); onChange(date.toISOString());
      }} /></label>}
    {error && <p role="alert" className="text-xs text-red-700">{error}</p>}
  </div>;
}
