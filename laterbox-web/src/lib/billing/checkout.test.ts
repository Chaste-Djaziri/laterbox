import assert from 'node:assert/strict';
import test from 'node:test';
import { checkoutSuccessUrl, loadCheckout, CHECKOUT_LOADING_ERROR } from './checkout';

test('checkout waits for delayed initialization', async () => {
  let resolve!: (value: object) => void;
  const instance = {};
  let ready = false;
  const promise = loadCheckout(() => new Promise<object>((done) => { resolve = done; })).then((value) => {
    ready = true;
    return value;
  });
  await Promise.resolve();
  assert.equal(ready, false);
  resolve(instance);
  assert.equal(await promise, instance);
});

test('failed, empty, and stalled initialization reject', async () => {
  await assert.rejects(loadCheckout(async () => { throw new Error('blocked'); }), /blocked/);
  await assert.rejects(loadCheckout(async () => undefined), { message: CHECKOUT_LOADING_ERROR });
  await assert.rejects(loadCheckout(() => new Promise(() => {}), 5), { message: CHECKOUT_LOADING_ERROR });
});

test('monthly and yearly checkout preserve plans and native pricing return flows', () => {
  for (const interval of ['month', 'year'] as const) {
    const plans = new URL(checkoutSuccessUrl('https://app.laterbox.dev', '/plans', interval));
    assert.equal(plans.pathname, '/plans');
    assert.equal(plans.searchParams.get('plan'), interval);
    assert.equal(plans.searchParams.get('checkout'), 'success');
    const pricing = new URL(checkoutSuccessUrl('https://laterbox.dev', '/pricing', interval, 'laterbox://billing'));
    assert.equal(pricing.pathname, '/pricing');
    assert.equal(pricing.searchParams.get('return_to'), 'laterbox://billing');
  }
});
