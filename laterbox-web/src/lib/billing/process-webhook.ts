import { getBillingAdminClient } from './server';

type PaddleEvent = {
  event_id: string;
  event_type: string;
  occurred_at: string;
  data: Record<string, any>;
};

function userIdFrom(data: Record<string, any>): string | null {
  const value = data.custom_data?.user_id;
  return typeof value === 'string' && value.length > 0 ? value : null;
}

async function knownUserId(customerId: string): Promise<string | null> {
  const admin = getBillingAdminClient();
  const { data } = await admin
    .from('billing_customers')
    .select('user_id')
    .eq('provider', 'paddle')
    .eq('customer_id', customerId)
    .maybeSingle();
  return data?.user_id ?? null;
}

async function upsertCustomer(data: Record<string, any>, occurredAt: string) {
  const customerId = data.customer_id || data.id;
  const userId = userIdFrom(data) || (customerId ? await knownUserId(customerId) : null);
  if (!customerId || !userId) return;
  const admin = getBillingAdminClient();
  const { error } = await admin.from('billing_customers').upsert(
    {
      provider: 'paddle',
      customer_id: customerId,
      user_id: userId,
      email: data.email ?? null,
      updated_at: occurredAt,
    },
    { onConflict: 'provider,customer_id' }
  );
  if (error) throw error;
}

async function upsertSubscription(data: Record<string, any>, occurredAt: string) {
  const customerId = data.customer_id;
  const userId = userIdFrom(data) || (customerId ? await knownUserId(customerId) : null);
  if (!customerId || !userId || !data.id) {
    throw new Error('Subscription event is missing LaterBox user ownership.');
  }

  const admin = getBillingAdminClient();
  await upsertCustomer({ customer_id: customerId, custom_data: { user_id: userId } }, occurredAt);
  const { data: current } = await admin
    .from('billing_subscriptions')
    .select('occurred_at,past_due_at')
    .eq('provider', 'paddle')
    .eq('subscription_id', data.id)
    .maybeSingle();
  if (current?.occurred_at && new Date(current.occurred_at) > new Date(occurredAt)) return;

  const firstItem = Array.isArray(data.items) ? data.items[0] : null;
  const period = data.current_billing_period;
  const scheduled = data.scheduled_change;
  const { error } = await admin.from('billing_subscriptions').upsert(
    {
      provider: 'paddle',
      subscription_id: data.id,
      customer_id: customerId,
      user_id: userId,
      status: data.status,
      product_id: firstItem?.price?.product_id ?? null,
      price_id: firstItem?.price?.id ?? null,
      trial_ends_at: data.status === 'trialing' ? data.next_billed_at ?? period?.ends_at ?? null : null,
      current_period_ends_at: period?.ends_at ?? data.next_billed_at ?? null,
      scheduled_change_action: scheduled?.action ?? null,
      scheduled_change_at: scheduled?.effective_at ?? null,
      past_due_at:
        data.status === 'past_due' ? current?.past_due_at ?? occurredAt : null,
      occurred_at: occurredAt,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'provider,subscription_id' }
  );
  if (error) throw error;
}

export async function processPaddleWebhook(event: PaddleEvent) {
  const admin = getBillingAdminClient();
  const { data: alreadyProcessed } = await admin
    .from('billing_webhook_events')
    .select('event_id')
    .eq('provider', 'paddle')
    .eq('event_id', event.event_id)
    .maybeSingle();
  if (alreadyProcessed) return;

  if (event.event_type === 'customer.created' || event.event_type === 'customer.updated') {
    await upsertCustomer(event.data, event.occurred_at);
  } else if (
    event.event_type === 'subscription.created' ||
    event.event_type === 'subscription.updated' ||
    event.event_type === 'subscription.activated' ||
    event.event_type === 'subscription.canceled'
  ) {
    await upsertSubscription(event.data, event.occurred_at);
  } else if (event.event_type === 'transaction.completed') {
    await upsertCustomer(event.data, event.occurred_at);
  }

  const { error } = await admin.from('billing_webhook_events').insert({
    provider: 'paddle',
    event_id: event.event_id,
    event_type: event.event_type,
    occurred_at: event.occurred_at,
  });
  if (error && error.code !== '23505') throw error;
}
