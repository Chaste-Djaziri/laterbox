import assert from 'node:assert/strict';
import test from 'node:test';
import { POST as portal } from '../../app/api/billing/portal/route';
import { POST as checkout } from '../../app/api/billing/checkout/route';

async function payload(response: Response): Promise<{ url?: string; transactionId?: string }> {
  return await response.json() as { url?: string; transactionId?: string };
}

function request(body: unknown, authenticated = true) {
  return new Request('https://app.laterbox.dev/api/billing', {
    method: 'POST',
    headers: authenticated ? { Authorization: 'Bearer test-session' } : {},
    body: JSON.stringify(body),
  });
}

test('billing routes authenticate, scope subscriptions, and handle Paddle failures', async () => {
  const saved = { ...process.env };
  const originalFetch = globalThis.fetch;
  let mode = 'active';
  const paddleRequests: { path: string; body: any }[] = [];
  const subscriptionQueries: string[] = [];
  Object.assign(process.env, {
    SUPABASE_SERVICE_ROLE_KEY: 'test-service-key', PADDLE_API_KEY: 'test-api-key',
    NEXT_PUBLIC_PADDLE_ENV: 'production',
    NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD: 'pri_month',
    NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD: 'pri_year',
  });
  globalThis.fetch = async (input, init) => {
    const url = new URL(typeof input === 'string' ? input : input instanceof URL ? input.href : input.url);
    const json = (value: unknown, status = 200) => new Response(JSON.stringify(value), { status, headers: { 'Content-Type': 'application/json' } });
    if (url.pathname === '/auth/v1/user') return json({ id: 'user-123', email: 'buyer@example.com' });
    if (url.pathname.endsWith('/billing_customers')) return json(mode === 'no-customer' ? null : { customer_id: 'ctm_owned' });
    if (url.pathname.endsWith('/billing_subscriptions')) {
      subscriptionQueries.push(url.search);
      return json(mode === 'no-subscription' ? [] : [{ subscription_id: 'sub_owned', status: 'active', scheduled_change_action: mode === 'scheduled' ? 'cancel' : null }]);
    }
    if (url.hostname === 'api.paddle.com') {
      paddleRequests.push({ path: url.pathname, body: JSON.parse(String(init?.body)) });
      if (mode === 'paddle-failure') return json({ error: { detail: 'Provider unavailable' } }, 503);
      if (url.pathname === '/transactions') return json({ data: { id: 'txn_created' } });
      return json({ data: { urls: { general: { overview: 'https://customer-portal.paddle.com/overview' }, subscriptions: [{ id: 'sub_owned', view_subscription: 'https://customer-portal.paddle.com/manage', cancel_subscription: 'https://customer-portal.paddle.com/cancel' }] } } });
    }
    throw new Error(`Unexpected request: ${url.pathname}`);
  };
  try {
    assert.equal((await portal(request({}, false))).status, 401);
    assert.equal((await portal(request({ action: 'invalid' }))).status, 400);
    assert.equal((await portal(new Request('https://app.laterbox.dev/api/billing', { method: 'POST', headers: { Authorization: 'Bearer test-session' }, body: '{' }))).status, 400);
    assert.equal((await payload(await portal(request({})))).url, 'https://customer-portal.paddle.com/manage');
    assert.equal((await payload(await portal(request({ action: 'cancel', subscriptionId: 'sub_someone_else' })))).url, 'https://customer-portal.paddle.com/cancel');
    assert.deepEqual(paddleRequests.at(-1)?.body, { subscription_ids: ['sub_owned'] });
    assert.ok(subscriptionQueries.every((query) => query.includes('user_id=eq.user-123') && query.includes('customer_id=eq.ctm_owned') && query.includes('provider=eq.paddle')));
    mode = 'scheduled';
    assert.equal((await portal(request({ action: 'cancel' }))).status, 409);
    mode = 'no-subscription';
    assert.equal((await portal(request({ action: 'cancel' }))).status, 409);
    assert.equal((await payload(await portal(request({})))).url, 'https://customer-portal.paddle.com/overview');
    mode = 'no-customer';
    assert.equal((await portal(request({}))).status, 404);
    mode = 'paddle-failure';
    assert.equal((await portal(request({}))).status, 503);
    assert.equal((await checkout(request({ interval: 'month' }))).status, 503);
    mode = 'active';
    assert.equal((await checkout(request({ interval: 'week' }))).status, 400);
    assert.equal((await checkout(request({ interval: 'month' }, false))).status, 401);
    for (const interval of ['month', 'year']) {
      assert.equal((await payload(await checkout(request({ interval })))).transactionId, 'txn_created');
      assert.equal(paddleRequests.at(-1)?.body.items[0].price_id, `pri_${interval}`);
      assert.equal(paddleRequests.at(-1)?.body.custom_data.user_id, 'user-123');
    }
    process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD = '';
    process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID = '';
    assert.equal((await checkout(request({ interval: 'month' }))).status, 503);
  } finally {
    globalThis.fetch = originalFetch;
    for (const key of Object.keys(process.env)) if (!(key in saved)) delete process.env[key];
    Object.assign(process.env, saved);
  }
});
