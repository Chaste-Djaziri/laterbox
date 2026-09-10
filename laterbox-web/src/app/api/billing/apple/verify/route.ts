import { NextResponse } from 'next/server';
import { assertAppleTransaction, verifyAppleTransaction } from '@/lib/billing/apple';
import { upsertAppleSubscription } from '@/lib/billing/process-apple';
import { getRequestUser } from '@/lib/billing/server';

export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user) {
    return NextResponse.json({ error: 'Authentication required.' }, { status: 401 });
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
    assertAppleTransaction(transaction, user.id);
    if (body.productId && transaction.productId !== body.productId) {
      return NextResponse.json({ error: 'Product identifier does not match.' }, { status: 400 });
    }
    await upsertAppleSubscription(transaction);
    return NextResponse.json({
      verified: true,
      productId: transaction.productId,
      transactionId: transaction.transactionId,
    });
  } catch (error) {
    console.error('[billing] Apple transaction verification failed', error);
    return NextResponse.json(
      { error: 'Unable to verify the App Store purchase.' },
      { status: 422 },
    );
  }
}
