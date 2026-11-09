// laterbox-web/src/app/api/billing/checkout/route.ts
import {NextResponse} from 'next/server';
import {subscriptionHasAccess} from '@/lib/billing/eligibility';
import {getBillingAdminClient,getRequestUser} from '@/lib/billing/server';
import {earnSettings,lookupReferral} from '@/lib/earn/affiliate';
import {parseWhopPlan,whopEnvironment,whopPlanId,whopReferralTrialPlanId,whopServer} from '@/lib/billing/whop';
export const dynamic='force-dynamic';

/** All prices and referral decisions are server-owned. Browser provides only SKU and code. */
export async function POST(request:Request) {
  const user=await getRequestUser(request);
  if(!user?.id||!user.email) {
    return NextResponse.json({error:'Sign in to purchase a storage plan.'},{status:401});
  }
  let key;
  let requestedReferral:unknown;
  try {
    const input=await request.json() as {plan?:unknown;referralCode?:unknown};
    key=parseWhopPlan(input.plan);
    requestedReferral=input.referralCode;
  } catch {
    return NextResponse.json({error:'Invalid checkout request.'},{status:400});
  }
  if(!key)return NextResponse.json({error:'Choose a valid storage plan.'},{status:400});
  try {
    const admin=getBillingAdminClient();
    const {data:subscriptions,error}=await admin.from('billing_subscriptions')
      .select('provider,status,current_period_ends_at,past_due_at,updated_at,revoked_at')
      .eq('user_id',user.id);
    if(error)throw error;
    const active=(subscriptions??[]).find(row=>subscriptionHasAccess(row));
    if(active)return NextResponse.json({
      error:'You already have an active subscription. Manage it before buying a second plan.',
      code:'subscription_already_active',
    },{status:409});

    let planId=whopPlanId(key);
    let affiliateUserId:string|null=null;
    let trialApplied=false;
    const cookieCode=request.headers.get('cookie')?.split(';').map(x=>x.trim())
      .find(x=>x.startsWith('laterbox_ref='))?.slice('laterbox_ref='.length);
    const code=typeof requestedReferral==='string'&&requestedReferral.trim()
      ? requestedReferral.trim():cookieCode;
    if((subscriptions??[]).length===0&&code) {
      try {
        const settings=await earnSettings();
        if(settings.enabled&&settings.trial_enabled) {
          const affiliate=await lookupReferral(code,user.id);
          if(affiliate) {
            const {count,error:claimError}=await admin.from('affiliate_trial_claims')
              .select('buyer_user_id',{head:true,count:'exact'}).eq('buyer_user_id',user.id);
            if(claimError)throw claimError;
            if((count??0)===0) {
              planId=whopReferralTrialPlanId(key);
              affiliateUserId=affiliate.user_id;
              trialApplied=true;
            }
          }
        }
      }catch(error) {
        // A misconfigured promotion must never break ordinary subscriptions.
        console.warn('[earn] trial offer unavailable',error instanceof Error?error.message:'unknown');
      }
    }

    const {data:pending,error:pendingError}=await admin.from('billing_checkout_intents')
      .select('id,checkout_id').eq('user_id',user.id).eq('provider','whop')
      .eq('plan_key',key).eq('plan_id',planId).eq('status','pending')
      .gt('expires_at',new Date().toISOString()).not('checkout_id','is',null)
      .order('created_at',{ascending:false}).limit(1).maybeSingle();
    if(pendingError)throw pendingError;
    if(pending?.checkout_id) {
      return NextResponse.json({
        checkoutId:pending.checkout_id,intentId:pending.id,
        environment:whopEnvironment(),trialApplied,
      },{headers:{'Cache-Control':'private, no-store'}});
    }
    const intentId=crypto.randomUUID();
    const {error:intentError}=await admin.from('billing_checkout_intents').insert({
      id:intentId,user_id:user.id,provider:'whop',
      plan_key:key,plan_id:planId,
      ...(affiliateUserId?{affiliate_user_id:affiliateUserId}:{}),
    });
    if(intentError)throw intentError;
    if(trialApplied&&affiliateUserId) {
      const {data:reserved,error:reserveError}=await admin.rpc('affiliate_reserve_trial',{
        buyer:user.id,affiliate:affiliateUserId,
        checkout:intentId,selected_plan:key,
      });
      if(reserveError||reserved!==true) {
        await admin.from('billing_checkout_intents')
          .delete().eq('id',intentId).eq('user_id',user.id);
        return NextResponse.json({
          error:'The referral free trial has already been used or reserved by this account.',
        },{status:409});
      }
    }
    const checkout=await whopServer().checkoutConfigurations.create({
      plan_id:planId,mode:'payment',
      metadata:{laterbox_intent_id:intentId},
    },{idempotencyKey:`laterbox-${intentId}`});
    const {error:updateError}=await admin.from('billing_checkout_intents')
      .update({checkout_id:checkout.id}).eq('id',intentId).eq('user_id',user.id);
    if(updateError)throw updateError;
    return NextResponse.json({
      checkoutId:checkout.id,intentId,environment:whopEnvironment(),trialApplied,
    },{headers:{'Cache-Control':'private, no-store'}});
  }catch(error) {
    console.error('[whop] checkout creation failed',error);
    return NextResponse.json({
      error:'Checkout is unavailable. Check Whop configuration and database migrations.',
    },{status:503});
  }
}
