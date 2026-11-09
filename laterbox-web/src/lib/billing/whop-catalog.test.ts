// laterbox-web/src/lib/billing/whop-catalog.test.ts
import test from 'node:test';
import assert from 'node:assert/strict';
import {
  WHOP_CATALOG_PLANS, WHOP_CATALOG_PRODUCTS,
  existingWhopProduct, existingWhopPlan, whopCatalogQuery, whopProductCreateBody, whopPlanCreateBody, type WhopPlanRecord,
} from './whop-catalog';

test('Whop provisioning retains original prices and includes fourteen plan options', () => {
  assert.deepEqual(WHOP_CATALOG_PRODUCTS.map(p => p.title), ['LaterBox Plus', 'LaterBox Vault']);
  assert.deepEqual(WHOP_CATALOG_PLANS.map(plan => [plan.key, plan.renewalPrice, plan.billingPeriod]), [
    ['plus_month', 2.99, 30],
    ['plus_year', 29.99, 365],
    ['plus50_month', 4.99, 30],
    ['plus50_year', 49.99, 365],
    ['vault_month', 6.99, 30],
    ['vault_year', 69.99, 365],
    ['vault250_month', 11.99, 30],
    ['vault250_year', 119.99, 365],
    ['vault500_month', 19.99, 30],
    ['vault500_year', 209.99, 365],
    ['vault1tb_month', 39.99, 30],
    ['vault1tb_year', 419.99, 365],
    ['vault2tb_month', 69.99, 30],
    ['vault2tb_year', 739.99, 365],
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

test('every Whop catalog list is strictly scoped to account_id, never the public marketplace', () => {
  const query = new URLSearchParams(whopCatalogQuery('biz_LaterBox123'));
  assert.equal(query.get('account_id'), 'biz_LaterBox123');
  assert.equal(query.get('company_id'), null);
  assert.equal(query.get('first'), '100');
  assert.equal(query.get('after'), null);
  const next = new URLSearchParams(whopCatalogQuery('biz_LaterBox123', 'opaque-cursor'));
  assert.equal(next.get('after'), 'opaque-cursor');
  assert.equal(next.get('account_id'), 'biz_LaterBox123');
  assert.throws(() => whopCatalogQuery('not-an-account'), /Invalid Whop account ID/);
});

test('Whop create requests use account_id and preserve existing LaterBox catalog prices', () => {
  const product = whopProductCreateBody('biz_LaterBox123', WHOP_CATALOG_PRODUCTS[0]);
  assert.deepEqual(product, {
    account_id: 'biz_LaterBox123',
    title: 'LaterBox Plus',
    description: WHOP_CATALOG_PRODUCTS[0].description,
  });
  const plan = whopPlanCreateBody('biz_LaterBox123', 'prod_Test123', WHOP_CATALOG_PLANS[0]);
  assert.equal(plan.account_id, 'biz_LaterBox123');
  assert.equal(plan.product_id, 'prod_Test123');
  assert.equal(plan.billing_period, 30);
  assert.equal(plan.renewal_price, 2.99);
  assert.equal(plan.initial_price, 0);
  assert.equal(plan.plan_type, 'renewal');
  assert.equal('company_id' in plan, false);
  assert.throws(() => whopPlanCreateBody('biz_LaterBox123', 'other', WHOP_CATALOG_PLANS[0]), /Invalid Whop product ID/);
});
