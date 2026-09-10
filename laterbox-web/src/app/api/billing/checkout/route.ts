import { NextResponse } from 'next/server';
import { getRequestUser, paddleRequest } from '@/lib/billing/server';

type BillingInterval = 'month' | 'year';

export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user?.email) return NextResponse.json({ error: 'Authentication required.' }, { status: 401 });

  try {
    const body = (await request.json()) as { interval?: BillingInterval };
    if (body.interval !== 'month' && body.interval !== 'year') {
      return NextResponse.json({ error: 'Choose a monthly or annual plan.' }, { status: 400 });
    }
    const isProduction = process.env.NEXT_PUBLIC_PADDLE_ENV === 'production';
    const priceId =
      body.interval === 'month'
        ? isProduction
          ? process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD ||
            process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID
          : process.env.NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID
        : isProduction
          ? process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD ||
            process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID
          : process.env.NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID;
    if (!priceId) throw new Error('Paddle price is not configured.');

    const transaction = await paddleRequest<{ id: string }>('/transactions', {
      method: 'POST',
      body: JSON.stringify({
        items: [{ price_id: priceId, quantity: 1 }],
        custom_data: { user_id: user.id },
        collection_mode: 'automatic',
      }),
    });
    return NextResponse.json({ transactionId: transaction.id });
  } catch (error) {
    console.error('[billing] checkout preparation failed', error);
    return NextResponse.json({ error: 'Unable to start checkout.' }, { status: 503 });
  }
}
