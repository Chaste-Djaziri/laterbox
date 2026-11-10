// laterbox-web/src/components/admin/AdminOverviewView.tsx
'use client';

import { BarChart3 } from 'lucide-react';
import { useAdmin } from './AdminContext';

const usd = (n: number) => (n / 100).toLocaleString('en-US', { style: 'currency', currency: 'USD' });

function MetricCard({ title, value, detail }: { title: string; value: string | number; detail: string }) {
  return (
    <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm transition-shadow hover:shadow-md">
      <p className="text-xs font-semibold uppercase tracking-widest text-[#677362]">{title}</p>
      <p className="mt-4 text-3xl font-bold tracking-tight text-[#171711]">{value}</p>
      <p className="mt-2 text-xs text-[#677362] font-medium">{detail}</p>
    </section>
  );
}

export function AdminOverviewView() {
  const { data } = useAdmin();

  if (!data) return null;

  const maxNewUsers = Math.max(...data.monthly.map(x => x.newUsers), 1);

  return (
    <div className="space-y-7">
      {/* Primary KPI Grid */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <MetricCard
          title="Registered users"
          value={data.totals.users}
          detail="Supabase identities"
        />
        <MetricCard
          title="Whop-connected"
          value={data.totals.advocates}
          detail="Verified Advocate accounts"
        />
        <MetricCard
          title="Active subscriptions"
          value={data.totals.activeSubscriptions}
          detail="Active and trialing"
        />
        <MetricCard
          title="Tracked referrals"
          value={data.totals.referrals}
          detail="Across all advocates"
        />
      </div>

      {/* Charts & Breakdown */}
      <div className="grid gap-6 xl:grid-cols-[1.6fr_1fr]">
        {/* User Acquisition */}
        <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
          <div className="flex items-center gap-2.5">
            <BarChart3 size={20} className="text-[#435b34]" />
            <h2 className="font-bold text-base text-[#171711]">User acquisition</h2>
          </div>
          <p className="mt-1 text-xs text-[#677362]">New user registrations by month</p>
          <div className="mt-8 flex h-52 items-end gap-3 px-2">
            {data.monthly.map(m => (
              <div key={m.month} className="flex h-full flex-1 flex-col items-center justify-end gap-2.5">
                <span className="text-xs font-semibold text-[#171711]">{m.newUsers}</span>
                <div
                  className="w-full rounded-t-lg bg-[#c4d895] transition-all duration-300 hover:bg-[#a9c56f]"
                  style={{ height: `${Math.max((m.newUsers / maxNewUsers) * 78, 5)}%` }}
                />
                <span className="text-[10px] font-semibold text-[#677362] uppercase tracking-wider">
                  {m.month.slice(5)}
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* Subscription Health */}
        <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
          <h2 className="font-bold text-base text-[#171711]">Subscription health</h2>
          <p className="mt-1 text-xs text-[#677362]">Breakdown of current storage entitlements</p>
          <div className="mt-6 divide-y divide-[#f0ede5]">
            {Object.entries(data.totals.subscriptionsByStatus).map(([name, count]) => (
              <div key={name} className="flex items-center justify-between py-3.5 text-sm">
                <span className="capitalize font-medium text-[#677362]">{name}</span>
                <b className="font-bold text-[#171711]">{count}</b>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* Financial Overview */}
      <div className="grid gap-4 sm:grid-cols-3">
        <MetricCard
          title="Accrued commissions"
          value={usd(data.totals.totalCommissionCents)}
          detail="Earn program ledger total"
        />
        <MetricCard
          title="Pending commissions"
          value={usd(data.totals.pendingCommissionCents)}
          detail="Subject to qualification period"
        />
        <MetricCard
          title="Paid referrals"
          value={usd(data.totals.totalPaidCents)}
          detail="Recorded payout transfers"
        />
      </div>
    </div>
  );
}
