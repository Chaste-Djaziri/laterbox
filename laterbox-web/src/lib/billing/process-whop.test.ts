import assert from 'node:assert/strict';
import { test } from 'node:test';
import { processWhopWebhook } from './process-whop';
import { whopServer } from './whop';

test('verified Whop payment links its plan only to the server-owned LaterBox checkout intent', async () => {
  const env = { ...process.env };
  const oldFetch = globalThis.fetch;
  Object.assign(process.env, {
    SUPABASE_SERVICE_ROLE_KEY: 'test-service',
    WHOP_COMPANY_API_KEY: 'test-company-api-key',
    WHOP_SANDBOX: 'true',
    WHOP_PLUS_MONTHLY_PLAN_ID: 'plan_laterboxPlus',
  });
  const sdk = whopServer();
  const paymentApi = sdk.payments as unknown as { retrieve: (args: { id: string }) => Promise<unknown> };
  const memberApi = sdk.memberships as unknown as { retrieve: (args: { id: string }) => Promise<unknown> };
  const realPayments = paymentApi.retrieve;
  const realMemberships = memberApi.retrieve;
  let mismatchedPlan = false;
  let persistedSubscription: Record<string, unknown> | null = null;
  const acknowledged = new Set<string>();
  let paidMembershipUpdates = 0;

  paymentApi.retrieve = async () => ({
    id: 'pay_test_01',
    substatus: 'succeeded',
    membership_id: 'mem_test_01',
    user: { id: 'user_whop_buyer' },
    plan_id: 'plan_laterboxPlus',
    metadata: { laterbox_intent_id: '00000000-0000-4000-8000-000000000123' },
    checkout_configuration_id: 'ch_test_01',
  });
  memberApi.retrieve = async () => ({
    id: 'mem_test_01',
    user_id: 'user_whop_buyer',
    plan_id: 'plan_laterboxPlus',
    product_id: 'prod_test',
    status: 'active',
    updated_at: new Date().toISOString(),
    current_period_start: new Date().toISOString(),
    current_period_end: new Date(Date.now() + 30 * 86_400_000).toISOString(),
    cancel_at_period_end: false,
  });

  globalThis.fetch = async (input, init) => {
    const url = new URL(typeof input === 'string' ? input : input instanceof URL ? input.href : input.url);
    const response = (data: unknown, code = 200) => new Response(JSON.stringify(data), {
      status: code, headers: { 'content-type': 'application/json' },
    });
    if (url.pathname.endsWith('/billing_webhook_events')) {
      if (init?.method === 'POST') {
        const row = JSON.parse(String(init.body)) as { event_id: string };
        acknowledged.add(row.event_id);
        return response({}, 201);
      }
      return response(acknowledged.has(url.searchParams.get('event_id')?.replace('eq.', '') ?? '') ? { event_id: 'evt_payment_1' } : null);
    }
    if (url.pathname.endsWith('/billing_checkout_intents')) {
      if (init?.method === 'PATCH') return response({}, 200);
      return response({
        user_id: 'laterbox_account_uuid',
        plan_id: mismatchedPlan ? 'plan_attacker' : 'plan_laterboxPlus',
        status: 'pending',
      });
    }
    if (url.pathname.endsWith('/billing_subscriptions')) {
      if (init?.method === 'POST') {
        paidMembershipUpdates++;
        persistedSubscription = JSON.parse(String(init.body)) as Record<string, unknown>;
        return response({}, 201);
      }
      return response(null);
    }
    if (url.pathname.endsWith('/billing_customers')) return response({}, 201);
    throw new Error('Unexpected test API request: ' + url.pathname);
  };
  try {
    const event = { id: 'evt_payment_1', type: 'payment.succeeded', data: { id: 'pay_test_01' } };
    assert.equal(await processWhopWebhook(event, 'evt_payment_1'), 'processed');
    assert.ok(persistedSubscription);
    const inserted = persistedSubscription as unknown as Record<string,unknown>;
    assert.equal(inserted.user_id, 'laterbox_account_uuid');
    assert.equal(inserted.customer_id, 'user_whop_buyer');
    assert.equal(inserted.storage_plan, 'plus');
    assert.equal(paidMembershipUpdates, 1);
    assert.equal(await processWhopWebhook(event, 'evt_payment_1'), 'duplicate');
    assert.equal(paidMembershipUpdates, 1);
    mismatchedPlan = true;
    await assert.rejects(
      processWhopWebhook({ id:'evt_payment_2',type:'payment.succeeded',data:{id:'pay_test_01'} }, 'evt_payment_2'),
      /checkout intent or plan mismatch/,
    );
    assert.equal(acknowledged.has('evt_payment_2'), false);
  } finally {
    paymentApi.retrieve = realPayments;
    memberApi.retrieve = realMemberships;
    globalThis.fetch = oldFetch;
    for (const key of Object.keys(process.env)) if (!(key in env)) delete process.env[key];
    Object.assign(process.env, env);
  }
});
