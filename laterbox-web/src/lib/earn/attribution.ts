// laterbox-web/src/lib/earn/attribution.ts
// Verified Whop payments only; no customer-controlled monetary amounts.
import {getBillingAdminClient} from '@/lib/billing/server';
import {earnSettings,earnedAfterQualification,parseUsdCents} from './affiliate';
import {storagePlanForWhopId} from '@/lib/billing/whop';

const isValidPayment=(id:unknown):id is string=>
  typeof id==='string' && /^pay_[a-zA-Z0-9_-]+$/.test(id);
const isReversed=(p:Record<string,unknown>)=>Boolean(p.refunded_at || p.auto_refunded===true
  || p.dispute_created_at || parseUsdCents(p.refunded_amount)!==null);

export async function recordVerifiedWhopPayment(
  payment:Record<string,unknown>,buyerId:string,membershipId:string,
  affiliateUserId:string|null,
):Promise<void> {
  const id=payment.id;
  if(!isValidPayment(id)||payment.substatus!=='succeeded')return;
  if(isReversed(payment))return;
  const paidAt=typeof payment.paid_at==='string'&&Number.isFinite(Date.parse(payment.paid_at))
    ? payment.paid_at : new Date().toISOString();
  const netCents=parseUsdCents(payment.amount_after_fees);
  const db=getBillingAdminClient();
  const {error:receiptError}=await db.from('affiliate_paid_receipts').upsert({
    whop_payment_id:id,buyer_user_id:buyerId,membership_id:membershipId,
    paid_at:paidAt,amount_cents:netCents??0,
  },{onConflict:'whop_payment_id',ignoreDuplicates:true});
  if(receiptError)throw receiptError;

  // The claim is bound to the account and the Whop membership during checkout,
  // never to an arbitrary referral id sent by the client or webhook.
  const {data:claim,error:claimError}=await db.from('affiliate_trial_claims')
    .select('buyer_user_id,affiliate_user_id,membership_id,status,started_at,trial_ends_at,qualified_at,plan_key,created_at')
    .eq('buyer_user_id',buyerId).maybeSingle();
  if(claimError)throw claimError;
  if(!claim || claim.status==='expired'||claim.affiliate_user_id===buyerId)return;
  if(claim.membership_id!==membershipId||!claim.started_at||!claim.trial_ends_at)return;
  if(affiliateUserId && affiliateUserId!==claim.affiliate_user_id)return;
  const settings=await earnSettings();
  if(!settings.enabled)return;
  const {data:affiliate,error:affiliateError}=await db.from('affiliate_profiles')
    .select('user_id,status,age_confirmed_at')
    .eq('user_id',claim.affiliate_user_id).maybeSingle();
  if(affiliateError)throw affiliateError;
  // A unique code is given to everyone; legal-age attestation and Whop
  // payout verification are still required before any money moves.
  if(affiliate?.status!=='active'||!netCents)return;
  const {data:receipts,error:historyError}=await db.from('affiliate_paid_receipts')
    .select('paid_at').eq('buyer_user_id',buyerId).eq('membership_id',membershipId)
    .is('refunded_at',null).order('paid_at',{ascending:true});
  if(historyError)throw historyError;
  const annual=claim.plan_key.endsWith('_year');
  const eligible=earnedAfterQualification({
    startedAt:claim.started_at,trialEndsAt:claim.trial_ends_at,
    payments:(receipts??[]).map(row=>row.paid_at),
    paidAt,annual,
  });
  if(!eligible)return;

  const {data:existingReferral,error:existingError}=await db.from('affiliate_referrals')
    .select('id,affiliate_user_id,membership_id')
    .eq('buyer_user_id',buyerId).maybeSingle();
  if(existingError)throw existingError;
  let referral=existingReferral;
  if(!referral) {
    const {data:created,error}=await db.from('affiliate_referrals').upsert({
      affiliate_user_id:claim.affiliate_user_id,buyer_user_id:buyerId,
      membership_id:membershipId,first_payment_id:id,
      referred_at:claim.created_at??claim.started_at,
      trial_end_at:claim.trial_ends_at,qualified_at:new Date().toISOString(),
    },{onConflict:'buyer_user_id',ignoreDuplicates:true})
      .select('id,affiliate_user_id,membership_id').maybeSingle();
    if(error)throw error;
    referral=created;
    if(!referral) {
      const {data,error:reloadError}=await db.from('affiliate_referrals')
        .select('id,affiliate_user_id,membership_id').eq('buyer_user_id',buyerId).maybeSingle();
      if(reloadError)throw reloadError;
      referral=data;
    }
  }
  if(!referral||referral.affiliate_user_id!==claim.affiliate_user_id||
    referral.membership_id!==membershipId)return;
  if(claim.status!=='qualified') {
    const {error}=await db.from('affiliate_trial_claims').update({
      status:'qualified',qualified_at:new Date().toISOString(),
    }).eq('buyer_user_id',buyerId).eq('membership_id',membershipId);
    if(error)throw error;
  }
  const {data:prior,error:priorError}=await db.from('affiliate_commissions')
    .select('id').eq('referral_id',referral.id);
  if(priorError)throw priorError;
  const {data:existingCommission,error:commissionReadError}=await db.from('affiliate_commissions')
    .select('id').eq('payment_id',id).maybeSingle();
  if(commissionReadError)throw commissionReadError;
  if(existingCommission)return;

  const previousPayments=prior?.length??0;
  const bps=previousPayments<settings.intro_payment_count ?
    settings.intro_commission_bps:settings.ongoing_commission_bps;
  const amount=Math.floor(netCents*bps/10000);
  if(amount<1)return;
  const {error}=await db.from('affiliate_commissions').upsert({
    referral_id:referral.id,affiliate_user_id:claim.affiliate_user_id,
    payment_id:id,membership_id:membershipId,billing_cycle:previousPayments+1,
    net_amount_cents:netCents,commission_cents:amount,commission_bps:bps,
    hold_until:new Date(Date.parse(paidAt)+settings.hold_days*86400000).toISOString(),
    status:'pending',
  },{onConflict:'payment_id',ignoreDuplicates:true});
  if(error)throw error;
}

// Refunds and chargebacks revoke not-yet-paid commissions. Already-transferred
// losses require an explicit manual clawback, never an automatic negative
// transfer that could debit someone's external wallet unexpectedly.
export async function reverseRefundedCommission(payment:Record<string,unknown>):Promise<void> {
  if(!isValidPayment(payment.id)||!isReversed(payment))return;
  await reversePaymentId(payment.id);
}
export async function reversePaymentId(id:string):Promise<void> {
  if(!isValidPayment(id))return;
  const db=getBillingAdminClient();
  const {error:r}=await db.from('affiliate_paid_receipts')
    .update({refunded_at:new Date().toISOString()}).eq('whop_payment_id',id);
  if(r)throw r;
  const {error:c}=await db.from('affiliate_commissions').update({status:'reversed'})
    .eq('payment_id',id).in('status',['pending','available']);
  if(c)throw c;
}
