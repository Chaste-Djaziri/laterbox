import { getRequestUser } from '@/lib/billing/server';
import { deleteApplicationAccount } from '@/lib/auth/delete-account';

export async function POST(request: Request) {
  try {
    const user = await getRequestUser(request);
    if (!user?.id) return Response.json({ error: 'Invalid or expired session.' }, { status: 401 });
    await deleteApplicationAccount(user.id);
    return Response.json({ success: true });
  } catch {
    return Response.json({ error: 'Account deletion could not finish. Cleanup can be retried.' }, { status: 503 });
  }
}
