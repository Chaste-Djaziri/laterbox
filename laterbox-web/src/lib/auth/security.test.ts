import assert from 'node:assert/strict';
import test from 'node:test';
import { SignJWT, generateKeyPair, exportJWK } from 'jose';
import { safeReturnPath } from './config';
import { isClerkToken, verifyClerkSubject } from './server';
import { getRequestUser } from '../billing/server';

test('Clerk verification checks signature, expiry, issuer and frontend origin before mapping an account',async () => {
  const savedFetch = globalThis.fetch;
  const savedServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const { publicKey,privateKey } = await generateKeyPair('RS256');
  const publicJwk = { ...await exportJWK(publicKey),kid: 'test-auth',alg: 'RS256',use: 'sig' };
  let legacyCalls = 0;
  let identityCalls = 0;
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-key';
  globalThis.fetch = async (input) => {
    const url = new URL(typeof input === 'string' ? input : input instanceof URL ? input.href : input.url);
    if (url.hostname === 'clerk.laterbox.dev') return Response.json({ keys: [publicJwk] });
    if (url.pathname === '/auth/v1/user') { legacyCalls++; return Response.json({}, { status: 401 }); }
    if (url.pathname === '/rest/v1/account_identities') {
      identityCalls++;
      assert.equal(url.searchParams.get('subject'),'eq.user_test');
      return Response.json({ account_id: '00000000-0000-4000-8000-000000000001', accounts: { id: '00000000-0000-4000-8000-000000000001',email: 'test@example.com',display_name: 'Test',state: 'active' } });
    }
    throw new Error('Unexpected network request.');
  };
  const jwt = (claims: Record<string,unknown> = {}, key = privateKey) => new SignJWT({ sid: 'sess_test',azp: 'https://app.laterbox.dev', ...claims }).setProtectedHeader({ alg: 'RS256',kid: 'test-auth' }).setIssuer('https://clerk.laterbox.dev').setSubject('user_test').setIssuedAt().setExpirationTime('1m').sign(key);
  try {
    const token = await jwt();
    assert.equal(isClerkToken(token),true);
    assert.equal(await verifyClerkSubject(token),'user_test');
    const user = await getRequestUser(new Request('https://app.laterbox.dev/api/billing',{ headers: { Authorization: `Bearer ${token}` } }));
    assert.equal(user?.id,'00000000-0000-4000-8000-000000000001');
    assert.equal(legacyCalls,0);
    assert.equal(identityCalls,1);
    await assert.rejects(verifyClerkSubject(await jwt({ azp: 'https://attacker.example' })));
    const expired = await new SignJWT({ sid: 'sess_test',azp: 'https://app.laterbox.dev' }).setProtectedHeader({ alg: 'RS256',kid: 'test-auth' }).setIssuer('https://clerk.laterbox.dev').setSubject('user_test').setIssuedAt().setExpirationTime(1).sign(privateKey);
    await assert.rejects(verifyClerkSubject(expired));
    const wrongKey = await generateKeyPair('RS256');
    const forged = await jwt({},wrongKey.privateKey);
    assert.equal(await getRequestUser(new Request('https://app.laterbox.dev/api/billing',{ headers: { Authorization: `Bearer ${forged}` } })),null);
    assert.equal(identityCalls,1);
    assert.equal(legacyCalls,0);
    const wrongIssuer = await new SignJWT({ sid: 'sess_test',azp: 'https://app.laterbox.dev' }).setProtectedHeader({ alg: 'RS256',kid: 'test-auth' }).setIssuer('https://attacker.example').setSubject('user_test').setIssuedAt().setExpirationTime('1m').sign(privateKey);
    await assert.rejects(verifyClerkSubject(wrongIssuer));
    assert.equal(isClerkToken('invalid'),false);
  } finally {
    globalThis.fetch = savedFetch;
    if (savedServiceKey === undefined) delete process.env.SUPABASE_SERVICE_ROLE_KEY; else process.env.SUPABASE_SERVICE_ROLE_KEY = savedServiceKey;
  }
});
test('return destinations reject external URLs, backslash escapes and control characters',() => {
  for (const value of [null,'https://attacker.example','//attacker.example','/\\attacker.example','/\nattacker.example']) assert.equal(safeReturnPath(value),'/inbox');
  assert.equal(safeReturnPath('/extension/connect?request=123'),'/extension/connect?request=123');
});

test('getClerkUserEmail and getClerkDisplayName reliably extract verified email and name', async () => {
  const { getClerkUserEmail, getClerkDisplayName } = await import('./server');

  // Backend Clerk User with primary email
  const userWithPrimary = {
    firstName: 'Jane',
    lastName: 'Doe',
    primaryEmailAddressId: 'email_2',
    emailAddresses: [
      { id: 'email_1', emailAddress: 'secondary@example.com', verification: { status: 'unverified' } },
      { id: 'email_2', emailAddress: 'jane@example.com', verification: { status: 'verified' } },
    ],
  };
  assert.deepEqual(getClerkUserEmail(userWithPrimary), { emailAddress: 'jane@example.com', verified: true });
  assert.equal(getClerkDisplayName(userWithPrimary), 'Jane Doe');

  // Unverified primary email
  const unverifiedPrimary = {
    primaryEmailAddressId: 'email_1',
    emailAddresses: [
      { id: 'email_1', emailAddress: 'unverified@example.com', verification: { status: 'unverified' } },
    ],
  };
  assert.deepEqual(getClerkUserEmail(unverifiedPrimary), { emailAddress: 'unverified@example.com', verified: false });

  // Fallback to verified email if no primary ID
  const noPrimaryId = {
    emailAddresses: [
      { id: 'email_1', emailAddress: 'first@example.com', verification: { status: 'unverified' } },
      { id: 'email_2', emailAddress: 'verified@example.com', verification: { status: 'verified' } },
    ],
  };
  assert.deepEqual(getClerkUserEmail(noPrimaryId), { emailAddress: 'verified@example.com', verified: true });

  // Snake_case support from webhooks
  const snakeCaseUser = {
    first_name: 'Alex',
    primary_email_address_id: 'email_snake',
    email_addresses: [
      { id: 'email_snake', email_address: 'alex@example.com', verification: { status: 'verified' } },
    ],
  };
  assert.deepEqual(getClerkUserEmail(snakeCaseUser), { emailAddress: 'alex@example.com', verified: true });
  assert.equal(getClerkDisplayName(snakeCaseUser), 'Alex');
});

