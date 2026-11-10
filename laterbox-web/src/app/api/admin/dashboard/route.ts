// laterbox-web/src/app/api/admin/dashboard/route.ts
// Every read and mutation is authorized on the server against platform_roles.
import {NextResponse} from 'next/server';
import {getBillingAdminClient} from '@/lib/billing/server';
import {authorizeAdmin} from '@/lib/admin/platform-roles';
import {fetchWhopTeamRoles} from '@/lib/admin/whop-team';
export const dynamic='force-dynamic';
const noStore={'Cache-Control':'private, no-store'};
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function GET(request:Request){
 let auth:Awaited<ReturnType<typeof authorizeAdmin>>;
 try{auth=await authorizeAdmin(request);}catch(e){console.error('[admin] authorization error',e);return NextResponse.json({error:'Dashboard is unavailable.'},{status:503});}
 if('error'in auth)return NextResponse.json({error:auth.error},{status:auth.status});
 try{
  const db=getBillingAdminClient();
  const [userResponse,staff,affiliates,subscriptions,skus,commissions,payouts,referrals,settings,team]=await Promise.all([
    db.auth.admin.listUsers({page:1,perPage:1000}),
    db.from('platform_roles').select('user_id,role,granted_at'),
    db.from('affiliate_profiles').select('user_id,referral_code,verified_whop_user_id,status,age_confirmed_at,commission_bps,created_at'),
    db.from('billing_subscriptions').select('user_id,provider,status,storage_plan,price_id,created_at,current_period_ends_at'),
    db.from('billing_storage_skus').select('provider_price_id,sku_key,family,quota_bytes,trial_days'),
    db.from('affiliate_commissions').select('commission_cents,status,currency,created_at'),
    db.from('affiliate_payouts').select('amount_cents,status,currency,created_at'),
    db.from('affiliate_referrals').select('id,affiliate_user_id,created_at'),
    db.from('affiliate_program_settings').select('enabled,automatic_payouts,trial_enabled,trial_days,intro_commission_bps,ongoing_commission_bps,hold_days,minimum_payout_cents').eq('id',true).single(),
    fetchWhopTeamRoles(),
  ]);
  const error=userResponse.error||staff.error||affiliates.error||subscriptions.error||skus.error||commissions.error||payouts.error||referrals.error||settings.error;
  if(error)throw error;
  const staffById=new Map((staff.data??[]).map(r=>[r.user_id,r.role]));
  const affiliatesById=new Map((affiliates.data??[]).map(r=>[r.user_id,r]));
  const subscriptionMap=new Map<string,string[]>();
  for(const sub of subscriptions.data??[]){
   if(!sub.user_id)continue;
   const prev=subscriptionMap.get(sub.user_id)??[];
   prev.push(sub.status);
   subscriptionMap.set(sub.user_id,prev);
  }
  const users=(userResponse.data?.users??[]).map(u=>{
   const a=affiliatesById.get(u.id);
   const staffRole=staffById.get(u.id)??null;
   return {
    id:u.id,email:u.email??null,createdAt:u.created_at,
    role:staffRole??(a?.verified_whop_user_id?'advocate':'member'),
    whopConnected:Boolean(a?.verified_whop_user_id),
    whopTeamRole:a?.verified_whop_user_id?team.get(a.verified_whop_user_id)??null:null,
    referralCode:a?.verified_whop_user_id?a.referral_code:null,
    affiliateStatus:a?.status??null,
    subscriptions:subscriptionMap.get(u.id)??[],
   };
  });
  const counts=(rows:{status:string}[])=>Object.fromEntries([...new Set(rows.map(r=>r.status))].map(key=>[key,rows.filter(r=>r.status===key).length]));
  const commissionsData=commissions.data??[];
  const payoutsData=payouts.data??[];
  const totals={
   users:users.length,advocates:users.filter(u=>u.whopConnected).length,
   activeSubscriptions:(subscriptions.data??[]).filter(x=>['active','trialing'].includes(x.status)).length,
   subscriptionsByStatus:counts(subscriptions.data??[]),
   referrals:(referrals.data??[]).length,
   pendingCommissionCents:commissionsData.filter(x=>x.status==='pending').reduce((sum,x)=>sum+Number(x.commission_cents),0),
   totalCommissionCents:commissionsData.reduce((sum,x)=>sum+Number(x.commission_cents),0),
   totalPaidCents:payoutsData.filter(x=>x.status==='paid').reduce((sum,x)=>sum+Number(x.amount_cents),0),
   payoutCount:payoutsData.length,
  };
  const monthly=Array.from({length:6},(_,i)=>{
   const d=new Date();d.setUTCDate(1);d.setUTCMonth(d.getUTCMonth()-(5-i));
   const label=d.toISOString().slice(0,7);
   return {month:label,newUsers:users.filter(u=>u.createdAt?.startsWith(label)).length,
    commissionsCents:commissionsData.filter(c=>c.created_at?.startsWith(label)).reduce((sum,c)=>sum+Number(c.commission_cents),0)};
  });
  return NextResponse.json({
   role:auth.roles.role,users,totals,monthly,
   plans:(skus.data??[]).map(p=>({...p,quotaBytes:Number(p.quota_bytes)})),
   settings:settings.data,
   earnings:{commissions:commissionsData.length,payouts:payoutsData.length,byStatus:counts(commissionsData)},
   scope:{read:true,manage:['owner','admin'].includes(auth.roles.role),roles:auth.roles.role==='owner'},
   whopRoleAvailable:team.size>0,
   note:'Revenue is not inferred from commissions; edit live prices using Whop until payment-ledger reconciliation is enabled.',
  },{headers:noStore});
 }catch(e){console.error('[admin] dashboard failed',e);return NextResponse.json({error:'Could not load dashboard data.'},{status:503});}
}

