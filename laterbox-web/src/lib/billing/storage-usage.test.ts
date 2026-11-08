// laterbox-web/src/lib/billing/storage-usage.test.ts
import assert from 'node:assert/strict';
import test from 'node:test';
import { formatStorageBytes, getStorageUsage } from './storage-usage';

const quota = 500_000_000;

test('storage usage displays real values without treating missing measurements as zero', () => {
  const unknown = getStorageUsage(null, quota);
  assert.equal(unknown.level, 'unknown');
  assert.equal(unknown.percent, null);
  assert.equal(unknown.usedBytes, null);
  assert.equal(unknown.limitBytes, quota);
  assert.equal(getStorageUsage(0, quota).level, 'normal');
  assert.equal(getStorageUsage(0, 0).level, 'unknown');
  assert.equal(getStorageUsage(-1, quota).level, 'unknown');
});

test('warning, critical and full thresholds are inclusive and handle over-quota accounts', () => {
  assert.equal(getStorageUsage(quota * .799, quota).level, 'normal');
  assert.equal(getStorageUsage(quota * .8, quota).level, 'warning');
  assert.equal(getStorageUsage(quota * .95, quota).level, 'critical');
  assert.equal(getStorageUsage(quota - 1, quota).level, 'critical');
  assert.equal(getStorageUsage(quota, quota).level, 'full');
  const over = getStorageUsage(quota * 1.2, quota);
  assert.equal(over.level, 'full');
  assert.equal(over.percent, 120);
});

test('used and plan limit use readable decimal units, with no false 0 MB value', () => {
  assert.equal(formatStorageBytes(0), '0 MB');
  assert.equal(formatStorageBytes(500_000_000), '500 MB');
  assert.equal(formatStorageBytes(10 * 1024 ** 3), '10.74 GB');
  assert.equal(formatStorageBytes(750_000), '750 KB');
  assert.equal(formatStorageBytes(-1), 'Unavailable');
});
