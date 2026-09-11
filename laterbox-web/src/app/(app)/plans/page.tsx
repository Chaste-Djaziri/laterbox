'use client';

import React, { Suspense, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import {
  Crown,
  Check,
  Sparkles,
  Cloud,
  LockKeyhole,
  Database,
  ExternalLink,
  Loader2,
  AlertCircle,
  Clock,
  ShieldCheck,
  Layers,
  ArrowRight,
} from 'lucide-react';
import { presentEntitlement } from '@/lib/billing/types';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';

type Interval = 'month' | 'year';

const freeFeatures = [
  'Unlimited local saves',
  'Instant offline search & organization',
  'Full reader mode with clean typography',
  'Local attachments and document storage',
  'Complete JSON & Markdown data exports',
  'Works without an account or internet',
];

const proFeatures = [
  'Everything in Free tier',
  'Real-time cloud sync across all devices',
  'Cloud-backed attachments, images, and PDFs',
  'Browser extensions (Chrome, Safari, Firefox)',
  'System share sheet integration (iOS & Android)',
  'macOS companion notch & screen OCR Watch Mode',
  'Instant deduplication & automatic enrichment',
  'Priority feature access & continuous updates',
];

export default function AppPlansPage() {
  return (
    <Suspense
      fallback={
        <div className="flex h-64 items-center justify-center">
          <Loader2 className="w-6 h-6 animate-spin text-[#171711]" />
        </div>
      }
    >
      <AppPlansContent />
    </Suspense>
  );
}

function AppPlansContent() {
  const { user } = useAuth();
  const searchParams = useSearchParams();
  const {
    entitlement,
    isPro,
    subscribe,
    manage,
    checkoutState,
    previewPrices,
    loading: billingLoading,
  } = useBilling();

  const [interval, setInterval] = useState<Interval>(() =>
    searchParams.get('plan') === 'month' ? 'month' : 'year'
  );
  const [busy, setBusy] = useState<Interval | 'manage' | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [prices, setPrices] = useState<Record<string, string>>({});

  const isProduction = process.env.NEXT_PUBLIC_PADDLE_ENV === 'production';
  const monthlyId = isProduction
    ? process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD ||
      process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID ||
      ''
    : process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID || '';
  const annualId = isProduction
    ? process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD ||
      process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID ||
      ''
    : process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID || '';

  const presentation = useMemo(() => presentEntitlement(entitlement), [entitlement]);

  useEffect(() => {
    const ids = [monthlyId, annualId].filter(Boolean);
    if (ids.length !== 2) return;
    let active = true;
    previewPrices(ids)
      .then((value) => active && setPrices(value))
      .catch(() => active && setPrices({}));
    return () => {
      active = false;
    };
  }, [monthlyId, annualId, previewPrices]);

  async function handleAction(action: Interval | 'manage') {
    setBusy(action);
    setMessage(null);
    try {
      if (action === 'manage') {
        await manage();
      } else {
        if (!user) {
          window.location.assign(`/login?next=${encodeURIComponent('/plans?plan=' + action)}`);
          return;
        }
        await subscribe(action);
      }
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Billing is temporarily unavailable.');
    } finally {
      setBusy(null);
    }
  }

  const autoCheckoutTriggered = useRef(false);
  useEffect(() => {
    const shouldCheckout = searchParams.get('checkout') === 'true';
    if (!shouldCheckout || !user || isPro || autoCheckoutTriggered.current || busy !== null || billingLoading) return;
    autoCheckoutTriggered.current = true;
    const timer = window.setTimeout(() => {
      void handleAction(interval);
    }, 400);
    return () => window.clearTimeout(timer);
  }, [billingLoading, busy, interval, isPro, searchParams, user]);

  const selectedId = interval === 'month' ? monthlyId : annualId;
  const localizedPrice = prices[selectedId] || (interval === 'month' ? '$3.99' : '$39.99');

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-8 py-8 sm:py-10 space-y-8">
      {searchParams.get('source') === 'extension' && (
        <div className="rounded-2xl border border-[#d0db84] bg-[#fbffdc] px-4 py-3 text-center text-xs font-bold text-[#444a10]">
          ⚡ Upgrade to LaterBox Pro below to activate and use your browser extension.
        </div>
      )}

      {/* Top Breadcrumb / Header */}
      <div className="space-y-1">
        <div className="flex items-center gap-2 text-xs font-bold text-[#6c6b63]">
          <Link href="/settings" className="hover:text-[#171711] transition-colors">
            Settings
          </Link>
          <span>/</span>
          <span className="text-[#171711]">Plans &amp; Subscription</span>
        </div>
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-[#171711] flex items-center gap-2.5">
          <Crown className="w-6 h-6 text-[#171711]" />
          <span>Plans &amp; Subscription</span>
        </h1>
        <p className="text-xs sm:text-sm text-[#6c6b63] font-medium max-w-2xl">
          LaterBox gives you unlimited local reading and organization for free. Upgrade to LaterBox Pro to unlock real-time cloud sync, attachments, and automated capture on all your devices.
        </p>
      </div>

      {/* Current Subscription Status Banner */}
      <div className="rounded-3xl border border-[#e4e0d5] bg-[#171711] p-6 sm:p-7 text-white shadow-sm">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-5">
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <Crown
                className={`size-5 ${
                  presentation.tone === 'warning' ? 'text-amber-300' : 'text-[#d7ff27]'
                }`}
              />
              <span className="font-extrabold text-sm sm:text-base text-white">
                {presentation.label}
              </span>
              <span className="px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-white/10 text-zinc-300">
                Current Plan
              </span>
            </div>
            <p className="text-xs text-zinc-300 max-w-xl leading-relaxed">
              {presentation.description}
            </p>
            {presentation.progress !== null && (
              <div className="mt-2 h-1.5 max-w-md overflow-hidden rounded-full bg-white/15">
                <div
                  className={`h-full ${
                    presentation.tone === 'warning' ? 'bg-amber-300' : 'bg-[#d7ff27]'
                  }`}
                  style={{ width: `${Math.round(presentation.progress * 100)}%` }}
                />
              </div>
            )}
            {entitlement.billingWarning && (
              <p className="text-xs font-bold text-amber-300 flex items-center gap-1.5 mt-1">
                <AlertCircle className="w-3.5 h-3.5" />
                <span>Payment needs attention. Update your payment method to avoid losing Pro access.</span>
              </p>
            )}
            {message && (
              <p className="text-xs font-bold text-red-300 flex items-center gap-1.5 mt-1">
                <AlertCircle className="w-3.5 h-3.5" />
                <span>{message}</span>
              </p>
            )}
          </div>

          <div className="shrink-0 flex items-center gap-3">
            {isPro && entitlement.provider === 'paddle' ? (
              <button
                type="button"
                disabled={busy !== null || billingLoading}
                onClick={() => handleAction('manage')}
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-white hover:bg-zinc-100 text-[#171711] text-xs font-black transition-colors disabled:opacity-50 cursor-pointer shadow-sm"
              >
                {busy === 'manage' && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                <span>{presentation.actionLabel || 'Manage Subscription'}</span>
              </button>
            ) : isPro && entitlement.provider === 'apple' ? (
              <div className="rounded-xl border border-white/20 px-4 py-2 text-xs font-bold text-zinc-200">
                Managed via Apple ID
              </div>
            ) : (
              <button
                type="button"
                onClick={() => {
                  const target = document.getElementById('pro-plan-card');
                  target?.scrollIntoView({ behavior: 'smooth' });
                }}
                className="inline-flex items-center gap-1.5 px-5 py-2.5 rounded-xl bg-[#d7ff27] hover:bg-[#cbf71e] text-black text-xs font-black transition-colors cursor-pointer shadow-sm"
              >
                <Sparkles className="w-3.5 h-3.5" />
                <span>Upgrade to Pro</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Checkout Status Notice */}
      {checkoutState !== 'idle' && (
        <div
          role="status"
          className={`rounded-2xl border px-5 py-4 text-xs font-bold ${
            checkoutState === 'confirmed'
              ? 'border-emerald-200 bg-emerald-50 text-emerald-800'
              : 'border-amber-200 bg-amber-50 text-amber-900'
          }`}
        >
          {checkoutState === 'processing' && 'Payment received. Confirming Pro with the billing service…'}
          {checkoutState === 'confirmed' && 'LaterBox Pro is now active on your account!'}
          {checkoutState === 'delayed' &&
            'Your payment is complete. Activation is processing and will appear automatically in a few moments.'}
        </div>
      )}

      {/* Billing Interval Toggle */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2">
        <div>
          <h2 className="text-lg font-black text-[#171711]">Choose Your Plan</h2>
          <p className="text-xs text-[#6c6b63]">
            Upgrade or switch intervals anytime. Subscriptions include a 14-day free trial.
          </p>
        </div>

        <div className="inline-flex rounded-full border border-[#dedace] bg-white p-1 self-start sm:self-auto">
          <button
            type="button"
            onClick={() => setInterval('month')}
            className={`rounded-full px-4 py-1.5 text-xs font-bold transition ${
              interval === 'month'
                ? 'bg-[#171711] text-white'
                : 'text-[#6c6b63] hover:text-[#171711]'
            }`}
          >
            Monthly
          </button>
          <button
            type="button"
            onClick={() => setInterval('year')}
            className={`rounded-full px-4 py-1.5 text-xs font-bold transition ${
              interval === 'year'
                ? 'bg-[#171711] text-white'
                : 'text-[#6c6b63] hover:text-[#171711]'
            }`}
          >
            Annual · 2 Months Free
          </button>
        </div>
      </div>

      {/* Plan Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Free Plan Card */}
        <div className="p-6 sm:p-8 rounded-3xl bg-white border border-[#dedace] flex flex-col justify-between shadow-2xs space-y-6">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-xl font-black text-[#171711]">LaterBox Free</h3>
              {!isPro && (
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
                  Current Plan
                </span>
              )}
            </div>
            <div>
              <p className="text-3xl font-black tracking-tight text-[#171711]">$0</p>
              <p className="text-xs font-semibold text-[#6c6b63] mt-0.5">Free forever · No credit card required</p>
            </div>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              A private, calm personal library on your device. Never lose articles, notes, or research.
            </p>

            <div className="border-t border-[#f0ede4] pt-4">
              <p className="text-xs font-bold text-[#171711] mb-3">Included features:</p>
              <ul className="space-y-2.5">
                {freeFeatures.map((feat) => (
                  <li key={feat} className="flex items-start gap-2.5 text-xs text-[#3a3935]">
                    <Check className="w-4 h-4 text-[#768213] shrink-0 mt-0.5" />
                    <span>{feat}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <div className="pt-4 border-t border-[#f0ede4]">
            <Link
              href="/inbox"
              className="block w-full py-2.5 rounded-xl border border-[#dedace] hover:bg-[#f7f5ee] text-[#171711] text-center text-xs font-bold transition-colors"
            >
              Continue with Free
            </Link>
          </div>
        </div>

        {/* Pro Plan Card */}
        <div
          id="pro-plan-card"
          className="p-6 sm:p-8 rounded-3xl bg-[#171711] border border-[#171711] text-white flex flex-col justify-between shadow-xl shadow-black/5 space-y-6 relative overflow-hidden"
        >
          <div className="absolute top-0 right-0 w-32 h-32 bg-[#d7ff27]/10 rounded-full blur-2xl pointer-events-none" />

          <div className="space-y-4 relative z-10">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Crown className="w-5 h-5 text-[#d7ff27]" />
                <h3 className="text-xl font-black text-white">LaterBox Pro</h3>
              </div>
              <span className="inline-flex rounded-full bg-[#d7ff27] px-2.5 py-0.5 text-[10px] font-black text-black">
                14-Day Free Trial
              </span>
            </div>

            <div>
              <div className="flex items-baseline gap-1">
                <span className="text-3xl font-black tracking-tight text-white">{localizedPrice}</span>
                <span className="text-xs font-semibold text-zinc-400">
                  {interval === 'month' ? '/month' : '/year'}
                </span>
              </div>
              <p className="text-xs font-semibold text-[#d7ff27] mt-0.5">
                {interval === 'year' ? '$3.33/mo billed annually · 14-day free trial' : '14-day free trial, cancel anytime'}
              </p>
            </div>

            <p className="text-xs text-zinc-300 leading-relaxed">
              Unlock cloud superpowers, continuous capture, and instant synchronization across all your computers and phones.
            </p>

            <div className="border-t border-white/10 pt-4">
              <p className="text-xs font-bold text-white mb-3">All Pro features:</p>
              <ul className="space-y-2.5">
                {proFeatures.map((feat) => (
                  <li key={feat} className="flex items-start gap-2.5 text-xs text-zinc-200">
                    <Check className="w-4 h-4 text-[#d7ff27] shrink-0 mt-0.5" />
                    <span>{feat}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <div className="pt-4 border-t border-white/10 relative z-10">
            {isPro && entitlement.provider === 'paddle' ? (
              <button
                type="button"
                disabled={busy !== null}
                onClick={() => handleAction('manage')}
                className="w-full py-3 rounded-xl bg-white hover:bg-zinc-100 text-[#171711] text-center text-xs font-black transition-colors disabled:opacity-50 cursor-pointer shadow-sm flex items-center justify-center gap-2"
              >
                {busy === 'manage' && <Loader2 className="w-4 h-4 animate-spin" />}
                <span>Manage in Billing Portal</span>
              </button>
            ) : isPro && entitlement.provider === 'apple' ? (
              <div className="w-full py-3 rounded-xl border border-white/20 text-center text-xs font-bold text-zinc-300">
                Pro active via App Store
              </div>
            ) : (
              <button
                type="button"
                disabled={busy !== null}
                onClick={() => handleAction(interval)}
                className="w-full py-3 rounded-xl bg-[#d7ff27] hover:bg-[#cbf71e] text-black text-center text-xs font-black transition-colors disabled:opacity-50 cursor-pointer shadow-sm flex items-center justify-center gap-2"
              >
                {busy === interval && <Loader2 className="w-4 h-4 animate-spin" />}
                <span>Start 14-Day Free Trial</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Value Pillars */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-4">
        <div className="p-5 rounded-2xl bg-white border border-[#dedace] space-y-2">
          <div className="w-8 h-8 rounded-lg bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
            <Cloud className="w-4 h-4" />
          </div>
          <h4 className="text-xs font-bold text-[#171711]">Multi-Device Cloud Sync</h4>
          <p className="text-[11px] text-[#6c6b63] leading-relaxed">
            Seamless synchronization between your iPhone, Android, Mac, Windows, and Web.
          </p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-[#dedace] space-y-2">
          <div className="w-8 h-8 rounded-lg bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
            <Layers className="w-4 h-4" />
          </div>
          <h4 className="text-xs font-bold text-[#171711]">macOS Notch &amp; OCR</h4>
          <p className="text-[11px] text-[#6c6b63] leading-relaxed">
            Drag-and-drop notch island, screen context awareness, and Vision OCR text extraction.
          </p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-[#dedace] space-y-2">
          <div className="w-8 h-8 rounded-lg bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
            <ShieldCheck className="w-4 h-4" />
          </div>
          <h4 className="text-xs font-bold text-[#171711]">No Vendor Lock-in</h4>
          <p className="text-[11px] text-[#6c6b63] leading-relaxed">
            If your plan ever lapses, your library remains 100% intact, readable, and exportable forever.
          </p>
        </div>
      </div>

      {/* Footer Notes */}
      <div className="text-center text-xs text-[#6c6b63] pt-4 space-y-1">
        <p>
          Secure payments, localized currencies, taxes, and subscriptions processed by <strong>Paddle</strong>.
        </p>
        <p className="text-[11px] text-[#9e9b92]">
          <Link href="/terms" className="underline hover:text-[#171711]">
            Terms of Service
          </Link>
          {' · '}
          <Link href="/privacy" className="underline hover:text-[#171711]">
            Privacy Policy
          </Link>
          {' · '}
          <Link href="/refund" className="underline hover:text-[#171711]">
            Refund Policy
          </Link>
        </p>
      </div>
    </div>
  );
}
