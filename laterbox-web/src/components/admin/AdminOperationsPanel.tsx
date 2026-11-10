// laterbox-web/src/components/admin/AdminOperationsPanel.tsx
'use client';
import {useCallback,useEffect,useMemo,useState} from 'react';
import {getSupabaseClient} from '@/lib/supabase/client';
import {AlertTriangle,CalendarClock,Check,Clock3,RefreshCw,ShieldCheck,ToggleLeft} from 'lucide-react';
type Mode='off'|'scheduled'|'active';
type Feature='referrals'|'checkout'|'support'|'ai';
type Ticket={id:string;user_id:string|null;email:string;category:string;subject:string;message:string;platform:string;app_version:string|null;status:'open'|'in_progress'|'resolved';created_at:string};
type Operations={features:Record<Feature,boolean>;maintenanceMode:Mode;maintenanceStartsAt:string|null;maintenanceEndsAt:string|null;maintenanceMessage:string;updatedAt:string|null};
type Audit={id:number;action:string;target:string|null;created_at:string};
type Payload={operations:Operations;maintenanceState:string;tickets:Ticket[];audit:Audit[];isOwner:boolean;canManage:boolean};
const featureInfo:{key:Feature;label:string;description:string}[]=[
 {key:'referrals',label:'Referral Earn',description:'Activate referral enrollment and commission attribution. Automatic payouts remain disabled.'},
 {key:'checkout',label:'Subscription checkout',description:'Allow users to initiate new Whop storage-plan purchases.'},
 {key:'support',label:'Support submissions',description:'Accept new reports, feedback, and requests from users.'},
 {key:'ai',label:'AI services',description:'Allow AI search, organization, and mobile AI proxy requests.'},
];
const input='w-full rounded-xl border border-[#dde2d2] bg-white px-4 py-3 text-sm text-[#171711] outline-none focus:border-[#9bad79]';
const toLocal=(v:string|null)=>v?new Date(v).toLocaleString('sv-SE').slice(0,16).replace(' ','T'):'';
export function AdminOperationsPanel({view}:{view:'feedback'|'features'|'maintenance'}){
 const [data,setData]=useState<Payload|null>(null),[loading,setLoading]=useState(true),[error,setError]=useState(''),[success,setSuccess]=useState('');
 const [busy,setBusy]=useState(false),[filter,setFilter]=useState('all');
 const [mode,setMode]=useState<Mode>('off'),[start,setStart]=useState(''),[end,setEnd]=useState(''),[message,setMessage]=useState('');
 const token=async()=>{
  const {data:{session}}=await getSupabaseClient().auth.getSession();
  if(!session?.access_token)throw Error('Sign in to the Control Center again.');
  return session.access_token;
 };
 const load=useCallback(async()=>{
  setLoading(true);setError('');
  try{
   const response=await fetch('/api/admin/operations',{headers:{Authorization:'Bearer '+await token()},cache:'no-store'});
   const result=await response.json() as Payload&{error?:string};
   if(!response.ok)throw Error(result.error||'Could not load operations.');
   setData(result);setMode(result.operations.maintenanceMode);
   setStart(toLocal(result.operations.maintenanceStartsAt));setEnd(toLocal(result.operations.maintenanceEndsAt));
   setMessage(result.operations.maintenanceMessage);
  }catch(e){setError(e instanceof Error?e.message:'Could not load operations.')}
  finally{setLoading(false)}
 },[]);
 useEffect(()=>{void load()},[load]);
 const update=async(payload:Record<string,unknown>,confirm?:string)=>{
  if(!data?.isOwner)return;
  if(confirm&&!window.confirm(confirm))return;
  setBusy(true);setError('');setSuccess('');
  try{
   const response=await fetch('/api/admin/operations',{method:'PATCH',headers:{Authorization:'Bearer '+await token(),'Content-Type':'application/json'},body:JSON.stringify(payload)});
   const result=await response.json() as {error?:string};
   if(!response.ok)throw Error(result.error||'Operation failed.');
   setSuccess('Change saved and recorded in the audit log.');await load();
  }catch(e){setError(e instanceof Error?e.message:'Operation failed.')}
  finally{setBusy(false)}
 };
 const tickets=useMemo(()=>data?.tickets.filter(t=>filter==='all'||t.category===filter||t.status===filter)??[],[data,filter]);
 if(loading)return <div className="flex items-center gap-2 rounded-2xl bg-white p-6 text-sm text-[#63705e]"><RefreshCw size={17} className="animate-spin"/>Loading live operations…</div>;
 return <div className="space-y-5">
  {error&&<p role="alert" className="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">{error}</p>}
  {success&&<p role="status" className="rounded-xl border border-[#c5d8a5] bg-[#f0f6e4] p-4 text-sm text-[#47663d]">{success}</p>}
  {view==='features'&&<section className="rounded-2xl border border-[#e1e6d7] bg-white p-6">
   <div className="flex items-center gap-3"><ToggleLeft size={22}/><div><h2 className="text-lg font-bold">Feature availability</h2><p className="text-sm text-[#74806e]">Server-side controls with an audit trail</p></div></div>
   <div className="mt-5 divide-y divide-[#edf0e7]">{featureInfo.map(f=><div key={f.key} className="flex flex-wrap items-center justify-between gap-5 py-5">
    <div className="max-w-lg"><h3 className="font-semibold">{f.label}</h3><p className="mt-1 text-sm leading-6 text-[#788272]">{f.description}</p></div>
    <button type="button" role="switch" aria-checked={Boolean(data?.operations.features[f.key])} disabled={!data?.isOwner||busy} onClick={()=>void update({action:'feature',feature:f.key,enabled:!data?.operations.features[f.key]},f.key==='referrals'&&!data?.operations.features.referrals?'Enable the live referral program? This may begin new referral attribution. Automatic payouts remain off.':'Change '+f.label+' availability for all users?')}
      className={'relative h-8 w-14 shrink-0 rounded-full transition-colors disabled:opacity-50 '+(data?.operations.features[f.key]?'bg-[#829f5b]':'bg-[#c9d1c1]')}>
     <span className={'absolute top-1 h-6 w-6 rounded-full bg-white shadow transition-all '+(data?.operations.features[f.key]?'left-7':'left-1')}/>
    </button>
   </div>)}</div>
   <p className="mt-5 text-xs text-[#778370]">The owner can enable or pause these services. Turning off a feature does not cancel existing subscriptions or delete user data.</p>
  </section>}
  {view==='maintenance'&&<section className="rounded-2xl border border-[#e1e6d7] bg-white p-6">
   <div className="flex items-center gap-3"><CalendarClock size={22}/><div><h2 className="text-lg font-bold">Site-wide maintenance</h2><p className="text-sm text-[#74806e]">Schedule downtime, publish an announcement, and display a live countdown</p></div></div>
   <div className="mt-6 grid gap-5 md:grid-cols-2">
    <label className="text-sm font-semibold">Maintenance mode<select className={'mt-2 '+input} value={mode} onChange={e=>setMode(e.target.value as Mode)} disabled={!data?.isOwner}><option value="off">Off — site is available</option><option value="scheduled">Scheduled — announce a future window</option><option value="active">Start maintenance immediately</option></select></label>
    <div className="flex items-end gap-2"><ShieldCheck size={18} className="mb-3"/><p className="pb-2 text-sm text-[#67755d]">Current state: <strong className="capitalize">{data?.maintenanceState}</strong></p></div>
    {mode!=='off'&&<>
     {mode==='scheduled'&&<label className="text-sm font-semibold">Start date and time <span className="text-xs font-normal text-[#74806e]">(local)</span><input className={'mt-2 '+input} type="datetime-local" value={start} onChange={e=>setStart(e.target.value)} disabled={!data?.isOwner}/></label>}
     <label className="text-sm font-semibold">Expected end date and time <span className="text-xs font-normal text-[#74806e]">(local)</span><input className={'mt-2 '+input} type="datetime-local" value={end} onChange={e=>setEnd(e.target.value)} disabled={!data?.isOwner}/></label>
    </>}
   </div>
   <label className="mt-5 block text-sm font-semibold">User-facing message<textarea rows={3} className={'mt-2 '+input} value={message} maxLength={500} onChange={e=>setMessage(e.target.value)} disabled={!data?.isOwner}/></label>
   <div className="mt-5 flex flex-wrap items-center justify-between gap-4"><p className="max-w-lg text-xs leading-5 text-[#7c8577]">When active, visitors see a full-screen LaterBox maintenance screen. Scheduled maintenance shows advance notice. Admin access remains available for recovery.</p>
    <button disabled={!data?.isOwner||busy} className="rounded-xl bg-[#e6edb0] px-5 py-3 text-sm font-bold text-[#171711] disabled:opacity-50" onClick={()=>{
     if(mode==='scheduled'&&(!start||Number.isNaN(Date.parse(start)))){setError('Select a valid future start time.');return}
     if(mode!=='off'&&(!end||Number.isNaN(Date.parse(end)))){setError('Select a valid end time.');return}
     void update({action:'maintenance',mode,
       startsAt:mode==='scheduled'?new Date(start).toISOString():mode==='active'?new Date().toISOString():null,
       endsAt:mode!=='off'&&end?new Date(end).toISOString():null,message},
       mode==='active'?'Start maintenance immediately for every LaterBox visitor?':'Save maintenance configuration?');
    }}>{busy?'Saving…':'Save maintenance'}</button>
   </div>
   <div className="mt-7 rounded-2xl border border-[#e7e9db] bg-[#f6f7ef] p-4"><p className="flex items-center gap-2 text-sm font-semibold"><Clock3 size={17}/> User-facing maintenance preview</p><p className="mt-2 text-sm text-[#778272]">{message}</p><p className="mt-2 text-xs text-[#778272]">{end?'Estimated restoration: '+new Date(end).toLocaleString():'No end time selected'}</p></div>
  </section>}
  {view==='feedback'&&<section className="rounded-2xl border border-[#e1e6d7] bg-white p-6">
   <div className="flex flex-wrap items-center justify-between gap-4"><div><h2 className="text-lg font-bold">Feedback, help requests & user reports</h2><p className="mt-1 text-sm text-[#74806e]">Live support queue · {data?.tickets.length??0} latest submissions</p></div><select className={'max-w-[210px] '+input} value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">All submissions</option><option value="problem">Problem reports</option><option value="feedback">Feedback</option><option value="help">Help requests</option><option value="other">Other</option><option value="open">Open</option><option value="in_progress">In progress</option><option value="resolved">Resolved</option></select></div>
   <div className="mt-5 divide-y divide-[#edf0e7]">{tickets.length===0?<p className="py-10 text-center text-sm text-[#788272]">No reports match this filter.</p>:tickets.map(t=><article key={t.id} className="py-5">
    <div className="flex flex-wrap items-center justify-between gap-3"><div><p className="text-xs font-bold uppercase tracking-widest text-[#788470]">{t.category} · {t.platform} · {new Date(t.created_at).toLocaleString()}</p><h3 className="mt-2 font-bold">{t.subject}</h3><p className="mt-1 text-xs text-[#74806e]">{t.email}</p></div>
     <select aria-label={'Status of '+t.subject} className="rounded-xl border border-[#d9dfcb] bg-[#f8faf3] p-2 text-xs" disabled={!data?.isOwner||busy} value={t.status} onChange={e=>void update({action:'ticket',ticketId:t.id,status:e.target.value})}><option value="open">Open</option><option value="in_progress">In progress</option><option value="resolved">Resolved</option></select>
    </div><p className="mt-3 whitespace-pre-wrap break-words rounded-xl bg-[#f7f7f2] p-4 text-sm leading-6 text-[#525e4b]">{t.message}</p>
   </article>)}</div>
  </section>}
  <section className="rounded-2xl border border-[#e1e6d7] bg-white p-5"><div className="flex items-center gap-2"><AlertTriangle size={17}/><h3 className="text-sm font-bold">Recent administrative actions</h3></div><div className="mt-3 space-y-2">{(data?.audit??[]).slice(0,12).map(a=><p key={a.id} className="text-xs text-[#6d7867]">{new Date(a.created_at).toLocaleString()} · {a.action} · {a.target??'platform'}</p>)}</div></section>
 </div>;
}
