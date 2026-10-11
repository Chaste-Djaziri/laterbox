import assert from 'node:assert/strict';
import test from 'node:test';
import { appleSubscriptionState, assertAppleTransaction } from './apple';
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

test('Apple free trial transaction maps to trialing', () => {
  const now = Date.now();
  const state = appleSubscriptionState({
    originalTransactionId: 'original',
    transactionId: 'transaction',
    productId: 'com.laterbox.pro.monthly',
    purchaseDate: now - 1_000,
    expiresDate: now + 86_400_000,
    offerType: 1,
    offerDiscountType: 'FREE_TRIAL',
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

test('Paddle plan presentation preserves provider and billing states', () => {
  const now = new Date('2026-10-07T12:00:00Z');
  const active: Entitlement = {
    ...FREE_ENTITLEMENT, tier: 'pro', provider: 'paddle', status: 'active',
    accessEndsAt: '2026-11-07T12:00:00Z', phaseEndsAt: '2026-11-07T12:00:00Z',
  };
  assert.equal(presentEntitlement(active, now).actionLabel, 'Manage');
  assert.equal(presentEntitlement({ ...active, status: 'past_due' }, now).actionLabel, 'Fix payment');
  for (const status of ['active', 'trialing', 'canceled'] as const) {
    const value = presentEntitlement({ ...active, status, willCancel: true }, now);
    assert.equal(value.tone, 'warning');
    assert.equal(value.description, 'Your plan stays active until the end of this period.');
  }
  assert.equal(presentEntitlement({ ...active, status: 'granted', provider: null }, now).actionLabel, 'View plans');
  assert.equal(presentEntitlement({ ...active, provider: 'apple' }, now).actionLabel, 'Manage');
  assert.equal(presentEntitlement(active, new Date('2026-12-01')).label, 'Free');
});


test('Apple discounted introductory purchases are paid access, not free trials', () => {
  for (const offerDiscountType of ['PAY_AS_YOU_GO', 'PAY_UP_FRONT', undefined]) {
    assert.equal(appleSubscriptionState({ offerType: 1, offerDiscountType, expiresDate: Date.now() + 60_000 }).status, 'active');
  }
});

test('Apple refund ends access immediately even during grace or trial', () => {
  const now = Date.now();
  const state = appleSubscriptionState({ expiresDate: now + 60_000, revocationDate: now - 1, offerDiscountType: 'FREE_TRIAL' }, { isInBillingRetryPeriod: true, gracePeriodExpiresDate: now + 120_000 });
  assert.equal(state.status, 'canceled');
  assert.ok(Date.parse(state.periodEnd!) <= now);
});

test('Apple ownership is mandatory and only verified server environments are accepted', () => {
  const id = '00000000-0000-4000-8000-000000000001';
  const transaction = { productId: 'com.laterbox.pro.monthly', originalTransactionId: 'original', transactionId: 'transaction', environment: 'Sandbox', appAccountToken: id };
  assert.doesNotThrow(() => assertAppleTransaction(transaction, id));
  assert.doesNotThrow(() => assertAppleTransaction({ ...transaction, environment: 'Production' }, id));
  assert.throws(() => assertAppleTransaction({ ...transaction, appAccountToken: undefined }, id), /not linked/);
  assert.throws(() => assertAppleTransaction(transaction, 'other-account'), /Sign in/);
  for (const environment of ['Xcode', 'LocalTesting', undefined]) {
    assert.throws(() => assertAppleTransaction({ ...transaction, environment }, id), /Only App Store/);
  }
});
