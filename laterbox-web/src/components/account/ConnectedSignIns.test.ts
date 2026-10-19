import assert from 'node:assert/strict';
import { test } from 'node:test';
import { connectionResult } from './ConnectedSignIns';

test('connection succeeds only for the original LaterBox user with the requested provider', () => {
  assert.match(connectionResult({ provider: 'google', userId: 'original' }, 'original', [{ provider: 'google', email: 'a@example.com' }]), /Google is connected/);
  assert.match(connectionResult({ provider: 'apple', userId: 'original' }, 'original', [{ provider: 'apple' }]), /Apple is connected/);
  assert.match(connectionResult({ provider: 'google', userId: 'original' }, 'other', [{ provider: 'google' }]), /account changed/);
  assert.match(connectionResult({ provider: 'apple', userId: 'original' }, 'original', [{ provider: 'google' }]), /Could not connect Apple/);
});
