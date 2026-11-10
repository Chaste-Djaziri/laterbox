// laterbox-web/src/components/admin/AdminMaintenanceView.tsx
'use client';

import { useState, useEffect } from 'react';
import { AlertTriangle, CalendarClock, Clock3, ShieldCheck } from 'lucide-react';
import { useAdmin, type Mode } from './AdminContext';

const inputClass =
  'w-full rounded-xl border border-[#dde2d2] bg-white px-4 py-3 text-sm text-[#171711] outline-none focus:border-[#9bad79] transition-colors';

const toLocal = (v: string | null) =>
  v ? new Date(v).toLocaleString('sv-SE').slice(0, 16).replace(' ', 'T') : '';

export function AdminMaintenanceView() {
  const { operations, busyOperations, updateOperations, setError } = useAdmin();
  const [mode, setMode] = useState<Mode>('off');
  const [start, setStart] = useState('');
  const [end, setEnd] = useState('');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (operations?.operations) {
      setMode(operations.operations.maintenanceMode);
      setStart(toLocal(operations.operations.maintenanceStartsAt));
      setEnd(toLocal(operations.operations.maintenanceEndsAt));
      setMessage(operations.operations.maintenanceMessage || 'We are improving LaterBox. Please check back shortly.');
    }
  }, [operations]);

  if (!operations) return null;

  const handleSave = () => {
    if (mode === 'scheduled' && (!start || Number.isNaN(Date.parse(start)))) {
      setError('Select a valid future start time for scheduled maintenance.');
      return;
    }
    if (mode !== 'off' && (!end || Number.isNaN(Date.parse(end)))) {
      setError('Select a valid estimated completion time.');
      return;
    }

    const confirmPrompt =
      mode === 'active'
        ? 'Start maintenance immediately for every LaterBox visitor?'
        : 'Save maintenance configuration?';

    void updateOperations(
      {
        action: 'maintenance',
        mode,
        startsAt:
          mode === 'scheduled'
            ? new Date(start).toISOString()
            : mode === 'active'
            ? new Date().toISOString()
            : null,
        endsAt: mode !== 'off' && end ? new Date(end).toISOString() : null,
        message,
      },
      confirmPrompt
    );
  };

  return (
    <div className="space-y-6">
      {/* Site-wide maintenance card */}
      <section className="rounded-2xl border border-[#e1e6d7] bg-white p-6 shadow-sm">
        <div className="flex items-center gap-3 border-b border-[#f0ede5] pb-5">
          <CalendarClock size={22} className="text-[#435b34]" />
          <div>
            <h2 className="text-base font-bold text-[#171711]">Site-wide maintenance</h2>
            <p className="text-xs text-[#74806e]">
              Schedule downtime, publish an announcement, and display a live countdown
            </p>
          </div>
        </div>

        <div className="mt-6 grid gap-5 md:grid-cols-2">
          <div>
            <label className="text-xs font-bold uppercase tracking-wider text-[#677362]">
              Maintenance mode
            </label>
            <select
              className={'mt-2 ' + inputClass}
              value={mode}
              onChange={e => setMode(e.target.value as Mode)}
              disabled={!operations.isOwner || busyOperations}
            >
              <option value="off">Off — site is available</option>
              <option value="scheduled">Scheduled — announce a future window</option>
              <option value="active">Start maintenance immediately</option>
            </select>
          </div>

          <div className="flex items-end pb-1">
            <div className="flex items-center gap-2.5 rounded-xl bg-[#fafbf6] border border-[#e4e5d9] px-4 py-3 w-full">
              <ShieldCheck
                size={20}
                className={
                  operations.maintenanceState === 'active'
                    ? 'text-amber-600'
                    : operations.maintenanceState === 'scheduled'
                    ? 'text-blue-600'
                    : 'text-[#435b34]'
                }
              />
              <p className="text-sm text-[#67755d]">
                Current state:{' '}
                <strong className="capitalize text-[#171711] font-bold">
                  {operations.maintenanceState}
                </strong>
              </p>
            </div>
          </div>

          {mode !== 'off' && (
            <>
              {mode === 'scheduled' && (
                <div>
                  <label className="text-xs font-bold uppercase tracking-wider text-[#677362]">
                    Start date and time <span className="font-normal text-[#74806e]">(local)</span>
                  </label>
                  <input
                    className={'mt-2 ' + inputClass}
                    type="datetime-local"
                    value={start}
                    onChange={e => setStart(e.target.value)}
                    disabled={!operations.isOwner || busyOperations}
                  />
                </div>
              )}
              <div className={mode === 'active' ? 'md:col-span-2' : ''}>
                <label className="text-xs font-bold uppercase tracking-wider text-[#677362]">
                  Expected end date and time <span className="font-normal text-[#74806e]">(local)</span>
                </label>
                <input
                  className={'mt-2 ' + inputClass}
                  type="datetime-local"
                  value={end}
                  onChange={e => setEnd(e.target.value)}
                  disabled={!operations.isOwner || busyOperations}
                />
              </div>
            </>
          )}
        </div>

        <div className="mt-5">
          <label className="block text-xs font-bold uppercase tracking-wider text-[#677362]">
            User-facing message
          </label>
          <textarea
            rows={3}
            className={'mt-2 ' + inputClass}
            value={message}
            maxLength={500}
            onChange={e => setMessage(e.target.value)}
            disabled={!operations.isOwner || busyOperations}
            placeholder="We are improving LaterBox. Please check back shortly."
          />
        </div>

        <div className="mt-6 flex flex-wrap items-center justify-between gap-4 border-t border-[#f0ede5] pt-5">
          <p className="max-w-lg text-xs leading-5 text-[#7c8577]">
            When active, visitors see a full-screen LaterBox maintenance screen. Scheduled maintenance shows
            advance notice. Admin access remains available for recovery.
          </p>
          <button
            type="button"
            disabled={!operations.isOwner || busyOperations}
            onClick={handleSave}
            className="rounded-xl bg-[#e6edb0] px-6 py-2.5 text-sm font-bold text-[#171711] shadow-sm hover:bg-[#d8e39d] transition-colors disabled:opacity-50"
          >
            {busyOperations ? 'Saving…' : 'Save maintenance'}
          </button>
        </div>

        {/* User-facing preview */}
        <div className="mt-6 rounded-2xl border border-[#e7e9db] bg-[#f6f7ef] p-4.5">
          <p className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-[#171711]">
            <Clock3 size={16} className="text-[#435b34]" />
            <span>User-facing maintenance preview</span>
          </p>
          <p className="mt-2 text-sm text-[#434b3f] leading-relaxed font-medium">
            {message || 'We are improving LaterBox. Please check back shortly.'}
          </p>
          <p className="mt-2 text-xs text-[#778272]">
            {end ? `Estimated restoration: ${new Date(end).toLocaleString()}` : 'No end time selected'}
          </p>
        </div>
      </section>

      {/* Recent administrative actions */}
      <section className="rounded-2xl border border-[#e1e6d7] bg-white p-6 shadow-sm">
        <div className="flex items-center gap-2 border-b border-[#f0ede5] pb-4">
          <AlertTriangle size={18} className="text-[#877134]" />
          <h3 className="text-sm font-bold text-[#171711]">Recent administrative actions</h3>
        </div>
        <div className="mt-4 divide-y divide-[#f4f2ea]">
          {(operations.audit ?? []).slice(0, 15).map(a => (
            <div key={a.id} className="py-2.5 flex flex-wrap items-center justify-between gap-2 text-xs">
              <span className="font-mono text-[#6d7867]">
                {new Date(a.created_at).toLocaleString()}
              </span>
              <span className="font-semibold text-[#171711]">{a.action}</span>
              <span className="rounded-md bg-[#f0f2e9] px-2 py-0.5 font-mono text-[11px] text-[#55634d]">
                {a.target ?? 'platform'}
              </span>
            </div>
          ))}
          {(!operations.audit || operations.audit.length === 0) && (
            <p className="py-6 text-center text-xs text-[#8a9582]">No audit records found.</p>
          )}
        </div>
      </section>
    </div>
  );
}
