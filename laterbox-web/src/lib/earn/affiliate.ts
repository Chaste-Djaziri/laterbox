// laterbox-web/src/lib/earn/affiliate.ts
// The authoritative program state lives in Supabase; clients never set rates,
// earnings, subscriber age or payout status.
import { randomBytes } from 'node:crypto';
import { getBillingAdminClient } from '@/lib/billing/server';
import { subscriptionHasAccess } from '@/lib/billing/eligibility';
import { storagePlanForWhopId } from '@/lib/billing/whop';

export type EarnPlan = 'free' | 'plus' | 'vault';
export type EarnRole = 'plus_partner' | 'vault_ambassador';
export interface EarnState {
  programEnabled: boolean;
  payoutsEnabled: boolean;
  eligible: boolean;
  eligibleAt: string | null;
  plan: EarnPlan;
  role: EarnRole | null;
  rateBps: number | null;
  memberSince: string | null;
  status: 'locked' | 'eligible' | 'active' | 'suspended' | 'not_launched';
  referralCode: string | null;
  referralUrl: string | null;
  payoutConnected: boolean;
  balances: { pendingCents: number; availableCents: number; processingCents: number; paidCents: number; reversedCents: number };
  referrals: number;
  commissions: { id: string; amountCents: number; status: string; createdAt: string; holdUntil: string }[];
  payouts: { id: string; amountCents: number; status: string; createdAt: string; paidAt: string | null }[];
}

export type EarnSettings = {
  enabled: boolean;
  automatic_payouts: boolean;
  plus_commission_bps: number;
  vault_commission_bps: number;
  hold_days: number;
  minimum_payout_cents: number;
};

type Subscription = {
  provider: string;
  subscription_id: string;
  status: string;
  created_at: string;
  updated_at: string;
  current_period_ends_at: string | null;
  revoked_at: string | null;
  past_due_at: string | null;
  storage_plan: string | null;
  price_id: string | null;
  trial_ends_at?: string | null;
};

export async function earnSettings(): Promise<EarnSettings> {
  const { data, error } = await getBillingAdminClient().from('affiliate_program_settings')
    .select('enabled,automatic_payouts,plus_commission_bps,vault_commission_bps,hold_days,minimum_payout_cents')
    .eq('id', true).single();
  if (error || !data) throw new Error('Earn database migration has not been applied.');
  return {
    ...(data as EarnSettings),
    // Prevent enabling the public program if webhook receipt tracking is off.
    enabled: Boolean(data.enabled && process.env.EARN_TRACKING_ENABLED === 'true'),
  };
}

function plusTwoMonths(value: string): string {
  const date = new Date(value);
  // Anchor to the month and preserve local day capped at the target month end.
  const day = date.getUTCDate();
  date.setUTCDate(1);
  date.setUTCMonth(date.getUTCMonth() + 2);
  const last = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 0)).getUTCDate();
  date.setUTCDate(Math.min(day, last));
  return date.toISOString();
}

