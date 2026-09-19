import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { IDBFactory } from 'fake-indexeddb';

function worker() {
  const handlers = new Map<string, (event: unknown) => void>();
  const shown: { title: string; options: { tag: string; body: string; data: unknown } }[] = [];
  const opened: string[] = [];
  const self = {
    location: { origin: 'https://laterbox.dev' },
    addEventListener: (name: string, handler: (event: unknown) => void) => handlers.set(name, handler),
    registration: { showNotification: async (title: string, options: typeof shown[number]['options']) => { shown.push({ title, options }); } },
    clients: { matchAll: async () => [], openWindow: async (url: string) => { opened.push(url); } },
  };
  runInNewContext(readFileSync(new URL('../../../public/notifications-sw.js', import.meta.url), 'utf8'), { self, indexedDB: new IDBFactory(), URL });
  const dispatch = async (name: string, data: object) => {
    let work = Promise.resolve();
    handlers.get(name)!({ ...data, waitUntil: (promise: Promise<void>) => { work = promise; } });
    await work;
  };
  const configure = (userId: string | null, enabled = true) => dispatch('message', {
    data: { type: 'configure', userId, preferences: { enabled, returns: true, saves: true } }, ports: [],
  });
  const push = (eventId: string, userId = 'a', kind = 'return') => dispatch('push', {
    data: { json: () => ({ event_id: eventId, user_id: userId, kind, item_id: '00000000-0000-4000-8000-000000000001' }) },
  });
  return { shown, opened, configure, push, dispatch };
}
test('push retries and simultaneous events show one generic notification', async () => {
  const w = worker(); await w.configure('a');
  await Promise.all([w.push('event'), w.push('event')]);
  assert.equal(w.shown.length, 1);
  assert.equal(w.shown[0].title, 'LaterBox');
  assert.equal(w.shown[0].options.body, 'An item is ready in your inbox.');
  await w.push('next', 'a', 'save'); assert.equal(w.shown.length, 2);
});
test('logout, permission preferences and account changes suppress stale pushes', async () => {
  const w = worker(); await w.configure('a');
  await w.push('other', 'b'); assert.equal(w.shown.length, 0);
  await w.configure(null, false); await w.push('logged-out'); assert.equal(w.shown.length, 0);
  await w.configure('b'); await w.push('old-account'); assert.equal(w.shown.length, 0);
  await w.push('new-account', 'b'); assert.equal(w.shown.length, 1);
});
test('notification clicks use a checked inbox route and reject arbitrary URLs', async () => {
  const w = worker(); await w.configure('a');
  await w.dispatch('notificationclick', { notification: { close() {}, data: { user_id: 'a', item_id: '00000000-0000-4000-8000-000000000001' } } });
  assert.equal(w.opened[0], 'https://laterbox.dev/inbox?notificationItem=00000000-0000-4000-8000-000000000001');
  await w.dispatch('notificationclick', { notification: { close() {}, data: { user_id: 'a', item_id: 'https://evil.example' } } });
  assert.equal(w.opened[1], 'https://laterbox.dev/inbox');
});
