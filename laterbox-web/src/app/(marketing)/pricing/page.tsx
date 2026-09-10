'use client';

import Link from 'next/link';
import { Check, Loader2 } from 'lucide-react';
import { useState } from 'react';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';

const features = [
  'Cloud sync across every device',
  'Cloud-backed attachments',
  'Browser and system share integrations',
  'macOS notch clipboard capture and Watch Mode',
  'Automatic capture and enrichment features',
];

export default function PricingPage() {
  const { user } = useAuth();
  const { entitlement, isPro, subscribe, manage } = useBilling();
  const [busy, setBusy] = useState<'month' | 'year' | 'manage' | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  async function run(action: 'month' | 'year' | 'manage') {
    setBusy(action);
    setMessage(null);
    try {
      if (action === 'manage') await manage();
      else await subscribe(action);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Billing is temporarily unavailable.');
    } finally {
      setBusy(null);
    }
  }

  return (
    <main className="min-h-screen bg-[#f7f5ee] px-5 py-16 text-[#171711]">
      <div className="mx-auto max-w-5xl">
        <div className="mx-auto max-w-2xl text-center">
          <p className="text-xs font-black uppercase tracking-[0.24em] text-[#768213]">LaterBox Pro</p>
          <h1 className="mt-4 text-4xl font-black tracking-tight sm:text-5xl">Keep the local app free. Upgrade the connected parts.</h1>
          <p className="mt-5 text-base leading-7 text-[#6c6b63]">Your local library stays usable without a subscription. Pro adds secure sync, integrations, and automatic capture on every supported device.</p>
        </div>

        <div className="mx-auto mt-12 grid max-w-4xl gap-5 md:grid-cols-2">
          {([
            { interval: 'month' as const, price: '$3.99', suffix: '/month', title: 'Monthly' },
            { interval: 'year' as const, price: '$39.99', suffix: '/year', title: 'Annual · save 16%' },
          ]).map((plan) => (
            <section key={plan.interval} className="rounded-[28px] border border-[#dedace] bg-white p-7 shadow-sm">
              <p className="text-sm font-bold text-[#6c6b63]">{plan.title}</p>
              <p className="mt-3 text-4xl font-black">{plan.price}<span className="ml-1 text-sm font-semibold text-[#77746d]">{plan.suffix}</span></p>
              <p className="mt-2 text-sm text-[#77746d]">Includes a 14-day trial. Cancel anytime.</p>
              <button
                onClick={() => void run(plan.interval)}
                disabled={!user || isPro || busy !== null}
                className="mt-6 flex w-full items-center justify-center rounded-2xl bg-[#171711] px-5 py-3 text-sm font-black text-white disabled:cursor-not-allowed disabled:opacity-45"
              >
                {busy === plan.interval && <Loader2 className="mr-2 size-4 animate-spin" />}
                {isPro ? 'Pro is active' : user ? 'Start free trial' : 'Sign in to subscribe'}
              </button>
            </section>
          ))}
        </div>

        <div className="mx-auto mt-8 max-w-2xl rounded-[24px] bg-[#ece9df] p-6">
          <h2 className="font-black">Everything in Pro</h2>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            {features.map((feature) => <p key={feature} className="flex gap-2 text-sm"><Check className="mt-0.5 size-4 shrink-0 text-[#768213]" />{feature}</p>)}
          </div>
        </div>

        <div className="mt-8 text-center">
          {!user && <Link href="/login" className="font-bold underline">Sign in or create an account</Link>}
          {isPro && entitlement.provider === 'paddle' && <button onClick={() => void run('manage')} className="font-bold underline">Manage subscription</button>}
          {message && <p className="mt-3 text-sm font-semibold text-red-700" role="alert">{message}</p>}
          <p className="mt-4 text-xs text-[#77746d]">Secure checkout and billing are provided by Paddle.</p>
        </div>
      </div>
    </main>
  );
}
