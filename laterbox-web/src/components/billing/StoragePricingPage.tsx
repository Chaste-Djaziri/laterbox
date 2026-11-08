// laterbox-web/src/components/billing/StoragePricingPage.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  ArrowRight, Check, CheckCircle2, Cloud, HardDrive, LockKeyhole, RefreshCcw,
  ShieldCheck, Sparkles, Zap,
} from 'lucide-react';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { useWhopPrices } from '@/lib/billing/use-whop-prices';
import { formatWhopPrice, yearlySavings } from '@/lib/billing/whop-prices';
import { type WhopPlanKey } from '@/lib/billing/storage-plans';

const tiers = [
  {
    name: 'Free', key: 'free', size: '500 MB', description: 'A home for every link, without a subscription.',
    features: ['Sync across all your devices', 'Unlimited links and collections', 'Smart reminders and search', 'Export your library anytime'],
  },
  {
    name: 'Plus', key: 'plus', size: '10 GB', description: 'A little more room for everything worth keeping.',
    features: ['Everything in Free', 'Save files, images and PDFs', 'Keep full-page copies', 'Manage cloud storage easily'],
  },
  {
    name: 'Vault', key: 'vault', size: '100 GB', description: 'Your growing digital library, with room to spare.',
    features: ['Everything in Plus', '100 GB cloud storage', 'Room for bigger documents', 'Space for a growing archive'],
  },
] as const;