export async function PATCH(request:Request){
 let auth:Awaited<ReturnType<typeof authorizeAdmin>>;
 try{auth=await authorizeAdmin(request,'owner');}catch{return NextResponse.json({error:'Authorization unavailable.'},{status:503});}
 if('error'in auth)return NextResponse.json({error:auth.error},{status:auth.status});
 let body:{action?:unknown;userId?:unknown;role?:unknown;status?:unknown};
 try{body=await request.json();}catch{return NextResponse.json({error:'Invalid request body.'},{status:400});}
 const db=getBillingAdminClient();
 if(body.action==='role'){
  const target=body.userId;
  const role=body.role;
  if(typeof target!=='string'||!uuid.test(target)||typeof role!=='string'||!['member','support','analyst','admin'].includes(role))
   return NextResponse.json({error:'Invalid role assignment.'},{status:400});
  if(target===auth.user.id)return NextResponse.json({error:'You cannot change your own Owner role.'},{status:403});
  const {data:existing,error:readError}=await db.from('platform_roles').select('role').eq('user_id',target).maybeSingle();
  if(readError)return NextResponse.json({error:'Could not inspect current role.'},{status:503});
  if(existing?.role==='owner')return NextResponse.json({error:'Owner roles must be managed through a verified recovery process.'},{status:403});
  const {data:targetUser,error:targetError}=await db.auth.admin.getUserById(target);
  if(targetError||!targetUser.user)return NextResponse.json({error:'User not found.'},{status:404});
  const op=role==='member'
   ?await db.from('platform_roles').delete().eq('user_id',target)
   :await db.from('platform_roles').upsert({user_id:target,role,granted_by:auth.user.id,updated_at:new Date().toISOString()},{onConflict:'user_id'});
  if(op.error)return NextResponse.json({error:'Unable to save role.'},{status:503});
  const {error:auditError}=await db.from('platform_role_audit').insert({actor_user_id:auth.user.id,target_user_id:target,previous_role:existing?.role??null,next_role:role==='member'?null:role});
  if(auditError)console.error('[admin] audit write failed',auditError.code);
  return NextResponse.json({updated:true,role},{headers:noStore});
 }
 if(body.action==='affiliate_status'){
  if(typeof body.userId!=='string'||!uuid.test(body.userId)||!['active','suspended'].includes(String(body.status)))
   return NextResponse.json({error:'Invalid affiliate status.'},{status:400});
  if(body.userId===auth.user.id)return NextResponse.json({error:'Cannot suspend your own owner account.'},{status:403});
  const {error}=await db.from('affiliate_profiles').update({status:body.status}).eq('user_id',body.userId);
  if(error)return NextResponse.json({error:'Unable to update referral status.'},{status:503});
  return NextResponse.json({updated:true},{headers:noStore});
 }
 return NextResponse.json({error:'Unsupported admin operation.'},{status:400});
}
