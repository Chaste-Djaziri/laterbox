import assert from 'node:assert/strict';
import test from 'node:test';
import { safeReturnPath } from './config';

test('return destinations reject external URLs, backslash escapes and control characters', () => {
  for (const value of [null, 'https://attacker.example', '//attacker.example', '/\\attacker.example', '/\nattacker.example']) {
    assert.equal(safeReturnPath(value), '/inbox');
  }
  assert.equal(safeReturnPath('/extension/connect?request=123'), '/extension/connect?request=123');
});

