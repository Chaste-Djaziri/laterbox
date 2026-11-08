import { getBillingAdminClient } from './server';
import { storagePlanForWhopId, WHOP_STORAGE_PLANS, whopServer } from './whop';

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
  const userId = existing?.user_id ?? owner;
  if (!userId) return; // Out-of-order lifecycle event; initial paid event will bind it.
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

  if (intentId) {
    const { data: intent, error } = await admin.from('billing_checkout_intents')
      .select('user_id,plan_id,status')
      .eq('id', intentId).eq('provider', 'whop').maybeSingle();
    if (error) throw error;
    if (!intent || intent.plan_id !== membership.plan_id || (payment.plan_id && payment.plan_id !== intent.plan_id)) {
      throw new Error('Whop checkout intent or plan mismatch.');
    }
    owner = intent.user_id;
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
  }
  await updateMembership(membership, owner);
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
    const id = string(event.data.payment_id);
    if (id?.startsWith('pay_')) {
      const payment = await whopServer().payments.retrieve({ id });
      if (payment.membership_id) {
        const membership = await whopServer().memberships.retrieve({ id: payment.membership_id });
        await updateMembership(membership, null);
      }
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
