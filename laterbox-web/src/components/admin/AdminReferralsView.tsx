// laterbox-web/src/components/admin/AdminReferralsView.tsx
'use client';

import { Activity, ShieldAlert } from 'lucide-react';
import { useAdmin } from './AdminContext';

function MetricCard({ title, value, detail }: { title: string; value: string | number; detail: string }) {
  return (
    <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-widest text-[#677362]">{title}</p>
      <p className="mt-4 text-3xl font-bold tracking-tight text-[#171711]">{value}</p>
      <p className="mt-2 text-xs text-[#677362] font-medium">{detail}</p>
    </section>
  );
}

export function AdminReferralsView() {
  const { data } = useAdmin();

  if (!data) return null;

  return (
    <div className="space-y-6">
      {/* Top Metrics */}
      <div className="grid gap-4 sm:grid-cols-3">
        <MetricCard
          title="Connected advocates"
          value={data.totals.advocates}
          detail="Whop OAuth confirmed"
        />
        <MetricCard
          title="Tracked referrals"
          value={data.totals.referrals}
          detail="Active referral rows in ledger"
        />
        <MetricCard
          title="Program state"
          value={data.settings.enabled ? 'Enabled' : 'Paused'}
          detail="Commission attribution status"
        />
      </div>

      {/* Referral controls */}
      <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
        <div className="flex items-center gap-2">
          <Activity size={20} className="text-[#435b34]" />
          <h2 className="font-bold text-base text-[#171711]">Referral program parameters</h2>
        </div>
        <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-xl border border-[#f0ede5] bg-[#fafbf7] p-4">
            <p className="text-xs font-semibold text-[#677362] uppercase tracking-wider">Intro Commission</p>
            <p className="mt-2 text-2xl font-bold text-[#171711]">
              {data.settings.intro_commission_bps / 100}%
            </p>
            <p className="mt-1 text-[11px] text-[#7d8876]">First billing cycle</p>
          </div>
          <div className="rounded-xl border border-[#f0ede5] bg-[#fafbf7] p-4">
            <p className="text-xs font-semibold text-[#677362] uppercase tracking-wider">Ongoing Commission</p>
            <p className="mt-2 text-2xl font-bold text-[#171711]">
              {data.settings.ongoing_commission_bps / 100}%
            </p>
            <p className="mt-1 text-[11px] text-[#7d8876]">Subsequent renewals</p>
          </div>
          <div className="rounded-xl border border-[#f0ede5] bg-[#fafbf7] p-4">
            <p className="text-xs font-semibold text-[#677362] uppercase tracking-wider">Hold Period</p>
            <p className="mt-2 text-2xl font-bold text-[#171711]">{data.settings.hold_days} days</p>
            <p className="mt-1 text-[11px] text-[#7d8876]">Refund qualification buffer</p>
          </div>
          <div className="rounded-xl border border-[#f0ede5] bg-[#fafbf7] p-4">
            <p className="text-xs font-semibold text-[#677362] uppercase tracking-wider">Minimum Payout</p>
            <p className="mt-2 text-2xl font-bold text-[#171711]">
              {(data.settings.minimum_payout_cents / 100).toLocaleString('en-US', {
                style: 'currency',
                currency: 'USD',
              })}
            </p>
            <p className="mt-1 text-[11px] text-[#7d8876]">Threshold for transfer</p>
          </div>
        </div>

        <div className="mt-6 flex items-start gap-3 rounded-2xl border border-[#e4e5d9] bg-[#fbfbf8] p-4">
          <ShieldAlert size={19} className="text-[#6d7963] shrink-0 mt-0.5" />
          <div className="text-xs leading-relaxed text-[#677362]">
            <strong className="text-[#171711]">Safety Policy: </strong>
            Financial switches and automated payout execution remain protected until verified production
            settlement testing is completed. Referrals are tracked and safely attributed in the database.
          </div>
        </div>
      </section>
    </div>
  );
}
