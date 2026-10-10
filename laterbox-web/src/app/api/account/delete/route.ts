import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';
import { isClerkToken, verifyClerkSubject } from '@/lib/auth/server';
import { deleteApplicationAccount } from '@/lib/auth/delete-account';

export async function POST(request: Request) {
  try {
    const token = request.headers.get('authorization')?.match(/^Bearer (.+)$/)?.[1];
    let accountId: string | undefined;
    if (token && isClerkToken(token)) {
      // Allow a deleting account to retry cleanup, while other APIs reject it.
      const subject = await verifyClerkSubject(token);
      const { data,error } = await getBillingAdminClient().from('account_identities').select('account_id').eq('provider','clerk').eq('subject',subject).maybeSingle();
      if (error) throw error;
      accountId = data?.account_id;
    } else accountId = (await getRequestUser(request))?.id;
    if (!accountId) return Response.json({ error: 'Invalid or expired session.' },{ status: 401 });
    await deleteApplicationAccount(accountId);
    return Response.json({ success: true });
  } catch {
    return Response.json({ error: 'Account deletion could not finish. Cleanup can be retried.' },{ status: 503 });
  }
}
