import assert from 'node:assert/strict';
import test from 'node:test';
import { createQueryRecovery, isFutureIssuedJwt } from './query-recovery';

const skew = { code: 'PGRST303', message: 'JWT issued at future' };
const failure = { data: null, error: skew };
const success = { data: ['item'], error: null };

 test('only future-issued JWT messages qualify for recovery', () => {
  assert.equal(isFutureIssuedJwt(skew), true);
  assert.equal(isFutureIssuedJwt({ code: 'PGRST303', message: 'JWT expired' }), false);
  assert.equal(isFutureIssuedJwt({ message: 'future network failure' }), false);
});

test('successful queries do not refresh or wait', async () => {
  const recover = createQueryRecovery(async () => { throw new Error('unexpected refresh'); });
  assert.deepEqual(await recover(async () => success), success);
});

test('refresh recovers a query and is shared across snapshot queries', async () => {
  let refreshes = 0;
  const waits: number[] = [];
  const recover = createQueryRecovery(async () => { refreshes++; return { error: null }; }, async ms => { waits.push(ms); });
  for (let i = 0; i < 6; i++) {
    let calls = 0;
    assert.deepEqual(await recover(async () => ++calls === 1 ? failure : success), success);
    assert.equal(calls, 2);
  }
  assert.equal(refreshes, 1);
  assert.deepEqual(waits, Array(6).fill(2500));
});

test('persistent skew stops after three retries and a new sync can recover', async () => {
  let calls = 0;
  let refreshes = 0;
  const waits: number[] = [];
  const recover = createQueryRecovery(async () => { refreshes++; return { error: null }; }, async ms => { waits.push(ms); });
  assert.deepEqual(await recover(async () => { calls++; return failure; }), failure);
  assert.equal(calls, 4);
  assert.equal(refreshes, 1);
  assert.deepEqual(waits, [2500, 2500, 2500]);
  const manualSync = createQueryRecovery(async () => ({ error: null }));
  assert.deepEqual(await manualSync(async () => success), success);
});

test('refresh failures and exceptions stop without further requests', async () => {
  for (const refresh of [async () => ({ error: new Error('failed') }), async () => { throw new Error('failed'); }]) {
    let calls = 0;
    const recover = createQueryRecovery(refresh, async () => assert.fail('unexpected wait'));
    assert.deepEqual(await recover(async () => { calls++; return failure; }), failure);
    assert.equal(calls, 1);
  }
});

test('unrelated authentication errors return immediately', async () => {
  const result = { data: null, error: { code: 'PGRST303', message: 'JWT expired' } };
  const recover = createQueryRecovery(async () => { throw new Error('unexpected refresh'); });
  assert.deepEqual(await recover(async () => result), result);
});
