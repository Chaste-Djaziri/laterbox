// laterbox-web/src/app/(app)/earn/page.tsx
'use client';

import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowUpRight, BadgeCheck, Check, ChevronRight, Clock3, Coins, Copy,
  Gift, LockKeyhole, RefreshCcw, ShieldCheck, Sparkles, Wallet } from 'lucide-react';
import { getSupabaseClient } from '@/lib/supabase/client';
import type { EarnState } from '@/lib/earn/affiliate';

type Dashboard = EarnState & { awaitingReceipts?: boolean; termsUrl?: string };
const formatUsd = (cents:number) => (cents / 100).toLocaleString('en-US',{style:'currency',currency:'USD'});
const formatDate = (value:string) => new Date(value).toLocaleDateString(undefined,{month:'short',day:'numeric',year:'numeric'});

export default function EarnPage() {
  const [data,setData] = useState<Dashboard|null>(null);
  const [loading,setLoading] = useState(true);
  const [error,setError] = useState('');
  const [adult,setAdult] = useState(false);
  const [accepted,setAccepted] = useState(false);
  const [joining,setJoining] = useState(false);
  const [connecting,setConnecting] = useState(false);
  const [copied,setCopied] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);setError('');
    try {
      const {data:session}=await getSupabaseClient().auth.getSession();
      const token=session.session?.access_token;
      if(!token){setData(null);setError('Sign in to view your affiliate account.');return;}
      const response=await fetch('/api/earn',{headers:{Authorization:`Bearer ${token}`},cache:'no-store'});
      const body=await response.json() as Dashboard & {error?:string};
      if(!response.ok)throw new Error(body.error||'Earn is temporarily unavailable.');
      setData(body);
    }catch(e){setError(e instanceof Error?e.message:'Could not load Earn.');}
    finally{setLoading(false);}
  },[]);

  useEffect(()=>{void load();},[load]);
  const join = async () => {
    if(joining||!adult||!accepted)return;
    setJoining(true);setError('');
    try{
      const {data:session}=await getSupabaseClient().auth.getSession();
      if(!session.session?.access_token)throw new Error('Sign in to enroll.');
      const response=await fetch('/api/earn',{
        method:'POST',headers:{Authorization:`Bearer ${session.session.access_token}`,'Content-Type':'application/json'},
        body:JSON.stringify({adult:true,acceptedTerms:true}),
      });
      const body=await response.json() as {state:Dashboard;error?:string};
      if(!response.ok)throw new Error(body.error||'Could not join Earn.');
      setData(body.state);
    }catch(e){setError(e instanceof Error?e.message:'Enrollment unavailable.');}
    finally{setJoining(false);}
  };

  const connectWhop = async () => {
    if(connecting)return;
    setConnecting(true);setError('');
    try{
      const {data:session}=await getSupabaseClient().auth.getSession();
      if(!session.session?.access_token) throw new Error('Sign in to LaterBox before connecting Whop.');
      const res=await fetch('/api/earn/connect',{
        method:'POST',headers:{Authorization:`Bearer ${session.session.access_token}`},
      });
      const data=await res.json() as {url?:string;error?:string};
      if(!res.ok||!data.url)throw new Error(data.error||'Whop connection is unavailable.');
      window.location.assign(data.url);
    }catch(e){setError(e instanceof Error?e.message:'Could not connect Whop.');setConnecting(false);}
  };

  const copyLink=async()=>{
    if(!data?.referralUrl)return;
    try{await navigator.clipboard.writeText(`${data.referralUrl}\nDisclosure: I may receive a commission if you purchase a LaterBox subscription through this link.`);setCopied(true);window.setTimeout(()=>setCopied(false),2200);}
    catch{setError('Could not copy the link.');}
  };

  const isActive=data?.status==='active';
  const isReady=data?.status==='eligible';
  const isLocked=data?.status==='locked';
  const isPaused=data?.status==='suspended';
  const isLaunchPending=data?.status==='not_launched';
  const planLabel=data?.plan==='vault'?'Vault':data?.plan==='plus'?'Plus':'Free';
  const roleLabel=data?.role==='vault_ambassador'?'Vault Ambassador':'Plus Partner';

  return <div className="mx-auto max-w-6xl px-5 py-9 text-[#171711] sm:px-8">
    <div className="flex flex-wrap items-start justify-between gap-5">
      <div>
        <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-[#e6edb0] px-3 py-1.5 text-xs font-bold tracking-wide text-[#2d3e1c]">
          <Sparkles size={14}/> LATERBOX EARN
        </div>
        <h1 className="text-4xl font-black tracking-[-0.05em] sm:text-5xl">Share what you love.<br/>Earn along the way.</h1>
        <p className="mt-4 max-w-xl text-sm leading-7 text-[#6f7667]">Invite someone to save what matters. Eligible paid members can earn a commission when a new customer purchases through their unique LaterBox referral link.</p>
      </div>
      <button type="button" onClick={()=>void load()} disabled={loading}
        className="inline-flex items-center gap-2 rounded-xl border border-[#dfe5d6] bg-white px-4 py-2.5 text-sm font-semibold hover:bg-[#f6f8f1]">
        <RefreshCcw size={15} className={loading?'animate-spin':''}/> Refresh
      </button>
    </div>

    {error&&<div role="alert" className="mt-7 rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-800">{error}</div>}
    {loading&&!data&&<div className="mt-9 animate-pulse rounded-3xl border border-[#e5e9df] bg-[#f4f6ec] p-10 text-[#6f7667]">Checking your membership and earnings…</div>}

    {data&&<div className="mt-9 space-y-6">
      <div className="grid gap-4 md:grid-cols-3">
        {[
          {label:'Pending',amount:data.balances.pendingCents, icon:Clock3,detail:'Waiting through the hold period'},
          {label:'Available',amount:data.balances.availableCents,icon:Wallet,detail:'Approved for payout'},
          {label:'Paid',amount:data.balances.paidCents,icon:BadgeCheck,detail:'Confirmed Whop transfers'},
        ].map(({label,amount,icon:Icon,detail})=><section key={label} className="rounded-3xl border border-[#e3e7dc] bg-white p-6">
          <div className="flex items-center justify-between text-[#65725c]"><span className="text-sm font-semibold">{label}</span><Icon size={19}/></div>
          <p className="mt-4 text-3xl font-extrabold tracking-tight">{formatUsd(amount)}</p>
          <p className="mt-2 text-xs text-[#81897b]">{detail}</p>
        </section>)}
      </div>

      <section className="overflow-hidden rounded-[28px] border border-[#e0e7d7] bg-[#eef3d9]">
        <div className="flex flex-col gap-6 px-6 py-7 sm:flex-row sm:items-center sm:justify-between sm:px-8">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.15em] text-[#5b6d47]">Your affiliate status</p>
            <h2 className="mt-2 text-2xl font-extrabold tracking-tight">
              {isActive?roleLabel:isReady?'You qualify to join':isPaused?'Membership paused':isLaunchPending?'The Earn program is in preparation':'Unlock Earn with your paid plan'}
            </h2>
            <p className="mt-3 max-w-xl text-sm leading-6 text-[#5e6956]">
              {isActive?'Your unique link is ready. Earnings are tracked from verified first purchases.':
               isLaunchPending?'LaterBox is finalizing commission rates, payout configuration and the affiliate program terms. No commissions are active yet.':
               isReady?'Your active paid subscription meets the two-month requirement. Review the terms and activate your affiliate role.':
               isPaused?'Your referrals are paused while the account is under review.':
               data.awaitingReceipts?'Your subscription tenure is sufficient, but we are verifying your successful paid billing cycles.':
               data.eligibleAt?`Maintain your paid plan until ${formatDate(data.eligibleAt)} to qualify.`:'Subscribe to Plus or Vault and keep your paid plan active for two months.'}
            </p>
            {data.memberSince&&data.eligibleAt&&data.plan!=='free'&&<div className="mt-5 max-w-sm">
              <div className="mb-2 flex items-center justify-between text-xs font-semibold text-[#617750]">
                <span>Paid membership tenure</span>
                <span>{Date.now()>=new Date(data.eligibleAt).getTime()?'2 months complete':'Building eligibility'}</span>
              </div>
              <div role="progressbar" aria-label="Paid membership tenure" aria-valuemin={0} aria-valuemax={100}
                aria-valuenow={Math.round(100*Math.max(0,Math.min(1,(Date.now()-new Date(data.memberSince).getTime())/(new Date(data.eligibleAt).getTime()-new Date(data.memberSince).getTime()||1))))}
                className="h-2 overflow-hidden rounded-full bg-[#d7e2c3]">
                <div className="h-full rounded-full bg-[#526f3b]" style={{width:`${Math.round(100*Math.max(0,Math.min(1,(Date.now()-new Date(data.memberSince).getTime())/(new Date(data.eligibleAt).getTime()-new Date(data.memberSince).getTime()||1))))}%`}}/>
              </div>
            </div>}
          </div>
          <div className="shrink-0 rounded-2xl border border-[#ceddb4] bg-white/65 px-5 py-4">
            <p className="text-xs font-semibold text-[#778568]">Your current plan</p>
            <p className="mt-1 text-xl font-bold">{planLabel}</p>
            <p className="mt-1 text-xs text-[#778568]">{isActive?roleLabel:data.memberSince?`Member since ${formatDate(data.memberSince)}`:'A paid plan is required'}</p>
          </div>
        </div>
        {!isActive&&!isReady&&<div className="border-t border-[#dce5c9] bg-white/30 px-6 py-4 text-sm">
          <Link className="inline-flex items-center gap-1 font-bold text-[#3c592b] hover:underline" href="/plans">Explore paid plans <ChevronRight size={16}/></Link>
        </div>}
      </section>

      {isActive && <section className="rounded-[28px] border border-[#e0e5da] bg-white p-6 sm:p-8">
        <div className="flex items-center gap-3"><Gift className="text-[#6c874a]"/><h2 className="text-xl font-extrabold">Your referral link</h2></div>
        <p className="mt-2 text-sm text-[#737b6e]">Invite new customers and track confirmed purchases. Include a clear affiliate disclosure when sharing.</p>
        <div className="mt-5 flex flex-col gap-3 sm:flex-row">
          <div className="min-w-0 flex-1 overflow-hidden rounded-xl border border-[#dce5d2] bg-[#f8faf3] px-4 py-3 font-mono text-sm text-[#3d5732]">{data.referralUrl}</div>
          <button onClick={()=>void copyLink()} type="button" className="flex items-center justify-center gap-2 rounded-xl bg-[#e6edb0] px-5 py-3 text-sm font-bold hover:bg-[#d9e5a1]">
            {copied?<Check size={17}/>:<Copy size={17}/>} {copied?'Copied with disclosure':'Copy link'}
          </button>
        </div>
        <div className="mt-5 flex flex-wrap gap-5 text-sm text-[#68785f]">
          <span><strong className="text-[#242c21]">{data.referrals}</strong> referred customers</span>
          <span><strong className="text-[#242c21]">{data.rateBps!==null?`${(data.rateBps/100).toFixed(0)}%`:'—'}</strong> of eligible net first payment</span>
        </div>
        <div className="mt-6 flex flex-wrap items-center justify-between gap-3 border-t border-[#e5e9de] pt-5">
          <div><p className="text-sm font-bold">{data.payoutConnected?'Whop account connected':'Connect Whop for payouts'}</p>
            <p className="mt-1 text-xs text-[#818a7d]">{data.payoutConnected?'Your verified Whop account can receive approved transfers.':'Connect securely via Whop to verify the recipient for your earned commissions.'}</p></div>
          {data.payoutConnected?<span className="inline-flex items-center gap-1 rounded-full bg-[#e6edb0] px-3 py-2 text-xs font-bold"><Check size={14}/> Connected</span>:
            <button type="button" onClick={()=>void connectWhop()} disabled={connecting} className="rounded-xl bg-[#171711] px-5 py-3 text-sm font-bold text-white disabled:opacity-50">
              {connecting?'Connecting…':'Connect Whop'}
            </button>}
        </div>
      </section>}

      {isReady && <section className="rounded-[28px] border border-[#e0e5da] bg-white p-6 sm:p-8">
        <h2 className="text-xl font-extrabold">Activate {roleLabel}</h2>
        <p className="mt-2 text-sm text-[#777e72]">Your commission rate is based on your qualifying paid plan. New referrals earn only after a verified first subscription payment.</p>
        <div className="mt-5 space-y-3 text-sm">
          <label className="flex items-start gap-3"><input type="checkbox" checked={adult} onChange={e=>setAdult(e.target.checked)} className="mt-1 accent-[#516e3e]"/><span>I confirm that I am at least 18 years old.</span></label>
          <label className="flex items-start gap-3"><input type="checkbox" checked={accepted} onChange={e=>setAccepted(e.target.checked)} className="mt-1 accent-[#516e3e]"/><span>I accept the <Link href="/earn-terms" className="font-semibold underline">LaterBox affiliate program terms</Link>.</span></label>
        </div>
        <button onClick={()=>void join()} disabled={!adult||!accepted||joining} className="mt-6 rounded-xl bg-[#171711] px-6 py-3 font-bold text-white disabled:cursor-not-allowed disabled:opacity-40">
          {joining?'Activating…':'Join LaterBox Earn'}
        </button>
      </section>}

      <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <section className="rounded-[28px] border border-[#e0e5da] bg-white p-6 sm:p-8">
          <h2 className="text-xl font-extrabold">Your earnings activity</h2>
          {data.commissions.length===0?<div className="mt-7 flex flex-col items-center rounded-2xl bg-[#f7f9f2] px-5 py-10 text-center"><Coins size={29} className="text-[#84976b]"/><p className="mt-3 font-bold">Nothing here yet</p><p className="mt-1 text-sm text-[#858b80]">Qualified referrals and verified commission events appear here.</p></div>
            :<div className="mt-5 divide-y divide-[#e9ece5]">{data.commissions.map(c=><div key={c.id} className="flex items-center justify-between gap-4 py-4"><div><p className="text-sm font-bold capitalize">{c.status==='reversed'?'Reversed commission':'Subscription referral'}</p><p className="mt-1 text-xs text-[#92988d]">{formatDate(c.createdAt)} · {c.status==='pending'?`Hold until ${formatDate(c.holdUntil)}`:c.status}</p></div><span className="text-sm font-black">{formatUsd(c.amountCents)}</span></div>)}</div>}
        </section>
        <section className="rounded-[28px] border border-[#e0e5da] bg-white p-6 sm:p-8">
          <h2 className="text-xl font-extrabold">How it works</h2>
          <div className="mt-6 space-y-5">
            {[
              ['1','Qualify','Keep a Plus or Vault subscription paid and active for at least two months.'],
              ['2','Join and share','Enroll, receive your referral link and disclose that you may earn a commission.'],
              ['3','Track the purchase','A new customer completes a first paid Whop web checkout through your link.'],
              ['4','Review and release','Commissions remain pending during the hold period and may be reversed for refunds.'],
              ['5','Receive money','Once enabled and verified, transfers reach your Whop balance for withdrawal.'],
            ].map(([n,title,copy])=><div key={n} className="flex gap-3"><div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[#e6edb0] text-xs font-black">{n}</div><div><p className="text-sm font-bold">{title}</p><p className="mt-1 text-xs leading-5 text-[#81897c]">{copy}</p></div></div>)}
          </div>
          <div className="mt-7 rounded-2xl border border-[#e2e9d7] bg-[#f8faf3] p-4">
            <div className="flex items-center gap-2 font-bold"><ShieldCheck size={18}/> Whop payments</div>
            <p className="mt-2 text-xs leading-5 text-[#72806a]">Bank accounts, identity checks and withdrawal details are handled by Whop. LaterBox never asks for your banking credentials.</p>
            <a href="https://whop.com/" target="_blank" rel="noopener noreferrer" className="mt-3 inline-flex items-center gap-1 text-xs font-bold text-[#526c41] hover:underline">Open Whop to manage withdrawals <ArrowUpRight size={14}/></a>
          </div>
        </section>
      </div>

      <section className="rounded-[28px] border border-[#e0e5da] bg-white p-6 sm:p-8">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-xl font-extrabold">Payout history</h2>
          {data.payoutConnected?<span className="rounded-full bg-[#e6edb0] px-3 py-1 text-xs font-bold text-[#385129]">Whop verified</span>:
            <span className="text-xs font-semibold text-[#7f877b]">Connect Whop to enable transfers</span>}
        </div>
        {data.payouts.length===0?<p className="mt-5 text-sm text-[#81897c]">No transfers yet. Once approved earnings reach the payout threshold, eligible transfers will appear here.</p>:
          <div className="mt-4 divide-y divide-[#e7eae3]">{data.payouts.map(p=><div key={p.id} className="flex items-center justify-between gap-5 py-4">
            <div><p className="text-sm font-bold">Whop balance transfer</p>
              <p className="mt-1 text-xs text-[#81897c]">{formatDate(p.createdAt)} · {p.status==='paid'?'Whop confirmed':p.status==='processing'?'Transferring':p.status==='failed'?'Needs attention':p.status}</p></div>
            <div className="text-right"><p className="text-sm font-extrabold">{formatUsd(p.amountCents)}</p><p className="mt-1 text-xs capitalize text-[#747c6f]">{p.status}</p></div>
          </div>)}</div>}
      </section>

      <div className="flex items-start gap-2 text-xs leading-6 text-[#7d8479]"><LockKeyhole size={16} className="mt-1 shrink-0"/> Commission amounts are conditional until approved and transferred. You cannot refer yourself. Refunds, disputes, fraudulent or duplicate transactions may void earnings. Tax obligations and payout availability depend on your location. <Link href="/earn-terms" className="font-semibold underline">Read terms</Link>.</div>
    </div>}
  </div>;
}
