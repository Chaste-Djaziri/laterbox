import { getBillingAdminClient } from './server';
import { recordVerifiedWhopPayment, reverseRefundedCommission, reversePaymentId } from '@/lib/earn/attribution';
import { storagePlanForWhopId, isWhopReferralTrialPlan, WHOP_STORAGE_PLANS, whopServer } from './whop';

export type WhopWebhook = {
  id: string;
  type: string;
  data: Record<string, unknown>;
};
type WhopMembership = Awaited<ReturnType<ReturnType<typeof whopServer>['memberships']['retrieve']>>;

function record(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value) ? value as Record<string, unknown> : {};
}
function string(value: unknown): string | null {
  return typeof value === 'string' && value.trim() ? value : null;
}
function validTimestamp(value: string | null): string | null {
  return value && Number.isFinite(Date.parse(value)) ? new Date(value).toISOString() : null;
}

async function updateMembership(membership: WhopMembership, owner: string | null) {
  const admin = getBillingAdminClient();
  if (!membership.id.startsWith('mem_') || !membership.user_id) throw new Error('Invalid Whop membership identity.');

  const key = storagePlanForWhopId(membership.plan_id);
  if (!key) throw new Error('Whop membership is not a configured LaterBox storage product.');

  const { data: existing, error: existingError } = await admin.from('billing_subscriptions')
    .select('user_id,customer_id,occurred_at')
    .eq('provider', 'whop').eq('subscription_id', membership.id).maybeSingle();
  if (existingError) throw existingError;

  // For renewals and cancellations, subscription ownership MUST already exist.
  if (existing && owner && owner !== existing.user_id) {
    throw new Error('Whop purchase intent conflicts with the previously linked LaterBox account.');
  }
  let userId = existing?.user_id ?? owner;
  let verifiedCheckoutIntentId: string | null = null;
  // A zero-dollar trial has no payment.succeeded event at activation. Whop's
  // verified membership checkout ID securely identifies the LaterBox buyer.
  const checkoutId=(membership as WhopMembership & {checkout_configuration_id?:string|null})
    .checkout_configuration_id;
  if(!userId && checkoutId) {
    const {data:intent,error:intentError}=await admin.from('billing_checkout_intents')
      .select('id,user_id,plan_id').eq('checkout_id',checkoutId)
      .eq('provider','whop').maybeSingle();
    if(intentError)throw intentError;
    if(intent && intent.plan_id===membership.plan_id) {
      userId=intent.user_id;
      verifiedCheckoutIntentId=intent.id;
    }
  }
  if (!userId) return;
  if (existing && existing.customer_id !== membership.user_id) throw new Error('Whop buyer changed unexpectedly.');
  const changed = validTimestamp(membership.updated_at);
  if (!changed) throw new Error('Whop did not provide a membership timestamp.');
  if (existing?.occurred_at && Date.parse(existing.occurred_at) > Date.parse(changed)) return;

  const end = validTimestamp(membership.current_period_end);
  const state = membership.status;
  // Restrict to renewable memberships. Never create indefinite paid storage.
  if (['active', 'trialing', 'past_due'].includes(state) && (!end || Date.parse(end) <= Date.now())) {
    throw new Error('Whop subscription is missing a future billing period.');
  }
  const status = state === 'active' || state === 'trialing' || state === 'past_due'
    ? state : state === 'expired' || state === 'canceled'
      ? 'canceled' : 'paused';
  const { error: customerError } = await admin.from('billing_customers').upsert({
    provider: 'whop',
    customer_id: membership.user_id,
    user_id: userId,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'provider,customer_id' });
  if (customerError) throw customerError;

  const { error } = await admin.from('billing_subscriptions').upsert({
    provider: 'whop',
    subscription_id: membership.id,
    customer_id: membership.user_id,
    user_id: userId,
    status,
    product_id: membership.product_id,
    price_id: membership.plan_id,
    storage_plan: WHOP_STORAGE_PLANS[key].storage,
    trial_ends_at:status==='trialing'?end:null,
    current_period_starts_at: validTimestamp(membership.current_period_start),
    current_period_ends_at: end,
    scheduled_change_action: membership.cancel_at_period_end ? 'cancel' : null,
    scheduled_change_at: membership.cancel_at_period_end ? end : null,
    past_due_at: status === 'past_due' ? changed : null,
    revoked_at: status === 'canceled' || status === 'paused' ? changed : null,
    occurred_at: changed,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'provider,subscription_id' });
  if (error) throw error;
  if(process.env.EARN_TRACKING_ENABLED==='true' && isWhopReferralTrialPlan(membership.plan_id)) {
    let intentId=verifiedCheckoutIntentId;
    if(!intentId && checkoutId) {
      const {data:intent,error:checkoutError}=await admin.from('billing_checkout_intents')
        .select('id,user_id,plan_id').eq('checkout_id',checkoutId)
        .eq('provider','whop').maybeSingle();
      if(checkoutError)throw checkoutError;
      if(intent && intent.user_id===userId && intent.plan_id===membership.plan_id) intentId=intent.id;
    }
    if(intentId) {
      const start=validTimestamp(membership.created_at);
      const trialEnd=status==='trialing' ? end :
        validTimestamp(membership.current_period_start);
      if(start && trialEnd && Date.parse(trialEnd)>Date.parse(start)) {
        const {error:claimError}=await admin.from('affiliate_trial_claims').update({
          membership_id:membership.id,started_at:start,trial_ends_at:trialEnd,
          status:'trialing', // Qualification requires verified paid billing cycles.
        }).eq('checkout_intent_id',intentId).eq('buyer_user_id',userId)
          .eq('status','reserved');
        if(claimError)throw claimError;
      }
    }
  }
}

