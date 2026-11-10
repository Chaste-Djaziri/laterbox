// laterbox-web/src/components/account/ConnectedWhop.tsx
'use client';
import {useEffect,useState} from 'react';
import {CheckCircle2,ExternalLink,Wallet} from 'lucide-react';
import {getSupabaseClient} from '@/lib/supabase/client';

export function ConnectedWhop({userId}:{userId:string}){
 const [linked,setLinked]=useState<boolean|null>(null);
 const [message,setMessage]=useState('');
 const [connecting,setConnecting]=useState(false);
 useEffect(()=>{
  let live=true;
  setLinked(null);setMessage('');
  void (async()=>{
   try{
    const {data}=await getSupabaseClient().auth.getSession();
    if(!data.session?.access_token||data.session.user.id!==userId)throw Error('Sign in again to check Whop.');
    const response=await fetch('/api/earn',{headers:{Authorization:`Bearer ${data.session.access_token}`},cache:'no-store'});
    const body=await response.json() as {payoutConnected?:boolean;error?:string};
    if(!response.ok)throw Error(body.error||'Connection status unavailable.');
    if(live)setLinked(Boolean(body.payoutConnected));
   }catch(err){if(live)setMessage(err instanceof Error?err.message:'Connection status unavailable.');}
  })();
  return ()=>{live=false};
 },[userId]);
 const connect=async()=>{
  setConnecting(true);setMessage('');
  try{
   const {data}=await getSupabaseClient().auth.getSession();
   if(!data.session?.access_token||data.session.user.id!==userId)throw Error('Sign in again before connecting Whop.');
   const response=await fetch('/api/earn/connect',{method:'POST',headers:{Authorization:`Bearer ${data.session.access_token}`}});
   const body=await response.json() as {url?:string;error?:string};
   if(!response.ok||!body.url)throw Error(body.error||'Could not start Whop verification.');
   window.location.assign(body.url);
  }catch(err){setMessage(err instanceof Error?err.message:'Whop is unavailable.');setConnecting(false);}
 };
 return <div className="border-t border-[#e4e0d5] pt-4">
  <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-[#e4e0d5] bg-[#faf8f2] px-4 py-3">
   <div className="flex items-center gap-3">
    <Wallet size={21} aria-hidden="true"/>
    <div><p className="text-sm font-bold">Whop</p>
      <p className="text-xs text-[#6c6b63]">Referral earnings and payout identity · not a sign-in method</p></div>
   </div>
   {linked===true?<span className="flex items-center gap-1 text-xs font-bold text-emerald-700"><CheckCircle2 size={16}/>Verified</span>:
    <button type="button" onClick={()=>void connect()} disabled={connecting||linked===null}
      className="rounded-xl bg-[#171711] px-4 py-2 text-xs font-bold text-white disabled:opacity-50">
      {connecting?'Connecting…':linked===null?'Checking…':'Connect Whop'} <ExternalLink size={12} className="inline"/>
    </button>}
  </div>
  {message&&<p role="status" className="mt-2 text-xs text-amber-700">{message}</p>}
 </div>;
}
