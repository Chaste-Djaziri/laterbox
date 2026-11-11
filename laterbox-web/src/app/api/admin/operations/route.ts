// laterbox-web/src/app/api/admin/operations/route.ts
import {NextResponse} from 'next/server';
import {authorizeAdmin} from '@/lib/admin/platform-roles';
import {getBillingAdminClient} from '@/lib/billing/server';
import {readOperations,featureKeys,maintenanceState} from '@/lib/platform/operations';
export const dynamic='force-dynamic';
const headers={'Cache-Control':'private, no-store'};
type Input={action?:unknown;feature?:unknown;enabled?:unknown;mode?:unknown;startsAt?:unknown;endsAt?:unknown;message?:unknown;ticketId?:unknown;status?:unknown};
const isIso=(v:unknown)=>typeof v==='string'&&v.length<=40&&!Number.isNaN(Date.parse(v));

export async function GET(request:Request){
 let auth:Awaited<ReturnType<typeof authorizeAdmin>>;
 try{auth=await authorizeAdmin(request);}catch{return NextResponse.json({error:'Authorization unavailable.'},{status:503})}
 if('error'in auth)return NextResponse.json({error:auth.error},{status:auth.status});
 try{
  const db=getBillingAdminClient();
  const [ops,tickets,ledger]=await Promise.all([
   readOperations(),
   db.from('support_requests').select('id,user_id,email,category,subject,message,platform,app_version,status,created_at').order('created_at',{ascending:false}).limit(300),
   db.from('platform_operations_audit').select('id,actor_id,action,target,created_at').order('created_at',{ascending:false}).limit(60),
  ]);
  if(tickets.error||ledger.error)throw tickets.error??ledger.error;
  return NextResponse.json({operations:ops,maintenanceState:maintenanceState(ops),tickets:tickets.data??[],audit:ledger.data??[],canManage:auth.roles.staffRole==='owner'||auth.roles.staffRole==='admin',isOwner:auth.roles.staffRole==='owner'},{headers});
 }catch(error){console.error('[operations] read failed',error);return NextResponse.json({error:'Operations could not be loaded.'},{status:503})}
}
export async function PATCH(request:Request){
 let body:Input;
 try{body=await request.json()}catch{return NextResponse.json({error:'Invalid request.'},{status:400})}
 const requiredRole = body.action === 'ticket' ? 'manage' : 'owner';
 let auth:Awaited<ReturnType<typeof authorizeAdmin>>;
 try{auth=await authorizeAdmin(request,requiredRole);}catch{return NextResponse.json({error:'Authorization unavailable.'},{status:503})}
 if('error'in auth)return NextResponse.json({error:auth.error},{status:auth.status});
 const db=getBillingAdminClient();
 try{
  if(body.action==='feature'){
   if(typeof body.feature!=='string'||!featureKeys.includes(body.feature as (typeof featureKeys)[number])||typeof body.enabled!=='boolean')
    return NextResponse.json({error:'Invalid feature switch.'},{status:400});
   const before=await readOperations();
   const features={...before.features,[body.feature]:body.enabled};
   // The database and the application kill switch must both permit referral enrollment.
   // Automatic payouts remain disabled and cannot be changed here.
   const {error}=await db.from('platform_operations').update({features,updated_at:new Date().toISOString(),updated_by:auth.user.id}).eq('id',true);
   if(error)throw error;
   if(body.feature==='referrals'){
    const {error:earnError}=await db.from('affiliate_program_settings').update({enabled:body.enabled,automatic_payouts:false,updated_at:new Date().toISOString()}).eq('id',true);
    if(earnError){
     await db.from('platform_operations').update({features:before.features}).eq('id',true);
     throw earnError;
    }
   }
   await db.from('platform_operations_audit').insert({actor_id:auth.user.id,action:'feature',target:body.feature,previous:{enabled:before.features[body.feature as keyof typeof before.features]},next:{enabled:body.enabled}});
   return NextResponse.json({updated:true,operations:await readOperations()},{headers});
  }
  if(body.action==='maintenance'){
   if(!['off','scheduled','active'].includes(String(body.mode)))return NextResponse.json({error:'Invalid maintenance mode.'},{status:400});
   const mode=body.mode as 'off'|'scheduled'|'active';
   const start=mode==='off'?null:body.startsAt;
   const end=mode==='off'?null:body.endsAt;
   if(mode==='scheduled'&&!isIso(start))return NextResponse.json({error:'Scheduled maintenance requires a valid start time.'},{status:400});
   if(start!==null&&start!==undefined&&!isIso(start))return NextResponse.json({error:'Invalid start time.'},{status:400});
   if(end!==null&&end!==undefined&&!isIso(end))return NextResponse.json({error:'Invalid end time.'},{status:400});
   const beginning=start?Date.parse(start as string):Date.now();
   if(end && Date.parse(end as string)<=beginning)return NextResponse.json({error:'End time must be after start time.'},{status:400});
   if(mode==='scheduled'&&beginning<Date.now()-60000)return NextResponse.json({error:'Choose a future start time.'},{status:400});
   if(mode!=='off'&&!end)return NextResponse.json({error:'Set an end time so maintenance cannot continue indefinitely.'},{status:400});
   const message=typeof body.message==='string'?body.message.trim():'';
   if(message.length<10||message.length>500)return NextResponse.json({error:'Message must contain 10–500 characters.'},{status:400});
   const before=await readOperations();
   const next={maintenance_mode:mode,maintenance_starts_at:start||null,maintenance_ends_at:end||null,maintenance_message:message,updated_at:new Date().toISOString(),updated_by:auth.user.id};
   const {error}=await db.from('platform_operations').update(next).eq('id',true);
   if(error)throw error;
   await db.from('platform_operations_audit').insert({actor_id:auth.user.id,action:'maintenance',target:mode,previous:{mode:before.maintenanceMode,start:before.maintenanceStartsAt,end:before.maintenanceEndsAt},next});
   return NextResponse.json({updated:true,operations:await readOperations()},{headers});
  }
  if(body.action==='ticket'){
   if(typeof body.ticketId!=='string'||!/^[0-9a-f-]{36}$/i.test(body.ticketId)||!['open','in_progress','resolved'].includes(String(body.status)))
    return NextResponse.json({error:'Invalid support request update.'},{status:400});
   const {data:current,error:readError}=await db.from('support_requests').select('id,status').eq('id',body.ticketId).maybeSingle();
   if(readError||!current)return NextResponse.json({error:'Ticket not found.'},{status:404});
   const {error}=await db.from('support_requests').update({status:body.status}).eq('id',body.ticketId);
   if(error)throw error;
   await db.from('platform_operations_audit').insert({actor_id:auth.user.id,action:'support_ticket',target:body.ticketId,previous:{status:current.status},next:{status:body.status}});
   return NextResponse.json({updated:true},{headers});
  }
  return NextResponse.json({error:'Unsupported action.'},{status:400});
 }catch(error){console.error('[operations] mutation failed',error);return NextResponse.json({error:'Could not save the operation.'},{status:503})}
}
