// laterbox-web/src/app/admin/page.tsx
'use client';
import {useCallback,useEffect,useMemo,useState} from 'react';
import {getSupabaseClient} from '@/lib/supabase/client';
import {Activity,ArrowUpRight,BarChart3,CreditCard,LayoutDashboard,Loader2,LockKeyhole,RefreshCcw,Search,Shield,Users,Wallet,MessageSquareText,CalendarClock,SlidersHorizontal,Trash2} from 'lucide-react';
import {AdminOperationsPanel} from '@/components/admin/AdminOperationsPanel';

type Role='member'|'advocate'|'support'|'analyst'|'admin'|'owner';
type UserRow={id:string;email:string|null;createdAt:string;role:Role;whopConnected:boolean;whopTeamRole:string|null;referralCode:string|null;affiliateStatus:string|null;subscriptions:string[]};
type Plan={provider_price_id:string;sku_key:string;family:string;quotaBytes:number;trial_days:number};
type Data={
 role:Role;scope:{read:boolean;manage:boolean;roles:boolean};users:UserRow[];
 totals:{users:number;advocates:number;activeSubscriptions:number;referrals:number;pendingCommissionCents:number;totalCommissionCents:number;totalPaidCents:number;payoutCount:number;subscriptionsByStatus:Record<string,number>};
 monthly:{month:string;newUsers:number;commissionsCents:number}[];plans:Plan[];
 settings:{enabled:boolean;automatic_payouts:boolean;trial_enabled:boolean;trial_days:number;intro_commission_bps:number;ongoing_commission_bps:number;hold_days:number;minimum_payout_cents:number};
 earnings:{commissions:number;payouts:number;byStatus:Record<string,number>};whopRoleAvailable:boolean;
};
type Tab='overview'|'users'|'plans'|'referrals'|'earnings'|'feedback'|'features'|'maintenance'|'settings';
const tabs:{id:Tab;title:string;icon:typeof LayoutDashboard}[]=[
 {id:'overview',title:'Overview',icon:LayoutDashboard},{id:'users',title:'Users & roles',icon:Users},
 {id:'plans',title:'Storage plans',icon:CreditCard},{id:'referrals',title:'Referrals',icon:Activity},
 {id:'earnings',title:'Earnings',icon:Wallet},{id:'feedback',title:'Feedback & reports',icon:MessageSquareText},
 {id:'features',title:'Feature controls',icon:SlidersHorizontal},{id:'maintenance',title:'Maintenance',icon:CalendarClock},
 {id:'settings',title:'Operations',icon:Shield},
];
const usd=(n:number)=>(n/100).toLocaleString('en-US',{style:'currency',currency:'USD'});
const quota=(n:number)=>(n>=1024**4?Math.round(n/1024**4)+' TB':Math.round(n/1024**3)+' GB');
function Metric({title,value,detail}:{title:string;value:string|number;detail:string}){
 return <section className="rounded-2xl border border-[#e4e5d9] bg-white p-5"><p className="text-xs font-semibold uppercase tracking-widest text-[#677362]">{title}</p><p className="mt-4 text-3xl font-semibold tracking-tight text-[#171711]">{value}</p><p className="mt-2 text-xs text-[#677362]">{detail}</p></section>;
}
export default function AdminPage(){
 const [tab,setTab]=useState<Tab>('overview'),[data,setData]=useState<Data|null>(null);
 const [loading,setLoading]=useState(true),[error,setError]=useState(''),[notice,setNotice]=useState('');
 const [query,setQuery]=useState(''),[busy,setBusy]=useState<string|null>(null),[signedIn,setSignedIn]=useState<boolean|null>(null);
 const [deleteTarget,setDeleteTarget]=useState<UserRow|null>(null),[confirmEmail,setConfirmEmail]=useState(''),[deleteReason,setDeleteReason]=useState('');
 const getToken=async()=>{
  const {data:{session}}=await getSupabaseClient().auth.getSession();
  if(!session?.access_token)throw Error('Please sign in.');
  return session.access_token;
 };
 const load=useCallback(async()=>{
  setLoading(true);setError('');
  try{
   const token=await getToken();setSignedIn(true);
   const res=await fetch('/api/admin/dashboard',{headers:{Authorization:'Bearer '+token},cache:'no-store'});
   const body=await res.json() as Data&{error?:string};
   if(!res.ok)throw Error(body.error||'Could not load dashboard.');
   setData(body);
  }catch(e){
   const message=e instanceof Error?e.message:'Dashboard unavailable.';
   if(message.toLowerCase().includes('sign in'))setSignedIn(false);
   setError(message);setData(null);
  }finally{setLoading(false)}
 },[]);
 useEffect(()=>{void load()},[load]);
 const visible=useMemo(()=>data?.users.filter(u=>[u.email??'',u.id,u.role,u.referralCode??''].some(x=>x.toLowerCase().includes(query.toLowerCase())))??[],[data,query]);
 const change=async(user:UserRow,action:'role'|'affiliate_status',value:string)=>{
  if(!data?.scope.roles)return;
  if(!window.confirm('Change '+(action==='role'?'role':'referral status')+' for '+(user.email||user.id)+' to '+value+'? This changes production access.'))return;
  setBusy(user.id);setNotice('');setError('');
  try{
   const response=await fetch('/api/admin/dashboard',{method:'PATCH',headers:{Authorization:'Bearer '+await getToken(),'Content-Type':'application/json'},body:JSON.stringify({action,userId:user.id,[action==='role'?'role':'status']:value})});
   const result=await response.json() as {error?:string};
   if(!response.ok)throw Error(result.error||'Update failed.');
   setNotice('Account updated.');await load();
  }catch(e){setError(e instanceof Error?e.message:'Update failed.')}finally{setBusy(null)}
 };
 const deleteAccount=async()=>{
  if(!deleteTarget)return;
  setBusy(deleteTarget.id);setError('');
  try{
   const res=await fetch('/api/admin/users/'+deleteTarget.id,{method:'DELETE',headers:{Authorization:'Bearer '+await getToken(),'Content-Type':'application/json'},body:JSON.stringify({confirmEmail,reason:deleteReason})});
   const body=await res.json() as {error?:string};
   if(!res.ok)throw Error(body.error||'Could not delete account');
   setDeleteTarget(null);setConfirmEmail('');setDeleteReason('');
   setNotice('Account permanently deleted.');await load();
  }catch(e){setError(e instanceof Error?e.message:'Delete failed.')}finally{setBusy(null)}
 };
 const max=Math.max(...(data?.monthly.map(x=>x.newUsers)??[1]),1);
 return <main className="min-h-screen bg-[#f7f5ee] text-[#171711]"><div className="mx-auto flex min-h-screen max-w-[1600px] flex-col lg:flex-row">
  <aside className="border-b border-[#e4e5d9] bg-white px-5 py-6 lg:sticky lg:top-0 lg:h-screen lg:w-64 lg:shrink-0 lg:border-b-0 lg:border-r">
   <div className="flex items-center gap-3"><span className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e6edb0] font-black text-[#171711]">LB</span><div><p className="font-bold">LaterBox</p><p className="text-xs text-[#677362]">Control center</p></div></div>
   <p className="mb-3 mt-10 hidden text-[11px] font-semibold uppercase tracking-widest text-[#677362] lg:block">Workspace</p>
   <nav aria-label="Dashboard navigation" className="mt-5 flex gap-2 overflow-x-auto lg:mt-0 lg:flex-col">{tabs.map(item=>{const Icon=item.icon;return <button key={item.id} type="button" onClick={()=>setTab(item.id)} className={tab===item.id?'flex shrink-0 items-center gap-3 rounded-xl bg-[#e6edb0] px-4 py-3 text-left text-sm font-bold text-[#171711] lg:w-full':'flex shrink-0 items-center gap-3 rounded-xl px-4 py-3 text-left text-sm text-[#677362] hover:bg-[#f1f3e9] lg:w-full'}><Icon size={17}/>{item.title}</button>})}</nav>
   <div className="mt-10 rounded-2xl border border-[#e4e5d9] p-4"><p className="text-[11px] uppercase tracking-widest text-[#677362]">Access</p><p className="mt-2 text-sm font-semibold capitalize">{data?.role??'Restricted'}</p><a href="https://app.laterbox.dev/inbox" className="mt-3 inline-flex items-center gap-1 text-xs text-[#435b34]">Open LaterBox <ArrowUpRight size={13}/></a></div>
  </aside>
  <section className="min-w-0 flex-1 px-5 py-8 sm:px-9 lg:px-11">
   <header className="flex flex-wrap items-start justify-between gap-4 border-b border-[#e4e5d9] pb-7"><div><p className="text-xs uppercase tracking-widest text-[#677362]">Platform administration</p><h1 className="mt-2 text-3xl font-semibold tracking-tight sm:text-4xl">{tabs.find(t=>t.id===tab)?.title}</h1><p className="mt-2 text-sm text-[#677362]">Live, role-restricted LaterBox operations</p></div><button onClick={()=>void load()} disabled={loading} className="inline-flex items-center gap-2 rounded-xl border border-[#d9dece] px-4 py-2 text-sm hover:bg-[#f1f3e9]"><RefreshCcw size={15}/>Refresh</button></header>
   {notice&&<p role="status" className="mt-5 rounded-xl border border-[#718d63] bg-[#eff5e3] px-5 py-3 text-sm">{notice}</p>}
   {error&&<div role="alert" className="mt-6 rounded-2xl border border-amber-800/60 bg-[#fff2e8] p-5"><p className="font-semibold">Access or operation unavailable</p><p className="mt-2 text-sm text-[#945632]">{error}</p>{signedIn===false&&<a href="/login?next=%2Fadmin" className="mt-4 inline-block rounded-xl bg-[#e6edb0] px-5 py-3 text-sm font-bold text-[#161d13]">Sign in</a>}</div>}
   {loading&&<div className="mt-12 flex items-center gap-3 text-[#677362]"><Loader2 className="animate-spin"/>Loading secure dashboard…</div>}
   {!loading&&data&&<div className="mt-7 space-y-7">
    {tab==='overview'&&<>
     <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><Metric title="Registered users" value={data.totals.users} detail="Supabase identities"/><Metric title="Whop-connected" value={data.totals.advocates} detail="Verified Advocate accounts"/><Metric title="Active subscriptions" value={data.totals.activeSubscriptions} detail="Active and trialing"/><Metric title="Tracked referrals" value={data.totals.referrals} detail="Across all advocates"/></div>
     <div className="grid gap-5 xl:grid-cols-[1.5fr_1fr]"><section className="rounded-2xl border border-[#e4e5d9] bg-white p-6"><div className="flex items-center gap-2"><BarChart3 size={20} className="text-[#435b34]"/><h2 className="font-semibold">User acquisition</h2></div><p className="mt-1 text-xs text-[#677362]">New sign-ups by month</p><div className="mt-7 flex h-52 items-end gap-3">{data.monthly.map(m=><div key={m.month} className="flex h-full flex-1 flex-col items-center justify-end gap-3"><span className="text-xs text-[#677362]">{m.newUsers}</span><div className="w-full rounded-t-lg bg-[#c4d895]" style={{height:String(Math.max(m.newUsers/max*78,4))+'%'}}/><span className="text-[10px] text-[#677362]">{m.month.slice(5)}</span></div>)}</div></section>
      <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6"><h2 className="font-semibold">Subscription health</h2><div className="mt-6 space-y-4">{Object.entries(data.totals.subscriptionsByStatus).map(([name,n])=><div key={name} className="flex justify-between border-b border-[#e4e5d9] pb-3 text-sm"><span className="capitalize text-[#677362]">{name}</span><b>{n}</b></div>)}</div></section></div>
     <div className="grid gap-4 sm:grid-cols-3"><Metric title="Accrued commissions" value={usd(data.totals.totalCommissionCents)} detail="Not gross revenue"/><Metric title="Pending commissions" value={usd(data.totals.pendingCommissionCents)} detail="Subject to qualification"/><Metric title="Paid referrals" value={usd(data.totals.totalPaidCents)} detail="Recorded payout transfers"/></div>
    </>}
    {tab==='users'&&<section className="overflow-hidden rounded-2xl border border-[#e4e5d9] bg-white"><div className="flex flex-wrap justify-between gap-4 border-b border-[#e4e5d9] p-5"><div><h2 className="font-semibold">Accounts and permissions</h2><p className="mt-1 text-xs text-[#677362]">Whop roles are informational and do not grant admin access.</p></div><label className="flex items-center gap-2 rounded-xl border border-[#d9dece] px-3"><Search size={16}/><input aria-label="Search users" value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search users…" className="w-48 bg-transparent py-2 text-sm outline-none"/></label></div>
     <div className="overflow-x-auto"><table className="w-full min-w-[900px] text-left text-sm"><thead className="text-xs uppercase text-[#677362]"><tr>{['Account','LaterBox role','Whop role','Subscription','Referral','Management'].map(x=><th key={x} className="border-b border-[#e4e5d9] px-5 py-4">{x}</th>)}</tr></thead><tbody>{visible.map(u=><tr key={u.id} className="border-b border-white/5"><td className="px-5 py-4"><p className="font-semibold">{u.email??'No email'}</p><p className="mt-1 font-mono text-[10px] text-[#677362]">{u.id.slice(0,14)}…</p></td><td className="px-5 py-4 font-semibold capitalize">{u.role}</td><td className="px-5 py-4 text-[#677362]">{u.whopConnected?(u.whopTeamRole??'Connected · no team role'):'Not connected'}</td><td className="px-5 py-4 text-xs">{u.subscriptions.length?u.subscriptions.join(', '):'Free'}</td><td className="px-5 py-4 text-xs">{u.referralCode??'—'}</td><td className="px-5 py-4"><div className="flex flex-col items-start gap-2">{data.scope.roles&&u.role!=='owner'?<select aria-label={'Change role for '+u.email} value={['admin','analyst','support'].includes(u.role)?u.role:'member'} onChange={e=>void change(u,'role',e.target.value)} disabled={busy===u.id} className="rounded-lg border border-[#d2d9c8] bg-white px-3 py-2 text-xs"><option value="member">Member / Advocate</option><option value="support">Support</option><option value="analyst">Analyst</option><option value="admin">Admin</option></select>:<span className="text-xs text-[#677362]">{u.role==='owner'?'Protected owner':'Read only'}</span>}{data.scope.roles&&u.whopConnected&&u.role!=='owner'&&<button type="button" disabled={busy===u.id} onClick={()=>void change(u,'affiliate_status',u.affiliateStatus==='suspended'?'active':'suspended')} className="text-xs font-semibold text-[#677362] underline">{u.affiliateStatus==='suspended'?'Restore referrals':'Suspend referrals'}</button>}{data.scope.roles&&u.role!=='owner'&&<button type="button" disabled={busy===u.id} onClick={()=>{setDeleteTarget(u);setConfirmEmail('');setDeleteReason('')}} className="inline-flex items-center gap-1 text-xs font-semibold text-red-700 hover:underline"><Trash2 size={12}/> Delete account</button>}</div></td></tr>)}</tbody></table></div>
    </section>}
    {tab==='plans'&&<section className="rounded-2xl border border-[#e4e5d9] bg-white p-5"><div className="flex flex-wrap justify-between gap-4"><div><h2 className="font-semibold">Whop storage catalog</h2><p className="mt-1 text-xs text-[#677362]">Production SKU mapping and assigned storage. Edit prices in Whop to keep billing accurate.</p></div><a href="https://whop.com/dashboard/" target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 rounded-xl bg-[#e6edb0] px-4 py-2 text-sm font-semibold text-[#182013]">Manage pricing in Whop <ArrowUpRight size={15}/></a></div><div className="mt-6 grid gap-3 md:grid-cols-2 xl:grid-cols-3">{data.plans.map(p=><div key={p.provider_price_id} className="rounded-xl border border-[#e4e5d9] bg-[#f4f7ed] p-4"><p className="font-semibold">{p.sku_key.replaceAll('_',' ').toUpperCase()}</p><div className="mt-3 flex justify-between text-sm text-[#677362]"><span>{quota(p.quotaBytes)}</span><span>{p.trial_days?String(p.trial_days)+'-day trial':'Standard'}</span></div><p className="mt-3 truncate font-mono text-[10px] text-[#677362]">{p.provider_price_id}</p></div>)}</div></section>}
    {tab==='referrals'&&<><div className="grid gap-4 sm:grid-cols-3"><Metric title="Connected advocates" value={data.totals.advocates} detail="Whop OAuth confirmed"/><Metric title="Referrals" value={data.totals.referrals} detail="Tracked referral rows"/><Metric title="Program state" value={data.settings.enabled?'Enabled':'Paused'} detail="Separate from payouts"/></div><section className="rounded-2xl border border-[#e4e5d9] bg-white p-6"><h2 className="font-semibold">Referral controls</h2><p className="mt-3 text-sm text-[#677362]">Introductory rate: {data.settings.intro_commission_bps/100}% · Ongoing: {data.settings.ongoing_commission_bps/100}% · Hold: {data.settings.hold_days} days.</p><p className="mt-2 text-sm text-[#677362]">Free trial: {data.settings.trial_enabled?'Enabled':'Disabled'} · Automatic payouts: {data.settings.automatic_payouts?'Enabled':'Disabled'}.</p><p className="mt-4 text-xs text-[#677362]">Financial switches remain protected until verified production settlement testing is completed.</p></section></>}
    {tab==='earnings'&&<><div className="grid gap-4 md:grid-cols-3"><Metric title="Total commissions" value={usd(data.totals.totalCommissionCents)} detail={String(data.earnings.commissions)+' ledger entries'}/><Metric title="Pending" value={usd(data.totals.pendingCommissionCents)} detail="Awaiting qualification"/><Metric title="Paid transfers" value={usd(data.totals.totalPaidCents)} detail={String(data.earnings.payouts)+' recorded payouts'}/></div><section className="rounded-2xl border border-[#e4e5d9] bg-white p-6"><h2 className="font-semibold">Commission lifecycle</h2><div className="mt-4 space-y-3">{Object.entries(data.earnings.byStatus).map(([status,n])=><div key={status} className="flex justify-between border-b border-[#e4e5d9] pb-2 text-sm"><span className="capitalize text-[#677362]">{status}</span>{n}</div>)}</div><p className="mt-5 text-xs text-[#677362]">Whop-derived referral ledger totals, not gross subscription revenue.</p></section></>}
    {(tab==='feedback'||tab==='features'||tab==='maintenance')&&<AdminOperationsPanel view={tab}/>}
    {tab==='settings'&&<section className="rounded-2xl border border-[#e4e5d9] bg-white p-6"><div className="flex items-center gap-2"><LockKeyhole size={19} className="text-[#435b34]"/><h2 className="font-semibold">Operations and safeguards</h2></div><div className="mt-6 space-y-4 text-sm text-[#677362]"><p>Effective role: <strong className="capitalize text-[#171711]">{data.role}</strong></p><p>Role changes: {data.scope.roles?'Owner only — enabled':'Read only'}</p><p>Whop business role lookup: {data.whopRoleAvailable?'Available':'Unavailable or missing Whop permission'}</p><p>Financial operations: <strong className="text-[#171711]">No automatic payout enablement from this dashboard.</strong></p><p>For Whop team role visibility, grant <code>company:authorized_user:read</code> and <code>member:email:read</code> to the company API key.</p><p>Production: server-side role checks, RLS-protected database, and Owner protection.</p></div></section>}
   </div>}
  </section>
 </div>
 {deleteTarget&&<div role="dialog" aria-modal="true" aria-labelledby="delete-account-title" className="fixed inset-0 z-[100] flex items-center justify-center bg-[#171711]/45 p-4">
  <div className="w-full max-w-md rounded-3xl bg-white p-7 shadow-2xl">
   <h2 id="delete-account-title" className="text-xl font-bold text-[#171711]">Permanently delete account?</h2>
   <p className="mt-3 text-sm leading-6 text-[#636a60]">This deletes the user and their LaterBox data, including attachments, using the existing account deletion workflow. This cannot be undone.</p>
   <p className="mt-3 text-sm font-semibold">{deleteTarget.email}</p>
   <label className="mt-5 block text-xs font-semibold">Type the full account email<input value={confirmEmail} onChange={e=>setConfirmEmail(e.target.value)} className="mt-2 w-full rounded-xl border border-[#d6dcc9] px-3 py-2 text-sm" placeholder="Exact account email"/></label>
   <label className="mt-4 block text-xs font-semibold">Reason (minimum 10 characters)<textarea value={deleteReason} onChange={e=>setDeleteReason(e.target.value)} rows={3} className="mt-2 w-full rounded-xl border border-[#d6dcc9] px-3 py-2 text-sm" placeholder="Document why the account is being deleted"/></label>
   <div className="mt-5 flex justify-end gap-3"><button type="button" className="rounded-xl border border-[#d6dcc9] px-5 py-2.5 text-sm" onClick={()=>setDeleteTarget(null)}>Cancel</button><button type="button" onClick={()=>void deleteAccount()} disabled={busy===deleteTarget.id||confirmEmail.toLowerCase().trim()!==deleteTarget.email?.toLowerCase()||deleteReason.trim().length<10} className="rounded-xl bg-red-700 px-5 py-2.5 text-sm font-bold text-white disabled:opacity-40">Permanently delete</button></div>
  </div>
 </div>}
 </main>;
}
