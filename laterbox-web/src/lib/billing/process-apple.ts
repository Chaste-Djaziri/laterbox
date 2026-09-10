import type {
  JWSRenewalInfoDecodedPayload,
  JWSTransactionDecodedPayload,
} from '@apple/app-store-server-library';
import { appleSubscriptionState, assertAppleTransaction } from './apple';
import { getBillingAdminClient } from './server';

export async function upsertAppleSubscription(
  transaction: JWSTransactionDecodedPayload,
  renewal?: JWSRenewalInfoDecodedPayload | null,
) {
  assertAppleTransaction(transaction);
  const admin = getBillingAdminClient();
  const userId = transaction.appAccountToken!;
  const subscriptionId = transaction.originalTransactionId!;
  const occurredAt = new Date(transaction.signedDate ?? Date.now()).toISOString();
  const state = appleSubscriptionState(transaction, renewal);

  const { error: customerError } = await admin.from('billing_customers').upsert(
    {
      provider: 'apple',
      customer_id: userId,
      user_id: userId,
      updated_at: occurredAt,
    },
    { onConflict: 'provider,customer_id' },
  );
  if (customerError) throw customerError;

  const { data: current } = await admin
    .from('billing_subscriptions')
    .select('occurred_at,past_due_at')
    .eq('provider', 'apple')
    .eq('subscription_id', subscriptionId)
    .maybeSingle();
  if (current?.occurred_at && new Date(current.occurred_at) > new Date(occurredAt)) return;

  const { error } = await admin.from('billing_subscriptions').upsert(
    {
      provider: 'apple',
      subscription_id: subscriptionId,
      customer_id: userId,
      user_id: userId,
      status: state.status,
      product_id: transaction.productId,
      price_id: transaction.productId,
      trial_ends_at: state.status === 'trialing' ? state.periodEnd : null,
      current_period_starts_at: state.status === 'past_due'
        ? current?.past_due_at ?? occurredAt
        : state.periodStart,
      current_period_ends_at: state.status === 'past_due'
        ? state.graceEnd ?? state.periodEnd
        : state.periodEnd,
      scheduled_change_action: state.willCancel ? 'cancel' : null,
      scheduled_change_at: state.willCancel ? state.periodEnd : null,
      past_due_at: state.status === 'past_due'
        ? current?.past_due_at ?? occurredAt
        : null,
      occurred_at: occurredAt,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'provider,subscription_id' },
  );
  if (error) throw error;
}

export async function processAppleNotification(
  eventId: string,
  eventType: string,
  occurredAt: string,
  transaction: JWSTransactionDecodedPayload | null,
  renewal: JWSRenewalInfoDecodedPayload | null,
) {
  const admin = getBillingAdminClient();
  const { data: existing } = await admin
    .from('billing_webhook_events')
    .select('event_id')
    .eq('provider', 'apple')
    .eq('event_id', eventId)
    .maybeSingle();
  if (existing) return;

  if (transaction) await upsertAppleSubscription(transaction, renewal);

  const { error } = await admin.from('billing_webhook_events').insert({
    provider: 'apple',
    event_id: eventId,
    event_type: eventType,
    occurred_at: occurredAt,
  });
  if (error && error.code !== '23505') throw error;
}
