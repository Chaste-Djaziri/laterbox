import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser, paddleRequest } from '@/lib/billing/server';

type PortalSession = { urls: { general: { overview: string }; subscriptions: { id: string; view_subscription: string; cancel_subscription: string }[] } };

export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user) return NextResponse.json({ error: 'Authentication required.' }, { status: 401 });

  let action: 'manage' | 'cancel' = 'manage';
  try {
    const text = await request.text();
    const body = text ? JSON.parse(text) : {};
    if (body.action !== undefined && body.action !== 'manage' && body.action !== 'cancel') {
      return NextResponse.json({ error: 'Choose management or cancellation.' }, { status: 400 });
    }
    action = body.action ?? 'manage';
  } catch {
    return NextResponse.json({ error: 'Invalid billing request.' }, { status: 400 });
  }

  try {
    const admin = getBillingAdminClient();
    const { data: customer, error } = await admin
      .from('billing_customers')
      .select('customer_id')
      .eq('provider', 'paddle')
      .eq('user_id', user.id)
      .maybeSingle();
    if (error) throw error;
    if (!customer?.customer_id) {
      return NextResponse.json({ error: 'No Paddle subscription found.' }, { status: 404 });
    }

    const { data: subscriptions, error: subscriptionError } = await admin
      .from('billing_subscriptions')
      .select('subscription_id,status,scheduled_change_action,current_period_ends_at')
      .eq('provider', 'paddle')
      .eq('user_id', user.id)
      .eq('customer_id', customer.customer_id)
      .order('current_period_ends_at', { ascending: false, nullsFirst: false });
    if (subscriptionError) throw subscriptionError;
    const subscription = subscriptions?.find((row) =>
      ['active', 'trialing', 'past_due', 'paused'].includes(row.status)
      || (row.status === 'canceled' && new Date(row.current_period_ends_at).getTime() > Date.now())
    );
    if (action === 'cancel' && (!subscription || subscription.status === 'canceled' || subscription.scheduled_change_action === 'cancel')) {
      return NextResponse.json({ error: 'No subscription available to cancel.' }, { status: 409 });
    }

    const session = await paddleRequest<PortalSession>(
      `/customers/${encodeURIComponent(customer.customer_id)}/portal-sessions`,
      { method: 'POST', body: JSON.stringify({ subscription_ids: subscription ? [subscription.subscription_id] : [] }) }
    );
    const links = session.urls.subscriptions.find((links) => links.id === subscription?.subscription_id);
    const url = action === 'cancel' ? links?.cancel_subscription : links?.view_subscription || session.urls.general.overview;
    if (!url) throw new Error('Paddle portal link is missing.');
    return NextResponse.json({ url }, { headers: { 'Cache-Control': 'private, no-store' } });
  } catch (error) {
    console.error('[billing] portal session failed', error);
    return NextResponse.json({ error: 'Unable to open subscription management.' }, { status: 503 });
  }
}
