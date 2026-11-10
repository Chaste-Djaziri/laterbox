// laterbox-web/src/components/admin/AdminPlansView.tsx
'use client';

import { ArrowUpRight, CreditCard } from 'lucide-react';
import { useAdmin } from './AdminContext';

const quota = (n: number) =>
  n >= 1024 ** 4 ? Math.round(n / 1024 ** 4) + ' TB' : Math.round(n / 1024 ** 3) + ' GB';

export function AdminPlansView() {
  const { data } = useAdmin();

  if (!data) return null;

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-4 border-b border-[#f0ede5] pb-5">
          <div>
            <div className="flex items-center gap-2">
              <CreditCard size={20} className="text-[#435b34]" />
              <h2 className="font-bold text-base text-[#171711]">Whop storage catalog</h2>
            </div>
            <p className="mt-1 text-xs text-[#677362]">
              Production SKU mapping and assigned storage limits. Edit prices in Whop to keep billing accurate.
            </p>
          </div>
          <a
            href="https://whop.com/dashboard/"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 rounded-xl bg-[#e6edb0] px-4 py-2.5 text-sm font-bold text-[#182013] shadow-sm hover:bg-[#dae49f] transition-colors"
          >
            <span>Manage pricing in Whop</span>
            <ArrowUpRight size={15} />
          </a>
        </div>

        <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {data.plans.map(p => (
            <div
              key={p.provider_price_id}
              className="rounded-2xl border border-[#e4e5d9] bg-[#fafbf6] p-5 shadow-sm transition-all hover:border-[#c5d3a5]"
            >
              <div className="flex items-center justify-between">
                <p className="font-bold text-sm tracking-wide text-[#171711]">
                  {p.sku_key.replaceAll('_', ' ').toUpperCase()}
                </p>
                <span className="rounded-md bg-[#edf0e2] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-[#54624b]">
                  {p.family}
                </span>
              </div>
              <div className="mt-4 flex items-center justify-between text-sm text-[#677362]">
                <span className="font-bold text-lg text-[#171711]">{quota(p.quotaBytes)}</span>
                <span className="font-medium">
                  {p.trial_days ? `${p.trial_days}-day trial` : 'Standard subscription'}
                </span>
              </div>
              <div className="mt-4 border-t border-[#f0ede5] pt-3">
                <p className="text-[10px] uppercase tracking-wider text-[#8a9482] font-semibold">Price ID</p>
                <p className="mt-0.5 truncate font-mono text-[11px] text-[#677362]">
                  {p.provider_price_id}
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

