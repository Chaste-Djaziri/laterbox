// laterbox-web/src/app/admin/page.tsx
'use client';
import {useCallback,useEffect,useMemo,useState} from 'react';
import {getSupabaseClient} from '@/lib/supabase/client';
import {Activity,ArrowUpRight,BarChart3,CreditCard,LayoutDashboard,Loader2,LockKeyhole,RefreshCcw,Search,Shield,Users,Wallet} from 'lucide-react';

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
type Tab='overview'|'users'|'plans'|'referrals'|'earnings'|'settings';
const tabs:{id:Tab;title:string;icon:typeof LayoutDashboard}[]=[
 {id:'overview',title:'Overview',icon:LayoutDashboard},{id:'users',title:'Users & roles',icon:Users},
 {id:'plans',title:'Storage plans',icon:CreditCard},{id:'referrals',title:'Referrals',icon:Activity},
 {id:'earnings',title:'Earnings',icon:Wallet},{id:'settings',title:'Operations',icon:Shield},
];
const usd=(n:number)=>(n/100).toLocaleString('en-US',{style:'currency',currency:'USD'});
const quota=(n:number)=>(n>=1024**4?Math.round(n/1024**4)+' TB':Math.round(n/1024**3)+' GB');
function Metric({title,value,detail}:{title:string;value:string|number;detail:string}){
 return <section className="rounded-2xl border border-white/10 bg-[#1c231b] p-5"><p className="text-xs font-semibold uppercase tracking-widest text-[#a7b39f]">{title}</p><p className="mt-4 text-3xl font-semibold tracking-tight text-white">{value}</p><p className="mt-2 text-xs text-[#899783]">{detail}</p></section>;
}
export default function AdminPage(){
 const [tab,setTab]=useState<Tab>('overview'),[data,setData]=useState<Data|null>(null);
 const [loading,setLoading]=useState(true),[error,setError]=useState(''),[notice,setNotice]=useState('');
 const [query,setQuery]=useState(''),[busy,setBusy]=useState<string|null>(null),[signedIn,setSignedIn]=useState<boolean|null>(null);
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
 const max=Math.max(...(data?.monthly.map(x=>x.newUsers)??[1]),1);
 return <main className="min-h-screen bg-[#10140f] text-[#f6f8f0]"><div className="mx-auto flex min-h-screen max-w-[1600px] flex-col lg:flex-row">
  <aside className="border-b border-white/10 bg-[#171d16] px-5 py-6 lg:sticky lg:top-0 lg:h-screen lg:w-64 lg:shrink-0 lg:border-b-0 lg:border-r">
   <div className="flex items-center gap-3"><span className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e6edb0] font-black text-[#171711]">LB</span><div><p className="font-bold">LaterBox</p><p className="text-xs text-[#9ba795]">Control center</p></div></div>
   <p className="mb-3 mt-10 hidden text-[11px] font-semibold uppercase tracking-widest text-[#778473] lg:block">Workspace</p>
   <nav aria-label="Dashboard navigation" className="mt-5 flex gap-2 overflow-x-auto lg:mt-0 lg:flex-col">{tabs.map(item=>{const Icon=item.icon;return <button key={item.id} type="button" onClick={()=>setTab(item.id)} className={tab===item.id?'flex shrink-0 items-center gap-3 rounded-xl bg-[#e6edb0] px-4 py-3 text-left text-sm font-bold text-[#171711] lg:w-full':'flex shrink-0 items-center gap-3 rounded-xl px-4 py-3 text-left text-sm text-[#b5c0af] hover:bg-white/10 lg:w-full'}><Icon size={17}/>{item.title}</button>})}</nav>
   <div className="mt-10 rounded-2xl border border-white/10 p-4"><p className="text-[11px] uppercase tracking-widest text-[#879484]">Access</p><p className="mt-2 text-sm font-semibold capitalize">{data?.role??'Restricted'}</p><a href="https://app.laterbox.dev/inbox" className="mt-3 inline-flex items-center gap-1 text-xs text-[#e6edb0]">Open LaterBox <ArrowUpRight size={13}/></a></div>
  </aside>
  <section className="min-w-0 flex-1 px-5 py-8 sm:px-9 lg:px-11">
   <header className="flex flex-wrap items-start justify-between gap-4 border-b border-white/10 pb-7"><div><p className="text-xs uppercase tracking-widest text-[#b4bfab]">Platform administration</p><h1 className="mt-2 text-3xl font-semibold tracking-tight sm:text-4xl">{tabs.find(t=>t.id===tab)?.title}</h1><p className="mt-2 text-sm text-[#9fac99]">Live, role-restricted LaterBox operations</p></div><button onClick={()=>void load()} disabled={loading} className="inline-flex items-center gap-2 rounded-xl border border-white/15 px-4 py-2 text-sm hover:bg-white/10"><RefreshCcw size={15}/>Refresh</button></header>
   {notice&&<p role="status" className="mt-5 rounded-xl border border-[#718d63] bg-[#243222] px-5 py-3 text-sm">{notice}</p>}
   {error&&<div role="alert" className="mt-6 rounded-2xl border border-amber-800/60 bg-[#34251c] p-5"><p className="font-semibold">Access or operation unavailable</p><p className="mt-2 text-sm text-[#e7c9ad]">{error}</p>{signedIn===false&&<a href="/login?next=%2Fadmin" className="mt-4 inline-block rounded-xl bg-[#e6edb0] px-5 py-3 text-sm font-bold text-[#161d13]">Sign in</a>}</div>}
   {loading&&<div className="mt-12 flex items-center gap-3 text-[#adbba7]"><Loader2 className="animate-spin"/>Loading secure dashboard…</div>}
   {!loading&&data&&<div className="mt-7 space-y-7">
    {tab==='overview'&&<>
     <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><Metric title="Registered users" value={data.totals.users} detail="Supabase identities"/><Metric title="Whop-connected" value={data.totals.advocates} detail="Verified Advocate accounts"/><Metric title="Active subscriptions" value={data.totals.activeSubscriptions} detail="Active and trialing"/><Metric title="Tracked referrals" value={data.totals.referrals} detail="Across all advocates"/></div>
     <div className="grid gap-5 xl:grid-cols-[1.5fr_1fr]"><section className="rounded-2xl border border-white/10 bg-[#1c231b] p-6"><div className="flex items-center gap-2"><BarChart3 size={20} className="text-[#e6edb0]"/><h2 className="font-semibold">User acquisition</h2></div><p className="mt-1 text-xs text-[#a4b19e]">New sign-ups by month</p><div className="mt-7 flex h-52 items-end gap-3">{data.monthly.map(m=><div key={m.month} className="flex h-full flex-1 flex-col items-center justify-end gap-3"><span className="text-xs text-[#cfd8c8]">{m.newUsers}</span><div className="w-full rounded-t-lg bg-[#d8e7a5]" style={{height:String(Math.max(m.newUsers/max*78,4))+'%'}}/><span className="text-[10px] text-[#aab6a3]">{m.month.slice(5)}</span></div>)}</div></section>
      <section className="rounded-2xl border border-white/10 bg-[#1c231b] p-6"><h2 className="font-semibold">Subscription health</h2><div className="mt-6 space-y-4">{Object.entries(data.totals.subscriptionsByStatus).map(([name,n])=><div key={name} className="flex justify-between border-b border-white/10 pb-3 text-sm"><span className="capitalize text-[#a4b19e]">{name}</span><b>{n}</b></div>)}</div></section></div>
     <div className="grid gap-4 sm:grid-cols-3"><Metric title="Accrued commissions" value={usd(data.totals.totalCommissionCents)} detail="Not gross revenue"/><Metric title="Pending commissions" value={usd(data.totals.pendingCommissionCents)} detail="Subject to qualification"/><Metric title="Paid referrals" value={usd(data.totals.totalPaidCents)} detail="Recorded payout transfers"/></div>
    </>}
    {tab==='users'&&<section className="overflow-hidden rounded-2xl border border-white/10 bg-[#1c231b]"><div className="flex flex-wrap justify-between gap-4 border-b border-white/10 p-5"><div><h2 className="font-semibold">Accounts and permissions</h2><p className="mt-1 text-xs text-[#98a594]">Whop roles are informational and do not grant admin access.</p></div><label className="flex items-center gap-2 rounded-xl border border-white/15 px-3"><Search size={16}/><input aria-label="Search users" value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search users…" className="w-48 bg-transparent py-2 text-sm outline-none"/></label></div>
     <div className="overflow-x-auto"><table className="w-full min-w-[900px] text-left text-sm"><thead className="text-xs uppercase text-[#a2b09c]"><tr>{['Account','LaterBox role','Whop role','Subscription','Referral','Management'].map(x=><th key={x} className="border-b border-white/10 px-5 py-4">{x}</th>)}</tr></thead><tbody>{visible.map(u=><tr key={u.id} className="border-b border-white/5"><td className="px-5 py-4"><p className="font-semibold">{u.email??'No email'}</p><p className="mt-1 font-mono text-[10px] text-[#879484]">{u.id.slice(0,14)}…</p></td><td className="px-5 py-4 font-semibold capitalize">{u.role}</td><td className="px-5 py-4 text-[#c6d3be]">{u.whopConnected?(u.whopTeamRole??'Connected · no team role'):'Not connected'}</td><td className="px-5 py-4 text-xs">{u.subscriptions.length?u.subscriptions.join(', '):'Free'}</td><td className="px-5 py-4 text-xs">{u.referralCode??'—'}</td><td className="px-5 py-4"><div className="flex flex-col items-start gap-2">{data.scope.roles&&u.role!=='owner'?<select aria-label={'Change role for '+u.email} value={['admin','analyst','support'].includes(u.role)?u.role:'member'} onChange={e=>void change(u,'role',e.target.value)} disabled={busy===u.id} className="rounded-lg border border-white/20 bg-[#272e25] px-3 py-2 text-xs"><option value="member">Member / Advocate</option><option value="support">Support</option><option value="analyst">Analyst</option><option value="admin">Admin</option></select>:<span className="text-xs text-[#8d9a88]">{u.role==='owner'?'Protected owner':'Read only'}</span>}{data.scope.roles&&u.whopConnected&&u.role!=='owner'&&<button type="button" disabled={busy===u.id} onClick={()=>void change(u,'affiliate_status',u.affiliateStatus==='suspended'?'active':'suspended')} className="text-xs font-semibold text-[#dce9bc] underline">{u.affiliateStatus==='suspended'?'Restore referrals':'Suspend referrals'}</button>}</div></td></tr>)}</tbody></table></div>
    </section>}
    {tab==='plans'&&<section className="rounded-2xl border border-white/10 bg-[#1c231b] p-5"><div className="flex flex-wrap justify-between gap-4"><div><h2 className="font-semibold">Whop storage catalog</h2><p className="mt-1 text-xs text-[#acb8a6]">Production SKU mapping and assigned storage. Edit prices in Whop to keep billing accurate.</p></div><a href="https://whop.com/dashboard/" target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 rounded-xl bg-[#e6edb0] px-4 py-2 text-sm font-semibold text-[#182013]">Manage pricing in Whop <ArrowUpRight size={15}/></a></div><div className="mt-6 grid gap-3 md:grid-cols-2 xl:grid-cols-3">{data.plans.map(p=><div key={p.provider_price_id} className="rounded-xl border border-white/10 bg-[#262e24] p-4"><p className="font-semibold">{p.sku_key.replaceAll('_',' ').toUpperCase()}</p><div className="mt-3 flex justify-between text-sm text-[#c4d4bc]"><span>{quota(p.quotaBytes)}</span><span>{p.trial_days?String(p.trial_days)+'-day trial':'Standard'}</span></div><p className="mt-3 truncate font-mono text-[10px] text-[#83917e]">{p.provider_price_id}</p></div>)}</div></section>}
    {tab==='referrals'&&<><div className="grid gap-4 sm:grid-cols-3"><Metric title="Connected advocates" value={data.totals.advocates} detail="Whop OAuth confirmed"/><Metric title="Referrals" value={data.totals.referrals} detail="Tracked referral rows"/><Metric title="Program state" value={data.settings.enabled?'Enabled':'Paused'} detail="Separate from payouts"/></div><section className="rounded-2xl border border-white/10 bg-[#1c231b] p-6"><h2 className="font-semibold">Referral controls</h2><p className="mt-3 text-sm text-[#abb9a4]">Introductory rate: {data.settings.intro_commission_bps/100}% · Ongoing: {data.settings.ongoing_commission_bps/100}% · Hold: {data.settings.hold_days} days.</p><p className="mt-2 text-sm text-[#abb9a4]">Free trial: {data.settings.trial_enabled?'Enabled':'Disabled'} · Automatic payouts: {data.settings.automatic_payouts?'Enabled':'Disabled'}.</p><p className="mt-4 text-xs text-[#85917f]">Financial switches remain protected until verified production settlement testing is completed.</p></section></>}
    {tab==='earnings'&&<><div className="grid gap-4 md:grid-cols-3"><Metric title="Total commissions" value={usd(data.totals.totalCommissionCents)} detail={String(data.earnings.commissions)+' ledger entries'}/><Metric title="Pending" value={usd(data.totals.pendingCommissionCents)} detail="Awaiting qualification"/><Metric title="Paid transfers" value={usd(data.totals.totalPaidCents)} detail={String(data.earnings.payouts)+' recorded payouts'}/></div><section className="rounded-2xl border border-white/10 bg-[#1c231b] p-6"><h2 className="font-semibold">Commission lifecycle</h2><div className="mt-4 space-y-3">{Object.entries(data.earnings.byStatus).map(([status,n])=><div key={status} className="flex justify-between border-b border-white/10 pb-2 text-sm"><span className="capitalize text-[#afbaa9]">{status}</span>{n}</div>)}</div><p className="mt-5 text-xs text-[#8e9b87]">Whop-derived referral ledger totals, not gross subscription revenue.</p></section></>}
    {tab==='settings'&&<section className="rounded-2xl border border-white/10 bg-[#1c231b] p-6"><div className="flex items-center gap-2"><LockKeyhole size={19} className="text-[#e6edb0]"/><h2 className="font-semibold">Operations and safeguards</h2></div><div className="mt-6 space-y-4 text-sm text-[#b5c3b0]"><p>Effective role: <strong className="capitalize text-white">{data.role}</strong></p><p>Role changes: {data.scope.roles?'Owner only — enabled':'Read only'}</p><p>Whop business role lookup: {data.whopRoleAvailable?'Available':'Unavailable or missing Whop permission'}</p><p>Financial operations: <strong className="text-white">No automatic payout enablement from this dashboard.</strong></p><p>For Whop team role visibility, grant <code>company:authorized_user:read</code> and <code>member:email:read</code> to the company API key.</p><p>Production: server-side role checks, RLS-protected database, and Owner protection.</p></div></section>}
   </div>}
  </section>
 </div></main>;
}
