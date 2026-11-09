// laterbox-web/src/lib/earn/affiliate.ts
// All monetary amounts and attribution are calculated server-side from Whop.
// Every account has a code, even if its subscription is Free.
import { getBillingAdminClient } from '@/lib/billing/server';

export type EarnPlan = 'free' | 'plus' | 'vault';
export type EarnRole = 'community_referrer';
export interface EarnState {
  programEnabled: boolean;
  payoutsEnabled: boolean;
  trialEnabled: boolean;
  trialDays: number;
  eligible: boolean;
  eligibleAt: string | null;
  plan: EarnPlan;
  role: EarnRole | null;
  rateBps: number | null;
  memberSince: string | null;
  status: 'active' | 'suspended' | 'not_launched' | 'eligible' | 'locked';
  referralCode: string | null;
  referralUrl: string | null;
  payoutConnected: boolean;
  balances: { pendingCents: number; availableCents: number; processingCents: number; paidCents: number; reversedCents: number };
  referrals: number;
  referredProgress: { id:string; plan: string; status:string; referredAt:string;
    trialEndsAt:string|null; qualifiedAt:string|null; nextStep:string }[];
  commissions: { id: string; amountCents: number; status: string; createdAt: string; holdUntil: string }[];
  payouts: { id: string; amountCents: number; status: string; createdAt: string; paidAt: string | null }[];
}
export type EarnSettings = {
  enabled: boolean;
  automatic_payouts: boolean;
  trial_enabled: boolean;
  trial_days: number;
  intro_commission_bps: number;
  ongoing_commission_bps: number;
  intro_payment_count: number;
  plus_commission_bps: number;
  vault_commission_bps: number;
  hold_days: number;
  minimum_payout_cents: number;
};