async function paymentSucceeded(paymentId: string): Promise<void> {
  const admin = getBillingAdminClient();
  const payment = await whopServer().payments.retrieve({ id: paymentId });
  if (payment.substatus !== 'succeeded' || !payment.membership_id || !payment.user?.id) {
    throw new Error('Whop payment is not a confirmed subscription payment.');
  }
  const membership = await whopServer().memberships.retrieve({ id: payment.membership_id });
  if (membership.user_id !== payment.user?.id) throw new Error('Whop payment ownership mismatch.');
  const metadata = record(payment.metadata);
  let intentId = string(metadata.laterbox_intent_id);
  // Some Whop payment methods do not copy checkout metadata to the receipt.
  // In that case trust only the verified Whop checkout identifier, never an email.
  if (!intentId && payment.checkout_configuration_id) {
    const { data: matched, error } = await admin.from('billing_checkout_intents')
      .select('id').eq('checkout_id', payment.checkout_configuration_id)
      .eq('provider','whop').maybeSingle();
    if (error) throw error;
    intentId = matched?.id ?? null;
  }
  let owner: string | null = null;
  let affiliateUserId: string | null = null;

  if (intentId) {
    const { data: intent, error } = await admin.from('billing_checkout_intents')
      .select('user_id,plan_id,status,affiliate_user_id')
      .eq('id', intentId).eq('provider', 'whop').maybeSingle();
    // Billing must not be blocked if the opt-in Earn migration is still pending.
    let resolvedIntent = intent;
    if (error && (error.code === '42703' || error.code === 'PGRST204' || error.code === 'PGRST205')) {
      const fallback = await admin.from('billing_checkout_intents')
        .select('user_id,plan_id,status')
        .eq('id', intentId).eq('provider', 'whop').maybeSingle();
      if (fallback.error) throw fallback.error;
      resolvedIntent = fallback.data ? { ...fallback.data, affiliate_user_id: null } : null;
    } else if (error) throw error;
    if (!resolvedIntent || resolvedIntent.plan_id !== membership.plan_id || (payment.plan_id && payment.plan_id !== resolvedIntent.plan_id)) {
      throw new Error('Whop checkout intent or plan mismatch.');
    }
    owner = resolvedIntent.user_id;
    affiliateUserId = resolvedIntent.affiliate_user_id ?? null;
  }
  if (!owner) {
    const { data: linked, error } = await admin.from('billing_subscriptions')
      .select('user_id').eq('provider','whop')
      .eq('subscription_id',membership.id).maybeSingle();
    if (error) throw error;
    if (!linked?.user_id) {
      // Never acknowledge a successful charge that has no LaterBox owner.
      // Whop can retry; support can resolve truly orphaned purchases.
      throw new Error('Paid Whop membership is missing a trusted LaterBox checkout intent.');
    }
    owner = linked.user_id;
  }
  await updateMembership(membership, owner);
  // Store every verified successful receipt for affiliate tenure. Only a
  // first-time checkout tied to a referral can create one commission.
  if (owner && process.env.EARN_TRACKING_ENABLED === 'true') {
    try {
      await recordVerifiedWhopPayment(payment as unknown as Record<string,unknown>,
        owner, membership.id, affiliateUserId);
    } catch (error) {
      // Missing feature tables must never disrupt a paying subscriber.
      const code = (error as {code?: string})?.code;
      if (!['42P01','PGRST204','PGRST205'].includes(code ?? '')) throw error;
      console.warn('[earn] receipt tracking awaits the Earn migration');
    }
  }
  if (intentId && owner) {
    const { error } = await admin.from('billing_checkout_intents').update({ status: 'fulfilled' })
      .eq('id', intentId).eq('user_id', owner);
    if (error) throw error;
  }
}

