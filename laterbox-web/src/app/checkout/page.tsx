// laterbox-web/src/app/checkout/page.tsx
'use client';

import { Suspense, useState } from 'react';
import {getAccessToken} from '@/lib/auth/tokens';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import {
  ArrowLeft, ArrowRight, BadgeCheck, Check, ChevronRight, Cloud,
  CreditCard, HardDrive, LockKeyhole, RefreshCcw, ShieldCheck, Sparkles, Zap,
} from 'lucide-react';
import { WhopCheckout } from '@/components/billing/WhopCheckout';
import { useWhopPrices } from '@/lib/billing/use-whop-prices';
import { formatWhopPrice, yearlySavings } from '@/lib/billing/whop-prices';
import { WHOP_STORAGE_PLANS, parseWhopPlan, planFamilySlug, type WhopPlanKey } from '@/lib/billing/storage-plans';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';

function Content() {
  const params = useSearchParams();
  const { user } = useAuth();
  const { entitlement } = useBilling();
  const { prices, loading, error: priceError, retry } = useWhopPrices();
  const interval = params.get('interval') === 'year' ? 'year' : 'month';
  const selectedSlug = params.get('plan') || 'plus';
  const planKey = parseWhopPlan(`${selectedSlug}_${interval}`) ?? `plus_${interval}` as WhopPlanKey;
  const plan = WHOP_STORAGE_PLANS[planKey];
  const storage = planFamilySlug(planKey);
  const quote = prices?.[planKey];
  const capacity = plan.bytes / (1024 ** 3);
  const active = Boolean(entitlement.provider && entitlement.status !== 'free');
  const [referralInput,setReferralInput]=useState('');
  const [appliedReferral,setAppliedReferral]=useState<{code:string;plan:WhopPlanKey}|null>(null);
  const [referralMessage,setReferralMessage]=useState('');
  const [checkingReferral,setCheckingReferral]=useState(false);
  const validateReferral=async()=>{
    setCheckingReferral(true);setReferralMessage('');
    setAppliedReferral(null);
    try {
      const token=await getAccessToken();
      if(!token)throw new Error('Sign in to apply a referral code.');
      const response=await fetch('/api/earn/validate',{
        method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},
        body:JSON.stringify({code:referralInput,plan:planKey}),
      });
      const body=await response.json() as {valid?:boolean;code?:string;error?:string;trialDays?:number};
      if(!response.ok||!body.valid||!body.code)throw new Error(body.error||'This code is not available.');
      setAppliedReferral({code:body.code,plan:planKey});
      setReferralMessage('Referral code verified. The 30-day free trial will appear in the secure Whop checkout.');
    }catch(error){
      setReferralMessage(error instanceof Error?error.message:'Referral verification failed.');
    }finally{setCheckingReferral(false);}
  };
  const savings = yearlySavings(prices?.[`${storage}_month` as WhopPlanKey], prices?.[`${storage}_year` as WhopPlanKey]);
  const nextUrl = `/checkout?plan=${storage}&interval=${interval}`;
  const variantOptions = (Object.keys(WHOP_STORAGE_PLANS) as WhopPlanKey[])
    .filter(key => key.endsWith('_month'))
    .map(key => ({slug:planFamilySlug(key),label:WHOP_STORAGE_PLANS[key].label,quota:WHOP_STORAGE_PLANS[key].quotaLabel}));

  return (
    <main className="min-h-screen bg-[#f7f8f2] px-4 pb-16 pt-7 text-[#1c2219] sm:px-8 sm:pt-10">
      <div className="mx-auto max-w-6xl">
        <nav className="flex flex-wrap items-center justify-between gap-4" aria-label="Checkout navigation">
          <Link href="/plans" className="inline-flex items-center gap-2 rounded-full border border-[#dce4d2] bg-white px-4 py-2.5 text-xs font-bold text-[#52634c] transition hover:bg-[#eef2e6]">
            <ArrowLeft size={15}/> Back to plans
          </Link>
          <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.14em] text-[#73806a]">
            <LockKeyhole size={14}/> Encrypted, secure checkout
          </div>
        </nav>

        <header className="mt-9 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-[#789159]">LaterBox / Checkout</p>
            <h1 className="mt-3 text-[clamp(2.15rem,5vw,3.6rem)] font-black leading-tight tracking-[-0.055em]">Make space for more.</h1>
            <p className="mt-2 max-w-xl text-sm leading-6 text-[#7a8475]">Choose your storage, review the price, and complete your purchase securely with Whop.</p>
          </div>
          <span className="inline-flex items-center gap-2 rounded-full bg-[#e6edb0] px-4 py-2 text-xs font-black text-[#3a4b2b]">
            <BadgeCheck size={15}/> Protected payment
          </span>
        </header>

        <div className="mt-9 grid items-start gap-6 lg:grid-cols-[minmax(0,0.85fr)_minmax(0,1.15fr)]">
          <aside className="lg:sticky lg:top-6">
            <div className="relative overflow-hidden rounded-[30px] bg-[#1c2519] p-6 text-white shadow-[0_28px_80px_rgba(26,37,21,.16)] sm:p-8">
              <div className="pointer-events-none absolute -right-24 -top-32 size-80 rounded-full bg-[#ddebab]/10 blur-3xl"/>
              <div className="relative">
                <div className="flex items-center justify-between gap-4">
                  <span className="rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-[10px] font-black uppercase tracking-[0.16em] text-[#d4dfc5]">Your order</span>
                  <Sparkles size={19} className="text-[#d0e4a4]"/>
                </div>
                <div className="mt-7 flex items-start gap-4">
                  <div className="flex size-14 shrink-0 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#26341c]">
                    {plan.storage === 'vault' ? <HardDrive size={27} /> : <Cloud size={27} />}
                  </div>
                  <div>
                    <h2 className="text-2xl font-black tracking-tight">LaterBox {plan.label}</h2>
                    <p className="mt-1 text-sm text-[#bdcbb7]">{plan.quotaLabel} of secure cloud space</p>
                  </div>
                </div>

                <p className="mt-8 text-[11px] font-black uppercase tracking-[0.14em] text-[#aebda6]">Storage plan</p>
                <div className="mt-3 grid grid-cols-2 gap-2">
                  {variantOptions.map(tier => (
                    <Link key={tier.slug} href={`/checkout?plan=${tier.slug}&interval=${interval}`} aria-current={storage === tier.slug ? 'page' : undefined}
                      className={`flex items-center justify-center gap-2 rounded-xl border px-2 py-3 text-xs font-bold transition ${storage === tier.slug ? 'border-[#e6edb0] bg-[#e6edb0] text-[#1b2916]' : 'border-white/20 bg-white/5 text-[#d7e0d0] hover:bg-white/10'}`}>
                      {tier.slug.startsWith('plus') ? <Zap size={14}/> : <HardDrive size={14}/>}
                      {tier.label} · {tier.quota}
                    </Link>
                  ))}
                </div>

                <p className="mt-7 text-[11px] font-black uppercase tracking-[0.14em] text-[#aebda6]">Billing cycle</p>
                <div className="mt-3 grid grid-cols-2 gap-2">
                  {(['month','year'] as const).map(value => (
                    <Link key={value} href={`/checkout?plan=${storage}&interval=${value}`} aria-current={interval === value ? 'page' : undefined}
                      className={`rounded-xl border px-4 py-3 text-center text-xs font-black transition ${interval === value ? 'border-[#e6edb0] bg-white/15 text-white' : 'border-white/20 bg-white/5 text-[#c2cebb] hover:bg-white/10'}`}>
                      {value === 'month' ? 'Every 30 days' : 'Every 365 days'}
                    </Link>
                  ))}
                </div>

                <div className="mt-8 border-t border-white/15 pt-6">
                  <div className="flex items-center justify-between gap-4 text-sm">
                    <span className="text-[#b8c9b0]">Plan base price</span>
                    <span className="font-bold">
                      {loading ? 'Loading…' : quote ? formatWhopPrice(quote.renewalPrice, quote.currency) : 'See Whop checkout'}
                    </span>
                  </div>
                  {quote && quote.initialPrice > 0 && (
                    <div className="mt-3 flex items-center justify-between gap-3 text-sm">
                      <span className="text-[#b8c9b0]">One-time initial fee</span>
                      <span className="font-bold">{formatWhopPrice(quote.initialPrice, quote.currency)}</span>
                    </div>
                  )}
                  <div className="mt-3 flex items-center justify-between gap-4 text-sm">
                    <span className="text-[#b8c9b0]">Taxes & local currency</span>
                    <span className="text-right text-xs font-semibold text-[#e3edda]">Calculated by Whop</span>
                  </div>
                  <div className="mt-6 flex items-end justify-between gap-2 border-t border-white/15 pt-5">
                    <div>
                      <p className="text-[10px] font-black uppercase tracking-[0.14em] text-[#b0c29f]">Recurring base rate</p>
                      <div className="mt-2 text-3xl font-black tracking-[-0.045em]">
                        {loading ? '…' : quote ? formatWhopPrice(quote.renewalPrice, quote.currency) : '—'}
                      </div>
                    </div>
                    <span className="pb-1 text-xs text-[#c6d1bd]">/ {interval === 'month' ? '30 days' : '365 days'}</span>
                  </div>
                  {interval === 'year' && savings != null && (
                    <p className="mt-4 inline-flex rounded-full border border-[#b4d181]/25 bg-[#d6eeb1]/10 px-3 py-1.5 text-xs font-bold text-[#d4eeb3]">
                      Save {savings}% vs. 12 monthly payments
                    </p>
                  )}
                  {quote?.trialDays ? <p className="mt-3 text-xs text-[#d4dfce]">{quote.trialDays}-day trial configured by Whop. The payment form shows when billing starts.</p> : null}
                  {priceError && (
                    <div role="status" className="mt-4 flex flex-wrap items-center gap-2 text-xs text-[#f2d5ab]">
                      Live price unavailable. <button type="button" onClick={retry} className="inline-flex items-center gap-1 font-black underline"><RefreshCcw size={12}/> Retry</button>
                    </div>
                  )}
                  <p className="mt-4 text-[11px] leading-5 text-[#aab9a2]">Your final charge, discounts and any applicable taxes are shown and confirmed in Whop&apos;s payment form before you pay.</p>
                </div>
              </div>
            </div>

            <div className="mt-5 rounded-[24px] border border-[#e0e6d7] bg-white p-6">
              <h3 className="flex items-center gap-2 text-sm font-black"><ShieldCheck size={18} className="text-[#7c9655]"/> Your plan includes</h3>
              <ul className="mt-4 space-y-3 text-xs leading-5 text-[#687563]">
                {['Your links and collections sync for free', 'Encrypted cloud storage for uploaded content', 'Keep your existing library if you cancel'].map(value => (
                  <li key={value} className="flex items-start gap-2"><Check size={15} className="mt-0.5 shrink-0 text-[#92a96d]"/>{value}</li>
                ))}
              </ul>
              <Link href="/plans" className="mt-5 inline-flex items-center gap-1 text-xs font-black text-[#566d43] hover:underline">
                Compare all plans <ChevronRight size={14}/>
              </Link>
            </div>
          </aside>

          <section className="overflow-hidden rounded-[30px] border border-[#e0e6d6] bg-white shadow-[0_15px_55px_rgba(31,43,24,.06)]">
            <div className="border-b border-[#edf0e8] bg-[#fafbf7] px-6 py-6 sm:px-8">
              <div className="flex flex-wrap items-center justify-between gap-4">
                <div>
                  <p className="text-[10px] font-black uppercase tracking-[0.16em] text-[#849776]">Step 02 / 02</p>
                  <h2 className="mt-1.5 text-2xl font-black tracking-[-0.035em]">Complete your purchase</h2>
                  <p className="mt-2 text-xs text-[#73806c]">Your payment is processed securely by Whop.</p>
                </div>
                <div className="flex size-12 items-center justify-center rounded-2xl border border-[#e0e8d1] bg-[#e6edb0] text-[#415a30]">
                  <CreditCard size={23}/>
                </div>
              </div>
            </div>
            <div className="min-h-[420px] px-5 py-7 sm:px-8">
              {!user ? (
                <div className="rounded-2xl border border-[#e6e9dd] bg-[#fafbf7] p-7">
                  <h3 className="text-lg font-black">First, sign in to LaterBox</h3>
                  <p className="mt-2 text-sm leading-6 text-[#727d6a]">Your purchase must be linked to your LaterBox account so your storage unlocks across devices.</p>
                  <Link href={`/login?next=${encodeURIComponent(nextUrl)}`} className="mt-6 inline-flex items-center gap-2 rounded-xl bg-[#1c2519] px-5 py-3 text-sm font-bold text-white">
                    Sign in to continue <ArrowRight size={16}/>
                  </Link>
                </div>
              ) : active ? (
                <div className="rounded-2xl border border-[#dde7ca] bg-[#f6f9ef] p-7">
                  <h3 className="flex items-center gap-2 text-lg font-black"><BadgeCheck size={20} className="text-[#7c9952]"/> You&apos;re already subscribed</h3>
                  <p className="mt-3 text-sm leading-6 text-[#687865]">Manage your existing {entitlement.provider} plan before buying again. This protects you from duplicate charges.</p>
                  <Link href="/plans" className="mt-6 inline-flex items-center gap-2 rounded-xl bg-[#e6edb0] px-5 py-3 text-sm font-black text-[#22301d]">View your subscription <ArrowRight size={16}/></Link>
                </div>
              ) : planKey ? (
                <div>
                  <div className="mb-6 rounded-2xl border border-[#dfe8d2] bg-[#f7faf1] p-5">
                    <h3 className="text-sm font-black">Have a referral code?</h3>
                    <p className="mt-1 text-xs leading-5 text-[#68785f]">New customers may receive a free 30-day plan trial when a valid referral offer is active. During trial, uploads are limited to 10 GB. Your chosen plan renews automatically at the displayed Whop rate unless canceled.</p>
                    <div className="mt-4 flex flex-wrap gap-2">
                      <input aria-label="Referral code" value={referralInput} onChange={e=>{
                        setReferralInput(e.target.value.toLowerCase());setAppliedReferral(null);setReferralMessage('');
                      }} maxLength={32} placeholder="Enter referral code"
                        className="min-w-0 flex-1 rounded-xl border border-[#ced9c1] bg-white px-4 py-3 font-mono text-sm"/>
                      <button onClick={()=>void validateReferral()} disabled={checkingReferral||!referralInput.trim()}
                        className="rounded-xl bg-[#1c2519] px-5 py-3 text-sm font-black text-white disabled:opacity-40">{checkingReferral?'Checking…':'Apply code'}</button>
                    </div>
                    {referralMessage&&<p role="status" className="mt-3 text-xs font-semibold text-[#5f754f]">{referralMessage}</p>}
                    {appliedReferral?.plan===planKey&&<p className="mt-2 text-xs font-bold text-[#42642e]">Code applied: {appliedReferral.code}</p>}
                    <p className="mt-2 text-[11px] text-[#869480]">If you followed a referral link, its code may already be securely attached to your checkout.</p>
                  </div>
                  <WhopCheckout key={planKey+':'+(appliedReferral?.plan===planKey?appliedReferral.code:'')} planKey={planKey}
                    buyerEmail={user.email ?? ''} referralCode={appliedReferral?.plan===planKey?appliedReferral.code:undefined}/>
                </div>
              ) : <p className="text-sm text-red-700">Choose a valid storage plan.</p>}
            </div>
            <div className="flex flex-wrap items-center justify-between gap-3 border-t border-[#edf0e8] bg-[#fafbf7] px-6 py-5 text-xs text-[#7a8674] sm:px-8">
              <span className="inline-flex items-center gap-2"><LockKeyhole size={15}/> Secure payment handled by Whop</span>
              <span>Cards · Apple Pay · Google Pay when available</span>
            </div>
          </section>
        </div>

        <p className="mx-auto mt-7 max-w-3xl text-center text-xs leading-6 text-[#8d9787]">
          No payment is taken until you confirm in the Whop form. Paid storage renews at the interval selected unless canceled.
          Payment methods depend on your device and Whop&apos;s merchant setup. <Link className="font-bold underline underline-offset-2" href="/terms">Terms</Link> · <Link className="font-bold underline underline-offset-2" href="/refund">Refund policy</Link>
        </p>
      </div>
    </main>
  );
}

export default function CheckoutPage() {
  return <Suspense fallback={<main className="min-h-screen bg-[#f7f8f2] px-6 py-16 text-sm text-[#66755b]">Preparing secure checkout…</main>}>
    <Content/>
  </Suspense>;
}
