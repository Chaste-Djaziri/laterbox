import assert from 'node:assert/strict';
import test from 'node:test';
import { appleSubscriptionState } from './apple';
import { FREE_ENTITLEMENT, presentEntitlement, type Entitlement } from './types';

test('free entitlement offers plans without progress', () => {
  const value = presentEntitlement(FREE_ENTITLEMENT, new Date('2026-09-10T12:00:00Z'));
  assert.equal(value.label, 'Free');
  assert.equal(value.actionLabel, 'View plans');
  assert.equal(value.progress, null);
});

test('trial presentation rounds remaining partial days up', () => {
  const entitlement: Entitlement = {
    tier: 'pro',
    status: 'trialing',
    provider: 'paddle',
    trialEndsAt: '2026-09-12T13:00:00Z',
    accessEndsAt: '2026-09-12T13:00:00Z',
    willCancel: false,
    billingWarning: null,
    phaseStartsAt: '2026-09-08T11:00:00Z',
    phaseEndsAt: '2026-09-12T13:00:00Z',
  };
  const value = presentEntitlement(entitlement, new Date('2026-09-10T12:00:00Z'));
  assert.equal(value.label, 'Pro trial · 3 days left');
  assert.equal(value.tone, 'success');
  assert.ok(value.progress !== null && value.progress > 0 && value.progress < 1);
});

test('Apple introductory transaction maps to trialing', () => {
  const now = Date.now();
  const state = appleSubscriptionState({
    originalTransactionId: 'original',
    transactionId: 'transaction',
    productId: 'com.laterbox.pro.monthly',
    purchaseDate: now - 1_000,
    expiresDate: now + 86_400_000,
    offerType: 1,
  });
  assert.equal(state.status, 'trialing');
});

test('Apple billing retry with grace maps to past due', () => {
  const now = Date.now();
  const state = appleSubscriptionState(
    {
      originalTransactionId: 'original',
      transactionId: 'transaction',
      productId: 'com.laterbox.pro.annual',
      purchaseDate: now - 86_400_000,
      expiresDate: now - 1_000,
    },
    {
      isInBillingRetryPeriod: true,
      gracePeriodExpiresDate: now + 86_400_000,
    },
  );
  assert.equal(state.status, 'past_due');
  assert.ok(state.graceEnd);
});
