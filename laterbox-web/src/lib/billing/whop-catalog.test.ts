// laterbox-web/src/lib/billing/whop-catalog.test.ts
import test from 'node:test';
import assert from 'node:assert/strict';
import {
  WHOP_CATALOG_PLANS, WHOP_CATALOG_PRODUCTS,
  existingWhopProduct, existingWhopPlan, type WhopPlanRecord,
} from './whop-catalog';

test('Whop provisioning covers the four existing LaterBox plans at their published USD prices', () => {
  assert.deepEqual(WHOP_CATALOG_PRODUCTS.map(p => p.title), ['LaterBox Plus', 'LaterBox Vault']);
  assert.deepEqual(WHOP_CATALOG_PLANS.map(plan => [plan.key, plan.renewalPrice, plan.billingPeriod]), [
    ['plus_month', 2.99, 30],
    ['plus_year', 29.99, 365],
    ['vault_month', 6.99, 30],
    ['vault_year', 69.99, 365],
  ]);
});

test('reuses existing matching products without creating duplicate products', () => {
  const product = { id: 'prod_123', title: 'LaterBox Plus' };
  assert.deepEqual(existingWhopProduct([product], WHOP_CATALOG_PRODUCTS[0]), product);
  assert.equal(existingWhopProduct([], WHOP_CATALOG_PRODUCTS[0]), null);
  assert.throws(() => existingWhopProduct([product, product], WHOP_CATALOG_PRODUCTS[0]), /Multiple products/);
});

test('reuses existing plans only when billing terms match exactly', () => {
  const desired = WHOP_CATALOG_PLANS[0];
  const record: WhopPlanRecord = {
    id: 'plan_123',
    title: desired.title,
    product: { id: 'prod_123' },
    currency: 'usd',
    plan_type: 'renewal',
    billing_period: desired.billingPeriod,
    renewal_price: desired.renewalPrice,
    initial_price: 0,
  };
  assert.deepEqual(existingWhopPlan([record], 'prod_123', desired), record);
  assert.equal(existingWhopPlan([record], 'prod_other', desired), null);
  assert.throws(() => existingWhopPlan([{ ...record, renewal_price: 20 }], 'prod_123', desired), /different billing terms/);
  assert.throws(() => existingWhopPlan([record, record], 'prod_123', desired), /Multiple/);
});
