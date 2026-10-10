import { createClient } from '@supabase/supabase-js';
import { clerkAdmin, verifyClerkSubject, linkClerk, IdentityConflict } from '@/lib/auth/server';
import { clerkAuthEnabled, authorizedOrigins } from '@/lib/auth/config';
import { getBillingAdminClient } from '@/lib/billing/server';

export async function POST(request: Request) {
  const headers = { 'Cache-Control': 'no-store' };
  if (!clerkAuthEnabled) return Response.json({ error: 'Migration is disabled.' },{ status: 503, headers });
  const origin = request.headers.get('origin');
  const host = request.headers.get('host');
  const allowed = authorizedOrigins();
  const isTrusted = origin ? allowed.includes(origin) : host ? allowed.some(a => a.endsWith(`://${host}`)) : true;
  if (!isTrusted) return Response.json({ error: 'Untrusted origin.' },{ status: 403, headers });
  const token = request.headers.get('authorization')?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return Response.json({ error: 'Sign in to your existing account.' },{ status: 401, headers });
  const legacy = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ltjisrgldssqskcylcbj.supabase.co',process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p', { auth: { persistSession: false } });
  const { data: { user }, error } = await legacy.auth.getUser(token);
  if (error || !user) return Response.json({ error: 'Your existing session has expired.' },{ status: 401, headers });
  if (user.factors?.some(factor => factor.status === 'verified')) return Response.json({ error: 'Your account uses MFA. Complete a reviewed MFA migration before linking.' },{ status: 409, headers });
  if (!user.email || !user.email_confirmed_at) return Response.json({ error: 'Verify your existing email before migrating.' },{ status: 409, headers });
  try {
    const admin = getBillingAdminClient();
    const { data: identity, error: lookupError } = await admin.from('account_identities').select('subject').eq('provider','clerk').eq('account_id',user.id).maybeSingle();
    if (lookupError) throw lookupError;
    const clerk = clerkAdmin();
    const proof = request.headers.get('x-clerk-token');
    let subject = identity?.subject;
    if (proof) {
      const provenSubject = await verifyClerkSubject(proof);
      if (subject && subject !== provenSubject) throw new IdentityConflict('This account is linked to a different Clerk account.');
      subject = provenSubject;
      const clerkUser = await clerk.users.getUser(subject);
      if (clerkUser.externalId && clerkUser.externalId !== user.id) throw new IdentityConflict('This Clerk account belongs to another account.');
    } else if (!subject) {
      const matches = await clerk.users.getUserList({ externalId: [user.id], limit: 1 });
      if (matches.data[0]) subject = matches.data[0].id;
      else {
        try {
          subject = (await clerk.users.createUser({ externalId: user.id, emailAddress: [user.email], emailAddressIdentificationStatus: ['verified'], firstName: String(user.user_metadata.display_name || '') || undefined, skipPasswordRequirement: true, skipLegalChecks: true })).id;
        } catch {
          // Recover concurrent creation only by the privileged externalId, never email.
          const retry = await clerk.users.getUserList({ externalId: [user.id], limit: 1 });
          if (!retry.data[0]) throw new IdentityConflict('Sign in with Clerk too, then use existing-account login to prove both identities.');
          subject = retry.data[0].id;
        }
      }
    }
    const target = await clerk.users.getUser(subject);
    if (target.banned || target.locked) throw new IdentityConflict('This Clerk account is unavailable.');
    if (!proof && target.twoFactorEnabled) throw new IdentityConflict('Sign in with Clerk to complete your second factor, then link your existing account.');
    await linkClerk(user.id,subject);
    if (proof) return Response.json({ linked: true },{ headers });
    const ticket = await clerk.signInTokens.createSignInToken({ userId: subject, expiresInSeconds: 60 });
    console.info('[auth-migration] session handoff ready');
    return Response.json({ ticket: ticket.token },{ headers });
  } catch (cause) {
    console.warn('[auth-migration] migration failed');
    return Response.json({ error: cause instanceof IdentityConflict ? cause.message : 'Migration could not finish. Retry your existing login.' },{ status: cause instanceof IdentityConflict ? 409 : 503, headers });
  }
}
