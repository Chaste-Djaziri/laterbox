'use client';

import { Checkout, CheckoutElement, WhopElements } from '@whop/elements-react';
import { loadWhop } from '@whop/elements';
import { useEffect, useMemo, useState } from 'react';
import { getAccessToken } from '@/lib/auth/tokens';
import { type WhopPlanKey, WHOP_STORAGE_PLANS } from '@/lib/billing/storage-plans';

type Stage = { kind: 'loading' | 'ready' | 'pending' | 'active' | 'error'; checkoutId?: string; message?: string; environment?: 'sandbox' | 'production' };

export function WhopCheckout({ planKey }: { planKey: WhopPlanKey }) {
  const [stage, setStage] = useState<Stage>({ kind: 'loading' });
  const elements = useMemo(() => loadWhop(), []);
  const paid = WHOP_STORAGE_PLANS[planKey];
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let cancelled = false;
    const params = new URLSearchParams(window.location.search);
    if (params.get('status') === 'processing' || params.get('status') === 'failed') {
      setStage({ kind: params.get('status') === 'failed' ? 'error' : 'pending', message: 'Confirming your subscription with Whop…' });
      return;
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
      } catch { /* Webhook activation is asynchronous. */ }
      if (!cancelled && tries < 20) window.setTimeout(poll, 1500);
    };
    void poll();
    return () => { cancelled = true; };
  }, [stage.kind, paid.storage]);

  if (stage.kind === 'loading') return <div className="rounded-2xl bg-white p-8 text-sm text-[#626c59]" role="status">Preparing your secure Whop checkout…</div>;
  if (stage.kind === 'active') return (
    <div className="rounded-2xl border border-[#bfd6a7] bg-white p-8 text-center" role="status">
      <h2 className="text-xl font-black text-[#1c2b18]">Your storage plan is active</h2>
      <p className="mt-2 text-sm text-[#526047]">Your space is available on Web, iOS, and Chrome with the same LaterBox account.</p>
      <a href="/settings" className="mt-5 inline-block rounded-full bg-[#171711] px-5 py-3 text-sm font-bold text-white">Go to settings</a>
    </div>
  );
  if (stage.kind === 'pending') return (
    <div className="rounded-2xl border border-[#d9dbc4] bg-white p-8" role="status">
      <h2 className="text-lg font-bold">Finishing your subscription</h2>
      <p className="mt-2 text-sm text-[#656c59]">Whop is confirming your purchase. Keep this page or return later — your plan activates after verification, even if you close the tab.</p>
      <a href="/plans" className="mt-4 inline-block text-sm font-bold underline">View your plan</a>
    </div>
  );
  if (stage.kind === 'error') return (
    <div className="rounded-2xl border border-amber-200 bg-white p-8" role="alert">
      <h2 className="text-lg font-bold">Checkout unavailable</h2>
      <p className="mt-2 text-sm text-[#64665a]">{stage.message}</p>
      <button type="button" onClick={() => { setStage({ kind: 'loading' }); setAttempt(n => n + 1); }} className="mt-5 rounded-full bg-[#171711] px-5 py-2.5 text-sm font-bold text-white">Try again</button>
    </div>
  );

  const returnUrl = `${window.location.origin}/checkout?plan=${paid.storage}&interval=${paid.interval}&status=processing`;
  return (
    <WhopElements elements={elements} environment={stage.environment ?? 'sandbox'}>
      <Checkout
        checkoutConfiguration={stage.checkoutId!}
        returnUrl={returnUrl}
        onComplete={(completed) => {
          if (completed.result === 'payment') setStage({ kind: 'pending' });
        }}
        fallback={<p className="p-8 text-sm text-[#656c59]">Loading Whop payment options…</p>}
      >
        <CheckoutElement />
      </Checkout>
    </WhopElements>
  );
}
