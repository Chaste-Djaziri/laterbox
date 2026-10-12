import { NextResponse } from 'next/server';
import { AppleBillingError, verifyAppleTransaction, assertAppleTransaction } from '@/lib/billing/apple';
import { currentAppleSubscription } from '@/lib/billing/apple-status';
import { appleSubscriptionRecord, resolveApplePurchaseOwner } from '@/lib/billing/process-apple';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';

export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user) return NextResponse.json({ code: 'authentication_required', error: 'Sign in to the account you want to connect.' }, { status: 401 });
  try {
    const body = await request.json() as { signedTransaction?: unknown };
    if (typeof body.signedTransaction !== 'string' || !body.signedTransaction) return NextResponse.json({ error: 'Signed transaction is required.' }, { status: 400 });
    const proof = await verifyAppleTransaction(body.signedTransaction);
    assertAppleTransaction(proof);
    const owner = await resolveApplePurchaseOwner(proof);
    if (owner && owner !== user.id) throw new AppleBillingError('account_mismatch', 'This purchase is already connected to another LaterBox account.', 409);
    const { transaction, renewal, stateAt } = await currentAppleSubscription(proof);
    const { error } = await getBillingAdminClient().rpc('claim_apple_purchase', {
      p_original_id: transaction.originalTransactionId,
      p_environment: transaction.environment,
      p_token: transaction.appAccountToken!.toLowerCase(),
      p_user: user.id,
      p_subscription: appleSubscriptionRecord(transaction, renewal, user.id, stateAt),
    });
    if (error) {
      if (error.code === 'P0001') throw new AppleBillingError('account_mismatch', 'This purchase is already connected to another LaterBox account.', 409);
      throw error;
    }
    return NextResponse.json({ linked: true, environment: transaction.environment }, { headers: { 'Cache-Control': 'private, no-store' } });
  } catch (error) {
    console.error('[billing] Apple account connection failed', { code: error instanceof AppleBillingError ? error.code : 'linking_unavailable' });
    return NextResponse.json({
      code: error instanceof AppleBillingError ? error.code : 'linking_unavailable',
      error: error instanceof AppleBillingError ? error.message : 'Device Pro is active. Unable to connect your account right now; please retry.',
    }, { status: error instanceof AppleBillingError ? error.status : 503 });
  }
}
