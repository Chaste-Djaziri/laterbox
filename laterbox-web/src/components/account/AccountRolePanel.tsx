// laterbox-web/src/components/account/AccountRolePanel.tsx
'use client';
import {useEffect,useState} from 'react';
import {ShieldCheck,ExternalLink} from 'lucide-react';
import {getSupabaseClient} from '@/lib/supabase/client';
type RoleInfo={role:'member'|'advocate'|'support'|'analyst'|'admin'|'owner';whopConnected:boolean;whopTeamRole:string|null;staffRole:string|null};
export function AccountRolePanel({userId}:{userId:string}){
 const [details,setDetails]=useState<RoleInfo|null>(null),[error,setError]=useState('');
 useEffect(()=>{
  let current=true;
  void (async()=>{
   try{
    const {data:{session}}=await getSupabaseClient().auth.getSession();
    if(!session||session.user.id!==userId)throw Error('Sign in again to view account roles.');
    const response=await fetch('/api/account/role',{headers:{Authorization:'Bearer '+session.access_token},cache:'no-store'});
    const info=await response.json() as RoleInfo&{error?:string};
    if(!response.ok)throw Error(info.error||'Role unavailable.');
    if(current)setDetails(info);
   }catch(e){if(current)setError(e instanceof Error?e.message:'Role unavailable.')}
  })();
  return ()=>{current=false};
 },[userId]);
 return <section className="rounded-2xl border border-[#e2e5d7] bg-[#f8faf2] p-4">
  <div className="flex items-center gap-2"><ShieldCheck size={18}/><h3 className="text-sm font-bold">LaterBox account role</h3></div>
  {error?<p role="status" className="mt-2 text-xs text-amber-700">{error}</p>:<p className="mt-2 text-sm font-semibold capitalize">{details?.role??'Checking access…'}</p>}
  {details&&<p className="mt-1 text-xs text-[#727c68]">Whop: {details.whopConnected?'Connected':'Not connected'}{details.whopTeamRole?' · Whop team: '+details.whopTeamRole:''}. Whop business roles never grant LaterBox administration.</p>}
  {(details?.staffRole==='owner'||details?.staffRole==='admin')&&<a href="https://admin.laterbox.dev" className="mt-3 inline-flex items-center gap-2 text-sm font-bold text-[#475e36] underline">Open control center <ExternalLink size={14}/></a>}
 </section>;
}
