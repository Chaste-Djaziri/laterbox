import type {
  JWSRenewalInfoDecodedPayload,
  JWSTransactionDecodedPayload,
} from '@apple/app-store-server-library';
import { AppleBillingError, appleSubscriptionState, assertAppleTransaction } from './apple';
import { getBillingAdminClient } from './server';

export async function resolveApplePurchaseOwner(transaction: JWSTransactionDecodedPayload): Promise<string | null> {
  assertAppleTransaction(transaction, undefined, true);
  const { data, error } = await getBillingAdminClient().rpc('resolve_apple_purchase_owner', {
    p_original_id: transaction.originalTransactionId,
    p_environment: transaction.environment,
    p_token: transaction.appAccountToken?.toLowerCase() ?? null,
  });
  if (error) {
    if (error.code === 'P0001') throw new AppleBillingError('account_mismatch', 'This Apple purchase belongs to another LaterBox account.', 409);
    throw error;
  }
  return data as string | null;
}

export function appleSubscriptionRecord(
  transaction: JWSTransactionDecodedPayload,
  renewal: JWSRenewalInfoDecodedPayload | null | undefined,
  userId: string,
  notificationAt?: string,
) {
  const state = appleSubscriptionState(transaction, renewal);
  const occurredAt = notificationAt ?? new Date(transaction.signedDate ?? Date.now()).toISOString();
  return {
    provider: 'apple', subscription_id: transaction.originalTransactionId,
    customer_id: userId, user_id: userId, status: state.status,
    product_id: transaction.productId, price_id: transaction.productId,
    trial_ends_at: state.status === 'trialing' ? state.periodEnd : null,
    current_period_starts_at: state.periodStart,
    current_period_ends_at: state.status === 'past_due' ? state.graceEnd : state.periodEnd,
    scheduled_change_action: state.willCancel ? 'cancel' : null,
    scheduled_change_at: state.willCancel ? state.periodEnd : null,
    past_due_at: state.status === 'past_due' ? occurredAt : null,
    occurred_at: occurredAt, apple_environment: transaction.environment,
    apple_transaction_id: transaction.transactionId,
    apple_notification_at: notificationAt ?? null,
    revoked_at: transaction.revocationDate ? new Date(transaction.revocationDate).toISOString() : null,
    renewal_known: Boolean(renewal),
  };
}

export async function upsertAppleSubscription(
  transaction: JWSTransactionDecodedPayload,
  renewal?: JWSRenewalInfoDecodedPayload | null,
  notificationAt?: string,
  expectedUserId?: string,
): Promise<boolean> {
  const userId = await resolveApplePurchaseOwner(transaction);
  if (!userId) return false;
  if (expectedUserId && userId.toLowerCase() !== expectedUserId.toLowerCase()) {
    throw new AppleBillingError('account_mismatch', 'Sign in to the LaterBox account connected to this purchase.', 403);
  }
  const { error } = await getBillingAdminClient().rpc('apply_apple_subscription', {
    p_notification: Boolean(notificationAt),
    p_subscription: appleSubscriptionRecord(transaction, renewal, userId, notificationAt),
  });
  if (error) throw error;
  return true;
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
