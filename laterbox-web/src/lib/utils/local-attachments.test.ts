import assert from 'node:assert/strict';
import test from 'node:test';
import { IDBFactory } from 'fake-indexeddb';
import { storeLocalAttachment, readLocalAttachment, deleteLocalAttachment } from './local-attachments';

test('browser attachment bytes remain scoped to the owning account', async () => {
  Object.defineProperty(globalThis, 'indexedDB', { configurable: true, value: new IDBFactory() });
  const own = await storeLocalAttachment(new File(['private'], 'secret.txt'), 'item-a', 'account-a');
  const recovered = await readLocalAttachment(own.id, 'account-a');
  assert.equal(recovered?.name, 'secret.txt');
  assert.equal(recovered?.type, 'application/octet-stream');
  assert.equal(await recovered?.text(), 'private');
  assert.equal(own.original_file_name, 'secret.txt');
  assert.equal(await readLocalAttachment(own.id, 'account-b'), null);
  assert.equal(await readLocalAttachment(own.id, null), null);
  await deleteLocalAttachment(own.id);
  assert.equal(await readLocalAttachment(own.id, 'account-a'), null);
});

test('guest-owned file bytes cannot expose signed-in files', async () => {
  Object.defineProperty(globalThis, 'indexedDB', { configurable: true, value: new IDBFactory() });
  const guest = await storeLocalAttachment(new File(['guest'], 'guest.txt'), 'item-b', null);
  const guestFile = await readLocalAttachment(guest.id, null);
  assert.equal(guestFile?.name, 'guest.txt');
  assert.equal(await guestFile?.text(), 'guest');
  // Guest files may be claimed during guest-to-account migration.
  const claimed = await readLocalAttachment(guest.id, 'signed-in');
  assert.equal(claimed?.name, 'guest.txt');
  assert.equal(await claimed?.text(), 'guest');
});

test('legacy IndexedDB attachments without filename metadata retain readable bytes', async () => {
  Object.defineProperty(globalThis, 'indexedDB', { configurable: true, value: new IDBFactory() });
  const db = await new Promise<IDBDatabase>((resolve, reject) => {
    const request = indexedDB.open('laterbox-files', 1);
    request.onupgradeneeded = () => request.result.createObjectStore('files', { keyPath: 'id' });
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  try {
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction('files', 'readwrite');
      tx.objectStore('files').put({ id: 'legacy-file', userId: 'account-a', file: new Blob(['older bytes'], { type: 'text/plain' }) });
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  } finally {
    db.close();
  }
  const original = await readLocalAttachment('legacy-file', 'account-a');
  assert.equal(await original?.text(), 'older bytes');
  assert.equal(original?.type, 'text/plain');
  assert.equal(await readLocalAttachment('legacy-file', 'account-b'), null);
});