export function normalizeReferralCode(value: unknown): string | null {
  if(typeof value!=='string')return null;
  const code=value.trim().toLowerCase();
  return /^[a-z0-9][a-z0-9_-]{3,31}$/.test(code) ? code : null;
}
const reserved=new Set([
  'laterbox','whop','admin','api','app','account','support','help',
  'login','signup','register','settings','billing','checkout','earn',
  'trial','free','premium','plus','vault','official','staff','team',
  'security','privacy','terms','system','payments','refund','root','www',
]);
export function referralCodeAllowed(input: unknown): boolean {
  const code=normalizeReferralCode(input);
  return Boolean(code && !reserved.has(code) && !code.startsWith('laterbox_'));
}
export function addMonthsUTC(iso:string,count:number): string {
  const date=new Date(iso);
  if(!Number.isFinite(date.getTime()))throw new Error('Invalid subscription date');
  const day=date.getUTCDate();
  date.setUTCDate(1);
  date.setUTCMonth(date.getUTCMonth()+count);
  const days=new Date(Date.UTC(date.getUTCFullYear(),date.getUTCMonth()+1,0)).getUTCDate();
  date.setUTCDate(Math.min(day,days));
  return date.toISOString();
}
export function earnedAfterQualification(args: {
  startedAt:string; trialEndsAt:string; payments:string[]; paidAt:string; annual:boolean;
}): boolean {
  const started=Date.parse(args.startedAt);
  const trialEnd=Date.parse(args.trialEndsAt);
  const paid=Date.parse(args.paidAt);
  if(!Number.isFinite(started)||!Number.isFinite(trialEnd)||!Number.isFinite(paid))return false;
  // The trial takes 30 days; eligibility requires another two calendar months
  // of paid membership AND three calendar months since trial activation.
  const at=Math.max(Date.parse(addMonthsUTC(args.startedAt,3)),
    Date.parse(addMonthsUTC(args.trialEndsAt,2)));
  if(paid<at)return false;
  const valid=[...new Set(args.payments)]
    .map(t=>Date.parse(t)).filter(t=>Number.isFinite(t)&&t>=trialEnd&&t<=paid).sort((a,b)=>a-b);
  if(args.annual)return valid.length>=1 && valid[0]+2*28*86400000<=paid;
  return valid.some((first,i)=>valid.some((second,j)=>j>i && second-first>=25*86400000));
}
export async function earnSettings():Promise<EarnSettings> {
  const {data,error}=await getBillingAdminClient().from('affiliate_program_settings')
    .select('enabled,automatic_payouts,trial_enabled,trial_days,intro_commission_bps,ongoing_commission_bps,intro_payment_count,plus_commission_bps,vault_commission_bps,hold_days,minimum_payout_cents')
    .eq('id',true).single();
  if(error||!data)throw new Error('Earn database migration has not been applied.');
  return {
    ...(data as EarnSettings),
    enabled:Boolean(data.enabled&&process.env.EARN_TRACKING_ENABLED==='true'),
    trial_enabled:Boolean(data.trial_enabled&&data.enabled&&process.env.EARN_TRACKING_ENABLED==='true'),
    // No recipient transfers until a separate production operations approval.
    automatic_payouts:Boolean(data.automatic_payouts&&data.enabled&&process.env.EARN_TRACKING_ENABLED==='true'),
  };
}
export async function ensureEarnProfile(userId:string) {
  const db=getBillingAdminClient();
  const {error}=await db.rpc('ensure_laterbox_referral',{target_user:userId});
  if(error)throw error;
  const {data,error:readError}=await db.from('affiliate_profiles')
    .select('user_id,referral_code,status,verified_whop_user_id,age_confirmed_at,code_changed_at')
    .eq('user_id',userId).single();
  if(readError||!data)throw readError??new Error('Referral code unavailable');
  return data;
}
export async function lookupReferral(input:unknown, buyerUserId?:string) {
  const code=normalizeReferralCode(input);
  if(!code)return null;
  const {data,error}=await getBillingAdminClient().from('affiliate_profiles')
    .select('user_id,referral_code,status').eq('referral_code',code).maybeSingle();
  if(error)throw error;
  if(!data||data.status!=='active'||data.user_id===buyerUserId)return null;
  return data;
}
export async function customizeReferralCode(userId:string,input:unknown) {
  const code=normalizeReferralCode(input);
  if(!code||!referralCodeAllowed(code))
    return {error:'Use 4–32 lowercase letters, numbers, hyphens or underscores. Reserved names are unavailable.',status:400};
  const db=getBillingAdminClient();
  const profile=await ensureEarnProfile(userId);
  if(profile.referral_code===code)return {code,status:200};
  if(profile.code_changed_at && Date.now()-Date.parse(profile.code_changed_at)<30*86400000)
    return {error:'You can change your referral code once every 30 days.',status:429};
  const {data:duplicate,error:duplicateError}=await db.from('affiliate_profiles')
    .select('user_id').eq('referral_code',code).maybeSingle();
  if(duplicateError)throw duplicateError;
  if(duplicate)return {error:'That referral code is already taken.',status:409};
  const now=new Date().toISOString();
  const {data,error}=await db.from('affiliate_profiles')
    .update({referral_code:code,code_changed_at:now})
    .eq('user_id',userId).eq('referral_code',profile.referral_code)
    .select('referral_code').maybeSingle();
  if(error?.code==='23505')return {error:'That referral code is already taken.',status:409};
  if(error)throw error;
  if(!data)return {error:'Referral code changed elsewhere. Refresh and retry.',status:409};
  return {code:data.referral_code,status:200};
}
// Registration is open to every signed-in adult account, including Free.
export async function enrollAffiliate(userId:string):Promise<'created'|'existing'|'unavailable'> {
  const settings=await earnSettings();
  if(!settings.enabled)return 'unavailable';
  const db=getBillingAdminClient();
  const profile=await ensureEarnProfile(userId);
  if(profile.status==='suspended')return 'unavailable';
  if(profile.age_confirmed_at)return 'existing';
  const {error}=await db.from('affiliate_profiles').update({
    age_confirmed_at:new Date().toISOString(),
  }).eq('user_id',userId).eq('status','active');
  if(error)throw error;
  return 'created';
}

