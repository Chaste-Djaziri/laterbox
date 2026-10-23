import assert from 'node:assert/strict';
import test from 'node:test';
import { isDue, migrateSchedule, resolveReturnPreset, scheduleItems, todayFocusItems, formatInboxAge, transitionItemStatus, moveItemToInbox, restoreItemToInbox, scheduleItemReturn } from './schedule';
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
  assert.deepEqual(scheduleItems(items, 'today', new Date(2026, 8, 17)).map(i => i.id), ['today', 'tomorrow']);
});
test('Today divides overdue and returning today at local-midnight boundaries', () => {
  const localNow = new Date(2026, 9, 25, 8, 15);
  const items = [
    item('old', new Date(2026, 9, 23, 23, 59)),
    item('yesterday', new Date(2026, 9, 24, 23, 59)),
    item('midnight', new Date(2026, 9, 25, 0, 0)),
    item('later-today', new Date(2026, 9, 25, 20, 30)),
    item('tomorrow', new Date(2026, 9, 26, 0, 0)),
    item('unplanned', null),
    item('legacy-inbox', null, 'inbox'),
    item('kept', new Date(2026, 9, 24), 'saved'),
    { ...item('deleted', new Date(2026, 9, 24)), deleted_at: localNow.toISOString() },
    item('invalid-date', null),
  ];
  items[9].return_at = 'not-a-date';
  const focus = todayFocusItems(items, localNow);
  assert.deepEqual(focus.overdue.map(i => i.id), ['old', 'yesterday']);
  assert.deepEqual(focus.returningToday.map(i => i.id), ['midnight', 'later-today']);
  assert.deepEqual(scheduleItems(items, 'today', localNow).map(i => i.id), ['old', 'yesterday', 'midnight', 'later-today']);
  assert.deepEqual(scheduleItems(items, 'upcoming', localNow).map(i => i.id), ['tomorrow']);
});
test('Today uses calendar boundaries even on daylight saving transition', () => {
  const now = new Date(2026, 9, 25, 12);
  const nextDay = new Date(2026, 9, 26, 0);
  const before = new Date(nextDay.getTime() - 1000);
  const focus = todayFocusItems([item('last-second', before), item('next-day', nextDay)], now);
  assert.deepEqual(focus.returningToday.map(i => i.id), ['last-second']);
});
test('Inbox age is only displayed for known current Inbox history', () => {
  const current = new Date('2026-10-23T09:10:00Z');
  const inbox = { ...item('recent', null, 'inbox'), inbox_entered_at: '2026-10-23T07:00:00Z' };
  assert.equal(formatInboxAge(inbox, current), 'In Inbox for 2 hrs, 10 min');
  assert.equal(formatInboxAge({ ...inbox, inbox_entered_at: '2026-10-23T09:09:45Z' }, current), 'Just entered Inbox');
  assert.equal(formatInboxAge({ ...inbox, inbox_entered_at: null }, current), null);
  assert.equal(formatInboxAge({ ...inbox, inbox_entered_at: 'bad-date' }, current), null);
  assert.equal(formatInboxAge({ ...inbox, inbox_entered_at: '2026-10-24T00:00:00Z' }, current), null);
  assert.equal(formatInboxAge({ ...inbox, status: 'deferred' }, current), null);
});
test('legacy Inbox without return schedule is never silently rewritten', () => {
  const legacy = item('legacy', null, 'inbox');
  const migrated = migrateSchedule(legacy);
  assert.equal(migrated.status, 'inbox');
  assert.equal(migrated.return_at, null);
  assert.equal(isDue(migrated, now), true);
  assert.deepEqual(migrateSchedule(migrated), legacy);
  for (const status of ['saved', 'archived'] as const) assert.deepEqual(migrateSchedule(item(status, null, status)), item(status, null, status));
});

