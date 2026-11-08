import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import { FREE_STORAGE_BYTES, parseWhopPlan, storagePlanForWhopId, whopEnvironment, whopPlanId, WHOP_STORAGE_PLANS } from './whop';

afterEach(() => {
  delete process.env.WHOP_PLUS_MONTHLY_PLAN_ID;
  delete process.env.WHOP_SANDBOX;
});

test('storage tiers preserve free cloud space and distinct paid capacities', () => {
  assert.equal(FREE_STORAGE_BYTES, 500_000_000);
  assert.equal(WHOP_STORAGE_PLANS.plus_month.bytes, 10 * 1024 ** 3);
  assert.equal(WHOP_STORAGE_PLANS.vault_month.bytes, 100 * 1024 ** 3);
});

test('no client-supplied arbitrary plan key can select a price', () => {
  assert.equal(parseWhopPlan('plus_month'), 'plus_month');
  assert.equal(parseWhopPlan('pro'), null);
  assert.equal(parseWhopPlan('__proto__'), null);
  assert.equal(parseWhopPlan(null), null);
});

test('only configured plan ids are valid, unknown ids never grant capacity', () => {
  assert.throws(() => whopPlanId('plus_month'));
  process.env.WHOP_PLUS_MONTHLY_PLAN_ID = 'plan_testA1';
  assert.equal(whopPlanId('plus_month'), 'plan_testA1');
  assert.equal(storagePlanForWhopId('plan_testA1'), 'plus_month');
  assert.equal(storagePlanForWhopId('plan_unknown'), null);
});

test('sandbox is the safe default', () => {
  assert.equal(whopEnvironment(), 'sandbox');
  process.env.WHOP_SANDBOX = 'false';
  assert.equal(whopEnvironment(), 'production');
});
