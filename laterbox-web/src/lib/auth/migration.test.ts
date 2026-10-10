import assert from 'node:assert/strict';
import test from 'node:test';
import { SignJWT, generateKeyPair, exportJWK } from 'jose';

test('migration verifies legacy sessions, retries without duplicates and requires proof for existing Clerk accounts',async () => {
  const savedEnv = { ...process.env };
  const savedFetch = globalThis.fetch;
  process.env.NEXT_PUBLIC_CLERK_AUTH_ENABLED = 'true';
  process.env.CLERK_SECRET_KEY = 'sk_test_fixture';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-key';
  const { POST } = await import('../../app/api/auth/migrate/route');
  const id = '00000000-0000-4000-8000-000000000001';
  let mode = 'valid';
  let linked: string | null = null;
  let created = 0;
  let tickets = 0;
  const requests: string[] = [];
  const { privateKey,publicKey } = await generateKeyPair('RS256');
  const jwk = { ...await exportJWK(publicKey),kid: 'migration-test',alg: 'RS256',use: 'sig' };
  const rawUser = (subject = 'user_migrated') => ({ object: 'user',id: subject,external_id: subject === 'user_existing' ? null : id,first_name: 'Test',email_addresses: [],phone_numbers: [],web3_wallets: [],external_accounts: [],passkeys: [],saml_accounts: [],public_metadata: {},private_metadata: {},unsafe_metadata: {},two_factor_enabled: mode === 'clerk-mfa',banned: false,locked: false });
  globalThis.fetch = async (input,init) => {
    const request = new Request(input,init);
    const url = new URL(request.url);
    requests.push(`${request.method} ${url.hostname}${url.pathname}`);
    if (url.hostname === 'clerk.laterbox.dev') return Response.json({ keys: [jwk] });
    if (url.pathname === '/auth/v1/user') return mode === 'expired' ? Response.json({ message: 'Expired' },{ status: 401 }) : Response.json({ id,email: 'test@example.com',email_confirmed_at: mode === 'unconfirmed' ? null : new Date().toISOString(),user_metadata: {},factors: mode === 'legacy-mfa' ? [{ status: 'verified' }] : [] });
    if (url.pathname === '/rest/v1/account_identities') return Response.json(linked ? { subject: linked } : null);
    if (url.pathname === '/rest/v1/rpc/link_clerk_identity') {
      const body = await request.json() as { p_account_id: string; p_subject: string };
      assert.equal(body.p_account_id,id);
      linked = body.p_subject;
      return Response.json(null);
    }
    if (url.hostname === 'api.clerk.com') {
      if (url.pathname === '/v1/users/count') return Response.json({ object: 'total_count',total_count: 0 });
      if (url.pathname === '/v1/users' && request.method === 'GET') return Response.json([]);
      if (url.pathname === '/v1/users' && request.method === 'POST') {
        if (mode === 'email-conflict') return Response.json({ errors: [{ code: 'form_identifier_exists',message: 'Identifier exists' }] },{ status: 422 });
        const body = await request.json() as Record<string,unknown>;
        assert.equal(body.external_id,id);
        assert.deepEqual(body.email_address_identification_status,['verified']);
        created++;
        return Response.json(rawUser());
      }
      if (url.pathname.startsWith('/v1/users/')) return Response.json(rawUser(url.pathname.split('/').at(-1)));
      if (url.pathname === '/v1/sign_in_tokens') {
        assert.equal((await request.json() as { expires_in_seconds: number }).expires_in_seconds,60);
        tickets++;
        return Response.json({ object: 'sign_in_token',id: 'sit_test',user_id: linked,token: 'single-use-ticket',status: 'pending' });
      }
    }
    throw new Error('Unexpected network request.');
  };
  const request = (proof?: string,origin = 'https://app.laterbox.dev') => new Request('https://app.laterbox.dev/api/auth/migrate',{ method: 'POST',headers: { Origin: origin,Authorization: 'Bearer legacy',...(proof ? { 'X-Clerk-Token': proof } : {}) },body: JSON.stringify({ accountId: 'attacker-ignored' }) });
  try {
    assert.equal((await POST(request(undefined,'https://attacker.example'))).status,403);
    mode = 'expired'; assert.equal((await POST(request())).status,401);
    mode = 'unconfirmed'; assert.equal((await POST(request())).status,409);
    mode = 'legacy-mfa'; assert.equal((await POST(request())).status,409);
    mode = 'valid';
    for (let i = 0; i < 2; i++) {
      const response = await POST(request());
      assert.equal(response.status,200,requests.join("; "));
      assert.equal(response.headers.get('cache-control'),'no-store');
      assert.deepEqual(await response.json(),{ ticket: 'single-use-ticket' });
    }
    assert.equal(created,1); assert.equal(tickets,2);
    linked = null; mode = 'email-conflict'; assert.equal((await POST(request())).status,409);
    assert.equal(linked,null);
    mode = 'valid';
    const proof = await new SignJWT({ sid: 'sess_test',azp: 'https://app.laterbox.dev' }).setProtectedHeader({ alg: 'RS256',kid: 'migration-test' }).setIssuer('https://clerk.laterbox.dev').setSubject('user_existing').setIssuedAt().setExpirationTime('1m').sign(privateKey);
    const response = await POST(request(proof));
    assert.equal(response.status,200,requests.join("; ")); assert.deepEqual(await response.json(),{ linked: true });
    assert.equal(linked,'user_existing'); assert.equal(tickets,2);
    mode = 'clerk-mfa'; assert.equal((await POST(request())).status,409);
  } finally {
    globalThis.fetch = savedFetch;
    for (const key of Object.keys(process.env)) if (!(key in savedEnv)) delete process.env[key];
    Object.assign(process.env,savedEnv);
  }
});
