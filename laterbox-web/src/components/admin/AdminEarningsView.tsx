// laterbox-web/src/components/admin/AdminEarningsView.tsx
'use client';

import { Wallet } from 'lucide-react';
import { useAdmin } from './AdminContext';

const usd = (n: number) => (n / 100).toLocaleString('en-US', { style: 'currency', currency: 'USD' });

function MetricCard({ title, value, detail }: { title: string; value: string | number; detail: string }) {
  return (
    <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-widest text-[#677362]">{title}</p>
      <p className="mt-4 text-3xl font-bold tracking-tight text-[#171711]">{value}</p>
      <p className="mt-2 text-xs text-[#677362] font-medium">{detail}</p>
    </section>
  );
}

export function AdminEarningsView() {
  const { data } = useAdmin();

  if (!data) return null;

  return (
    <div className="space-y-6">
      <div className="grid gap-4 md:grid-cols-3">
        <MetricCard
          title="Total commissions"
          value={usd(data.totals.totalCommissionCents)}
          detail={`${data.earnings.commissions} ledger entries`}
        />
        <MetricCard
          title="Pending"
          value={usd(data.totals.pendingCommissionCents)}
          detail="Awaiting qualification"
        />
        <MetricCard
          title="Paid transfers"
          value={usd(data.totals.totalPaidCents)}
          detail={`${data.earnings.payouts} recorded payouts`}
        />
      </div>

      <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
        <div className="flex items-center gap-2">
          <Wallet size={20} className="text-[#435b34]" />
          <h2 className="font-bold text-base text-[#171711]">Commission lifecycle</h2>
        </div>
        <div className="mt-5 divide-y divide-[#f0ede5]">
          {Object.entries(data.earnings.byStatus).map(([status, count]) => (
            <div key={status} className="flex items-center justify-between py-3.5 text-sm">
              <span className="capitalize font-medium text-[#677362]">{status}</span>
              <b className="font-bold text-[#171711]">{count}</b>
            </div>
          ))}
        </div>
        <p className="mt-5 text-xs text-[#677362]">
          Derived from Whop referral ledger entries, separate from gross subscription revenue.
        </p>
      </section>
    </div>
  );
}

