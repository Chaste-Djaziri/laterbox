// laterbox-web/src/components/admin/AdminFeedbackView.tsx
'use client';

import { useMemo, useState } from 'react';
import { MessageSquareText } from 'lucide-react';
import { useAdmin } from './AdminContext';

export function AdminFeedbackView() {
  const { operations, busyOperations, updateOperations } = useAdmin();
  const [filter, setFilter] = useState('all');

  const filteredTickets = useMemo(() => {
    return (
      operations?.tickets?.filter(t =>
        filter === 'all' ? true : t.category === filter || t.status === filter
      ) ?? []
    );
  }, [operations?.tickets, filter]);

  if (!operations) return null;

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-[#e1e6d7] bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-4 border-b border-[#f0ede5] pb-5">
          <div>
            <div className="flex items-center gap-2">
              <MessageSquareText size={20} className="text-[#435b34]" />
              <h2 className="text-base font-bold text-[#171711]">
                Feedback, help requests & user reports
              </h2>
            </div>
            <p className="mt-1 text-xs text-[#74806e]">
              Live support queue · {operations.tickets.length} total submissions
            </p>
          </div>
          <select
            value={filter}
            onChange={e => setFilter(e.target.value)}
            className="w-full sm:w-auto rounded-xl border border-[#dde2d2] bg-white px-4 py-2 text-sm text-[#171711] outline-none focus:border-[#9bad79]"
          >
            <option value="all">All submissions ({operations.tickets.length})</option>
            <option value="problem">Problem reports</option>
            <option value="feedback">Feedback</option>
            <option value="help">Help requests</option>
            <option value="other">Other</option>
            <option value="open">Open</option>
            <option value="in_progress">In progress</option>
            <option value="resolved">Resolved</option>
          </select>
        </div>

        <div className="mt-5 divide-y divide-[#edf0e7]">
          {filteredTickets.length === 0 ? (
            <div className="py-12 text-center text-sm text-[#788272]">
              No reports or tickets match this filter.
            </div>
          ) : (
            filteredTickets.map(t => (
              <article key={t.id} className="py-5">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="rounded-md bg-[#edf0e2] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-[#54624b]">
                        {t.category}
                      </span>
                      <span className="text-xs text-[#788470]">
                        {t.platform} · {new Date(t.created_at).toLocaleString()}
                      </span>
                    </div>
                    <h3 className="mt-2 text-base font-bold text-[#171711]">{t.subject}</h3>
                    <p className="mt-0.5 text-xs text-[#74806e]">{t.email}</p>
                  </div>
                  <select
                    aria-label={`Status of ${t.subject}`}
                    className="rounded-xl border border-[#d9dfcb] bg-[#f8faf3] px-3 py-1.5 text-xs font-semibold text-[#171711] outline-none focus:border-[#9bad79]"
                    disabled={!operations.isOwner || busyOperations}
                    value={t.status}
                    onChange={e =>
                      void updateOperations({ action: 'ticket', ticketId: t.id, status: e.target.value })
                    }
                  >
                    <option value="open">Open</option>
                    <option value="in_progress">In progress</option>
                    <option value="resolved">Resolved</option>
                  </select>
                </div>
                <div className="mt-3 whitespace-pre-wrap break-words rounded-xl bg-[#f7f7f2] p-4 text-sm leading-6 text-[#525e4b] border border-[#f0ede5]">
                  {t.message}
                </div>
              </article>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
