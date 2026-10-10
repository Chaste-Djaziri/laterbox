import { createClerkClient } from '@clerk/backend';
import { createRemoteJWKSet, jwtVerify, decodeJwt } from 'jose';
import { CLERK_ISSUER, authorizedOrigins } from './config';
import { getBillingAdminClient } from '../billing/server';
import type { AccountUser } from './types';

const jwks = createRemoteJWKSet(new URL(`${CLERK_ISSUER}/.well-known/jwks.json`));
export class IdentityConflict extends Error {}
export function clerkAdmin() {
  if (!process.env.CLERK_SECRET_KEY) throw new Error('Clerk is not configured.');
  return createClerkClient({ secretKey: process.env.CLERK_SECRET_KEY });
}
export function isClerkToken(token: string): boolean {
  try { return decodeJwt(token).iss === CLERK_ISSUER; } catch { return false; }
}
export async function verifyClerkSubject(token: string): Promise<string> {
  const { payload } = await jwtVerify(token, jwks, { issuer: CLERK_ISSUER, algorithms: ['RS256'], requiredClaims: ['exp','iat','sub','sid','azp'] });
  if (!payload.sub?.startsWith('user_') || typeof payload.sid !== 'string' || !authorizedOrigins().includes(String(payload.azp))) {
    throw new Error('Invalid Clerk session.');
  }
  return payload.sub;
}
export async function mappedClerkUser(subject: string): Promise<AccountUser | null> {
  const admin = getBillingAdminClient();
  const { data, error } = await admin.from('account_identities').select('account_id,accounts!inner(id,email,display_name,state)').eq('provider','clerk').eq('subject',subject).maybeSingle();
  if (error) throw error;
  const account = data?.accounts as unknown as { id: string; email: string | null; display_name: string | null; state: string } | undefined;
  if (!account || account.state !== 'active') return null;
  return { id: account.id, email: account.email ?? undefined, user_metadata: { display_name: account.display_name ?? undefined } };
}
export async function linkClerk(accountId: string, subject: string) {
  const { error } = await getBillingAdminClient().rpc('link_clerk_identity', { p_account_id: accountId, p_subject: subject });
  if (error) throw new IdentityConflict('This identity is already linked to another account.');
}
export async function ensureClerkAccount(subject: string): Promise<AccountUser> {
  const existing = await mappedClerkUser(subject);
  if (existing) return existing;
  const user = await clerkAdmin().users.getUser(subject);
  const admin = getBillingAdminClient();
  // externalId is assigned only by privileged migration tooling, never browser metadata.
  if (user.externalId) {
    const { data } = await admin.from('accounts').select('id').eq('id',user.externalId).maybeSingle();
    if (!data) throw new IdentityConflict('The migrated account is unavailable.');
    await linkClerk(data.id,subject);
  } else {
    const email = user.primaryEmailAddress;
    if (!email || email.verification?.status !== 'verified') throw new IdentityConflict('Verify your primary email before opening the app.');
    // The Supabase admin API refuses an existing email. Never merge on email alone.
    const { data, error } = await admin.auth.admin.createUser({ email: email.emailAddress, email_confirm: true, user_metadata: { display_name: user.fullName }, app_metadata: { clerk_provisioned_subject: subject } });
    if (error || !data.user) {
      // Recover only an account previously provisioned for this exact Clerk identity.
      const { data: recovered, error: recoveryError } = await admin.rpc('find_clerk_provisioned_account', { p_subject: subject });
      if (recoveryError || !recovered) throw new IdentityConflict('Sign in to your existing Supabase account to link it securely.');
      await linkClerk(recovered,subject);
    } else {
      await linkClerk(data.user.id,subject);
    }
  }
  const result = await mappedClerkUser(subject);
  if (!result) throw new Error('Account provisioning is incomplete. Please retry.');
  return result;
}
