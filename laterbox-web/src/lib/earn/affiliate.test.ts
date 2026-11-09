// laterbox-web/src/lib/earn/affiliate.test.ts
import assert from 'node:assert/strict';
import {test} from 'node:test';
import {parseUsdCents} from './affiliate';

test('commission basis uses only verified USD Money objects',()=>{
  assert.equal(parseUsdCents({amount:'2.99',currency:'usd',decimals:2}),299);
  assert.equal(parseUsdCents({amount:'69.99',currency:'usd',decimals:2}),6999);
  assert.equal(parseUsdCents({amount:'0.01',currency:'usd',decimals:2}),1);
  assert.equal(parseUsdCents({amount:'2.9',currency:'usd',decimals:2}),290);
  assert.equal(parseUsdCents({amount:'-5',currency:'usd',decimals:2}),null);
  assert.equal(parseUsdCents({amount:'NaN',currency:'usd',decimals:2}),null);
  assert.equal(parseUsdCents({amount:'10',currency:'eur',decimals:2}),null);
  assert.equal(parseUsdCents({amount:10,currency:'usd',decimals:2}),null);
  assert.equal(parseUsdCents({amount:'5000000000',currency:'usd',decimals:2}),null);
});
