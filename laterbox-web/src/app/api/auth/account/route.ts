import { verifyClerkSubject, ensureClerkAccount, IdentityConflict } from '@/lib/auth/server';
import { authorizedOrigins, clerkAuthEnabled } from '@/lib/auth/config';

export async function POST(request: Request) {
  const headers = { 'Cache-Control': 'no-store' };
  if (!clerkAuthEnabled) return Response.json({ error: 'Clerk rollout is disabled.' },{ status: 503, headers });
  if (!authorizedOrigins().includes(request.headers.get('origin') || '')) return Response.json({ error: 'Untrusted origin.' },{ status: 403, headers });
  const token = request.headers.get('authorization')?.match(/^Bearer (.+)$/)?.[1];
  let subject: string;
  try { subject = await verifyClerkSubject(token || ''); }
  catch { return Response.json({ error: 'Sign in to continue.' },{ status: 401, headers }); }
  try { return Response.json({ user: await ensureClerkAccount(subject) },{ headers }); }
  catch (cause) {
    return Response.json({ error: cause instanceof IdentityConflict ? cause.message : 'Account setup could not finish. Please retry.' },{ status: cause instanceof IdentityConflict ? 409 : 503, headers });
  }
}
