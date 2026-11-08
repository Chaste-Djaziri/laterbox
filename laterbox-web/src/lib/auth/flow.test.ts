// laterbox-web/src/lib/auth/flow.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { submitPasswordByMode, withAuthTimeout } from './flow';

test('login invokes sign-in without ever attempting account creation', async () => {
  let signInCalls = 0;
  let signUpCalls = 0;
  const result = await submitPasswordByMode(
    'login',
    async () => { signInCalls++; return { error: null }; },
    async () => { signUpCalls++; return { error: null, requiresConfirmation: true }; },
  );
  assert.deepEqual(result, { error: null });
  assert.equal(signInCalls, 1);
  assert.equal(signUpCalls, 0);
});

test('signup calls signup and retains verification requirements', async () => {
  let signInCalls = 0;
  const result = await submitPasswordByMode(
    'signup',
    async () => { signInCalls++; return { error: null }; },
    async () => ({ error: null, requiresConfirmation: true }),
  );
  assert.equal(result.requiresConfirmation, true);
  assert.equal(signInCalls, 0);
});

test('unreachable authentication endpoint produces a bounded failure', async () => {
  await assert.rejects(
    withAuthTimeout(new Promise<string>(() => {}), 5),
    /Authentication timed out/,
  );
});

test('authentication errors propagate without being hidden', async () => {
  await assert.rejects(
    withAuthTimeout(Promise.reject(new Error('Network unavailable')), 50),
    /Network unavailable/,
  );
});
