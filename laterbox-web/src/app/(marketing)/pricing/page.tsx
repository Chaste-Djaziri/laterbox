'use client';

import { Suspense, useEffect, useMemo, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Check, Cloud, Database, Loader2, LockKeyhole, Sparkles } from 'lucide-react';
import { presentEntitlement } from '@/lib/billing/types';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';

type Interval = 'month' | 'year';

const freeFeatures = ['Unlimited local saves', 'Reading, search, and organization', 'Local files and attachments', 'Export whenever you want', 'No account or connection required'];
const proFeatures = ['Everything in Free', 'Secure sync across every device', 'Cloud-backed files and attachments', 'Browser and system share integrations', 'macOS notch clipboard capture and Watch Mode', 'Automatic capture and enrichment'];
const faqs = [
  ['What happens when Pro ends?', 'Your local library stays readable and exportable. New cloud operations pause, pending local changes remain safe, and synchronization resumes when Pro returns.'],
  ['Can I use one subscription everywhere?', 'Yes. Sign in with the same LaterBox account. Web subscriptions work on supported devices, while Apple builds also offer App Store billing.'],
  ['How does the trial work?', 'Eligible new subscribers receive the trial shown in checkout. You can cancel before renewal from the billing portal or your App Store subscription settings.'],
];

export default function PricingPage() {
  return (
    <Suspense fallback={<main className="min-h-screen bg-[#f7f5ee]" aria-busy="true" />}>
      <PricingContent />
    </Suspense>
  );
}

