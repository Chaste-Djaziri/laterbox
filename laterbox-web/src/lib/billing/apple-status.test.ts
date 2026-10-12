import assert from 'node:assert/strict';
import test from 'node:test';
import { currentAppleSubscription, appleServerClient } from './apple-status';
import { appleSubscriptionState } from './apple';
import { Environment, type JWSTransactionDecodedPayload } from '@apple/app-store-server-library';

const now = Date.now();
const proof: JWSTransactionDecodedPayload = { productId: 'com.laterbox.pro.monthly', environment: Environment.SANDBOX, originalTransactionId: 'original', transactionId: 'old-transaction', appAccountToken: '00000000-0000-4000-8000-000000000003', signedDate: now, expiresDate: now + 60_000, purchaseDate: now - 1000 };
function dependencies(transaction = proof, status = 1, renewal = { originalTransactionId: 'original', autoRenewStatus: 0, signedDate: now + 1 }) {
  return {
    status: async (id: string, env: Environment) => {
      assert.equal(id, 'original'); assert.equal(env, Environment.SANDBOX);
      return { environment: Environment.SANDBOX, data: [{ lastTransactions: [{ originalTransactionId: 'original', signedTransactionInfo: 'apple-current', signedRenewalInfo: 'apple-renewal', status }] }] };
    },
    transaction: async () => transaction,
    renewal: async () => renewal,
  };
}

test('Connection uses current Apple state rather than the old trial receipt', async () => {
  const revoked = { ...proof, transactionId: 'current', revocationDate: now - 1, signedDate: now + 2 };
  const result = await currentAppleSubscription(proof, dependencies(revoked, 5));
  const state = appleSubscriptionState(result.transaction, result.renewal);
  assert.equal(state.status, 'canceled');
  assert.ok(Date.parse(state.periodEnd!) <= now);
  assert.equal(result.transaction.transactionId, 'current');
  const expired = await currentAppleSubscription(proof, dependencies({ ...proof, expiresDate: now - 1 }, 2));
  assert.equal(appleSubscriptionState(expired.transaction, expired.renewal).status, 'canceled');
  const canceled = await currentAppleSubscription(proof, dependencies());
  assert.equal(appleSubscriptionState(canceled.transaction, canceled.renewal).willCancel, true);
});

test('Connection rejects changed ownership, family sharing, and unknown latest state', async () => {
  await assert.rejects(currentAppleSubscription(proof, dependencies({ ...proof, appAccountToken: 'another-token' })), /another account/);
  await assert.rejects(currentAppleSubscription({ ...proof, inAppOwnershipType: 'FAMILY_SHARED' }, dependencies()), /purchaser/);
  await assert.rejects(currentAppleSubscription(proof, { ...dependencies(), status: async () => ({ environment: Environment.SANDBOX, data: [] }) }), /could not find/);
  await assert.rejects(currentAppleSubscription(proof, dependencies(proof, 5)), /revoked/);
});

test('Missing Apple server credentials prevent linking without changing local delivery', () => {
  const saved = process.env.APPLE_PRIVATE_KEY;
  delete process.env.APPLE_PRIVATE_KEY;
  try { assert.throws(() => appleServerClient(Environment.SANDBOX), /Device Pro is active/); }
  finally { if (saved !== undefined) process.env.APPLE_PRIVATE_KEY = saved; }
});
