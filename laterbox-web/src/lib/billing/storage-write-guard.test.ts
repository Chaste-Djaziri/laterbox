// laterbox-web/src/lib/billing/storage-write-guard.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { assertStorageWritable, StorageFullError } from './storage-write-guard';

test('storage writes are allowed below quota, including an upload exactly fitting remaining bytes', () => {
  assert.doesNotThrow(() => assertStorageWritable(20, 100));
  assert.doesNotThrow(() => assertStorageWritable(20, 100, 80));
});

test('new changes stop at full quota, even for metadata-only saves', () => {
  assert.throws(() => assertStorageWritable(100, 100), StorageFullError);
  assert.throws(() => assertStorageWritable(120, 100), StorageFullError);
  assert.throws(() => assertStorageWritable(99, 100, 2), StorageFullError);
});

test('unavailable account usage is not mistaken for zero or full storage', () => {
  assert.doesNotThrow(() => assertStorageWritable(null, 100));
  assert.doesNotThrow(() => assertStorageWritable(12, null));
  assert.doesNotThrow(() => assertStorageWritable(0, -1));
});
