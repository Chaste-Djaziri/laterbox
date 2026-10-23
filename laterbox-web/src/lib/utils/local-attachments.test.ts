import assert from 'node:assert/strict';
import test from 'node:test';
import { IDBFactory } from 'fake-indexeddb';
import { storeLocalAttachment, readLocalAttachment, deleteLocalAttachment } from './local-attachments';

test('browser attachment bytes remain scoped to the owning account', async () => {
  Object.defineProperty(globalThis, 'indexedDB', { configurable: true, value: new IDBFactory() });
  const own = await storeLocalAttachment(new File(['private'], 'secret.txt'), 'item-a', 'account-a');
  assert.equal((await readLocalAttachment(own.id, 'account-a'))?.name, 'secret.txt');
  assert.equal(await readLocalAttachment(own.id, 'account-b'), null);
  assert.equal(await readLocalAttachment(own.id, null), null);
  await deleteLocalAttachment(own.id);
  assert.equal(await readLocalAttachment(own.id, 'account-a'), null);
});

test('guest-owned file bytes cannot expose signed-in files', async () => {
  Object.defineProperty(globalThis, 'indexedDB', { configurable: true, value: new IDBFactory() });
  const guest = await storeLocalAttachment(new File(['guest'], 'guest.txt'), 'item-b', null);
  assert.equal((await readLocalAttachment(guest.id, null))?.name, 'guest.txt');
  // Guest files may be claimed during guest-to-account migration.
  assert.equal((await readLocalAttachment(guest.id, 'signed-in'))?.name, 'guest.txt');
});