test('Inbox entry is recorded on actual transition, not on ordinary edits', () => {
  const earlier = '2026-09-15T10:00:00.000Z';
  const later = '2026-09-16T10:00:00.000Z';
  const deferred = { ...item('return', new Date(later)), inbox_entered_at: earlier };
  const inInbox = transitionItemStatus(deferred, 'inbox', later);
  assert.equal(inInbox.inbox_entered_at, later);
  assert.equal(inInbox.status, 'inbox');
  assert.equal(transitionItemStatus(inInbox, 'inbox', '2026-09-16T11:00:00.000Z').inbox_entered_at, later);
  const kept = transitionItemStatus(inInbox, 'saved', '2026-09-16T12:00:00.000Z');
  assert.equal(kept.inbox_entered_at, later);
  const rescheduled = scheduleItemReturn(inInbox, null, later);
  assert.equal(rescheduled.status, 'deferred');
  assert.equal(rescheduled.return_at, null);
  assert.equal(rescheduled.inbox_entered_at, later);
});

test('restore from deleted resets Inbox entry and leaves legacy historical data unknown', () => {
  const restoredAt = '2026-09-16T22:00:00.000Z';
  const deleted = { ...item('deleted', null, 'inbox'), inbox_entered_at: '2026-09-01T08:00:00.000Z', deleted_at: '2026-09-15T20:00:00.000Z' };
  const restored = restoreItemToInbox(deleted, restoredAt);
  assert.equal(restored.inbox_entered_at, restoredAt);
  assert.equal(restored.deleted_at, null);
  assert.equal(restored.updated_at, restoredAt);
  const legacy = item('old', null, 'inbox');
  assert.equal(migrateSchedule(legacy).inbox_entered_at, undefined);
  assert.equal(transitionItemStatus(legacy, 'inbox', restoredAt).inbox_entered_at, null);
});
test('Move to Inbox clears old return and seen state without losing metadata', () => {
  const timestamp = '2026-10-23T09:00:00Z';
  const deferred = {
    ...item('archive-return', new Date(2026, 9, 19), 'archived'),
    seen: true,
    inbox_entered_at: '2026-09-01T09:00:00Z',
    metadata: {
      item_id: 'archive-return', status: 'enriched' as const, attempt_count: 1,
      created_at: '2026-08-01T09:00:00Z', updated_at: '2026-10-01T09:00:00Z',
      structured_data: JSON.stringify({ source: 'web', tags: ['science'], seen: true }),
    },
  };
  const moved = moveItemToInbox(deferred, timestamp);
  assert.equal(moved.status, 'inbox');
  assert.equal(moved.return_at, null);
  assert.equal(moved.inbox_entered_at, timestamp);
  assert.equal(moved.seen, false);
  assert.deepEqual(JSON.parse(moved.metadata!.structured_data!), { source: 'web', tags: ['science'], seen: false });
  assert.equal(moved.metadata!.updated_at, timestamp);
  assert.equal(moveItemToInbox(moved, '2026-10-23T10:00:00Z').inbox_entered_at, timestamp);
});

test('cloud serialization includes schedule and supports clearing it', () => {
  const row = itemRow(item('timed', now));
  assert.equal(row.return_at, now.toISOString()); assert.equal(row.status, 'deferred');
  assert.equal(itemRow(item('someday', null)).return_at, null);
  assert.equal(row.inbox_entered_at, null);
  assert.equal('attachments' in row, false);
  assert.equal(itemRow({ ...item('entered', null, 'inbox'), inbox_entered_at: now.toISOString() }).inbox_entered_at, now.toISOString());
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
    queueCapture({ ...item('a-item', null), inbox_entered_at: now.toISOString(), updated_at: new Date(now.getTime() + 1000).toISOString() });
    const a = JSON.parse(store.get('laterbox_pending_captures_a')!);
    const b = JSON.parse(store.get('laterbox_pending_captures_b')!);
    assert.deepEqual(Object.keys(a), ['a-item']); assert.equal(a['a-item'].return_at, null);
    assert.equal(a['a-item'].inbox_entered_at, now.toISOString());
    assert.deepEqual(Object.keys(b), ['b-item']);
    queueCapture({ ...item('guest', null), user_id: null }); assert.equal(store.size, 2);
  } finally {
    if (original) Object.defineProperty(globalThis, 'localStorage', original);
    else Reflect.deleteProperty(globalThis, 'localStorage');
  }
});