export async function earnEligibility(userId: string) {
  const db = getBillingAdminClient();
  const { data: subscriptions, error } = await db.from('billing_subscriptions')
    .select('provider,subscription_id,status,created_at,updated_at,current_period_ends_at,revoked_at,past_due_at,storage_plan,price_id,trial_ends_at')
    .eq('user_id', userId).order('created_at', { ascending: true });
  if (error) throw error;
  const now = Date.now();
  const active = ((subscriptions ?? []) as Subscription[])
    .filter(row => row.status === 'active' && subscriptionHasAccess(row, now) && !row.revoked_at);
  const chosen = [...active].sort((a,b) => (
    (b.storage_plan === 'vault' ? 2 : 1) - (a.storage_plan === 'vault' ? 2 : 1)
  ))[0] ?? null;
  const plan: EarnPlan = chosen?.storage_plan === 'vault' ? 'vault' : chosen ? 'plus' : 'free';
  const role: EarnRole | null = plan === 'vault' ? 'vault_ambassador' : plan === 'plus' ? 'plus_partner' : null;
  if (!chosen) return { eligible: false, eligibleAt: null, plan, role, memberSince: null };
  const dates = active.filter(row => row.storage_plan === chosen.storage_plan).map(row => row.created_at);
  const oldest = dates.sort()[0] ?? chosen.created_at;
  const eligibleAt = plusTwoMonths(oldest);
  const matured = now >= Date.parse(eligibleAt);
  // Whop monthly plans require at least two distinct, server-confirmed paid
  // billing periods; an annual plan requires one charge and two elapsed months.
  let receiptsVerified = true;
  if (chosen.provider === 'whop') {
    const { data: receipts, error: paidError } = await db.from('affiliate_paid_receipts')
      .select('paid_at,membership_id').eq('buyer_user_id', userId).is('refunded_at',null).order('paid_at', { ascending:true });
    if (paidError && !['42P01','PGRST204','PGRST205'].includes(paidError.code ?? '')) throw paidError;
    // Before migration or historical receipt backfill, assume unverified.
    // Never grant affiliate eligibility based on an unverified billing claim.
    const verifiedReceipts = paidError ? [] : (receipts ?? []);
    const membershipId = chosen.subscription_id;
    const matching = verifiedReceipts.filter(r => !membershipId || r.membership_id === membershipId);
    const isAnnual = Boolean(chosen.price_id && storagePlanForWhopId(chosen.price_id)?.endsWith('_year'));
    receiptsVerified = isAnnual ? matching.length >= 1 :
      matching.some((receipt,i) => matching.some((later,j) => j !== i &&
        Math.abs(Date.parse(later.paid_at) - Date.parse(receipt.paid_at)) >= 25 * 86400000));
  }
  return { eligible: matured && receiptsVerified, eligibleAt, plan, role, memberSince: oldest,
    awaitingReceipts: matured && !receiptsVerified };
}

