// laterbox-web/src/lib/earn/whop-connect.test.ts
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {newOAuthState,signOAuthState,verifyOAuthState} from './whop-connect';

const secret='test-signing-secret-at-least-32-chars-12345678';
const user='b9cb335c-047e-4c40-a2e8-fd8140e38ed5';

test('Whop connection state is bound to a specific LaterBox account',()=>{
  const payload=newOAuthState(user);
  const signed=signOAuthState(payload,secret);
  assert.deepEqual(verifyOAuthState(signed,secret),payload);
  assert.equal(verifyOAuthState(signed,secret+'tampered'),null);
  const corrupted=signed.replace(/.$/,'a');
  if(corrupted!==signed)assert.equal(verifyOAuthState(corrupted,secret),null);
});
test('expired Whop connection challenge never authorizes payout identity',()=>{
  const payload={...newOAuthState(user),created:Date.now()-720000};
  assert.equal(verifyOAuthState(signOAuthState(payload,secret),secret),null);
  assert.equal(verifyOAuthState('invalid',secret),null);
});
