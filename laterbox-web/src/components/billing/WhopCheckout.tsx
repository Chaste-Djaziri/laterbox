// laterbox-web/src/components/billing/WhopCheckout.tsx
'use client';

import { Checkout, CheckoutElement, WhopElements } from '@whop/elements-react';
import { loadWhop } from '@whop/elements';
import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { AlertCircle, CheckCircle2, Loader2, LockKeyhole, RefreshCcw, ShieldCheck } from 'lucide-react';
import { getAccessToken } from '@/lib/auth/tokens';
import { type WhopPlanKey, WHOP_STORAGE_PLANS } from '@/lib/billing/storage-plans';

type Stage = {
  kind: 'loading' | 'ready' | 'pending' | 'active' | 'error';
  checkoutId?: string;
  message?: string;
  environment?: 'sandbox' | 'production';
};

export function WhopCheckout({ planKey, buyerEmail }: { planKey: WhopPlanKey; buyerEmail: string }) {
  const [stage, setStage] = useState<Stage>({ kind: 'loading' });
  const elements = useMemo(() => loadWhop(), []);
  const paid = WHOP_STORAGE_PLANS[planKey];
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let cancelled = false;
    // Whop appends its own "status" query parameter after off-site payment.
    // Some older LaterBox URLs already include status=processing; use the LAST status.
    const params = new URLSearchParams(window.location.search);
    const status = params.getAll('status').at(-1);
    if (attempt === 0 && (status === 'succeeded' || status === 'processing')) {
      void Promise.resolve().then(() => { if (!cancelled) setStage({ kind: 'pending', message: 'Confirming your subscription with Whop…' }); });
      return () => { cancelled = true; };
    }
    if (attempt === 0 && (status === 'failed' || status === 'canceled')) {
      void Promise.resolve().then(() => {
        if (!cancelled) setStage({ kind: 'error', message: status === 'canceled'
          ? 'Payment was canceled. Your account was not upgraded.'
          : 'Your payment did not complete. You can safely try again.' });
      });
      return () => { cancelled = true; };
    }

    const create = async () => {
      try {
        const token = await getAccessToken();
        if (!token) throw new Error('Sign in to continue.');
        const response = await fetch('/api/billing/checkout', {
          method: 'POST',
          headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
          body: JSON.stringify({ plan: planKey }),
          cache: 'no-store',
        });
        const body = await response.json() as { checkoutId?: string; error?: string; environment?: 'sandbox' | 'production' };
        if (!response.ok || !body.checkoutId) throw new Error(body.error || 'Could not create checkout.');
        if (!cancelled) setStage({ kind: 'ready', checkoutId: body.checkoutId, environment: body.environment ?? 'sandbox' });
      } catch (error) {
        if (!cancelled) setStage({ kind: 'error', message: error instanceof Error ? error.message : 'Checkout could not start.' });
      }
    };
    void create();
    return () => { cancelled = true; };
  }, [planKey, attempt]);

  useEffect(() => {
    if (stage.kind !== 'pending') return;
    let cancelled = false;
    let tries = 0;
    const poll = async () => {
      if (cancelled) return;
      tries++;
      try {
        const token = await getAccessToken();
        if (!token) return;
        const res = await fetch('/api/billing/entitlement', {
          headers: { authorization: `Bearer ${token}` }, cache: 'no-store',
        });
        if (res.ok) {
          const entitlement = await res.json() as { provider?: string; storagePlan?: string };
          if (entitlement.provider === 'whop' && entitlement.storagePlan === paid.storage && !cancelled) {
            setStage({ kind: 'active' });
            return;
          }
        }
      } catch { /* Whop's webhook may still be processing. */ }
      if (!cancelled && tries < 40) window.setTimeout(poll, 1500);
    };
    void poll();
    return () => { cancelled = true; };
  }, [stage.kind, paid.storage]);

  const retry = () => {
    setStage({ kind: 'loading' });
    setAttempt(n => n + 1);
  };

  if (stage.kind === 'loading') return (
    <div role="status" aria-live="polite" className="flex min-h-80 flex-col items-center justify-center rounded-2xl bg-[#fafbf7] p-8 text-center">
      <Loader2 size={30} className="animate-spin text-[#90a96d]"/>
      <p className="mt-5 text-sm font-black">Preparing your secure checkout</p>
      <p className="mt-2 text-xs text-[#7b8773]">Connecting to Whop&apos;s protected payment service…</p>
    </div>
  );

  if (stage.kind === 'active') return (
    <div className="rounded-2xl border border-[#d2e8bb] bg-[#f5faef] p-8 text-center" role="status">
      <CheckCircle2 size={40} className="mx-auto text-[#82a65c]"/>
      <h2 className="mt-4 text-xl font-black">Your storage is ready!</h2>
      <p className="mt-2 text-sm leading-6 text-[#64765c]">Your new plan is now available on Web, iOS and Chrome using this LaterBox account.</p>
      <Link href="/settings" className="mt-6 inline-flex rounded-xl bg-[#1c2519] px-5 py-3 text-sm font-black text-white">Explore your storage</Link>
    </div>
  );

  if (stage.kind === 'pending') return (
    <div className="rounded-2xl border border-[#e3e5cd] bg-[#fafbf2] p-8" role="status" aria-live="polite">
      <Loader2 size={28} className="animate-spin text-[#839955]"/>
      <h2 className="mt-5 text-lg font-black">Verifying your subscription</h2>
      <p className="mt-2 text-sm leading-6 text-[#718069]">Whop is confirming your purchase. We&apos;ll unlock storage only after the payment is verified. You can return later without losing the order.</p>
      <a href="/plans" className="mt-5 inline-block text-sm font-black text-[#536b3e] underline underline-offset-2">View subscription status</a>
    </div>
  );

  if (stage.kind === 'error') return (
    <div className="rounded-2xl border border-[#eed8bc] bg-[#fffaf2] p-7" role="alert">
      <AlertCircle size={28} className="text-[#b88240]"/>
      <h2 className="mt-4 text-lg font-black">Checkout unavailable</h2>
      <p className="mt-2 text-sm leading-6 text-[#7c7467]">{stage.message}</p>
      <button type="button" onClick={retry} className="mt-6 inline-flex items-center gap-2 rounded-xl bg-[#1c2519] px-5 py-3 text-sm font-bold text-white">
        <RefreshCcw size={15}/> Try again
      </button>
    </div>
  );

  // The full CheckoutElement already includes Whop's native Apple Pay and Google Pay
  // express row whenever the buyer's browser, payment configuration and VERIFIED
  // payment domain support it. Do not mount ExpressCheckoutElement alongside it.
  const returnUrl = `${window.location.origin}/checkout?plan=${paid.storage}&interval=${paid.interval}`;
  return (
    <div>
      <div className="mb-5 flex flex-wrap items-center justify-between gap-2">
        <span className="inline-flex items-center gap-2 text-xs font-black text-[#485d3d]">
          <ShieldCheck size={17} className="text-[#86a15f]"/> Pay securely with Whop
        </span>
        <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold text-[#879080]">
          <LockKeyhole size={12}/> Encrypted
        </span>
      </div>
      <WhopElements elements={elements} environment={stage.environment ?? 'sandbox'}>
        <Checkout
          checkoutConfiguration={stage.checkoutId!}
          returnUrl={returnUrl}
          onComplete={(completed) => {
            if (completed.result === 'payment') setStage({ kind: 'pending' });
          }}
          fallback={<div role="status" className="rounded-2xl bg-[#f6f8f1] p-8 text-sm text-[#65735f]"><Loader2 size={18} className="mr-2 inline animate-spin"/> Loading Whop payment methods…</div>}
        >
          <CheckoutElement buyerEmail={buyerEmail} />
        </Checkout>
      </WhopElements>
      <p className="mt-5 text-center text-[11px] leading-5 text-[#8b9485]">
        Apple Pay and Google Pay appear automatically when supported by your browser and enabled for this verified payment domain.
        The total and any taxes shown in Whop are the amount you confirm.
      </p>
    </div>
  );
}
