// laterbox-web/src/components/platform/MaintenanceOverlay.tsx
'use client';
import {useEffect,useMemo,useState} from 'react';
import {Clock3,Construction} from 'lucide-react';

type Status={maintenance:{state:'off'|'upcoming'|'active';mode:string;startsAt:string|null;endsAt:string|null;message:string};serverTime:string};

const format=(target:string|null,now:number)=>{
 if(!target)return 'Until further notice';
 const delta=Math.max(0,Date.parse(target)-now);
 const days=Math.floor(delta/86400000),hours=Math.floor(delta%86400000/3600000),mins=Math.floor(delta%3600000/60000),secs=Math.floor(delta%60000/1000);
 return (days?days+'d ':'')+String(hours).padStart(2,'0')+':'+String(mins).padStart(2,'0')+':'+String(secs).padStart(2,'0');
};

function isLocalDevHost(hostname: string): boolean {
 return (
   hostname === 'localhost' ||
   hostname === '127.0.0.1' ||
   hostname === '[::1]' ||
   hostname.endsWith('.localhost')
 );
}

export function MaintenanceOverlay(){
 const [status,setStatus]=useState<Status|null>(null);
 const [now,setNow]=useState(()=>Date.now());
 const [isLocalDev,setIsLocalDev]=useState(()=> {
   if(process.env.NODE_ENV === 'development') return true;
   if(typeof window !== 'undefined') return isLocalDevHost(window.location.hostname);
   return false;
 });

 useEffect(()=>{
  if(typeof window==='undefined')return;
  const h=window.location.hostname;
  if(process.env.NODE_ENV === 'development' || isLocalDevHost(h)){
   setIsLocalDev(true);
   return;
  }
  if(h==='admin.laterbox.dev')return;

  let mounted=true;
  const load=async()=>{
   try{
    const response=await fetch('/api/platform/status',{cache:'no-store'});
    if(!response.ok)return;
    const json=await response.json() as Status;
    if(mounted)setStatus(json);
   }catch{/* Keep the last known state instead of incorrectly clearing maintenance. */}
  };
  void load();
  const poll=window.setInterval(()=>void load(),30000);
  const clock=window.setInterval(()=>setNow(Date.now()),1000);
  const refresh=()=>{if(document.visibilityState==='visible')void load()};
  document.addEventListener('visibilitychange',refresh);
  return ()=>{mounted=false;window.clearInterval(poll);window.clearInterval(clock);document.removeEventListener('visibilitychange',refresh)};
 },[]);

 const state=useMemo(()=>{
  if(isLocalDev||!status)return 'off';
  const {mode,startsAt,endsAt}=status.maintenance;
  if(mode==='off'||(endsAt&&now>=Date.parse(endsAt)))return 'off';
  if(mode==='active')return 'active';
  return startsAt&&now<Date.parse(startsAt)?'upcoming':'active';
 },[status,now,isLocalDev]);

 useEffect(()=>{
  if(isLocalDev||state!=='active')return;
  const old=document.body.style.overflow;
  document.body.style.overflow='hidden';
  return ()=>{document.body.style.overflow=old};
 },[state,isLocalDev]);

 if(isLocalDev||!status||state==='off')return null;

 const m=status.maintenance;
 if(state==='upcoming')return <div role="status" className="fixed inset-x-0 bottom-4 z-[2100000000] mx-auto flex max-w-xl flex-wrap items-center justify-between gap-2 rounded-2xl border border-[#d7dfbe] bg-[#f6f8e8] px-5 py-3 text-sm text-[#29311d] shadow-xl">
  <span className="flex items-center gap-2"><Clock3 size={17}/><strong>Scheduled maintenance</strong></span>
  <span>Starts in {format(m.startsAt,now)}</span>
 </div>;

 return <div role="dialog" aria-modal="true" aria-labelledby="laterbox-maintenance-heading" className="fixed inset-0 z-[2147483647] flex items-center justify-center overflow-y-auto bg-[#f7f5ee] px-5 py-10 text-[#171711]">
  <div className="w-full max-w-xl rounded-[28px] border border-[#e3e8d3] bg-white p-8 text-center shadow-[0_30px_100px_-25px_rgba(23,23,17,0.18)] sm:p-12">
   <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-[#e6edb0]"><Construction size={30}/></div>
   <p className="mt-7 text-xs font-bold uppercase tracking-[.22em] text-[#748064]">LaterBox · Maintenance</p>
   <h1 id="laterbox-maintenance-heading" className="mt-3 text-3xl font-bold tracking-tight">We'll be back shortly.</h1>
   <p className="mx-auto mt-4 max-w-md text-sm leading-7 text-[#60685a]">{m.message}</p>
   {m.endsAt&&<div className="mt-8 rounded-2xl bg-[#f3f5ea] px-5 py-5"><p className="text-xs uppercase tracking-widest text-[#68755f]">Estimated time remaining</p><p className="mt-2 font-mono text-3xl font-bold tabular-nums">{format(m.endsAt,now)}</p><p className="mt-2 text-xs text-[#788072]">Expected return: {new Date(m.endsAt).toLocaleString()}</p></div>}
   <p className="mt-7 text-xs text-[#7d8575]">Your saved items remain intact. This screen will update automatically.</p>
  </div>
 </div>;
}