export async function getEarnState(userId: string): Promise<EarnState & { awaitingReceipts?: boolean; termsUrl: string }> {
  const db = getBillingAdminClient();
  const eligibility = await earnEligibility(userId);
  let settings: EarnSettings;
  try {
    settings = await earnSettings();
  } catch (error) {
    // A new deployment can serve the Earn tab before the opt-in migration.
    // Display the correct locked launch state, never hypothetical earnings.
    if (error instanceof Error && error.message.includes('Earn database migration')) {
      return {
        programEnabled:false,payoutsEnabled:false,eligible:eligibility.eligible,
        eligibleAt:eligibility.eligibleAt,plan:eligibility.plan,role:eligibility.role,
        rateBps:null,memberSince:eligibility.memberSince,status:'not_launched',
        referralCode:null,referralUrl:null,payoutConnected:false,
        balances:{pendingCents:0,availableCents:0,processingCents:0,paidCents:0,reversedCents:0},
        referrals:0,commissions:[],payouts:[],awaitingReceipts:eligibility.awaitingReceipts,
        termsUrl:'/earn-terms',
      };
    }
    throw error;
  }
  const { data: profile, error: profileError } = await db.from('affiliate_profiles')
    .select('user_id,referral_code,status,role,commission_bps,verified_whop_user_id')
    .eq('user_id',userId).maybeSingle();
  if (profileError) throw profileError;
  const { data: commissions, error: cError } = await db.from('affiliate_commissions')
    .select('id,commission_cents,status,created_at,hold_until')
    .eq('affiliate_user_id',userId).order('created_at',{ ascending:false }).limit(100);
  if (cError) throw cError;
  const { data: payouts, error: pError } = await db.from('affiliate_payouts')
    .select('id,amount_cents,status,created_at,paid_at')
    .eq('affiliate_user_id',userId).order('created_at',{ ascending:false }).limit(50);
  if (pError) throw pError;
  const { count: referrals, error: rError } = await db.from('affiliate_referrals')
    .select('id',{ count:'exact',head:true }).eq('affiliate_user_id',userId);
  if (rError) throw rError;
  const {data:balanceRows,error:totalsError}=await db.rpc('affiliate_balance_totals',{
    target_user_id:userId,
  });
  if(totalsError)throw totalsError;
  const totals=Array.isArray(balanceRows)?balanceRows[0]:balanceRows;
  const balances = {
    pendingCents: Number(totals?.pending_cents ?? 0),
    availableCents: Number(totals?.available_cents ?? 0),
    processingCents: Number(totals?.processing_cents ?? 0),
    paidCents: Number(totals?.paid_cents ?? 0),
    reversedCents: Number(totals?.reversed_cents ?? 0),
  };
  const status = !settings.enabled ? 'not_launched' : profile?.status === 'suspended' ? 'suspended'
    : profile?.status === 'active' && eligibility.eligible ? 'active'
    : eligibility.eligible ? 'eligible' : 'locked';
  return {
    programEnabled: settings.enabled,
    payoutsEnabled: settings.automatic_payouts,
    eligible: eligibility.eligible,
    eligibleAt: eligibility.eligibleAt,
    plan: eligibility.plan,
    role: eligibility.role ?? profile?.role ?? null,
    rateBps: settings.enabled ? (
      eligibility.plan === 'vault' ? settings.vault_commission_bps :
      eligibility.plan === 'plus' ? settings.plus_commission_bps : null
    ) : null,
    memberSince: eligibility.memberSince,
    status,
    referralCode: status === 'active' ? profile?.referral_code ?? null : null,
    referralUrl: status === 'active'
      ? `https://laterbox.dev/r/${profile?.referral_code ?? ''}` : null,
    payoutConnected: Boolean(profile?.verified_whop_user_id),
    balances,
    referrals: referrals ?? 0,
    commissions: (commissions ?? []).map(c => ({
      id:c.id, amountCents:c.commission_cents, status:c.status,
      createdAt:c.created_at, holdUntil:c.hold_until,
    })),
    payouts: (payouts ?? []).map(p => ({
      id:p.id, amountCents:p.amount_cents, status:p.status,
      createdAt:p.created_at,paidAt:p.paid_at,
    })),
    awaitingReceipts: eligibility.awaitingReceipts,
    termsUrl:'/earn-terms',
  };
}

export async function enrollAffiliate(userId: string): Promise<'created'|'existing'|'unavailable'> {
  const [settings, eligibility] = await Promise.all([earnSettings(), earnEligibility(userId)]);
  if (!settings.enabled) return 'unavailable';
  if (!eligibility.eligible || !eligibility.role) return 'unavailable';
  const db = getBillingAdminClient();
  const { data: existing, error } = await db.from('affiliate_profiles')
    .select('user_id').eq('user_id',userId).maybeSingle();
  if(error)throw error;
  if(existing) return 'existing';
  const commission_bps = eligibility.plan === 'vault' ? settings.vault_commission_bps : settings.plus_commission_bps;
  const { error: createError } = await db.from('affiliate_profiles').insert({
    user_id:userId, referral_code: 'lb_' + randomBytes(12).toString('hex'),
    role:eligibility.role,commission_bps,age_confirmed_at:new Date().toISOString(),
  });
  if(createError) {
    if(createError.code === '23505') return 'existing';
    throw createError;
  }
  return 'created';
}

export function parseUsdCents(value: unknown): number | null {
  const info = value && typeof value === 'object' ? value as Record<string,unknown> : {};
  if(info.currency !== 'usd' || info.decimals !== 2 ||
    typeof info.amount !== 'string' || !/^[0-9]{1,9}([.][0-9]{1,2})?$/.test(info.amount)) return null;
  const [whole,fraction=''] = info.amount.split('.');
  const cents = Number(whole) * 100 + Number(fraction.padEnd(2,'0'));
  return Number.isSafeInteger(cents) && cents > 0 ? cents : null;
}
