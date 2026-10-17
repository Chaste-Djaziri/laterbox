import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { PGlite } from '@electric-sql/pglite';

test('attachment publication commits all references together and rolls back an incomplete upload', async () => {
  const db = new PGlite();
  const owner = '00000000-0000-4000-8000-000000000001';
  const itemId = '00000000-0000-4000-8000-000000000002';
  const attachmentId = '00000000-0000-4000-8000-000000000003';
  try {
    await db.exec(`create role authenticated; create schema auth;
      create function auth.uid() returns uuid language sql as $$select '${owner}'::uuid$$;
      create table items(id uuid primary key,user_id uuid,title text,url text,text_content text,type text,
        favorite boolean,status text,return_at timestamptz,created_at timestamptz,updated_at timestamptz,deleted_at timestamptz);
      create table attachments(id uuid primary key,item_id uuid references items(id),user_id uuid,
        original_file_name text,file_extension text,mime_type text,byte_size bigint check(byte_size > 0),
        sha256 text,r2_object_key text,created_at timestamptz,updated_at timestamptz,deleted_at timestamptz);`);
    await db.exec(readFileSync('../supabase/migrations/20261017223000_publish_item_attachments.sql', 'utf8'));
    const item = { id: itemId, user_id: owner, title: 'Photo', type: 'image', status: 'inbox', favorite: false };
    const asset = { id: attachmentId, item_id: itemId, user_id: owner, original_file_name: 'photo.jpg',
      file_extension: 'jpg', mime_type: 'image/jpeg', byte_size: 10, sha256: 'a'.repeat(64),
      r2_object_key: `users/${owner}/attachments/${attachmentId}/original.jpg` };
    const publish = (assets: unknown[]) => db.query('select publish_item_attachments($1::jsonb,$2::jsonb)',
      [JSON.stringify(item), JSON.stringify(assets)]);
    await assert.rejects(publish([{ ...asset, r2_object_key: null }]));
    await assert.rejects(publish([{ ...asset, byte_size: 0 }]));
    assert.equal((await db.query('select * from items')).rows.length, 0);
    assert.equal((await db.query('select * from attachments')).rows.length, 0);
    await publish([asset]);
    assert.equal((await db.query('select * from items')).rows.length, 1);
    assert.equal((await db.query('select * from attachments')).rows.length, 1);
    await publish([asset]);
    assert.equal((await db.query('select * from attachments')).rows.length, 1);
  } finally { await db.close(); }
});
