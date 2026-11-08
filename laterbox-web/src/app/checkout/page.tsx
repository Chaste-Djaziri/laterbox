'use client';

import { Suspense, useEffect } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Cloud, LockKeyhole, ArrowLeft, Check } from 'lucide-react';
import { WhopCheckout } from '@/components/billing/WhopCheckout';
import { WHOP_STORAGE_PLANS, parseWhopPlan } from '@/lib/billing/storage-plans';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';

function Content() {
  const params = useSearchParams();
  const { user } = useAuth();
  const { entitlement } = useBilling();
  const interval = params.get('interval') === 'year' ? 'year' : 'month';
  const storage = params.get('plan') === 'vault' ? 'vault' : 'plus';
  const planKey = parseWhopPlan(`${storage}_${interval}`);
  const plan = planKey ? WHOP_STORAGE_PLANS[planKey] : null;

  useEffect(() => {
    if (!user) return;
    // The checkout API checks existing subscriptions again, server-side.
  }, [user]);
  const active = entitlement.provider && entitlement.status !== 'free'
    && (!entitlement.accessEndsAt || Date.parse(entitlement.accessEndsAt) > Date.now());

  return <main className="min-h-screen bg-[#f7f5ee] px-4 py-12 sm:px-8">
    <div className="mx-auto max-w-5xl">
      <Link href="/plans" className="inline-flex items-center gap-2 text-sm font-bold text-[#56604c] hover:text-[#1c2714]">
        <ArrowLeft size={17} /> Back to plans
      </Link>
      <header className="mt-8 flex flex-wrap items-center justify-between gap-4">
        <div>
          <span className="text-xs font-black uppercase tracking-[0.18em] text-[#6c785c]">LaterBox</span>
          <h1 className="mt-2 text-3xl font-black tracking-tight sm:text-4xl">Your storage, upgraded.</h1>
          <p className="mt-2 text-sm text-[#69715e]">Finish subscribing without leaving LaterBox.</p>
        </div>
        <div className="flex items-center gap-2 rounded-full border border-[#d6dac7] bg-white px-4 py-2 text-xs font-bold text-[#515b46]">
          <LockKeyhole size={15}/> Secure Whop checkout
        </div>
      </header>
      <div className="mt-8 grid gap-5 lg:grid-cols-[0.85fr_1.15fr]">
        <section className="self-start rounded-[28px] border border-[#e2e3d7] bg-white p-6 sm:p-8">
          <Cloud size={26} className="text-[#72824e]" />
          <h2 className="mt-5 text-xl font-black">LaterBox {storage === 'vault' ? 'Vault' : 'Plus'}</h2>
          <p className="mt-2 text-sm text-[#66725e]">{storage === 'vault' ? '100 GB' : '10 GB'} for your saved copies, PDFs, images and uploads.</p>
          <p className="mt-5 text-4xl font-black">
            ${plan?.usd.toFixed(2) ?? '—'}
            <span className="ml-1 text-sm font-semibold text-[#6e7463]">/{interval === 'month' ? 'month' : 'year'}</span>
          </p>
          <p className="mt-2 text-xs text-[#747766]">USD reference price. Whop shows final charges and applicable taxes.</p>
          <div className="my-6 h-px bg-[#e8e8dc]"/>
          {[
            'Free sync across Web, iOS and Chrome',
            'Secure cloud attachments and offline copies',
            'Unlimited ordinary bookmarks and collections',
            'Keep your existing library after cancellation',
          ].map(feature=><p key={feature} className="mt-3 flex items-start gap-2 text-sm text-[#4d5945]">
            <Check className="mt-0.5 shrink-0 text-[#789146]" size={16} /> {feature}
          </p>)}
        </section>
        <section className="min-h-96 rounded-[28px] border border-[#e2e3d7] bg-white p-5 sm:p-8">
          <h2 className="mb-5 text-lg font-black">Secure checkout</h2>
          {!user ? <div className="space-y-3">
            <p className="text-sm text-[#65705e]">Sign in so your purchase can be activated on the right LaterBox account.</p>
            <Link href={`/login?next=${encodeURIComponent(`/checkout?plan=${storage}&interval=${interval}`)}`}
              className="inline-block rounded-xl bg-[#171711] px-5 py-3 text-sm font-bold text-white">Sign in to continue</Link>
          </div> : active ? <div className="space-y-3">
            <p className="font-bold">You already have a subscription.</p>
            <p className="text-sm text-[#66705e]">Manage your current plan before starting a new subscription to avoid duplicate charges.</p>
            <Link href="/plans" className="inline-block rounded-xl bg-[#e6edb0] px-5 py-3 text-sm font-bold">Manage plan</Link>
          </div> : planKey ? <WhopCheckout key={planKey} planKey={planKey}/> : <p className="text-sm text-red-700">Invalid storage plan.</p>}
        </section>
      </div>
      <p className="mt-6 text-center text-xs text-[#798071]">Payments are processed securely by Whop. Plans renew unless canceled through your payment provider.</p>
    </div>
  </main>;
}
export default function CheckoutPage() {
  return <Suspense fallback={<main className="min-h-screen bg-[#f7f5ee] p-10">Loading checkout…</main>}><Content /></Suspense>;
}
