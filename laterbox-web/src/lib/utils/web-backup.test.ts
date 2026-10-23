import assert from 'node:assert/strict';
import test from 'node:test';
import { webcrypto } from 'node:crypto';
import { createWebBackup, decryptWebBackup, encryptWebBackup, backupPreview, restoredAttachmentFile, isWebBackup } from './web-backup';
import type { LaterBoxItem } from '../supabase/types';

if (!globalThis.crypto) Object.defineProperty(globalThis, 'crypto', { value: webcrypto });
const makeItem = (id: string): LaterBoxItem => ({
  id, title: 'Research note', type: 'note', favorite: false, status: 'inbox',
  created_at: '2026-10-23T08:00:00Z', updated_at: '2026-10-23T08:00:00Z',
  return_at: null, inbox_entered_at: null,
});

test('encrypted web backup round-trips metadata, collections and file bytes', async () => {
  const item: LaterBoxItem = { ...makeItem('alpha'), attachments: [{
    id: 'file1', item_id: 'alpha', user_id: null, original_file_name: 'test.txt',
    file_extension: 'txt', mime_type: 'text/plain', byte_size: 5,
    created_at: '2026-10-23T08:00:00Z', updated_at: '2026-10-23T08:00:00Z',
  }] };
  const archive = await createWebBackup([item], [], [{
    id: 'col1', name: 'Reading', created_at: item.created_at, updated_at: item.updated_at,
  }], async () => new File(['hello'], 'test.txt', { type: 'text/plain' }));
  assert.equal(archive.format, 'laterbox-web-backup-v1');
  assert.equal(archive.unavailableAttachments.length, 0);
  const sealed = await encryptWebBackup(archive, 'safe-password123');
  assert.equal(new TextDecoder().decode(sealed).includes('Research note'), false);
  const opened = await decryptWebBackup(Uint8Array.from(sealed).buffer, 'safe-password123');
  assert.deepEqual(opened.items, [item]);
  assert.equal(opened.collections[0].name, 'Reading');
  assert.equal(await restoredAttachmentFile(opened, 'file1')?.text(), 'hello');
  assert.deepEqual(backupPreview(opened, new Set(['alpha'])).newItems, 0);
  assert.deepEqual(backupPreview(opened, new Set()).newItems, 1);
  await assert.rejects(() => decryptWebBackup(Uint8Array.from(sealed).buffer, 'wrong-password'), /Incorrect password/);
});
test('skips remote-only attachment bytes and reports incompleteness', async () => {
  const item = makeItem('remote');
  item.attachments = [{
    id: 'remote1', item_id: 'remote', original_file_name: 'remote.pdf', file_extension: 'pdf',
    mime_type: 'application/pdf', byte_size: 900, created_at: item.created_at,
    updated_at: item.updated_at, r2_object_key: 'remote-object',
  }];
  const archive = await createWebBackup([item], [], [], async () => null);
  assert.deepEqual(archive.unavailableAttachments, ['remote1']);
  assert.equal(restoredAttachmentFile(archive, 'remote1'), null);
});
test('rejects invalid schema, duplicate ids and unsupported formats', async () => {
  const item = makeItem('x');
  const archive = await createWebBackup([item], [], [], async () => null);
  assert.equal(isWebBackup(archive), true);
  assert.equal(isWebBackup({ ...archive, deletedItems: [item] }), false);
  assert.equal(isWebBackup({ ...archive, format: 'laterbox-encrypted-v1' }), false);
  await assert.rejects(() => encryptWebBackup(archive, 'short'), /8 characters/);
  const unsupported = new TextEncoder().encode(JSON.stringify({
    format: 'laterbox-encrypted-v1', salt: 'x', rounds: 250_000, sealed: 'x',
  }));
  await assert.rejects(() => decryptWebBackup(unsupported.buffer, 'safe-password123'), /iOS/);
});
