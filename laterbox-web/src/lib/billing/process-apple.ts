import type {
  JWSRenewalInfoDecodedPayload,
  JWSTransactionDecodedPayload,
} from '@apple/app-store-server-library';
import { appleSubscriptionState, assertAppleTransaction } from './apple';
import { getBillingAdminClient } from './server';

export async function upsertAppleSubscription(
  transaction: JWSTransactionDecodedPayload,
  renewal?: JWSRenewalInfoDecodedPayload | null,
  notificationAt?: string,
) {
  assertAppleTransaction(transaction);
  const admin = getBillingAdminClient();
  const userId = transaction.appAccountToken!.toLowerCase();
  const state = appleSubscriptionState(transaction, renewal);
  const occurredAt = notificationAt ?? new Date(transaction.signedDate ?? Date.now()).toISOString();
  const { error } = await admin.rpc('apply_apple_subscription', {
    p_notification: Boolean(notificationAt),
    p_subscription: {
      provider: 'apple',
      subscription_id: transaction.originalTransactionId,
      customer_id: userId,
      user_id: userId,
      status: state.status,
      product_id: transaction.productId,
      price_id: transaction.productId,
      trial_ends_at: state.status === 'trialing' ? state.periodEnd : null,
      current_period_starts_at: state.periodStart,
      current_period_ends_at: state.status === 'past_due' ? state.graceEnd : state.periodEnd,
      scheduled_change_action: state.willCancel ? 'cancel' : null,
      scheduled_change_at: state.willCancel ? state.periodEnd : null,
      past_due_at: state.status === 'past_due' ? occurredAt : null,
      occurred_at: occurredAt,
      apple_environment: transaction.environment,
      apple_transaction_id: transaction.transactionId,
      apple_notification_at: notificationAt ?? null,
      revoked_at: transaction.revocationDate ? new Date(transaction.revocationDate).toISOString() : null,
      renewal_known: Boolean(renewal),
    },
  });
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
  const { data: existing, error: lookupError } = await admin
    .from('billing_webhook_events')
    .select('event_id')
    .eq('provider', 'apple')
    .eq('event_id', eventId)
    .maybeSingle();
  if (lookupError) throw lookupError;
  if (existing) return;

  if (transaction) await upsertAppleSubscription(transaction, renewal, occurredAt);

  const { error } = await admin.from('billing_webhook_events').insert({
    provider: 'apple',
    event_id: eventId,
    event_type: eventType,
    occurred_at: occurredAt,
  });
  if (error && error.code !== '23505') throw error;
}
