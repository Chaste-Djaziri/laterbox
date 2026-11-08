import { unwrapWebhook } from '@whop/sdk/helpers';
import { NextResponse } from 'next/server';
import { processWhopWebhook, type WhopWebhook } from '@/lib/billing/process-whop';

export const dynamic = 'force-dynamic';
export async function POST(request: Request) {
  const secret = process.env.WHOP_WEBHOOK_SECRET;
  if (!secret) return NextResponse.json({ error: 'Webhook not configured.' }, { status: 503 });
  const raw = await request.text();
  if (!raw || raw.length > 1024 * 1024) return NextResponse.json({ error: 'Invalid webhook body.' }, { status: 400 });

  let event: WhopWebhook;
  try {
    event = unwrapWebhook<WhopWebhook>(raw, {
      headers: Object.fromEntries(request.headers.entries()),
      key: secret,
    });
    if (!event?.id || !event?.type || typeof event.data !== 'object' || !event.data) {
      return NextResponse.json({ error: 'Invalid event.' }, { status: 400 });
    }
  } catch {
    return NextResponse.json({ error: 'Invalid Whop webhook signature.' }, { status: 401 });
  }
  try {
    const deliveryId = request.headers.get('webhook-id') || event.id;
    const outcome = await processWhopWebhook(event, deliveryId);
    return NextResponse.json({ received: true, outcome });
  } catch (error) {
    console.error('[whop] webhook processing failed', error);
    return NextResponse.json({ error: 'Webhook processing failed; retry required.' }, { status: 500 });
  }
}
