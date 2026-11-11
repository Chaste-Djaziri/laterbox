// laterbox-web/src/app/(app)/earn/page.tsx
'use client';
import {useCallback,useEffect,useState} from 'react';
import Link from 'next/link';
import {ArrowUpRight,Check,Clock3,Coins,Copy,Gift,ShieldCheck,Wallet} from 'lucide-react';
import {getSupabaseClient} from '@/lib/supabase/client';
import type {EarnState} from '@/lib/earn/affiliate';

const usd=(c:number)=>(c/100).toLocaleString('en-US',{style:'currency',currency:'USD'});
const date=(v:string)=>new Date(v).toLocaleDateString(undefined,{month:'short',day:'numeric',year:'numeric'});
type Response=EarnState&{error?:string};
const whopConnectionErrors:Record<string,string>={
  missing_parameters:'Whop did not return the expected authorization details. Start a new connection.',
  state_missing:'The secure connection session cookie was not returned. Check browser cookie settings and try again.',
  state_invalid:'Your connection session expired or could not be verified. Start a new Whop connection.',
  configuration:'The LaterBox server could not read its Whop OAuth configuration. Contact support.',
  token_exchange:'Whop approved access, but the server could not exchange the authorization code. Check the Whop app API-key permission oauth:token_exchange and its client secret.',
  token_response:'Whop did not issue a usable access token. Try connecting again.',
  userinfo:'Whop approved access, but its profile verification request failed. Please try again.',
  identity:'Whop returned incomplete or inconsistent identity information. Please try again.',
  database:'Whop approval succeeded, but LaterBox could not save the verified connection. Contact support.',
};

