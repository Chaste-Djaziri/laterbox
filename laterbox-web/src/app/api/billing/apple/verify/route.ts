import { NextResponse } from 'next/server';
import { AppleBillingError, assertAppleTransaction, verifyAppleTransaction } from '@/lib/billing/apple';
import { upsertAppleSubscription } from '@/lib/billing/process-apple';
import { getRequestUser } from '@/lib/billing/server';

export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user) {
    return NextResponse.json({ error: 'Sign in again to sync your App Store purchase.', code: 'authentication_required' }, { status: 401 });
  }

  try {
    const body = (await request.json()) as {
      signedTransaction?: string;
      productId?: string;
    };
    if (!body.signedTransaction) {
      return NextResponse.json({ error: 'Signed transaction is required.' }, { status: 400 });
    }
    const transaction = await verifyAppleTransaction(body.signedTransaction);
    assertAppleTransaction(transaction, undefined, true);
    if (body.productId && transaction.productId !== body.productId) {
      return NextResponse.json({ error: 'Product identifier does not match.' }, { status: 400 });
    }
    try {
      const registered = await upsertAppleSubscription(transaction, undefined, undefined, user.id);
      if (!registered) return NextResponse.json({ code: 'link_required', error: 'Pro is active on your device. Choose Connect Pro to your account to enable web access.' }, { status: 409 });
    } catch (error) {
      if (error instanceof AppleBillingError) throw error;
      throw new AppleBillingError('registration_unavailable', 'Purchase registration is temporarily unavailable. Please retry.', 503);
    }
    return NextResponse.json({
      verified: true,
      environment: transaction.environment,
      productId: transaction.productId,
      transactionId: transaction.transactionId,
    });
  } catch (error) {
    console.error('[billing] Apple verification failed', { code: error instanceof AppleBillingError ? error.code : 'verification_failed' });
    return NextResponse.json(
      { error: error instanceof AppleBillingError ? error.message : 'Unable to verify the App Store purchase.', code: error instanceof AppleBillingError ? error.code : 'verification_failed' },
      { status: error instanceof AppleBillingError ? error.status : 422 },
    );
  }
}
