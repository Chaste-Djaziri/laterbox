/* Notifications only: no fetch handler or asset caching. */
const database = () => new Promise((resolve, reject) => {
  const request = indexedDB.open('laterbox-notifications', 1);
  request.onupgradeneeded = () => request.result.createObjectStore('state');
  request.onsuccess = () => resolve(request.result);
  request.onerror = () => reject(request.error);
});
async function read(key) {
  const db = await database();
  try { return await new Promise((resolve, reject) => {
    const request = db.transaction('state').objectStore('state').get(key);
    request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
  }); } finally { db.close(); }
}
async function write(key, value) {
  const db = await database();
  try { await new Promise((resolve, reject) => {
    const tx = db.transaction('state', 'readwrite'); tx.objectStore('state').put(value, key);
    tx.oncomplete = resolve; tx.onerror = () => reject(tx.error);
  }); } finally { db.close(); }
}
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
self.addEventListener('message', (event) => {
  if (event.data?.type === 'configure') event.waitUntil(write('account', event.data).then(() => event.ports[0]?.postMessage('saved')));
});
let deliveryQueue = Promise.resolve();
self.addEventListener('push', (event) => {
  deliveryQueue = deliveryQueue.catch(() => {}).then(async () => {
    const data = event.data?.json();
    const account = await read('account');
    if (!data?.event_id || !account?.preferences?.enabled || account.userId !== data.user_id) return;
    if (data.kind === 'return' ? !account.preferences.returns : !account.preferences.saves) return;
    const seen = await read('seen') || [];
    if (seen.includes(data.event_id)) return;
    await self.registration.showNotification('LaterBox', {
      body: data.kind === 'return' ? 'An item is ready in your inbox.' : 'An item was added to your inbox.',
      tag: data.event_id, data: { item_id: data.item_id, user_id: data.user_id },
    });
    await write('seen', [...seen.slice(-499), data.event_id]);
  });
  event.waitUntil(deliveryQueue);
});
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const data = event.notification.data || {};
    const account = await read('account');
    const item = account?.userId === data.user_id && /^[0-9a-f-]{36}$/i.test(data.item_id || '') ? data.item_id : null;
    const url = new URL(item ? `/inbox?notificationItem=${encodeURIComponent(item)}` : '/inbox', self.location.origin).href;
    const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    const existing = windows.find((client) => new URL(client.url).origin === self.location.origin);
    if (existing) { await existing.navigate(url); await existing.focus(); } else { await self.clients.openWindow(url); }
  })());
});
