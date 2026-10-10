import { getBillingAdminClient } from '../billing/server';
import { clerkAdmin } from './server';

/** Every operation is retryable; a tombstone survives provider/data deletion. */
export async function deleteApplicationAccount(accountId: string, clerkAlreadyDeleted = false): Promise<void> {
  const admin = getBillingAdminClient();
  const { data: identities, error: identityError } = await admin.from('account_identities').select('provider,subject').eq('account_id',accountId);
  if (identityError) throw identityError;
  const clerkSubject = identities?.find(identity => identity.provider === 'clerk')?.subject;
  const { data: prior, error: priorError } = await admin.from('account_deletion_jobs').select('*').eq('account_id',accountId).maybeSingle();
  if (priorError) throw priorError;
  if (prior?.completed_at) return;
  if (!prior) {
    const { error } = await admin.from('account_deletion_jobs').insert({ account_id: accountId, clerk_subject: clerkSubject });
    if (error && error.code !== '23505') throw error;
  }
  const { error: stateError } = await admin.from('accounts').update({ state: 'deleting' }).eq('id',accountId);
  if (stateError) throw stateError;
  const response = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ltjisrgldssqskcylcbj.supabase.co'}/functions/v1/attachment-storage`, {
    method: 'POST', headers: { Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`, apikey: process.env.SUPABASE_SERVICE_ROLE_KEY!, 'Content-Type': 'application/json' },
    body: JSON.stringify({ action: 'delete-account-files', accountId }),
  });
  if (!response.ok) throw new Error('Attachment cleanup failed. Deletion remains queued.');
  const subject = clerkSubject || prior?.clerk_subject;
  if (subject && !clerkAlreadyDeleted) {
    try { await clerkAdmin().users.deleteUser(subject); }
    catch (cause) { if ((cause as { status?: number }).status !== 404) throw cause; }
  }
  const legacySubject = identities?.find(identity => identity.provider === 'supabase')?.subject || accountId;
  const { error: authError } = await admin.auth.admin.deleteUser(legacySubject);
  if (authError && authError.status !== 404) throw authError;
  const { error: accountError } = await admin.from('accounts').delete().eq('id',accountId);
  if (accountError) throw accountError;
  const { error: jobError } = await admin.from('account_deletion_jobs').update({ completed_at: new Date().toISOString() }).eq('account_id',accountId);
  if (jobError) throw jobError;
}
