import assert from 'node:assert/strict';
import test from 'node:test';
import { isDue, migrateSchedule, resolveReturnPreset, scheduleItems } from './schedule';
import { itemRow, queueCapture } from './pending-captures';
import type { LaterBoxItem } from '../supabase/types';

const now = new Date(2026, 8, 16, 23, 30);
const item = (id: string, time: Date | null, status: LaterBoxItem['status'] = 'deferred'): LaterBoxItem => ({
  id, user_id: 'a', type: 'task', favorite: false, status, return_at: time?.toISOString() ?? null,
  created_at: now.toISOString(), updated_at: now.toISOString(),
});
test('Inbox includes exact and overdue times but excludes future, Someday and completed items', () => {
  assert.equal(isDue(item('due', now), now), true);
  assert.equal(isDue(item('old', new Date(now.getTime() - 1000)), now), true);
  assert.equal(isDue(item('future', new Date(now.getTime() + 1)), now), false);
  assert.equal(isDue(item('someday', null), now), false);
  assert.equal(isDue(item('done', now, 'archived'), now), false);
  assert.equal(isDue({ ...item('deleted', now), deleted_at: now.toISOString() }, now), false);
});
test('presets preserve local 9 AM choices across midnight and next weekend', () => {
  assert.equal(resolveReturnPreset('now', now), now.toISOString());
  assert.equal(resolveReturnPreset('laterToday', now), new Date(now.getTime() + 3 * 3600000).toISOString());
  assert.equal(resolveReturnPreset('tomorrow', now), new Date(2026, 8, 17, 9).toISOString());
  assert.equal(resolveReturnPreset('weekend', now), new Date(2026, 8, 19, 9).toISOString());
  assert.equal(resolveReturnPreset('weekend', new Date(2026, 8, 19, 8)), new Date(2026, 8, 26, 9).toISOString());
  assert.equal(resolveReturnPreset('someday', now), null);
});
test('Today, Upcoming and Someday use the same active lifecycle', () => {
  const items = [item('today', now), item('tomorrow', new Date(2026, 8, 17, 9)), item('someday', null), item('done', now, 'archived')];
  assert.deepEqual(scheduleItems(items, 'today', now).map(i => i.id), ['today']);
  assert.deepEqual(scheduleItems(items, 'upcoming', now).map(i => i.id), ['tomorrow']);
  assert.deepEqual(scheduleItems(items, 'someday', now).map(i => i.id), ['someday']);
  assert.deepEqual(scheduleItems(items, 'today', new Date(2026, 8, 17)).map(i => i.id), ['tomorrow']);
});
test('legacy migration is idempotent and preserves saved and archived items', () => {
  const legacy = item('legacy', null, 'inbox');
  const migrated = migrateSchedule(legacy);
  assert.equal(migrated.status, 'deferred'); assert.equal(migrated.return_at, legacy.created_at);
  assert.equal(isDue(migrated, now), true); assert.deepEqual(migrateSchedule(migrated), migrated);
  for (const status of ['saved', 'archived'] as const) assert.deepEqual(migrateSchedule(item(status, null, status)), item(status, null, status));
});
test('cloud serialization includes schedule and supports clearing it', () => {
  const row = itemRow(item('timed', now));
  assert.equal(row.return_at, now.toISOString()); assert.equal(row.status, 'deferred');
  assert.equal(itemRow(item('someday', null)).return_at, null);
  assert.equal('attachments' in row, false);
});
test('offline capture queues are isolated per account and keep the latest reschedule', () => {
  const store = new Map<string, string>();
  const original = Object.getOwnPropertyDescriptor(globalThis, 'localStorage');
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem: (key: string) => store.get(key) ?? null,
    setItem: (key: string, value: string) => store.set(key, value),
  } });
  try {
    queueCapture(item('a-item', now));
    queueCapture({ ...item('b-item', null), user_id: 'b' });
    queueCapture({ ...item('a-item', null), updated_at: new Date(now.getTime() + 1000).toISOString() });
    const a = JSON.parse(store.get('laterbox_pending_captures_a')!);
    const b = JSON.parse(store.get('laterbox_pending_captures_b')!);
    assert.deepEqual(Object.keys(a), ['a-item']); assert.equal(a['a-item'].return_at, null);
    assert.deepEqual(Object.keys(b), ['b-item']);
    queueCapture({ ...item('guest', null), user_id: null }); assert.equal(store.size, 2);
  } finally {
    if (original) Object.defineProperty(globalThis, 'localStorage', original);
    else Reflect.deleteProperty(globalThis, 'localStorage');
  }
});
