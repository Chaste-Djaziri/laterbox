// laterbox-web/src/components/billing/StoragePricingPage.tsx
'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  ArrowRight,
  Check,
  CheckCircle2,
  Cloud,
  HardDrive,
  LockKeyhole,
  RefreshCcw,
  ShieldCheck,
  Sparkles,
  Zap,
} from 'lucide-react';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { useWhopPrices } from '@/lib/billing/use-whop-prices';
import { formatWhopPrice, yearlySavings } from '@/lib/billing/whop-prices';
import { type WhopPlanKey } from '@/lib/billing/storage-plans';
import { hasProAccess } from '@/lib/billing/types';

const freeTier = {
  name: 'Free',
  key: 'free' as const,
  size: '500 MB',
  badge: 'Free Forever',
  description: 'Keep every link and idea together, at no cost.',
  features: [
    'Cross-device sync',
    'Unlimited links and collections',
    'Smart reminders & search',
    'Export your library anytime',
  ],
};

const plusTier = {
  name: 'Plus',
  key: 'plus' as const,
  size: '10 GB',
  badge: 'Most Popular',
  description: 'Extra room for everyday essentials and documents.',
  features: [
    'Everything in Free',
    '10 GB of secure cloud storage',
    'Upload files, images, and PDFs',
    'Full-page saves & media previews',
  ],
};

const sliderTiers = [
  {
    name: 'Plus 50',
    key: 'plus50' as const,
    size: '50 GB',
    description: 'A larger pocket for files, media, and references.',
    features: [
      'Everything in Plus',
      '50 GB of cloud storage',
      'High-resolution PDF & media storage',
      'Unlimited cross-device sync',
    ],
  },
  {
    name: 'Vault 100',
    key: 'vault' as const,
    size: '100 GB',
    description: 'Build a permanent, scalable personal knowledge vault.',
    features: [
      'Everything in Plus',
      '100 GB of cloud storage',
      'Large research documents & media',
      'High-bandwidth background sync',
    ],
  },
  {
    name: 'Vault 250',
    key: 'vault250' as const,
    size: '250 GB',
    description: 'Heavy workspace storage for study, work, and creative assets.',
    features: [
      'Everything in Plus',
      '250 GB of cloud storage',
      'Large project files and archives',
      'Priority cloud processing',
    ],
  },
  {
    name: 'Vault 500',
    key: 'vault500' as const,
    size: '500 GB',
    description: 'For serious collectors, researchers, and studio creators.',
    features: [
      'Everything in Plus',
      '500 GB of cloud storage',
      'Massive document and video libraries',
      'Uncapped file upload speeds',
    ],
  },
  {
    name: 'Vault 1 TB',
    key: 'vault1tb' as const,
    size: '1 TB',
    description: 'Bring your entire digital life and media archive.',
    features: [
      'Everything in Plus',
      '1 TB of cloud storage',
      'Complete digital archive storage',
      'Priority cross-device sync & backups',
    ],
  },
  {
    name: 'Vault 2 TB',
    key: 'vault2tb' as const,
    size: '2 TB',
    description: 'Maximum capacity for power users with massive datasets.',
    features: [
      'Everything in Plus',
      '2 TB of cloud storage',
      'Uncapped storage for life',
      'Priority support and cloud processing',
    ],
  },
] as const;

