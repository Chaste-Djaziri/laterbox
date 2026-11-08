'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Check, Cloud, HardDrive, LockKeyhole } from 'lucide-react';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { WHOP_STORAGE_PLANS } from '@/lib/billing/storage-plans';

const tiers = [
  { name: 'Free', key: 'free', size: '500 MB', features: ['Free sync across Web, iOS and Chrome', 'Unlimited ordinary bookmarks', 'Collections, scheduling and search', 'Local reading and exports'] },
  { name: 'Plus', key: 'plus', size: '10 GB', features: ['Everything in Free', 'Cloud PDFs, images and files', 'Permanent offline content copies', 'Cloud storage management'] },
  { name: 'Vault', key: 'vault', size: '100 GB', features: ['Everything in Plus', '100 GB cloud storage', 'Room for a larger document library', 'More space for archived pages'] },
] as const;

export function StoragePricingPage({ inApp = false }: { inApp?: boolean }) {
  const [interval, setInterval] = useState<'month' | 'year'>('year');
  const [error, setError] = useState('');
  const { user } = useAuth();
  const { entitlement, manage } = useBilling();
  const active = Boolean(entitlement.provider && (entitlement.accessEndsAt === null || Date.parse(entitlement.accessEndsAt) > Date.now()));
  const limit = entitlement.storageLimitBytes ?? 500_000_000;
  const used = entitlement.storageUsedBytes;
  const percent = used == null ? 0 : Math.min(100, Math.round(used / Math.max(1, limit) * 100));
  return (
    <main className={inApp ? 'min-h-screen bg-[#f7f5ee] px-4 py-8 text-[#171711]' : 'min-h-screen bg-[#f7f5ee] px-5 py-16 text-[#171711]'}>
      <div className="mx-auto max-w-6xl">
        <header className="mx-auto max-w-2xl text-center">
          <span className="inline-flex items-center gap-2 rounded-full bg-[#e6edb0] px-4 py-2 text-xs font-black uppercase tracking-widest"><Cloud size={15} /> LaterBox Storage</span>
          <h1 className="mt-6 text-4xl font-black tracking-tight sm:text-5xl">Save anywhere. Keep more when you need it.</h1>
          <p className="mt-5 text-base leading-7 text-[#64705a]">Sync links and collections across Web, iOS and Chrome for free. Pay for additional cloud storage, not access to your own devices.</p>
        </header>
        {user && <section className="mx-auto mt-8 max-w-xl rounded-2xl border border-[#dae0d1] bg-white p-5">
          <div className="flex justify-between gap-4"><span className="text-sm font-bold">Your plan: {(entitlement.storagePlan ?? 'free').toUpperCase()}</span><span className="text-sm text-[#68725f]">{used == null ? 'Usage unavailable' : (used / 1e9).toFixed(2) + ' GB used'}</span></div>
          <div className="mt-3 h-2 overflow-hidden rounded-full bg-[#edf0e7]"><div className="h-full rounded-full bg-[#a6b877]" style={{ width: percent + '%' }}/></div>
          <div className="mt-2 text-right text-xs text-[#68725f]">{(limit / 1e9).toFixed(limit < 1e9 ? 1 : 0)} GB total</div>
          {active && <button onClick={() => { void manage().catch(e => setError(e instanceof Error ? e.message : 'Unable to manage subscription.')); }} className="mt-3 text-sm font-bold underline">Manage subscription ({entitlement.provider})</button>}
        </section>}
        <div className="mx-auto mt-9 flex w-fit gap-1 rounded-full border border-[#dadecf] bg-white p-1">
          {(['month','year'] as const).map(value => <button key={value} onClick={() => setInterval(value)} type="button" className={'rounded-full px-5 py-2.5 text-sm font-bold ' + (interval === value ? 'bg-[#171711] text-white' : 'text-[#65705f]')}>{value === 'month' ? 'Monthly' : 'Yearly · save 2 months'}</button>)}
        </div>
        <div className="mt-8 grid gap-4 lg:grid-cols-3">
          {tiers.map(tier => {
            const featured = tier.key === 'plus';
            const isFree = tier.key === 'free';
            const plan = isFree ? null : WHOP_STORAGE_PLANS[(tier.key + '_' + interval) as keyof typeof WHOP_STORAGE_PLANS];
            const href = isFree ? '/inbox' : '/checkout?plan=' + tier.key + '&interval=' + interval;
            const destination = user || isFree ? href : '/login?next=' + encodeURIComponent(href);
            return <section key={tier.key} className={'flex flex-col rounded-[28px] border p-7 ' + (featured ? 'border-[#9fac80] bg-[#171711] text-white' : 'border-[#dce2d4] bg-white')}>
              <div className="flex justify-between items-center"><h2 className="text-xl font-black">{tier.name}</h2>{featured && <span className="rounded-full bg-[#e6edb0] px-3 py-1 text-xs font-black text-black">POPULAR</span>}</div>
              <div className="mt-5 flex items-center gap-3"><span className="text-4xl font-black">{tier.size}</span><HardDrive size={20} className="opacity-60"/></div>
              <p className="mt-4 text-2xl font-black">{isFree ? 'Free forever' : '$' + plan?.usd.toFixed(2)} {!isFree && <span className="text-xs font-semibold opacity-70">{interval === 'year' ? '/year' : '/month'}</span>}</p>
              <div className="my-6 h-px bg-current opacity-10"/>
              <div className="flex-1 space-y-3">{tier.features.map(f => <div key={f} className="flex gap-2 text-sm"><Check size={16} className={'mt-0.5 shrink-0 ' + (featured ? 'text-[#e6edb0]' : 'text-[#839953]')}/><span>{f}</span></div>)}</div>
              <Link href={destination} className={'mt-8 rounded-xl px-5 py-3 text-center text-sm font-black ' + (featured ? 'bg-[#e6edb0] text-[#171711]' : 'bg-[#171711] text-white')}>{isFree ? 'Continue free' : 'Choose ' + tier.name}</Link>
            </section>;
          })}
        </div>
        {error && <p className="mt-5 text-center text-sm text-red-700" role="alert">{error}</p>}
        <p className="mt-8 flex items-center justify-center gap-2 text-center text-xs text-[#6d7568]"><LockKeyhole size={14}/> Embedded Whop checkout. Existing Apple and Paddle subscriptions remain managed with their original providers.</p>
        <p className="mt-3 text-center text-xs text-[#7e8679]">Prices are USD reference amounts; the final total and any taxes appear at checkout.</p>
      </div>
    </main>
  );
}
