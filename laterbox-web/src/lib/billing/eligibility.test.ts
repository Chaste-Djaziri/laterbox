import assert from 'node:assert/strict';
import test from 'node:test';
import { subscriptionHasAccess, type SubscriptionAccess } from './eligibility';

const now = Date.parse('2026-10-12T12:00:00Z');
const row: SubscriptionAccess = { provider: 'apple', status: 'active', current_period_ends_at: '2026-10-13T12:00:00Z', updated_at: '2026-10-12T12:00:00Z' };

test('Apple access expires even when a notification was missed', () => {
  for (const status of ['active', 'trialing', 'canceled', 'past_due']) {
    assert.equal(subscriptionHasAccess({ ...row, status }, now), true);
    assert.equal(subscriptionHasAccess({ ...row, status }, now + 86_400_000), false);
    assert.equal(subscriptionHasAccess({ ...row, status, current_period_ends_at: null }, now), false);
  }
  assert.equal(subscriptionHasAccess({ ...row, revoked_at: new Date(now).toISOString() }, now), false);
});

test('Paddle retry access ends at the earlier of expiry or seven days', () => {
  assert.equal(subscriptionHasAccess({ ...row, provider: 'paddle', status: 'past_due' }, now), true);
  assert.equal(subscriptionHasAccess({ ...row, provider: 'paddle', status: 'past_due', past_due_at: '2026-10-01T12:00:00Z' }, now), false);
  assert.equal(subscriptionHasAccess({ ...row, provider: 'paddle', status: 'paused' }, now), false);
  assert.equal(subscriptionHasAccess({ ...row, provider: 'paddle', current_period_ends_at: 'invalid' }, now), false);
});