export function StoragePricingPage({ inApp = false }: { inApp?: boolean }) {
  const [interval, setInterval] = useState<'month' | 'year'>('year');
  const { prices, loading, error: priceError, retry } = useWhopPrices();
  const { user } = useAuth();
  const { entitlement } = useBilling();
  const active = Boolean(entitlement.provider && entitlement.status !== 'free');
  const plusSavings = yearlySavings(prices?.plus_month, prices?.plus_year);

  return (
    <main className={`min-h-screen overflow-hidden bg-[#f8f9f4] text-[#171b14] ${inApp ? 'px-4 py-10 sm:px-8' : 'px-4 py-16 sm:px-8'}`}>
      <div className="mx-auto max-w-6xl">
        {!inApp && (
          <>
        <header className="relative mx-auto max-w-3xl text-center">
          <div className="pointer-events-none absolute -top-28 left-1/2 -z-0 h-72 w-96 -translate-x-1/2 rounded-full bg-[#e6edb0]/55 blur-[85px]" />
          <div className="relative">
            <span className="inline-flex items-center gap-2 rounded-full border border-[#cfd7b5] bg-[#e6edb0] px-4 py-2 text-[11px] font-black uppercase tracking-[0.16em]">
              <Sparkles size={14} /> Storage that fits your life
            </span>
            <h1 className="mt-7 text-[clamp(2.7rem,6vw,4.8rem)] font-black leading-[1.06] tracking-[-0.055em]">
              Keep what matters.<br /><span className="text-[#84975a]">Leave the clutter.</span>
            </h1>
            <p className="mx-auto mt-6 max-w-xl text-base leading-7 text-[#697364] sm:text-lg">
              Saving links is always free. Get more secure cloud space only when your library needs it.
              No complicated bundles, just space to grow.
            </p>
          </div>
        </header>

        <div className="mt-10 flex flex-wrap items-center justify-center gap-x-7 gap-y-3 text-xs font-semibold text-[#58634e]">
          <span className="flex items-center gap-2"><CheckCircle2 size={16} className="text-[#819b51]" /> Free cross-device sync</span>
          <span className="flex items-center gap-2"><CheckCircle2 size={16} className="text-[#819b51]" /> Cancel your paid plan anytime</span>
          <span className="flex items-center gap-2"><CheckCircle2 size={16} className="text-[#819b51]" /> Keep your library on Free</span>
        </div>

          </>
        )}

        <div className={`${inApp ? "mt-0" : "mt-11"} flex flex-col items-center gap-3`}>
          <div className="inline-flex rounded-full border border-[#e1e5d8] bg-white p-1.5 shadow-sm" aria-label="Billing cycle">
            {(['month', 'year'] as const).map(value => (
              <button key={value} type="button" onClick={() => setInterval(value)}
                aria-pressed={interval === value}
                className={`rounded-full px-5 py-2.5 text-sm font-bold transition-all ${interval === value ? 'bg-[#1a2116] text-white shadow-sm' : 'text-[#7a8273] hover:text-[#1a2116]'}`}>
                {value === 'month' ? 'Pay monthly' : 'Pay yearly'}
              </button>
            ))}
          </div>
          {plusSavings != null && <p className="text-xs text-[#727f64]">Save up to {plusSavings}% on Plus with yearly billing, compared with 12 monthly payments.</p>}
        </div>

        <div className="mt-9 grid gap-5 lg:grid-cols-3 lg:items-stretch">
          {tiers.map(tier => {
            const featured = tier.key === 'plus';
            const isFree = tier.key === 'free';
            const key = isFree ? null : `${tier.key}_${interval}` as WhopPlanKey;
            const quote = key ? prices?.[key] : null;
            const saving = !isFree && interval === 'year' ? yearlySavings(prices?.[`${tier.key}_month` as WhopPlanKey], prices?.[`${tier.key}_year` as WhopPlanKey]) : null;
            const href = isFree ? '/inbox' : `/checkout?plan=${tier.key}&interval=${interval}`;
            const destination = user || isFree ? href : `/login?next=${encodeURIComponent(href)}`;
            return (
              <section key={tier.key} className={`group relative flex flex-col overflow-hidden rounded-[30px] border p-7 transition-transform duration-300 hover:-translate-y-1 sm:p-8 ${featured ? 'border-[#20291b] bg-[#1b2218] text-white shadow-[0_24px_60px_rgba(29,39,20,.16)]' : 'border-[#e0e4d9] bg-white shadow-[0_12px_32px_rgba(28,39,21,.04)]'}`}>
                {featured && <div className="pointer-events-none absolute -right-16 -top-24 h-56 w-56 rounded-full bg-[#c7df86]/10 blur-2xl" />}
                <div className="relative flex items-center justify-between">
                  <span className={`inline-flex size-11 items-center justify-center rounded-2xl ${featured ? 'bg-[#e6edb0] text-[#20291b]' : 'bg-[#f0f4e5] text-[#748851]'}`}>
                    {tier.key === 'vault' ? <HardDrive size={21} /> : tier.key === 'plus' ? <Zap size={21} /> : <Cloud size={21} />}
                  </span>
                  {featured && <span className="rounded-full border border-[#a8b989]/30 bg-[#e6edb0]/10 px-3 py-1.5 text-[10px] font-black uppercase tracking-widest text-[#e6edb0]">Most popular</span>}
                  {saving != null && saving > 0 && !featured && <span className="rounded-full bg-[#edf5d8] px-3 py-1.5 text-[11px] font-black text-[#526f2b]">Save {saving}%</span>}
                </div>
                <h2 className="mt-7 text-2xl font-black tracking-tight">LaterBox {tier.name}</h2>
                <p className={`mt-2 min-h-12 text-sm leading-6 ${featured ? 'text-[#bbc6b5]' : 'text-[#737e6d]'}`}>{tier.description}</p>
                <div className="mt-7 min-h-[106px]">
                  {isFree ? (
                    <><div className="text-[44px] font-black tracking-[-0.05em]">Free</div><p className="mt-1 text-xs text-[#82917b]">No credit card. Ever.</p></>
                  ) : loading ? (
                    <div role="status" aria-label="Loading Whop pricing"><div className={`mt-3 h-11 w-36 animate-pulse rounded-lg ${featured ? 'bg-white/10' : 'bg-[#edf0e6]'}`} /><p className="mt-3 text-xs opacity-60">Checking Whop pricing…</p></div>
                  ) : quote ? (
                    <>
                      <div className="flex flex-wrap items-end gap-2">
                        <strong className="text-[44px] font-black tracking-[-0.055em]">{formatWhopPrice(quote.renewalPrice, quote.currency)}</strong>
                        <span className={`mb-2 text-sm ${featured ? 'text-[#b3bfad]' : 'text-[#7b8473]'}`}>/ {interval === 'month' ? '30 days' : '365 days'}</span>
                      </div>
                      <p className={`mt-1 text-xs ${featured ? 'text-[#b9c6ae]' : 'text-[#84907b]'}`}>{quote.currency} base rate · Final total in checkout</p>
                    </>
                  ) : (
                    <><p className="mt-3 text-base font-black">Live price unavailable</p><p className="mt-2 text-xs opacity-70">View the final amount at checkout.</p></>
                  )}
                </div>
                <div className={`my-7 h-px ${featured ? 'bg-white/15' : 'bg-[#edf0e9]'}`} />
                <div className="flex items-baseline justify-between"><strong className="text-sm">Included with {tier.name}</strong><span className={`text-xs font-bold ${featured ? 'text-[#e6edb0]' : 'text-[#71865e]'}`}>{tier.size}</span></div>
                <ul className="mt-5 flex-1 space-y-3.5">
                  {tier.features.map(feature => <li key={feature} className="flex items-start gap-2.5 text-[13px] leading-5">
                    <Check size={17} className={`mt-0.5 shrink-0 ${featured ? 'text-[#d2e5a2]' : 'text-[#8ca66c]'}`}/><span className={featured ? 'text-[#e4eadf]' : 'text-[#4d5b46]'}>{feature}</span>
                  </li>)}
                </ul>
                <Link href={destination} className={`mt-9 flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-black transition-colors ${featured ? 'bg-[#e6edb0] text-[#1c2516] hover:bg-[#d7e29f]' : 'bg-[#1b2218] text-white hover:bg-[#34402d]'}`}>
                  {isFree ? 'Continue with Free' : active ? 'View ' + tier.name : 'Get ' + tier.name}
                  <ArrowRight size={16} />
                </Link>
              </section>
            );
          })}
        </div>

        {priceError && (
          <div className="mx-auto mt-5 flex max-w-xl flex-wrap items-center justify-center gap-3 text-center text-xs text-[#9b6439]" role="alert">
            <span>Live Whop pricing could not be loaded. Payments will display their final price before confirmation.</span>
            <button onClick={retry} type="button" className="inline-flex items-center gap-1 font-black underline underline-offset-2"><RefreshCcw size={13}/> Retry pricing</button>
          </div>
        )}

        <section className="mt-16 grid gap-6 rounded-[28px] border border-[#e2e7da] bg-white px-7 py-8 sm:grid-cols-3 sm:px-10">
          <div className="flex gap-3"><ShieldCheck className="mt-0.5 shrink-0 text-[#778e54]" size={22}/><div><h3 className="text-sm font-black">Your data, always yours</h3><p className="mt-1 text-xs leading-5 text-[#7e8974]">Cancel a paid plan without losing access to your regular bookmarks.</p></div></div>
          <div className="flex gap-3"><Cloud className="mt-0.5 shrink-0 text-[#778e54]" size={22}/><div><h3 className="text-sm font-black">Sync for everyone</h3><p className="mt-1 text-xs leading-5 text-[#7e8974]">A Free account can sync your links across compatible LaterBox apps.</p></div></div>
          <div className="flex gap-3"><LockKeyhole className="mt-0.5 shrink-0 text-[#778e54]" size={22}/><div><h3 className="text-sm font-black">Secure payments</h3><p className="mt-1 text-xs leading-5 text-[#7e8974]">Whop handles payments, taxes, and available express wallets.</p></div></div>
        </section>
        <p className="mt-7 text-center text-xs leading-5 text-[#858e7f]">
          Plan rates come directly from Whop in the plan currency. Taxes, discounts, conversion and payment fees (if applicable) are calculated in Whop checkout.
          Existing Apple and Paddle subscriptions remain with their original providers.
        </p>
        <p className="mt-3 text-center text-xs text-[#929b8e]"><Link className="underline hover:text-[#34402d]" href="/terms">Terms</Link> · <Link className="underline hover:text-[#34402d]" href="/refund">Refunds</Link></p>
      </div>
    </main>
  );
}