export function StoragePricingPage({ inApp = false }: { inApp?: boolean }) {
  const [interval, setInterval] = useState<'month' | 'year'>('year');
  const [sliderIndex, setSliderIndex] = useState<number>(1); // Default to Vault 100 GB
  const { prices, loading, error: priceError, retry } = useWhopPrices();
  const { user } = useAuth();
  const { entitlement, manage } = useBilling();
  const [manageError, setManageError] = useState<string | null>(null);
  const [openingPortal, setOpeningPortal] = useState(false);
  const active = Boolean(entitlement.provider && hasProAccess(entitlement));

  const openExistingPlan = async () => {
    if (openingPortal) return;
    setManageError(null);
    setOpeningPortal(true);
    try {
      await manage();
    } catch (err) {
      setManageError(err instanceof Error ? err.message : 'Unable to open subscription management.');
    } finally {
      setOpeningPortal(false);
    }
  };

  const plusSavings = yearlySavings(prices?.plus_month, prices?.plus_year);

  // Active slider tier
  const currentSliderTier = sliderTiers[sliderIndex] ?? sliderTiers[0];
  const sliderKey = `${currentSliderTier.key}_${interval}` as WhopPlanKey;
  const sliderQuote = prices?.[sliderKey] ?? null;
  const sliderSavings =
    interval === 'year'
      ? yearlySavings(
          prices?.[`${currentSliderTier.key}_month` as WhopPlanKey],
          prices?.[`${currentSliderTier.key}_year` as WhopPlanKey]
        )
      : null;

  // Plus tier quote
  const plusKey = `plus_${interval}` as WhopPlanKey;
  const plusQuote = prices?.[plusKey] ?? null;

  return (
    <div
      className={`w-full text-[#171711] ${
        inApp
          ? 'bg-[#f7f5ee] px-4 py-8 pb-32 sm:px-8 sm:pb-40'
          : 'min-h-screen bg-[#f8f9f4] px-4 py-16 sm:px-8'
      }`}
    >
      <div className="mx-auto max-w-6xl">
        {/* Page Header */}
        {inApp ? (
          <header className="mb-8 text-center max-w-2xl mx-auto">
            <span className="inline-flex items-center gap-1.5 rounded-full border border-[#cfd7b5] bg-[#e6edb0] px-3.5 py-1.5 text-[11px] font-black uppercase tracking-[0.14em] text-[#242b1a]">
              <Sparkles size={13} /> Storage plans
            </span>
            <h1 className="mt-4 text-3xl sm:text-4xl font-black tracking-tight text-[#171711]">
              Keep what matters. Choose your space.
            </h1>
            <p className="mt-2 text-sm text-[#697364] leading-relaxed">
              Saving links is always free. Upgrade anytime for extra cloud room from 10 GB to 2 TB.
            </p>
          </header>
        ) : (
          <>
            <header className="mx-auto max-w-3xl text-center">
              <div>
                <span className="inline-flex items-center gap-2 rounded-full border border-[#cfd7b5] bg-[#e6edb0] px-4 py-2 text-[11px] font-black uppercase tracking-[0.16em]">
                  <Sparkles size={14} /> Simple, Transparent Storage
                </span>
                <h1 className="mt-6 text-[clamp(2.5rem,5.5vw,4.5rem)] font-black leading-[1.06] tracking-[-0.055em] text-[#181b14]">
                  Keep what matters.<br />
                  <span className="text-[#678144]">Choose your space.</span>
                </h1>
                <p className="mx-auto mt-5 max-w-xl text-base leading-7 text-[#606458] sm:text-lg font-medium">
                  Saving links is always free. Pick standard storage or slide to customize your high-capacity vault.
                </p>
              </div>
            </header>

            <div className="mt-8 flex flex-wrap items-center justify-center gap-x-7 gap-y-3 text-xs font-semibold text-[#58634e]">
              <span className="flex items-center gap-2">
                <CheckCircle2 size={16} className="text-[#678144]" /> Free cross-device sync
              </span>
              <span className="flex items-center gap-2">
                <CheckCircle2 size={16} className="text-[#678144]" /> Cancel your plan anytime
              </span>
              <span className="flex items-center gap-2">
                <CheckCircle2 size={16} className="text-[#678144]" /> Keep your library forever
              </span>
            </div>
          </>
        )}

        {/* Billing Cycle Toggle */}
        <div className={`${inApp ? 'mt-4' : 'mt-10'} flex flex-col items-center gap-2.5`}>
          <div
            className="inline-flex rounded-full border border-[#e1e5d8] bg-white p-1.5 shadow-xs"
            aria-label="Billing cycle"
          >
            {(['month', 'year'] as const).map((value) => (
              <button
                key={value}
                type="button"
                onClick={() => setInterval(value)}
                aria-pressed={interval === value}
                className={`rounded-full px-5 py-2.5 text-sm font-bold transition-all cursor-pointer ${
                  interval === value
                    ? 'bg-[#181b14] text-white shadow-xs'
                    : 'text-[#606458] hover:text-[#181b14]'
                }`}
              >
                {value === 'month' ? 'Pay monthly' : 'Pay yearly'}
              </button>
            ))}
          </div>
          {plusSavings != null && interval === 'year' && (
            <p className="text-xs font-bold text-[#5e773c]">
              Save up to {plusSavings}% with yearly billing compared to monthly payments.
            </p>
          )}
        </div>

        {/* 3-Card Grid */}
        <div className="mt-10 grid gap-6 grid-cols-1 lg:grid-cols-3 items-stretch">
          {/* Card 1: Free Plan */}
          <section className="relative flex flex-col justify-between overflow-hidden rounded-3xl border border-[#e4e0d5] bg-white p-7 sm:p-8 shadow-xs hover:border-[#181b14]/30 transition-all">
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <span className="inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-[#f0f4e5] text-[#5e773c]">
                  <Cloud size={22} />
                </span>
                <span className="rounded-full px-3 py-1 text-[11px] font-bold bg-[#faf8f5] border border-[#e4e0d5] text-[#606458]">
                  {freeTier.badge}
                </span>
              </div>

              <div>
                <h2 className="text-2xl font-black tracking-tight text-[#181b14]">
                  {freeTier.name}
                </h2>
                <p className="mt-1.5 text-xs sm:text-sm text-[#606458] leading-relaxed">
                  {freeTier.description}
                </p>
              </div>

              {/* Price display */}
              <div className="min-h-[78px] flex flex-col justify-end">
                <div className="text-[44px] font-black tracking-[-0.05em] text-[#181b14] leading-none">
                  $0
                </div>
                <p className="mt-2 text-xs font-medium text-[#7d8375]">
                  Free forever. No credit card required.
                </p>
              </div>

              <div className="h-px bg-[#f0ede4]" />

              {/* Quota + Features */}
              <div className="space-y-4">
                <div className="flex items-center justify-between text-xs font-bold text-[#181b14]">
                  <span>Storage capacity</span>
                  <span className="text-[#5e773c] font-black">{freeTier.size}</span>
                </div>
                <ul className="space-y-3">
                  {freeTier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2.5 text-xs text-[#383d34] leading-snug">
                      <Check size={16} className="mt-0.5 shrink-0 text-[#5e773c]" />
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            <div className="pt-8">
              <Link
                href="/inbox"
                className="w-full flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-bold bg-[#f4f7eb] border border-[#cbd79c] text-[#181b14] hover:bg-[#e6edb0] transition-colors"
              >
                <span>Continue with Free</span>
                <ArrowRight size={16} />
              </Link>
            </div>
          </section>

          {/* Card 2: Plus Plan (10 GB) */}
          <section className="relative flex flex-col justify-between overflow-hidden rounded-3xl border border-[#cbd79c] bg-[#fafaf6] p-7 sm:p-8 shadow-xs hover:border-[#181b14]/30 transition-all">
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <span className="inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#181b14]">
                  <Zap size={22} />
                </span>
                <span className="rounded-full px-3 py-1 text-[11px] font-bold bg-[#e6edb0] border border-[#cbd79c] text-[#181b14]">
                  {plusTier.badge}
                </span>
              </div>

              <div>
                <h2 className="text-2xl font-black tracking-tight text-[#181b14]">
                  LaterBox {plusTier.name}
                </h2>
                <p className="mt-1.5 text-xs sm:text-sm text-[#606458] leading-relaxed">
                  {plusTier.description}
                </p>
              </div>

              {/* Price display */}
              <div className="min-h-[78px] flex flex-col justify-end">
                {loading ? (
                  <div className="h-10 w-28 bg-[#edf0e6] animate-pulse rounded-lg" />
                ) : plusQuote ? (
                  <>
                    <div className="flex items-baseline gap-1.5">
                      <strong className="text-[42px] font-black tracking-[-0.05em] text-[#181b14] leading-none">
                        {formatWhopPrice(plusQuote.renewalPrice, plusQuote.currency)}
                      </strong>
                      <span className="text-xs font-semibold text-[#7d8375]">
                        / {interval === 'month' ? 'month' : 'year'}
                      </span>
                    </div>
                    <p className="mt-2 text-xs font-medium text-[#7d8375]">
                      Billed {interval === 'month' ? 'monthly' : 'annually'} · Cancel anytime
                    </p>
                  </>
                ) : (
                  <div className="text-base font-bold text-[#181b14]">Live price at checkout</div>
                )}
              </div>

              <div className="h-px bg-[#e8e6dc]" />

              {/* Quota + Features */}
              <div className="space-y-4">
                <div className="flex items-center justify-between text-xs font-bold text-[#181b14]">
                  <span>Storage capacity</span>
                  <span className="text-[#5e773c] font-black">{plusTier.size}</span>
                </div>
                <ul className="space-y-3">
                  {plusTier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2.5 text-xs text-[#383d34] leading-snug">
                      <Check size={16} className="mt-0.5 shrink-0 text-[#5e773c]" />
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            <div className="pt-8">
              {active ? (
                entitlement.provider === 'apple' ? (
                  <a
                    href="https://apps.apple.com/account/subscriptions"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-bold bg-[#181b14] text-white hover:bg-[#30392a] transition-colors"
                  >
                    <span>Manage in App Store</span>
                    <ArrowRight size={16} />
                  </a>
                ) : (
                  <button
                    type="button"
                    disabled={openingPortal}
                    onClick={() => void openExistingPlan()}
                    className="w-full flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-bold bg-[#181b14] text-white hover:bg-[#30392a] transition-colors disabled:opacity-50 cursor-pointer"
                  >
                    <span>Manage plan</span>
                    <ArrowRight size={16} />
                  </button>
                )
              ) : (
                <Link
                  href={user ? `/checkout?plan=plus&interval=${interval}` : `/login?next=${encodeURIComponent(`/checkout?plan=plus&interval=${interval}`)}`}
                  className="w-full flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-bold bg-[#181b14] text-white hover:bg-[#30392a] transition-colors shadow-xs"
                >
                  <span>Get LaterBox Plus</span>
                  <ArrowRight size={16} />
                </Link>
              )}
            </div>
          </section>

          {/* Card 3: Dynamic Scalable Storage Card with Slider */}
          <section className="relative flex flex-col justify-between overflow-hidden rounded-3xl border border-[#23291d] bg-[#181b14] text-white p-7 sm:p-8 shadow-sm">
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <span className="inline-flex h-11 w-11 items-center justify-center rounded-2xl bg-white/10 text-white">
                  <HardDrive size={22} />
                </span>
                <span className="rounded-full px-3 py-1 text-[11px] font-bold bg-white/10 border border-white/20 text-[#e6edb0]">
                  Scalable Vault
                </span>
              </div>

              <div>
                <div className="flex items-baseline justify-between gap-2">
                  <h2 className="text-2xl font-black tracking-tight text-white">
                    {currentSliderTier.name}
                  </h2>
                  <span className="text-base font-black text-[#e6edb0]">
                    {currentSliderTier.size}
                  </span>
                </div>
                <p className="mt-1.5 text-xs sm:text-sm text-[#9ea895] leading-relaxed">
                  {currentSliderTier.description}
                </p>
              </div>

              {/* Dynamic Interactive Slider Controls */}
              <div className="space-y-3.5 pt-1">
                <div className="flex items-center justify-between text-xs font-bold text-[#b5c2ab]">
                  <span>Adjust storage size:</span>
                  <span className="font-mono text-[#e6edb0]">{currentSliderTier.size}</span>
                </div>

                {/* Range Slider */}
                <div className="relative pt-1 pb-1">
                  <input
                    type="range"
                    min={0}
                    max={sliderTiers.length - 1}
                    step={1}
                    value={sliderIndex}
                    onChange={(e) => setSliderIndex(Number(e.target.value))}
                    aria-label="Storage capacity slider"
                    className="w-full h-2.5 bg-white/20 rounded-lg appearance-none cursor-pointer accent-[#e6edb0] focus:outline-none"
                  />
                </div>

                {/* Quick Step Buttons */}
                <div className="grid grid-cols-6 gap-1 text-[11px] font-bold text-center">
                  {sliderTiers.map((tier, idx) => {
                    const isSelected = idx === sliderIndex;
                    return (
                      <button
                        key={tier.key}
                        type="button"
                        onClick={() => setSliderIndex(idx)}
                        className={`py-1 rounded-md transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-[#e6edb0] text-[#181b14] font-black scale-105 shadow-2xs'
                            : 'text-[#8e9c85] hover:text-white hover:bg-white/10'
                        }`}
                      >
                        {tier.size}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Price display for active slider selection */}
              <div className="min-h-[78px] flex flex-col justify-end pt-1">
                {loading ? (
                  <div className="h-10 w-28 bg-white/10 animate-pulse rounded-lg" />
                ) : sliderQuote ? (
                  <>
                    <div className="flex items-baseline gap-1.5">
                      <strong className="text-[42px] font-black tracking-[-0.05em] text-white leading-none">
                        {formatWhopPrice(sliderQuote.renewalPrice, sliderQuote.currency)}
                      </strong>
                      <span className="text-xs font-semibold text-[#9ea895]">
                        / {interval === 'month' ? 'month' : 'year'}
                      </span>
                      {sliderSavings != null && sliderSavings > 0 && interval === 'year' && (
                        <span className="ml-2 rounded-full px-2.5 py-0.5 text-[10px] font-black bg-[#e6edb0]/20 text-[#e6edb0] border border-[#e6edb0]/30">
                          Save {sliderSavings}%
                        </span>
                      )}
                    </div>
                    <p className="mt-2 text-xs font-medium text-[#9ea895]">
                      {sliderQuote.currency} rate via Whop · Cancel anytime
                    </p>
                  </>
                ) : (
                  <div className="text-base font-bold text-white">Live price at checkout</div>
                )}
              </div>

              <div className="h-px bg-white/15" />

              {/* Features of selected slider plan */}
              <div className="space-y-4">
                <div className="flex items-center justify-between text-xs font-bold text-white">
                  <span>Included with {currentSliderTier.name}</span>
                  <span className="text-[#e6edb0] font-black">{currentSliderTier.size}</span>
                </div>
                <ul className="space-y-3">
                  {currentSliderTier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2.5 text-xs text-[#cfd9c8] leading-snug">
                      <Check size={16} className="mt-0.5 shrink-0 text-[#e6edb0]" />
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            <div className="pt-8">
              {active ? (
                entitlement.provider === 'apple' ? (
                  <a
                    href="https://apps.apple.com/account/subscriptions"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-bold bg-[#e6edb0] text-[#181b14] hover:bg-[#d8e39f] transition-colors"
                  >
                    <span>Manage in App Store</span>
                    <ArrowRight size={16} />
                  </a>
                ) : (
                  <button
                    type="button"
                    disabled={openingPortal}
                    onClick={() => void openExistingPlan()}
                    className="w-full flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-bold bg-[#e6edb0] text-[#181b14] hover:bg-[#d8e39f] transition-colors disabled:opacity-50 cursor-pointer"
                  >
                    <span>Manage plan</span>
                    <ArrowRight size={16} />
                  </button>
                )
              ) : (
                <Link
                  href={
                    user
                      ? `/checkout?plan=${currentSliderTier.key}&interval=${interval}`
                      : `/login?next=${encodeURIComponent(`/checkout?plan=${currentSliderTier.key}&interval=${interval}`)}`
                  }
                  className="w-full flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-sm font-bold bg-[#e6edb0] text-[#181b14] hover:bg-[#d8e39f] transition-colors shadow-xs"
                >
                  <span>Get LaterBox {currentSliderTier.name}</span>
                  <ArrowRight size={16} />
                </Link>
              )}
            </div>
          </section>
        </div>

        {/* Error States */}
        {manageError && (
          <p
            role="alert"
            className="mx-auto mt-6 max-w-xl rounded-xl border border-red-200 bg-red-50 p-3 text-center text-xs font-semibold text-red-700"
          >
            {manageError}
          </p>
        )}

        {priceError && (
          <div
            className="mx-auto mt-6 flex max-w-xl flex-wrap items-center justify-center gap-3 text-center text-xs text-[#9b6439]"
            role="alert"
          >
            <span>Live Whop pricing could not be loaded. Payments will display their final price before confirmation.</span>
            <button
              onClick={retry}
              type="button"
              className="inline-flex items-center gap-1 font-black underline underline-offset-2 cursor-pointer"
            >
              <RefreshCcw size={13} /> Retry pricing
            </button>
          </div>
        )}

        {/* Value Pillars */}
        <section
          className={`mt-16 grid gap-6 rounded-3xl border bg-white px-7 py-8 sm:grid-cols-3 sm:px-10 ${
            inApp ? 'border-[#e4e0d5]' : 'border-[#e2e7da]'
          }`}
        >
          <div className="flex gap-3">
            <ShieldCheck className="mt-0.5 shrink-0 text-[#678144]" size={22} />
            <div>
              <h3 className="text-sm font-bold text-[#181b14]">Your data, always yours</h3>
              <p className="mt-1 text-xs leading-5 text-[#606458]">
                Cancel a paid plan without losing access to your saved links, bookmarks, and local library.
              </p>
            </div>
          </div>
          <div className="flex gap-3">
            <Cloud className="mt-0.5 shrink-0 text-[#678144]" size={22} />
            <div>
              <h3 className="text-sm font-bold text-[#181b14]">Sync for everyone</h3>
              <p className="mt-1 text-xs leading-5 text-[#606458]">
                Free and paid accounts sync smoothly across your phone, tablet, browser, and computer.
              </p>
            </div>
          </div>
          <div className="flex gap-3">
            <LockKeyhole className="mt-0.5 shrink-0 text-[#678144]" size={22} />
            <div>
              <h3 className="text-sm font-bold text-[#181b14]">Secure checkout</h3>
              <p className="mt-1 text-xs leading-5 text-[#606458]">
                Whop handles transactions, local currencies, taxes, and instant cancellation controls.
              </p>
            </div>
          </div>
        </section>

        <p className="mt-7 text-center text-xs leading-5 text-[#858e7f]">
          Rates are processed via Whop in the plan currency. Taxes, conversion, and regional fees are calculated during checkout. Existing Apple subscriptions remain managed through your Apple ID.
        </p>
        <p className="mt-3 text-center text-xs text-[#929b8e]">
          <Link className="underline hover:text-[#181b14]" href="/terms">
            Terms of Service
          </Link>{' '}
          ·{' '}
          <Link className="underline hover:text-[#181b14]" href="/refund">
            Refund Policy
          </Link>
        </p>
      </div>
    </div>
  );
}
