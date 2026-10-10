import { verifyWebhook } from '@clerk/backend/webhooks';
import { getBillingAdminClient } from '@/lib/billing/server';
import { clerkAdmin, ensureClerkAccount, IdentityConflict, getClerkUserEmail, getClerkDisplayName } from '@/lib/auth/server';
import { deleteApplicationAccount } from '@/lib/auth/delete-account';

export async function POST(request: Request) {
  let event;
  try { event = await verifyWebhook(request); }
  catch { return Response.json({ error: 'Invalid webhook signature.' },{ status: 400 }); }
  const eventId = request.headers.get('svix-id') || request.headers.get('webhook-id');
  if (!eventId) return Response.json({ error: 'Missing event ID.' },{ status: 400 });
  try {
    const admin = getBillingAdminClient();
    const { data: processed,error: lookupError } = await admin.from('auth_webhook_events').select('event_id').eq('event_id',eventId).maybeSingle();
    if (lookupError) throw lookupError;
    if (processed) return Response.json({ received: true });
    if (event.type === 'user.deleted' && event.data.id) {
      const { data,error } = await admin.from('account_identities').select('account_id').eq('provider','clerk').eq('subject',event.data.id).maybeSingle();
      if (error) throw error;
      if (data) await deleteApplicationAccount(data.account_id,true);
      else {
        const { data: job,error: jobError } = await admin.from('account_deletion_jobs').select('account_id,completed_at').eq('clerk_subject',event.data.id).maybeSingle();
        if (jobError) throw jobError;
        if (job && !job.completed_at) await deleteApplicationAccount(job.account_id,true);
      }
    } else if (event.type === 'user.created' || event.type === 'user.updated') {
      try {
        // Fetch the current profile; a delayed event must not restore stale email/name.
        const profile = await clerkAdmin().users.getUser(event.data.id);
        const account = await ensureClerkAccount(profile.id);
        const emailInfo = getClerkUserEmail(profile);
        const displayName = getClerkDisplayName(profile);
        const patch = { display_name: displayName, profile_updated_at: new Date(profile.updatedAt).toISOString(), ...(emailInfo?.verified ? { email: emailInfo.emailAddress } : {}) };
        const { error } = await admin.from('accounts').update(patch).eq('id',account.id).eq('state','active').or(`profile_updated_at.is.null,profile_updated_at.lte.${patch.profile_updated_at}`);
        if (error) throw error;
        // Keep the legacy identity usable on mobile, with the same verified profile.
        const { error: legacyError } = await admin.auth.admin.updateUserById(account.id,{ ...(emailInfo?.verified ? { email: emailInfo.emailAddress,email_confirm: true } : {}),user_metadata: { display_name: displayName } });
        if (legacyError) throw legacyError;
      } catch (cause) {
        // Existing-email conflicts require explicit login proof in the app.
        if (!(cause instanceof IdentityConflict) && (cause as { status?: number }).status !== 404) throw cause;
      }
    }
    const { error } = await admin.from('auth_webhook_events').insert({ event_id: eventId });
    if (error && error.code !== '23505') throw error;
    return Response.json({ received: true });
  } catch {
    console.warn('[auth-webhook] processing failed; retry required');
    return Response.json({ error: 'Webhook processing incomplete.' },{ status: 503 });
  }
}
