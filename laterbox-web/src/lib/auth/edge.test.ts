import assert from 'node:assert/strict';
import test from 'node:test';
import { authenticateAccount } from '../../../../supabase/functions/_shared/auth';
const id = '00000000-0000-4000-8000-000000000001';
const token = `header.${Buffer.from(JSON.stringify({ iss: 'https://clerk.laterbox.dev',sub: 'user_test' })).toString('base64url')}.signature`;
test('Edge Clerk authentication relies on verified Supabase RPC identity, never Supabase user lookup',async () => {
  let mode = 'mapped';
  const options = { supabaseUrl: 'https://project.supabase.co',anonKey: 'public',fetch: (async (input,init) => {
    assert.equal(String(input),'https://project.supabase.co/rest/v1/rpc/current_account_id');
    assert.equal(init?.method,'POST');
    assert.equal((init?.headers as Record<string,string>).authorization,`Bearer ${token}`);
    return mode === 'invalid' ? Response.json({}, { status: 401 }) : Response.json(mode === 'mapped' ? id : null);
  }) as typeof fetch };
  assert.equal(await authenticateAccount(token,options),id);
  mode = 'unmapped'; assert.equal(await authenticateAccount(token,options),null);
  mode = 'invalid'; assert.equal(await authenticateAccount(token,options),null);
});
test('Edge legacy authentication preserves validated Supabase UUIDs',async () => {
  assert.equal(await authenticateAccount('legacy',{ supabaseUrl: 'https://project.supabase.co',anonKey: 'public',fetch: (async input => {
    assert.equal(String(input),'https://project.supabase.co/auth/v1/user');
    return Response.json({ id });
  }) as typeof fetch }),id);
});
