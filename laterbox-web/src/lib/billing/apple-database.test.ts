import assert from 'node:assert/strict';
import test from 'node:test';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';

const user = '00000000-0000-4000-8000-000000000001';
const other = '00000000-0000-4000-8000-000000000002';
async function fixture() {
  const db = new PGlite();
  await db.exec(`create role authenticated; create role anon; create role service_role; create schema auth;
    create table auth.users(id uuid primary key); insert into auth.users values ('${user}'),('${other}');
    create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.sub',true),'')::uuid$$;
    create function auth.role() returns text language sql as $$select current_setting('request.role',true)$$;
    grant usage on schema auth to authenticated;`);
  for (const file of ['202609100001_create_billing_entitlements.sql', '202609100003_allow_service_entitlement_checks.sql', '202609100004_add_entitlement_phase_timing.sql', '202610120001_apple_subscription_sync.sql']) {
    await db.exec(await readFile(new URL(`../../../../supabase/migrations/${file}`, import.meta.url), 'utf8'));
  }
  await db.exec(`delete from billing_entitlement_grants; select set_config('request.sub','${user}',false); select set_config('request.role','authenticated',false);`);
  return db;
}
function subscription(overrides: Record<string, unknown> = {}) {
  const now = Date.now();
  return { provider: 'apple', subscription_id: 'original', customer_id: user, user_id: user,
    status: 'active', product_id: 'com.laterbox.pro.monthly', price_id: 'com.laterbox.pro.monthly',
    current_period_starts_at: new Date(now - 60_000).toISOString(), current_period_ends_at: new Date(now + 60_000).toISOString(),
    occurred_at: new Date(now).toISOString(), apple_environment: 'Sandbox', apple_transaction_id: 'transaction',
    apple_notification_at: null, revoked_at: null, renewal_known: false, ...overrides };
}
async function apply(db: PGlite, row: Record<string, unknown>, notification = false) {
  await db.query('select apply_apple_subscription($1::jsonb,$2)', [JSON.stringify(row), notification]);
}
async function pro(db: PGlite) {
  const rpc = (await db.query<{value: boolean}>('select has_pro_entitlement($1::uuid) as value', [user])).rows[0].value;
  const entitlement = (await db.query<{tier: string}>('select * from get_my_entitlement()')).rows[0].tier;
  assert.equal(rpc, entitlement === 'pro');
  return rpc;
}

test('Apple migration registers Sandbox/Production, expires access, and scopes RPC ownership', async () => {
  const db = await fixture();
  try {
    await apply(db, subscription());
    assert.equal(await pro(db), true);
    assert.equal((await db.query('select apple_environment from billing_subscriptions')).rows[0].apple_environment, 'Sandbox');
    assert.equal((await db.query<{value: boolean}>('select has_pro_entitlement($1::uuid) as value', [other])).rows[0].value, false);
    for (const status of ['active', 'trialing', 'canceled', 'past_due']) {
      await db.exec(`update billing_subscriptions set status='${status}',current_period_ends_at=now()-interval '1 second',past_due_at=now();`);
      assert.equal(await pro(db), false);
    }
    await apply(db, subscription({ subscription_id: 'production-original', apple_environment: 'Production' }));
    assert.equal(await pro(db), true);
    await assert.rejects(apply(db, subscription({ user_id: other, customer_id: other })), /ownership/);
    await assert.rejects(apply(db, subscription({ apple_environment: 'Production' })), /environment/);
    await db.exec('set role authenticated;');
    await assert.rejects(apply(db, subscription()), /permission denied/);
  } finally { await db.close(); }
});

test('Apple cancellation, grace and refund survive device replay and out-of-order notifications', async () => {
  const db = await fixture();
  try {
    const initial = subscription();
    await apply(db, initial);
    const time = Date.now();
    const notification = { ...initial, apple_notification_at: new Date(time + 1000).toISOString(), renewal_known: true, scheduled_change_action: 'cancel', scheduled_change_at: initial.current_period_ends_at };
    await apply(db, notification, true);
    await apply(db, { ...initial, occurred_at: new Date(time + 2000).toISOString() });
    assert.equal((await db.query('select will_cancel from get_my_entitlement()')).rows[0].will_cancel, true);
    await apply(db, { ...notification, apple_notification_at: new Date(time).toISOString(), scheduled_change_action: null }, true);
    assert.equal((await db.query('select will_cancel from get_my_entitlement()')).rows[0].will_cancel, true);
    const grace = { ...notification, status: 'past_due', apple_notification_at: new Date(time + 3000).toISOString(), past_due_at: new Date(time).toISOString() };
    await apply(db, grace, true);
    await apply(db, { ...initial, occurred_at: new Date(time + 4000).toISOString() });
    assert.equal((await db.query('select status from get_my_entitlement()')).rows[0].status, 'past_due');
    assert.equal(await pro(db), true);
    const refund = { ...notification, status: 'canceled', revoked_at: new Date(time).toISOString(), apple_notification_at: new Date(time + 5000).toISOString() };
    await apply(db, refund, true);
    await apply(db, { ...initial, occurred_at: new Date(time + 6000).toISOString() });
    assert.equal(await pro(db), false);
    // A later Apple refund reversal can restore the same transaction.
    await apply(db, { ...notification, apple_notification_at: new Date(time + 7000).toISOString() }, true);
    assert.equal(await pro(db), true);
    // A newer renewal wins over a later-delivered event for the previous period.
    const renewed = subscription({ apple_transaction_id: 'renewed', current_period_starts_at: new Date(time + 10000).toISOString(), current_period_ends_at: new Date(time + 120000).toISOString() });
    await apply(db, renewed);
    await apply(db, { ...refund, apple_notification_at: new Date(time + 15000).toISOString() }, true);
    assert.equal(await pro(db), true);
    assert.equal((await db.query('select apple_transaction_id from billing_subscriptions')).rows[0].apple_transaction_id, 'renewed');
  } finally { await db.close(); }
});
