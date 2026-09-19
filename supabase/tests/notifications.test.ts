import { PGlite } from 'npm:@electric-sql/pglite@0.3.14';
import { assertEquals, assertRejects } from 'jsr:@std/assert@1';

const a = '00000000-0000-4000-8000-000000000001';
const b = '00000000-0000-4000-8000-000000000002';
const origin = '00000000-0000-4000-8000-000000000010';
const other = '00000000-0000-4000-8000-000000000011';
const unrelated = '00000000-0000-4000-8000-000000000012';
async function fixture() {
  const db = new PGlite();
  await db.exec(`create role authenticated; create role anon; create role service_role;
    create schema auth; create table auth.users(id uuid primary key);
    insert into auth.users values('${a}'),('${b}');
    create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.sub',true),'')::uuid$$;
    create function auth.role() returns text language sql as $$select current_setting('request.role',true)$$;
    select set_config('request.sub','${a}',false); select set_config('request.role','service_role',false);
    create table public.eligible(user_id uuid primary key); insert into eligible values('${a}'),('${b}');
    create function public.has_pro_entitlement(target_user_id uuid) returns boolean language sql security definer as $$
      select (auth.role()='service_role' or auth.uid()=target_user_id) and exists(select 1 from eligible where user_id=target_user_id) $$;
    create table public.items(id uuid primary key,user_id uuid references auth.users(id),status text default 'deferred',
      created_at timestamptz default now(),updated_at timestamptz default now(),return_at timestamptz,deleted_at timestamptz,title text);`);
  await db.exec(await Deno.readTextFile(new URL('../migrations/202609190001_inbox_notifications.sql', import.meta.url)));
  for (const [id, user] of [[origin,a],[other,a],[unrelated,b]]) {
    await db.query(`insert into notification_installations(id,user_id,platform,transport,enabled,enabled_at) values($1,$2,'android','fcm',true,now()-interval '1 minute')`,[id,user]);
  }
  return db;
}
const claim = async (db: PGlite) => (await db.query<{ event_id: string; installation_id: string; item_id: string }>('select * from claim_notification_deliveries()')).rows;
Deno.test('arrival excludes source device and other accounts; metadata and retries do not duplicate', async () => {
  const db = await fixture();
  try {
    await db.query(`insert into items(id,user_id,status,origin_installation_id) values(gen_random_uuid(),$1,'inbox',$2)`,[a,origin]);
    const first = await claim(db); assertEquals(first.length,1); assertEquals(first[0].installation_id,other);
    assertEquals(await claim(db),[]);
    await db.exec(`update items set title='New metadata';`); assertEquals(await claim(db),[]);
    await db.exec(`update notification_deliveries set retry_at=now()-interval '1 second';`);
    const retry=await claim(db); assertEquals(retry.length,1); assertEquals(retry[0].event_id,first[0].event_id);
  } finally { await db.close(); }
});
Deno.test('history is silent; scheduled return invalidates on reschedule and archive', async () => {
  const db=await fixture();
  try {
    await db.query(`insert into items(id,user_id,status,created_at,return_at) values(gen_random_uuid(),$1,'inbox',now()-interval '2 days',now()-interval '1 day')`,[a]);
    assertEquals(await claim(db),[]);
    await db.query(`insert into items(id,user_id,return_at) values(gen_random_uuid(),$1,now()+interval '1 hour')`,[a]);
    await db.exec(`update items set return_at=now()+interval '2 hours' where status='deferred'; update notification_events set due_at=now();`);
    const result=await claim(db); assertEquals(result.length,2); assertEquals(new Set(result.map(x=>x.event_id)).size,1);
    await db.exec(`update items set status='archived'; update notification_deliveries set retry_at=now()-interval '1 second';`);
    assertEquals(await claim(db),[]);
    assertEquals((await db.query<{state: string}>(`select state from notification_deliveries`)).rows.every((r)=>r.state==='discarded'),true);
  } finally { await db.close(); }
});
Deno.test('permissions, entitlement loss and activation baseline prevent delivery', async () => {
  const db=await fixture();
  try {
    await db.query(`insert into items(id,user_id,status) values(gen_random_uuid(),$1,'inbox')`,[a]);
    await db.exec(`update notification_installations set enabled_at=now()+interval '1 minute';`);
    assertEquals(await claim(db),[]);
    await db.exec(`update notification_installations set enabled_at=now()-interval '1 minute',remote_saves=false;`);
    assertEquals(await claim(db),[]);
    await db.exec(`update notification_installations set remote_saves=true; delete from eligible;`);
    assertEquals(await claim(db),[]);
  } finally { await db.close(); }
});
Deno.test('clients cannot claim another device or replace another account registration', async () => {
  const db=await fixture();
  try {
    await db.exec(`select set_config('request.role','authenticated',false);`);
    await assertRejects(()=>db.query('select * from claim_notification_deliveries($1)',[unrelated]));
    await assertRejects(()=>db.query(`select register_notification_installation($1,'web','web')`,[unrelated]));
    await db.query(`select register_notification_installation($1,'linux','poll',null,null,true,true,true,'test-revocation-secret-with-sufficient-entropy')`,[origin]);
    await db.query(`insert into items(id,user_id,status) values(gen_random_uuid(),$1,'inbox')`,[a]);
    const polled=await db.query('select * from claim_notification_deliveries($1)',[origin]); assertEquals(polled.rows.length,1);
  } finally { await db.close(); }
});

Deno.test('a claimed delivery is invalidated by a last-moment archive or revoked preference', async () => {
  const db=await fixture();
  try {
    await db.query(`insert into items(id,user_id,status,origin_installation_id) values(gen_random_uuid(),$1,'inbox',$2)`,[a,origin]);
    const claimed=(await db.query<{event_id:string;installation_id:string;lease_id:string}>('select * from claim_notification_deliveries()')).rows[0];
    const params=[claimed.event_id,claimed.installation_id,claimed.lease_id];
    const current=async()=> (await db.query<{valid:boolean}>('select notification_delivery_is_current($1,$2,$3) valid',params)).rows[0].valid;
    assertEquals(await current(),true);
    await db.exec(`update notification_installations set remote_saves=false;`); assertEquals(await current(),false);
    await db.exec(`update notification_installations set remote_saves=true; update items set status='archived';`); assertEquals(await current(),false);
  } finally { await db.close(); }
});
Deno.test('poll acknowledgements require the correct device owner and current lease', async () => {
  const db=await fixture();
  try {
    await db.exec(`update notification_installations set transport='poll',platform='linux' where id='${other}';
      select set_config('request.role','authenticated',false);`);
    await db.query(`insert into items(id,user_id,status,origin_installation_id) values(gen_random_uuid(),$1,'inbox',$2)`,[a,origin]);
    const row=(await db.query<{event_id:string;installation_id:string;lease_id:string}>('select * from claim_notification_deliveries($1)',[other])).rows[0];
    await db.query('select ack_notification_delivery($1,$2,$3)',[row.event_id,other,origin]);
    assertEquals((await db.query<{state:string}>('select state from notification_deliveries')).rows[0].state,'sending');
    await db.query('select ack_notification_delivery($1,$2,$3)',[row.event_id,other,row.lease_id]);
    assertEquals((await db.query<{state:string}>('select state from notification_deliveries')).rows[0].state,'sent');
  } finally { await db.close(); }
});
