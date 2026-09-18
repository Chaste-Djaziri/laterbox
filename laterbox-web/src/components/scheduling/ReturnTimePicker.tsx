'use client';

import React, { useState } from 'react';
import { resolveReturnPreset, returnLabel, type ReturnPreset } from '@/lib/utils/schedule';
import { Clock, Calendar } from 'lucide-react';

export function ReturnTimePicker({
  value,
  onChange,
  disabled = false,
}: {
  value: string | null;
  onChange: (value: string | null) => void;
  disabled?: boolean;
}) {
  const [custom, setCustom] = useState(false);
  const [error, setError] = useState('');

  const presets: { key: ReturnPreset; label: string }[] = [
    { key: 'now', label: 'Now' },
    { key: 'laterToday', label: 'Later today' },
    { key: 'tomorrow', label: 'Tomorrow' },
    { key: 'weekend', label: 'Weekend' },
    { key: 'someday', label: 'Someday' },
  ];

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <p className="text-xs font-bold text-[#6c6b63] flex items-center gap-1.5">
          <Clock className="w-3.5 h-3.5 text-[#171711]" />
          <span>Choose when to return</span>
        </p>
        <span className="text-[11px] font-semibold text-[#171711] bg-white border border-[#e4e0d5] px-2 py-0.5 rounded-md">
          {returnLabel(value)}
        </span>
      </div>

      <div className="flex flex-wrap gap-1.5">
        {presets.map(({ key, label }) => {
          const isSomedaySelected = key === 'someday' && value === null;
          return (
            <button
              key={key}
              type="button"
              disabled={disabled}
              className={`rounded-xl border px-3 py-1.5 text-xs font-bold transition-all cursor-pointer disabled:opacity-50 ${
                isSomedaySelected
                  ? 'bg-[#e6edb0] border-[#d0db84] text-[#171711]'
                  : 'bg-white border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f5]'
              }`}
              onClick={() => {
                setError('');
                setCustom(false);
                onChange(resolveReturnPreset(key));
              }}
            >
              {label}
            </button>
          );
        })}

        <button
          type="button"
          disabled={disabled}
          onClick={() => setCustom(!custom)}
          className={`rounded-xl border px-3 py-1.5 text-xs font-bold transition-all cursor-pointer disabled:opacity-50 flex items-center gap-1 ${
            custom
              ? 'bg-[#171711] border-[#171711] text-white'
              : 'bg-white border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f5]'
          }`}
        >
          <Calendar className="w-3 h-3" />
          <span>Custom…</span>
        </button>
      </div>

      {custom && (
        <div className="pt-1 animate-in fade-in">
          <label className="block text-xs font-bold text-[#171711] mb-1">
            Pick specific return date and time:
          </label>
          <input
            type="datetime-local"
            disabled={disabled}
            className="block w-full rounded-xl border border-[#e4e0d5] bg-white p-2.5 text-xs font-medium text-[#171711] focus:outline-hidden focus:border-[#171711]"
            onChange={(event) => {
              const date = new Date(event.target.value);
              if (!Number.isFinite(date.getTime()) || date <= new Date()) {
                setError('Choose a future time, or select Now.');
                return;
              }
              setError('');
              onChange(date.toISOString());
            }}
          />
        </div>
      )}

      {error && (
        <p role="alert" className="text-xs font-semibold text-red-700">
          {error}
        </p>
      )}
    </div>
  );
}
