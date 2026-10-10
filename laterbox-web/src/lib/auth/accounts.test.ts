import assert from 'node:assert/strict';
import test from 'node:test';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
const a = '00000000-0000-4000-8000-000000000001';
const b = '00000000-0000-4000-8000-000000000002';
async function fixture() {
  const db = new PGlite();
  await db.exec(`create role anon; create role authenticated; create role service_role;
    create schema auth; create schema storage;
    create table auth.users(id uuid primary key,email text,raw_user_meta_data jsonb default '{}',raw_app_meta_data jsonb default '{}',created_at timestamptz default now());
    create function auth.jwt() returns jsonb language sql stable as $$select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb$$;
    create function auth.uid() returns uuid language sql stable as $$select (auth.jwt()->>'sub')::uuid$$;
    create table items(id uuid primary key,user_id uuid references auth.users(id) on delete cascade);
    create table support_requests(id uuid primary key,user_id uuid references auth.users(id) on delete set null);
    create table storage.objects(id uuid primary key,owner_id text);
    alter table items enable row level security; alter table storage.objects enable row level security;
    grant usage on schema auth,storage to authenticated;
    grant select,insert,update,delete on items to authenticated;
    grant select on storage.objects to authenticated;
    create policy own_items on items to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
    create policy own_storage on storage.objects for select to authenticated using(owner_id=auth.uid()::text);
    create function public.legacy_default(target uuid default auth.uid()) returns uuid language sql stable as $$select target$$;
    insert into auth.users(id,email) values('${a}','a@example.com'),('${b}','b@example.com');
    insert into items values('${a}','${a}'),('${b}','${b}');
    insert into support_requests values('${a}','${a}');
    insert into storage.objects values('${a}','${a}'),('${b}','${b}');`);
  for (const file of ['202610100002_shared_auth_accounts.sql','202610100003_auth_provisioning_recovery.sql','202610100004_account_lifecycle.sql']) {
    await db.exec(await readFile(new URL(`../../../../supabase/migrations/${file}`,import.meta.url),'utf8'));
  }
  return db;
}
async function session(db: PGlite, issuer: string, sub: string) {
  await db.query("select set_config('request.jwt.claims',$1,false)",[JSON.stringify({ iss: issuer,sub,role: 'authenticated' })]);
  await db.exec('set role authenticated');
}
test('migration preserves UUIDs and isolates both providers through RLS and Storage',async () => {
  const db = await fixture();
  try {
    await db.exec(`select link_clerk_identity('${a}','user_a'); select link_clerk_identity('${b}','user_b');`);
    for (const [issuer,sub] of [['https://ltjisrgldssqskcylcbj.supabase.co/auth/v1',a],['https://clerk.laterbox.dev','user_a']]) {
      await session(db,issuer,sub);
      assert.deepEqual((await db.query('select * from items')).rows,[{ id: a,user_id: a }]);
      assert.deepEqual((await db.query('select id from storage.objects')).rows,[{ id: a }]);
      assert.deepEqual((await db.query('select legacy_default() as id')).rows,[{ id: a }]);
      await assert.rejects(db.query('insert into items values(gen_random_uuid(),$1)',[b]),/row-level security/);
      await assert.rejects(db.query('select * from account_identities'),/permission denied/);
      await assert.rejects(db.query('select link_clerk_identity($1,$2)',[b,'user_attack']),/permission denied/);
      await db.exec('reset role');
    }
    await db.exec(`insert into auth.users(id,email) values('00000000-0000-4000-8000-000000000003','new@example.com');`);
    assert.equal((await db.query('select count(*)::int as count from accounts')).rows[0].count,3);
  } finally { await db.close(); }
});
test('unknown issuer, unmapped subject and deleting account have no database access',async () => {
  const db = await fixture();
  try {
    await db.exec(`select link_clerk_identity('${a}','user_a');`);
    for (const [issuer,sub] of [['https://attacker.example',a],['https://clerk.laterbox.dev','user_unmapped'],['https://clerk.laterbox.dev',a]]) {
      await session(db,issuer,sub);
      assert.deepEqual((await db.query('select current_account_id() as id')).rows,[{ id: null }]);
      assert.deepEqual((await db.query('select * from items')).rows,[]);
      await db.exec('reset role');
    }
    await db.exec(`update accounts set state='deleting' where id='${a}'`);
    await session(db,'https://clerk.laterbox.dev','user_a');
    assert.deepEqual((await db.query('select * from items')).rows,[]);
  } finally { await db.close(); }
});
test('identity linking retries safely, rejects conflicts and cascades application data',async () => {
  const db = await fixture();
  try {
    await db.exec(`select link_clerk_identity('${a}','user_a'); select link_clerk_identity('${a}','user_a');`);
    await assert.rejects(db.exec(`select link_clerk_identity('${b}','user_a')`),/Identity conflict/);
    await assert.rejects(db.exec(`select link_clerk_identity('${a}','user_b')`),/unique constraint/);
    await assert.rejects(db.exec('select delete_user_account()'),/account deletion endpoint/);
    await db.exec(`delete from accounts where id='${a}'`);
    assert.deepEqual((await db.query('select * from items')).rows,[{ id: b,user_id: b }]);
    assert.deepEqual((await db.query('select user_id from support_requests')).rows,[{ user_id: null }]);
    assert.equal((await db.query("select count(*)::int as count from account_identities where subject='user_a'")).rows[0].count,0);
  } finally { await db.close(); }
});
test('provisioning recovery ignores user editable metadata',async () => {
  const db = await fixture();
  try {
    await db.exec(`update auth.users set raw_user_meta_data='{"clerk_provisioned_subject":"user_target"}' where id='${a}'`);
    assert.deepEqual((await db.query("select find_clerk_provisioned_account('user_target') as id")).rows,[{ id: null }]);
    await db.exec(`update auth.users set raw_app_meta_data='{"clerk_provisioned_subject":"user_target"}' where id='${b}'`);
    assert.deepEqual((await db.query("select find_clerk_provisioned_account('user_target') as id")).rows,[{ id: b }]);
  } finally { await db.close(); }
});
