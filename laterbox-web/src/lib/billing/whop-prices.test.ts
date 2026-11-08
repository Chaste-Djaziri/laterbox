// laterbox-web/src/lib/billing/whop-prices.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { normalizeWhopPlan, formatWhopPrice, yearlySavings } from './whop-prices';

const monthly = {
  id: 'plan_live_1', currency: 'usd', renewal_price: 3.49, initial_price: 0,
  billing_period: 30, plan_type: 'renewal', tax_type: 'exclusive', collect_tax: true,
};

test('public quote uses live Whop renewal_price rather than hard-coded catalog defaults', () => {
  const quote = normalizeWhopPlan('plus_month', monthly);
  assert.equal(quote.renewalPrice, 3.49);
  assert.equal(quote.currency, 'USD');
  assert.equal(quote.taxType, 'exclusive');
  assert.equal(quote.billingPeriodDays, 30);
  assert.equal(formatWhopPrice(quote.renewalPrice, quote.currency), '$3.49');
});

test('incorrect billing periods, missing renewal prices and unsupported plan types fail closed', () => {
  assert.throws(() => normalizeWhopPlan('plus_year', monthly), /unsupported pricing/);
  assert.throws(() => normalizeWhopPlan('plus_month', { ...monthly, renewal_price: NaN }), /unsupported pricing/);
  assert.throws(() => normalizeWhopPlan('plus_month', { ...monthly, plan_type: 'one_time' }), /unsupported pricing/);
});

test('annual savings are calculated from live Whop prices and only for matching currencies', () => {
  const month = normalizeWhopPlan('plus_month', monthly);
  const year = normalizeWhopPlan('plus_year', { ...monthly, billing_period: 365, renewal_price: 30 });
  assert.equal(yearlySavings(month, year), 28);
  assert.equal(yearlySavings(month, { ...year, currency: 'EUR' }), null);
  assert.equal(yearlySavings(month, { ...year, renewalPrice: 100 }), null);
});