function PricingContent() {
  const { user } = useAuth();
  const searchParams = useSearchParams();
  const { entitlement, isPro, subscribe, manage, checkoutState, previewPrices } = useBilling();
  const [interval, setInterval] = useState<Interval>(() => searchParams.get('plan') === 'month' ? 'month' : 'year');
  const [busy, setBusy] = useState<Interval | 'manage' | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [prices, setPrices] = useState<Record<string, string>>({});
  const monthlyId = process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID || '';
  const annualId = process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID || '';
  const presentation = useMemo(() => presentEntitlement(entitlement), [entitlement]);

  useEffect(() => {
    const ids = [monthlyId, annualId].filter(Boolean);
    if (ids.length !== 2) return;
    let active = true;
    previewPrices(ids).then((value) => active && setPrices(value)).catch(() => active && setPrices({}));
    return () => { active = false; };
  }, [monthlyId, annualId, previewPrices]);

  async function run(action: Interval | 'manage') {
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

  const selectedId = interval === 'month' ? monthlyId : annualId;
  const localizedPrice = prices[selectedId] || (interval === 'month' ? '$3.99' : '$39.99');

  return (
    <main className="min-h-screen bg-[#f7f5ee] px-5 py-14 text-[#171711] sm:py-20">
      <div className="mx-auto max-w-6xl">
        <header className="mx-auto max-w-3xl text-center">
          <span className="inline-flex items-center gap-2 rounded-full bg-[#e6edb0] px-3 py-1.5 text-xs font-black uppercase tracking-[0.2em]"><Sparkles className="size-3.5" /> LaterBox Pro</span>
          <h1 className="mt-5 text-4xl font-black tracking-[-0.045em] sm:text-6xl">Your library is free. Upgrade the connected parts.</h1>
          <p className="mx-auto mt-5 max-w-2xl text-base leading-7 text-[#6c6b63] sm:text-lg">Save, read, search, organize, and export locally forever. Pro adds secure cloud access and the fastest ways to capture from every device.</p>
        </header>

        <div className="mx-auto mt-9 flex w-fit rounded-full border border-[#dedace] bg-white p-1" aria-label="Billing frequency">
          {(['month', 'year'] as const).map((value) => <button key={value} type="button" aria-pressed={interval === value} onClick={() => setInterval(value)} className={`rounded-full px-5 py-2 text-sm font-extrabold transition ${interval === value ? 'bg-[#171711] text-white' : 'text-[#6c6b63]'}`}>{value === 'month' ? 'Monthly' : 'Annual · best value'}</button>)}
        </div>

        <div className="mt-10 grid gap-5 lg:grid-cols-2">
          <PlanCard title="LaterBox Free" price="Free forever" description="A calm, private library that works without an account or internet connection." features={freeFeatures} action={<Link href="/inbox" className="block rounded-2xl border border-[#d7d2c5] px-5 py-3 text-center text-sm font-black">Open LaterBox Free</Link>} />
          <PlanCard featured title="LaterBox Pro" badge="14-day trial for eligible subscribers" price={localizedPrice} suffix={interval === 'month' ? '/month' : '/year'} description="Sync everywhere and capture useful content before it slips away." features={proFeatures} action={isPro ? entitlement.provider === 'paddle' ? <button type="button" onClick={() => void run('manage')} disabled={busy !== null} className="w-full rounded-2xl bg-[#d7ff27] px-5 py-3 text-sm font-black text-black disabled:opacity-50">{busy === 'manage' && <Loader2 className="mr-2 inline size-4 animate-spin" />}{presentation.actionLabel}</button> : <div className="rounded-2xl border border-white/15 px-5 py-3 text-center text-sm font-bold text-zinc-200">Pro is active · Manage in the App Store</div> : user ? <button type="button" onClick={() => void run(interval)} disabled={busy !== null} className="w-full rounded-2xl bg-[#d7ff27] px-5 py-3 text-sm font-black text-black disabled:opacity-50">{busy === interval && <Loader2 className="mr-2 inline size-4 animate-spin" />}Start free trial</button> : <Link href={`/login?next=${encodeURIComponent(`/pricing?plan=${interval}`)}`} className="block rounded-2xl bg-[#d7ff27] px-5 py-3 text-center text-sm font-black text-black">Sign in to start trial</Link>} />
        </div>

        {checkoutState !== 'idle' && <div role="status" className={`mx-auto mt-6 max-w-2xl rounded-2xl border px-5 py-4 text-center text-sm font-bold ${checkoutState === 'confirmed' ? 'border-emerald-200 bg-emerald-50 text-emerald-800' : 'border-amber-200 bg-amber-50 text-amber-900'}`}>{checkoutState === 'processing' && 'Payment received. Confirming Pro with the billing service…'}{checkoutState === 'confirmed' && 'LaterBox Pro is active on your account.'}{checkoutState === 'delayed' && 'Your payment is complete, but activation is still processing. It will appear automatically after the verified webhook arrives.'}</div>}
        {message && <p className="mt-5 text-center text-sm font-bold text-red-700" role="alert">{message}</p>}
        {!prices[selectedId] && <p className="mt-3 text-center text-xs text-[#77746d]">USD reference price shown. Your localized total and applicable tax appear in Paddle checkout.</p>}

        <section className="mt-16 grid gap-4 sm:grid-cols-3">
          <Value icon={<LockKeyhole />} title="Private by design" copy="Your local library does not disappear when a plan ends." />
          <Value icon={<Cloud />} title="One account everywhere" copy="Use the same entitlement across web, desktop, and mobile." />
          <Value icon={<Database />} title="No lock-in" copy="Keep reading and exporting your local data on Free." />
        </section>

        <section className="mx-auto mt-16 max-w-3xl"><h2 className="text-center text-3xl font-black tracking-tight">Questions, answered</h2><div className="mt-7 space-y-3">{faqs.map(([question, answer]) => <details key={question} className="rounded-2xl border border-[#dedace] bg-white p-5"><summary className="cursor-pointer font-extrabold">{question}</summary><p className="mt-3 text-sm leading-6 text-[#6c6b63]">{answer}</p></details>)}</div></section>
        <p className="mt-12 text-center text-xs leading-5 text-[#77746d]">Subscriptions renew automatically until canceled. Secure checkout, taxes, invoices, and web billing management are provided by Paddle. <Link href="/terms" className="underline">Terms</Link> · <Link href="/privacy" className="underline">Privacy</Link></p>
      </div>
    </main>
  );
}

function PlanCard({ title, price, suffix, description, features, action, badge, featured = false }: { title: string; price: string; suffix?: string; description: string; features: string[]; action: ReactNode; badge?: string; featured?: boolean }) {
  return <section className={`rounded-[30px] border p-7 sm:p-9 ${featured ? 'border-[#171711] bg-[#171711] text-white shadow-xl shadow-black/10' : 'border-[#dedace] bg-white'}`}>{badge && <span className="inline-flex rounded-full bg-[#d7ff27] px-3 py-1 text-[11px] font-black text-black">{badge}</span>}<h2 className="mt-4 text-xl font-black">{title}</h2><p className="mt-3 text-4xl font-black tracking-tight">{price}{suffix && <span className={`ml-1 text-sm font-semibold ${featured ? 'text-zinc-400' : 'text-[#77746d]'}`}>{suffix}</span>}</p><p className={`mt-3 min-h-12 text-sm leading-6 ${featured ? 'text-zinc-300' : 'text-[#6c6b63]'}`}>{description}</p><div className="my-7 h-px bg-current opacity-10" /><ul className="space-y-3">{features.map((feature) => <li key={feature} className="flex gap-2.5 text-sm"><Check className={`mt-0.5 size-4 shrink-0 ${featured ? 'text-[#d7ff27]' : 'text-[#768213]'}`} />{feature}</li>)}</ul><div className="mt-8">{action}</div></section>;
}

function Value({ icon, title, copy }: { icon: ReactNode; title: string; copy: string }) {
  return <div className="rounded-2xl border border-[#dedace] bg-white p-5"><div className="text-[#768213] [&>svg]:size-5">{icon}</div><h3 className="mt-3 font-black">{title}</h3><p className="mt-1 text-sm leading-6 text-[#6c6b63]">{copy}</p></div>;
}
