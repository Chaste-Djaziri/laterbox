import assert from 'node:assert/strict';
import test from 'node:test';
import { POST as verify } from '../../app/api/billing/apple/verify/route';
import { processAppleNotification, upsertAppleSubscription } from './process-apple';
const user = '00000000-0000-4000-8000-000000000001';
const transaction = { productId: 'com.laterbox.pro.monthly', originalTransactionId: 'original', transactionId: 'transaction', environment: 'Sandbox', appAccountToken: user, purchaseDate: Date.now() - 1000, expiresDate: Date.now() + 60_000, signedDate: Date.now() };

test('Apple registration persists environment, retries failed storage, and deduplicates notifications', async () => {
  const saved = { ...process.env };
  const originalFetch = globalThis.fetch;
  let mode = 'success';
  const requests: { path: string; body: any }[] = [];
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-key';
  globalThis.fetch = async (input, init) => {
    const url = new URL(typeof input === 'string' ? input : input instanceof URL ? input.href : input.url);
    requests.push({ path: url.pathname, body: init?.body ? JSON.parse(String(init.body)) : null });
    const json = (value: unknown, status = 200) => new Response(JSON.stringify(value), { status, headers: { 'Content-Type': 'application/json' } });
    if (url.pathname.endsWith('/billing_webhook_events') && !init?.body) return json(mode === 'duplicate' ? { event_id: 'event' } : null);
    if (url.pathname.endsWith('/rpc/apply_apple_subscription')) return mode === 'storage-failure' ? json({ message: 'database unavailable' }, 503) : json(null);
    if (url.pathname.endsWith('/billing_webhook_events')) return json(null);
    throw new Error(`Unexpected request ${url.pathname}`);
  };
  try {
    await upsertAppleSubscription(transaction);
    assert.equal(requests.at(-1)?.body.p_subscription.apple_environment, 'Sandbox');
    assert.equal(requests.at(-1)?.body.p_subscription.user_id, user);
    assert.equal(requests.at(-1)?.body.p_notification, false);
    const occurredAt = new Date().toISOString();
    await processAppleNotification('event', 'DID_RENEW', occurredAt, transaction, { autoRenewStatus: 1 });
    assert.equal(requests.at(-2)?.body.p_notification, true);
    assert.equal(requests.at(-2)?.body.p_subscription.apple_notification_at, occurredAt);
    mode = 'duplicate';
    requests.length = 0;
    await processAppleNotification('event', 'DID_RENEW', occurredAt, transaction, null);
    assert.equal(requests.length, 1);
    mode = 'storage-failure';
    requests.length = 0;
    await assert.rejects(processAppleNotification('failed-event', 'DID_RENEW', occurredAt, transaction, null));
    assert.ok(!requests.some((request) => request.path.endsWith('/billing_webhook_events') && request.body));
    mode = 'success';
    await processAppleNotification('failed-event', 'DID_RENEW', occurredAt, transaction, null);
    assert.equal(requests.at(-1)?.body.event_id, 'failed-event');
  } finally {
    globalThis.fetch = originalFetch;
    for (const key of Object.keys(process.env)) if (!(key in saved)) delete process.env[key];
    Object.assign(process.env, saved);
  }
});

test('Apple verification requires authentication and reports missing server configuration', async () => {
  const saved = { ...process.env };
  const originalFetch = globalThis.fetch;
  delete process.env.APPLE_ROOT_CERTIFICATES_BASE64;
  globalThis.fetch = async () => new Response(JSON.stringify({ id: user, email: 'buyer@example.com' }), { headers: { 'Content-Type': 'application/json' } });
  const request = (body: unknown, signedIn = true) => new Request('https://app.laterbox.dev/api/billing/apple/verify', { method: 'POST', headers: signedIn ? { Authorization: 'Bearer session' } : {}, body: JSON.stringify(body) });
  try {
    assert.equal((await verify(request({ signedTransaction: 'invalid' }, false))).status, 401);
    assert.equal((await verify(request({}))).status, 400);
    const response = await verify(request({ signedTransaction: 'invalid' }));
    assert.equal(response.status, 503);
    assert.equal(((await response.json()) as { code: string }).code, 'configuration_unavailable');
  } finally {
    globalThis.fetch = originalFetch;
    for (const key of Object.keys(process.env)) if (!(key in saved)) delete process.env[key];
    Object.assign(process.env, saved);
  }
});
