import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { PGlite } from '@electric-sql/pglite';
import { permanentlyDeleteCloudItem } from '../../../../supabase/functions/attachment-storage/permanent-delete';

test('permanent deletion removes every cloud attachment before database records', async () => {
  const calls: string[] = [];
  await permanentlyDeleteCloudItem('item', 'owner', {
    readItem: async () => ({ user_id: 'owner' }),
    readAttachments: async () => [{ id: 'one', r2_object_key: 'original' }, { id: 'two', r2_object_key: 'second' }],
    deleteFiles: async attachment => { calls.push(attachment.id); },
    deleteRecords: async () => { calls.push('database'); },
  });
  assert.deepEqual(calls, ['one', 'two', 'database']);
});

test('failed R2 cleanup preserves the database and a retry can finish', async () => {
  let fail = true;
  let deleted = false;
  const storage = {
    readItem: async () => ({ user_id: 'owner' }),
    readAttachments: async () => [{ id: 'one', r2_object_key: 'original' }],
    deleteFiles: async () => { if (fail) throw new Error('R2 unavailable'); },
    deleteRecords: async () => { deleted = true; },
  };
  await assert.rejects(permanentlyDeleteCloudItem('item', 'owner', storage));
  assert.equal(deleted, false);
  fail = false;
  await permanentlyDeleteCloudItem('item', 'owner', storage);
  assert.equal(deleted, true);
});

test('permanent deletion is idempotent and rejects another account', async () => {
  const noSideEffects = {
    readAttachments: async () => { throw new Error('Must not list attachments'); },
    deleteFiles: async () => { throw new Error('Must not delete files'); },
    deleteRecords: async () => { throw new Error('Must not delete records'); },
  };
  await permanentlyDeleteCloudItem('gone', 'owner', { ...noSideEffects, readItem: async () => null });
  await assert.rejects(permanentlyDeleteCloudItem('item', 'other', {
    ...noSideEffects, readItem: async () => ({ user_id: 'owner' }),
  }), /Unauthorized/);
});

test('database finalization removes related records atomically and is restricted to the service', async () => {
  const db = new PGlite();
  const item = '00000000-0000-4000-8000-000000000001';
  const owner = '00000000-0000-4000-8000-000000000002';
  const other = '00000000-0000-4000-8000-000000000003';
  try {
    await db.exec(`create role anon; create role authenticated; create role service_role;
      create schema auth;
      create table auth.users(id uuid primary key);
      insert into auth.users values('${owner}');
      create function auth.uid() returns uuid language sql as $$select '${owner}'::uuid$$;
      create table items(id uuid primary key,user_id uuid not null);
      create table attachments(id int primary key,item_id uuid references items(id),user_id uuid);
      create table item_metadata(item_id uuid references items(id) on delete cascade);
      create table blocked(item_id uuid references items(id));
      insert into items values('${item}','${owner}');
      insert into attachments values(1,'${item}','${owner}');
      insert into item_metadata values('${item}');
      insert into blocked values('${item}');`);
    await db.exec(readFileSync('../supabase/migrations/20261017230000_permanent_item_deletion.sql', 'utf8'));
    await db.exec(readFileSync('../supabase/migrations/20261017230100_permanent_deletion_receipts.sql', 'utf8'));
    const erase = (user = owner) => db.query('select finish_permanent_item_deletion($1,$2)', [item, user]);
    await assert.rejects(erase(other), /Unauthorized/);
    await assert.rejects(erase());
    assert.equal((await db.query('select * from attachments')).rows.length, 1);
    assert.equal((await db.query('select * from item_deletion_receipts')).rows.length, 0);
    await db.exec('delete from blocked');
    await erase();
    assert.equal((await db.query('select * from items')).rows.length, 0);
    assert.equal((await db.query('select * from attachments')).rows.length, 0);
    assert.equal((await db.query('select * from item_metadata')).rows.length, 0);
    assert.equal((await db.query('select * from item_deletion_receipts')).rows.length, 1);
    await assert.rejects(db.query('insert into items values($1,$2)', [item, owner]), /permanently deleted/);
    await erase();
    const access = await db.query<{ allowed: boolean }>("select has_function_privilege('authenticated', 'finish_permanent_item_deletion(uuid,uuid)', 'execute') as allowed");
    assert.equal(access.rows[0].allowed, false);
  } finally { await db.close(); }
});