function EarnSkeleton() {
  return (
    <div className="w-full space-y-6 animate-pulse" aria-busy="true" aria-label="Loading your referral account">
      {/* Whop Connection Banner Skeleton */}
      <section className="rounded-3xl border border-[#d8e2ca] bg-[#eef4e2] p-7 sm:p-9 space-y-4">
        <div className="h-4 w-28 rounded-full bg-[#d8e2ca]" />
        <div className="h-7 w-full max-w-md rounded-xl bg-[#d8e2ca]" />
        <div className="space-y-2 max-w-xl">
          <div className="h-3.5 w-full rounded-md bg-[#d8e2ca]/80" />
          <div className="h-3.5 w-4/5 rounded-md bg-[#d8e2ca]/80" />
        </div>
        <div className="pt-2">
          <div className="h-11 w-36 rounded-xl bg-[#171711]/20" />
        </div>
      </section>

      {/* 3 Metrics Cards Skeleton */}
      <div className="grid gap-4 sm:grid-cols-3">
        {[1, 2, 3].map((i) => (
          <section key={i} className="rounded-3xl border border-[#e1e7d7] bg-white p-6 space-y-3">
            <div className="flex items-center justify-between">
              <div className="h-4 w-20 rounded bg-[#e8ede1]" />
              <div className="h-5 w-5 rounded-full bg-[#e8ede1]" />
            </div>
            <div className="h-9 w-28 rounded-lg bg-[#e8ede1] pt-1" />
            <div className="h-3 w-40 rounded bg-[#e8ede1]/80" />
          </section>
        ))}
      </div>

      {/* Referral Link & Code Box Skeleton */}
      <section className="rounded-3xl border border-[#e1e7d7] bg-white p-6 sm:p-8 space-y-4">
        <div className="flex items-center gap-3">
          <div className="h-6 w-6 rounded-lg bg-[#e8ede1]" />
          <div className="h-5 w-56 rounded-md bg-[#e8ede1]" />
        </div>
        <div className="h-3.5 w-full max-w-lg rounded-md bg-[#e8ede1]/80" />
        <div className="pt-2 flex flex-wrap gap-2">
          <div className="h-12 flex-1 min-w-[200px] rounded-xl border border-[#dce6d3] bg-[#f8faf3]" />
          <div className="h-12 w-32 rounded-xl bg-[#e6edb0]/60" />
        </div>
        <div className="flex items-center gap-4 pt-1">
          <div className="h-4 w-24 rounded bg-[#e8ede1]" />
          <div className="h-4 w-20 rounded bg-[#e8ede1]" />
          <div className="h-4 w-24 rounded bg-[#e8ede1]" />
        </div>
      </section>

      {/* 2-Column Split Activity Skeleton */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Referral Progress Skeleton */}
        <section className="rounded-3xl border border-[#e1e7d7] bg-white p-6 space-y-4">
          <div className="h-5 w-40 rounded-md bg-[#e8ede1]" />
          <div className="divide-y divide-[#f0f3eb] pt-1">
            {[1, 2, 3].map((j) => (
              <div key={j} className="flex justify-between items-center py-4">
                <div className="space-y-2">
                  <div className="h-4 w-28 rounded bg-[#e8ede1]" />
                  <div className="h-3 w-36 rounded bg-[#e8ede1]/70" />
                </div>
                <div className="h-5 w-16 rounded-full bg-[#e8ede1]" />
              </div>
            ))}
          </div>
        </section>

        {/* Earnings & Payouts Skeleton */}
        <section className="rounded-3xl border border-[#e1e7d7] bg-white p-6 space-y-4">
          <div className="h-5 w-44 rounded-md bg-[#e8ede1]" />
          <div className="divide-y divide-[#f0f3eb] pt-1">
            {[1, 2, 3].map((k) => (
              <div key={k} className="flex justify-between items-center py-4">
                <div className="space-y-2">
                  <div className="h-4 w-32 rounded bg-[#e8ede1]" />
                  <div className="h-3 w-28 rounded bg-[#e8ede1]/70" />
                </div>
                <div className="h-5 w-14 rounded bg-[#e8ede1]" />
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* How It Works Skeleton */}
      <section className="rounded-3xl border border-[#e1e7d7] bg-white p-6 space-y-5">
        <div className="h-5 w-32 rounded-md bg-[#e8ede1]" />
        <div className="grid gap-4 md:grid-cols-4 pt-1">
          {[1, 2, 3, 4].map((step) => (
            <div key={step} className="space-y-2">
              <div className="h-8 w-8 rounded-full bg-[#e8ede1]" />
              <div className="h-4 w-20 rounded bg-[#e8ede1]" />
              <div className="h-3 w-full rounded bg-[#e8ede1]/70" />
              <div className="h-3 w-3/4 rounded bg-[#e8ede1]/70" />
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

export default function EarnPage(){
  const [data,setData]=useState<EarnState|null>(null);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState('');
  const [adult,setAdult]=useState(false);
  const [terms,setTerms]=useState(false);
  const [working,setWorking]=useState(false);
  const [editing,setEditing]=useState(false);
  const [custom,setCustom]=useState('');
  const [codeError,setCodeError]=useState('');
  const [copied,setCopied]=useState(false);
  const [connecting,setConnecting]=useState(false);
  const [whopResult,setWhopResult]=useState<'connected'|'failed'|null>(null);
  const [whopFailure,setWhopFailure]=useState('');
  const token=async()=>{
    const {data:session}=await getSupabaseClient().auth.getSession();
    if(!session.session?.access_token)throw new Error('Sign in to LaterBox to use Earn.');
    return session.session.access_token;
  };
  const load=useCallback(async()=>{
    setLoading(true);setError('');
    try{
      const {data:session}=await getSupabaseClient().auth.getSession();
      if(!session.session?.access_token)throw new Error('Sign in to view your referral account.');
      const response=await fetch('/api/earn',{cache:'no-store',headers:{Authorization:`Bearer ${session.session.access_token}`}});
      const body=await response.json() as Response;
      if(!response.ok)throw new Error(body.error||'Earn is temporarily unavailable.');
      setData(body);
    }catch(err){setError(err instanceof Error?err.message:'Could not load Earn.');}
    finally{setLoading(false);}
  },[]);
  useEffect(()=>{
    const params=new URLSearchParams(window.location.search);
    const result=params.get('whop');
    if(result==='connected'||result==='failed'){
      setWhopResult(result);
      const failure=params.get('reason')??'';
      setWhopFailure(Object.hasOwn(whopConnectionErrors,failure)?failure:'');
      const clean=new URL(window.location.href);
      clean.searchParams.delete('reason');
      clean.searchParams.delete('whop');
      window.history.replaceState(null,'',clean.pathname+clean.search+clean.hash);
    }
    void load();
  },[load]);

  const copy=async(value:string)=>{
    try{await navigator.clipboard.writeText(value);setCopied(true);window.setTimeout(()=>setCopied(false),2500);}
    catch{setError('Clipboard access is unavailable. Select the text and copy it manually.');}
  };
  const saveCode=async()=>{
    setWorking(true);setCodeError('');
    try{
      const response=await fetch('/api/earn/code',{
        method:'PATCH',headers:{Authorization:`Bearer ${await token()}`,'Content-Type':'application/json'},
        body:JSON.stringify({code:custom}),
      });
      const body=await response.json() as {code?:string;error?:string};
      if(!response.ok||!body.code)throw new Error(body.error||'Could not save the code.');
      setEditing(false);await load();
    }catch(err){setCodeError(err instanceof Error?err.message:'Code unavailable.');}
    finally{setWorking(false);}
  };
  const enroll=async()=>{
    setWorking(true);setError('');
    try{
      const response=await fetch('/api/earn',{
        method:'POST',headers:{Authorization:`Bearer ${await token()}`,'Content-Type':'application/json'},
        body:JSON.stringify({adult,acceptedTerms:terms}),
      });
      const body=await response.json() as {state?:EarnState;error?:string};
      if(!response.ok||!body.state)throw new Error(body.error||'Enrollment is unavailable.');
      setData(body.state);
    }catch(err){setError(err instanceof Error?err.message:'Enrollment failed.');}
    finally{setWorking(false);}
  };
  const connect=async()=>{
    setConnecting(true);setError('');
    try{
      const response=await fetch('/api/earn/connect',{
        method:'POST',headers:{Authorization:`Bearer ${await token()}`},
      });
      const body=await response.json() as {url?:string;error?:string};
      if(!response.ok||!body.url)throw new Error(body.error||'Whop connection unavailable.');
      window.location.assign(body.url);
    }catch(err){setError(err instanceof Error?err.message:'Connection failed.');setConnecting(false);}
  };

  return <main className="w-full px-3 sm:px-5 lg:px-6 py-4 sm:py-6 text-[#171711] space-y-6">
    {whopResult==='connected'&&<p role="status" className="rounded-xl border border-[#c5d7b1] bg-[#eff5dd] p-4 text-sm font-semibold text-[#39552e]">Whop connected successfully. Your personal referral link is ready below.</p>}
    {whopResult==='failed'&&<p role="alert" className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">{whopConnectionErrors[whopFailure]??'Whop could not be verified. Start a new connection.'}</p>}
    {error&&<p role="alert" className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">{error}</p>}
    {!data&&loading&&<EarnSkeleton />}
    {data&&<div className="w-full space-y-6">
      {!data.payoutConnected&&<section className="rounded-3xl border border-[#c6d5ad] bg-[#e6edb0] p-7 sm:p-9">
        <span className="text-xs font-black uppercase tracking-widest text-[#526741]">Step 1 · Required</span>
        <h2 className="mt-3 text-2xl font-black">Connect your Whop account to unlock referrals</h2>
        <p className="mt-3 max-w-2xl text-sm leading-7 text-[#536748]">Securely verify your Whop identity first. After connecting, your personal code and shareable referral link will appear here. A paid LaterBox plan is not required.</p>
        <button type="button" onClick={()=>void connect()} disabled={connecting} className="mt-5 rounded-xl bg-[#171711] px-6 py-3 text-sm font-black text-white disabled:opacity-50">{connecting?'Connecting to Whop…':'Connect Whop'}</button>
        <p className="mt-3 text-xs text-[#536748]">Referrals and commissions only become active after accepting Earn terms and when the program launches.</p>
      </section>}
      <div className="grid gap-4 sm:grid-cols-3">
        {[
          ['Pending',data.balances.pendingCents,Clock3,'Awaiting verification and hold'],
          ['Available',data.balances.availableCents,Wallet,'Eligible for Whop transfer'],
          ['Paid',data.balances.paidCents,Check,'Transferred and confirmed'],
        ].map(([name,amount,Icon,description])=>{
          const Graphic=Icon as typeof Wallet;
          return <section key={String(name)} className="rounded-3xl border border-[#e1e7d7] bg-white p-6">
            <div className="flex items-center justify-between text-sm font-bold text-[#65755d]"><span>{String(name)}</span><Graphic size={19}/></div>
            <p className="mt-4 text-3xl font-black">{usd(Number(amount))}</p>
            <p className="mt-2 text-xs text-[#7c8673]">{String(description)}</p>
          </section>;
        })}
      </div>
      {data.referralCode&&data.payoutConnected&&data.status!=='suspended'&&<section className="rounded-3xl border border-[#e1e7d7] bg-white p-6 sm:p-8">
        <div className="flex items-center gap-3"><Gift size={22} className="text-[#6b8951]"/><h2 className="text-xl font-black">Your referral link and code</h2></div>
        <p className="mt-2 text-sm text-[#7b8573]">Your unique code is unlocked by Whop verification. {data.status==='active'&&data.programEnabled?'Share either one and disclose your affiliate relationship.':'Your code is reserved; referral attribution and commissions will start only when your Earn enrollment and the referral program are active.'}</p>
        <div className="mt-5 flex flex-wrap gap-2">
          <div className="min-w-0 flex-1 break-all rounded-xl border border-[#dce6d3] bg-[#f8faf3] px-4 py-3 font-mono text-sm">{data.referralUrl}</div>
          <button onClick={()=>void copy(`${data.referralUrl}\nI may earn a commission if you buy through my link.`)} className="flex items-center gap-2 rounded-xl bg-[#e6edb0] px-5 py-3 text-sm font-bold"><Copy size={16}/>{copied?'Copied':'Copy link'}</button>
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-4 text-sm">
          <span>Code: <strong className="font-mono">{data.referralCode}</strong></span>
          <button type="button" className="font-bold text-[#597442] underline" onClick={()=>void copy(data.referralCode??'')}>Copy code</button>
          <button type="button" className="font-bold text-[#597442] underline" onClick={()=>{setEditing(v=>!v);setCustom(data.referralCode??'');setCodeError('');}}>Customize</button>
          <span className="text-xs text-[#83907a]">{data.referrals} referred accounts</span>
        </div>
        {editing&&<div className="mt-5 rounded-xl bg-[#f7f9f2] p-4">
          <label htmlFor="own-code" className="text-xs font-bold">Choose your unique code</label>
          <div className="mt-2 flex flex-wrap gap-2">
            <input id="own-code" value={custom} maxLength={32} onChange={e=>setCustom(e.target.value.toLowerCase())}
              autoComplete="off" spellCheck={false} className="min-w-0 flex-1 rounded-xl border border-[#dce5d5] bg-white px-4 py-3 font-mono text-sm"/>
            <button onClick={()=>void saveCode()} disabled={working} className="rounded-xl bg-[#171711] px-5 py-3 text-sm font-bold text-white disabled:opacity-50">{working?'Checking…':'Save code'}</button>
          </div>
          <p className="mt-2 text-xs text-[#7f8978]">8–32 lowercase characters: letters, numbers, underscores or hyphens. Availability is checked when saving. One change every 30 days.</p>
          {codeError&&<p role="alert" className="mt-2 text-xs font-semibold text-red-700">{codeError}</p>}
        </div>}
        {data.programEnabled&&data.status==='active'&&<p className="mt-4 text-xs text-[#818a79]">Introductory commission: {data.rateBps?data.rateBps/100:0}% of eligible net renewal revenue, followed by a lower ongoing rate. Commissions are not guaranteed.</p>}
      </section>}
      {data.status==='eligible'&&<section className="rounded-3xl border border-[#e1e7d7] bg-white p-7">
        <h2 className="text-xl font-black">Connect Whop and activate Earn</h2>
        <p className="mt-2 text-sm text-[#7c8674]">Connect a verified Whop account first. You can join with a Free LaterBox plan; you must also be an adult and accept the terms.</p>
        {data.payoutConnected&&<p className="mt-4 text-sm font-semibold text-[#48613d]">✓ Whop identity verified. Complete the final two checks to join Earn.</p>}
        <label className="mt-4 flex gap-3 text-sm"><input type="checkbox" checked={adult} onChange={e=>setAdult(e.target.checked)}/>I confirm I am at least 18 years old.</label>
        <label className="mt-3 flex gap-3 text-sm"><input type="checkbox" checked={terms} onChange={e=>setTerms(e.target.checked)}/>I accept the <Link href="/earn-terms" className="font-bold underline">affiliate program terms</Link>.</label>
        <button disabled={!data.payoutConnected||!adult||!terms||working} onClick={()=>void enroll()} className="mt-5 rounded-xl bg-[#171711] px-6 py-3 text-sm font-bold text-white disabled:opacity-40">Join Earn</button>
      </section>}
      {data.status==='active'&&<section className="flex flex-wrap items-center justify-between gap-4 rounded-3xl border border-[#e1e7d7] bg-white p-6">
        <div><h2 className="font-black">{data.payoutConnected?'Whop account verified':'Connect Whop for payouts'}</h2>
          <p className="mt-1 max-w-xl text-xs text-[#7d8777]">Whop handles identity checks, withdrawal methods and balances. LaterBox does not collect your bank credentials.</p></div>
        {data.payoutConnected?<span className="rounded-full bg-[#e6edb0] px-4 py-2 text-xs font-black">Connected</span>:
        <button disabled={connecting} onClick={()=>void connect()} className="rounded-xl bg-[#171711] px-5 py-3 text-sm font-bold text-white disabled:opacity-40">{connecting?'Connecting…':'Connect Whop'}</button>}
      </section>}
      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-3xl border border-[#e1e7d7] bg-white p-6">
          <h2 className="text-xl font-black">Referral progress</h2>
          {data.referredProgress.length===0?<p className="mt-5 text-sm text-[#85907e]">No tracked referrals yet. Status updates will appear after a qualified checkout.</p>:
            <div className="mt-4 divide-y">{data.referredProgress.map(p=><div key={p.id} className="flex justify-between gap-4 py-4 text-sm"><div><p className="font-bold">{p.plan.replaceAll('_',' ').toUpperCase()}</p><p className="mt-1 text-xs text-[#858e80]">{p.nextStep} · {date(p.referredAt)}</p></div><span className="capitalize">{p.status}</span></div>)}</div>}
        </section>
        <section className="rounded-3xl border border-[#e1e7d7] bg-white p-6">
          <h2 className="text-xl font-black">Earnings and payouts</h2>
          {data.commissions.length===0&&data.payouts.length===0?<div className="mt-7 text-center"><Coins className="mx-auto text-[#829b68]"/><p className="mt-3 text-sm text-[#85907e]">Your first qualified commission will appear here.</p></div>:
            <div className="mt-4 divide-y">{data.commissions.map(c=><div key={c.id} className="flex items-center justify-between gap-4 py-3"><div><p className="text-sm font-bold">Recurring commission</p><p className="text-xs text-[#879080]">{c.status} · {date(c.createdAt)}</p></div><strong>{usd(c.amountCents)}</strong></div>)}
              {data.payouts.map(p=><div key={p.id} className="flex items-center justify-between gap-4 py-3"><div><p className="text-sm font-bold">Whop transfer</p><p className="text-xs text-[#879080]">{p.status} · {date(p.createdAt)}</p></div><strong>{usd(p.amountCents)}</strong></div>)}</div>}
        </section>
      </div>
      <section className="rounded-3xl border border-[#e1e7d7] bg-white p-6">
        <h2 className="text-xl font-black">How it works</h2>
        <div className="mt-5 grid gap-4 md:grid-cols-4">
          {[
            ['1','Connect','Verify Whop, then share your unique referral link.'],
            ['2','Trial','Your new subscriber receives a free month only on a verified trial offer.'],
            ['3','Qualify','They must remain subscribed and complete two successful paid billing periods.'],
            ['4','Earn','Eligible renewals accrue commission; Whop handles verified payouts.'],
          ].map(([n,t,d])=><div key={n}><span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-[#e6edb0] text-xs font-black">{n}</span><h3 className="mt-2 font-bold">{t}</h3><p className="mt-1 text-xs leading-6 text-[#7b8575]">{d}</p></div>)}
        </div>
        <div className="mt-6 flex flex-wrap items-center justify-between gap-3 border-t pt-5 text-xs text-[#7d8678]"><span className="flex items-center gap-2"><ShieldCheck size={16}/>Refunded transactions do not qualify. Terms and regional eligibility apply.</span>
          <a href="https://whop.com/" rel="noopener noreferrer" target="_blank" className="flex items-center gap-1 font-bold underline">Manage Whop withdrawals <ArrowUpRight size={14}/></a></div>
      </section>
    </div>}
  </main>;
}