export async function getEarnState(userId:string):Promise<EarnState> {
  const db=getBillingAdminClient();
  // A migration-free release can still render the Coming Soon state safely.
  const empty={
    pendingCents:0,availableCents:0,processingCents:0,paidCents:0,reversedCents:0,
  };
  let settings:EarnSettings;
  try{settings=await earnSettings();}
  catch{
    return {programEnabled:false,payoutsEnabled:false,trialEnabled:false,trialDays:30,
      eligible:true,eligibleAt:null,plan:'free',role:'community_referrer',rateBps:null,
      memberSince:null,status:'not_launched',referralCode:null,referralUrl:null,
      payoutConnected:false,balances:empty,referrals:0,referredProgress:[],commissions:[],payouts:[]};
  }
  const profile=await ensureEarnProfile(userId);
  const {data:subscriptions,error:subsError}=await db.from('billing_subscriptions')
    .select('storage_plan,created_at,status').eq('user_id',userId).order('created_at',{ascending:true});
  if(subsError)throw subsError;
  const active=(subscriptions??[]).filter(s=>['active','trialing'].includes(s.status));
  const plan:EarnPlan=active.some(s=>s.storage_plan==='vault')?'vault':active.some(s=>s.storage_plan==='plus')?'plus':'free';
  const {data:commissions,error:cError}=await db.from('affiliate_commissions')
    .select('id,commission_cents,status,created_at,hold_until')
    .eq('affiliate_user_id',userId).order('created_at',{ascending:false}).limit(100);
  if(cError)throw cError;
  const {data:payouts,error:pError}=await db.from('affiliate_payouts')
    .select('id,amount_cents,status,created_at,paid_at')
    .eq('affiliate_user_id',userId).order('created_at',{ascending:false}).limit(50);
  if(pError)throw pError;
  const {data:claims,error:rError}=await db.from('affiliate_trial_claims')
    .select('buyer_user_id,plan_key,status,created_at,trial_ends_at,qualified_at')
    .eq('affiliate_user_id',userId).order('created_at',{ascending:false}).limit(100);
  if(rError)throw rError;
  const {data:balances,error:totalsError}=await db.rpc('affiliate_balance_totals',{target_user_id:userId});
  if(totalsError)throw totalsError;
  const totals=Array.isArray(balances)?balances[0]:balances;
  const status:EarnState['status']=!settings.enabled?'not_launched':profile.status==='suspended'?'suspended':profile.age_confirmed_at?'active':'eligible';
  const code=profile.referral_code as string;
  return {
    programEnabled:settings.enabled,payoutsEnabled:settings.automatic_payouts,
    trialEnabled:settings.trial_enabled,trialDays:settings.trial_days,
    eligible:true,eligibleAt:null,plan,role:'community_referrer',
    rateBps:settings.intro_commission_bps,memberSince:active[0]?.created_at??null,status,
    referralCode:code,referralUrl:`https://laterbox.dev/r/${code}`,
    payoutConnected:Boolean(profile.verified_whop_user_id),
    balances:{
      pendingCents:Number(totals?.pending_cents??0),availableCents:Number(totals?.available_cents??0),
      processingCents:Number(totals?.processing_cents??0),paidCents:Number(totals?.paid_cents??0),
      reversedCents:Number(totals?.reversed_cents??0),
    },referrals:claims?.length??0,
    referredProgress:(claims??[]).map(row=>({
      id:row.buyer_user_id,plan:row.plan_key,status:row.status,
      referredAt:row.created_at,trialEndsAt:row.trial_ends_at,
      qualifiedAt:row.qualified_at,
      nextStep:row.status==='qualified'?'Commissionable renewals':row.status==='trialing'?'Paid qualification':'Awaiting checkout',
    })),
    commissions:(commissions??[]).map(c=>({id:c.id,amountCents:c.commission_cents,status:c.status,
      createdAt:c.created_at,holdUntil:c.hold_until})),
    payouts:(payouts??[]).map(p=>({id:p.id,amountCents:p.amount_cents,status:p.status,
      createdAt:p.created_at,paidAt:p.paid_at})),
  };
}
export function parseUsdCents(value:unknown):number|null {
  const o=value&&typeof value==='object'?value as Record<string,unknown>:{};
  if(o.currency!=='usd'||o.decimals!==2||typeof o.amount!=='string'||
    !/^[0-9]{1,9}([.][0-9]{1,2})?$/.test(o.amount))return null;
  const [major,minor='']=o.amount.split('.');
  const cents=Number(major)*100+Number(minor.padEnd(2,'0'));
  return Number.isSafeInteger(cents)&&cents>0?cents:null;
}