export async function processWhopWebhook(event: WhopWebhook, deliveryId: string) {
  if (!/^[-\w]+$/.test(deliveryId)) throw new Error('Invalid Whop delivery ID.');
  const admin = getBillingAdminClient();
  const { data: already, error: readError } = await admin.from('billing_webhook_events')
    .select('event_id').eq('provider','whop').eq('event_id',deliveryId).maybeSingle();
  if (readError) throw readError;
  if (already) return 'duplicate';

  if (event.type === 'payment.succeeded') {
    const id = string(event.data.id);
    if (!id?.startsWith('pay_')) throw new Error('Payment webhook has no payment ID.');
    await paymentSucceeded(id);
  } else if ([
    'membership.activated', 'membership.updated', 'membership.went_valid',
    'membership.went_invalid', 'membership.cancel_at_period_end_changed',
    'membership_deactivated', 'membership_activated', 'membership_deactivated',
  ].includes(event.type)) {
    const id = string(event.data.id);
    if (id?.startsWith('mem_')) {
      const membership = await whopServer().memberships.retrieve({ id });
      await updateMembership(membership, null);
    }
  } else if (event.type === 'refund.updated' || event.type === 'refund.created') {
    // A successful refund can revoke membership access. Reconcile the membership
    // from Whop rather than trusting an unverified refund payload.
    const id = string(event.data.payment_id) || string(record(event.data.payment).id);
    if (id?.startsWith('pay_')) {
      const payment = await whopServer().payments.retrieve({ id });
      if (process.env.EARN_TRACKING_ENABLED === 'true') {
        try {
          await reverseRefundedCommission(payment as unknown as Record<string,unknown>);
        } catch (error) {
          const code=(error as {code?:string})?.code;
          if (!['42P01','PGRST204','PGRST205'].includes(code ?? '')) throw error;
        }
      }
      if (payment.membership_id) {
        const membership = await whopServer().memberships.retrieve({ id: payment.membership_id });
        await updateMembership(membership, null);
      }
    }
  } else if (event.type === 'dispute.created' || event.type === 'dispute.updated') {
    const id=string(record(event.data.payment).id)||string(event.data.payment_id);
    if (id?.startsWith('pay_') && process.env.EARN_TRACKING_ENABLED==='true') {
      await reversePaymentId(id);
    }
  }
  const { error } = await admin.from('billing_webhook_events').insert({
    provider:'whop',
    event_id:deliveryId,
    event_type:event.type,
    occurred_at:new Date().toISOString(),
  });
  if (error && error.code !== '23505') throw error;
  return 'processed';
}
