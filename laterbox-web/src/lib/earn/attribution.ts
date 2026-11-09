// laterbox-web/src/lib/earn/attribution.ts
import { getBillingAdminClient } from '@/lib/billing/server';
import { earnSettings, earnEligibility, parseUsdCents } from './affiliate';

// Called only after retrieving and verifying a real paid Whop payment server-side.
export async function recordVerifiedWhopPayment(
  payment: Record<string, unknown>,
  buyerId: string,
  membershipId: string,
  affiliateUserId: string | null
) {
  const db = getBillingAdminClient();
  const id = payment.id;
  if(typeof id!=='string'||!/^pay_[A-Za-z0-9_-]+$/.test(id)||payment.substatus!=='succeeded')return;
  // Out-of-order refund/dispute events must not re-award a commission or count
  // a refunded billing period toward the two-month paid-tenure rule.
  if(payment.auto_refunded === true || payment.refunded_at || payment.dispute_created_at ||
     parseUsdCents(payment.refunded_amount)!==null)return;
  const paidAt = typeof payment.paid_at==='string' && Number.isFinite(Date.parse(payment.paid_at))
    ? payment.paid_at : new Date().toISOString();
  const netCents = parseUsdCents(payment.amount_after_fees);
  const {error:receiptError} = await db.from('affiliate_paid_receipts').upsert({
    whop_payment_id:id,buyer_user_id:buyerId,membership_id:membershipId,
    paid_at:paidAt, amount_cents:netCents ?? 0,
  },{onConflict:'whop_payment_id',ignoreDuplicates:true});
  if(receiptError)throw receiptError;
  // Only initial, server-bound checkouts can create a commission. Renewals are
  // recorded for tenure but cannot re-attribute the buyer or earn twice.
  if(!affiliateUserId || !netCents || payment.billing_reason!=='subscription_create') return;
  const settings=await earnSettings();
  if(!settings.enabled)return;
  const {data:profile,error:profileError}=await db.from('affiliate_profiles')
    .select('user_id,status,commission_bps').eq('user_id',affiliateUserId).maybeSingle();
  if(profileError)throw profileError;
  if(!profile || profile.status!=='active'||affiliateUserId===buyerId)return;
  const eligibility=await earnEligibility(affiliateUserId);
  if(!eligibility.eligible || !eligibility.role)return;
  const currentBps=eligibility.plan==='vault' ? settings.vault_commission_bps : settings.plus_commission_bps;

  const {data:referral,error:referralError}=await db.from('affiliate_referrals')
    .upsert({
      affiliate_user_id:affiliateUserId,buyer_user_id:buyerId,first_payment_id:id
    },{onConflict:'buyer_user_id',ignoreDuplicates:true})
    .select('id,affiliate_user_id,first_payment_id').maybeSingle();
  if(referralError)throw referralError;
  let confirmed=referral;
  if(!confirmed) {
    const {data,error}=await db.from('affiliate_referrals')
      .select('id,affiliate_user_id,first_payment_id').eq('buyer_user_id',buyerId).maybeSingle();
    if(error)throw error;
    confirmed=data;
  }
  if(!confirmed||confirmed.first_payment_id!==id||confirmed.affiliate_user_id!==affiliateUserId)return;
  const commissionCents=Math.floor(netCents * currentBps/10000);
  if(commissionCents<1)return;
  const holdUntil=new Date(Date.parse(paidAt)+settings.hold_days*86400000).toISOString();
  const {error}=await db.from('affiliate_commissions').upsert({
    referral_id:confirmed.id,affiliate_user_id:affiliateUserId,payment_id:id,
    net_amount_cents:netCents,commission_cents:commissionCents,commission_bps:currentBps,
    hold_until:holdUntil,status:'pending'
  },{onConflict:'payment_id',ignoreDuplicates:true});
  if(error)throw error;
}

export async function reverseRefundedCommission(payment: Record<string,unknown>) {
  if(typeof payment.id!=='string')return;
  const refunded=payment.refunded_at!==null&&payment.refunded_at!==undefined;
  const refundedCents=parseUsdCents(payment.refunded_amount);
  if(!refunded && (!refundedCents || refundedCents<=0) && payment.auto_refunded !== true && !payment.dispute_created_at)return;
  const {error:receiptError}=await getBillingAdminClient().from('affiliate_paid_receipts')
    .update({refunded_at:new Date().toISOString()}).eq('whop_payment_id',payment.id);
  if(receiptError)throw receiptError;
  const {error}=await getBillingAdminClient().from('affiliate_commissions')
    .update({status:'reversed'})
    .eq('payment_id',payment.id).in('status',['pending','available']);
  if(error)throw error;
}
