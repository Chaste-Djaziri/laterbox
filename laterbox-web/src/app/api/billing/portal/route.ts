import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser, paddleRequest } from '@/lib/billing/server';
import { whopServer } from '@/lib/billing/whop';

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
    const { data: whopRows, error: whopError } = await admin.from('billing_subscriptions')
      .select('subscription_id,customer_id,status,current_period_ends_at')
      .eq('provider','whop').eq('user_id', user.id)
      .order('current_period_ends_at', { ascending:false, nullsFirst:false });
    if (whopError) throw whopError;
    const whopRow = whopRows?.find(row => (
      ['active','trialing','past_due'].includes(row.status)
      || (row.status === 'canceled' && row.current_period_ends_at && Date.parse(row.current_period_ends_at) > Date.now())
    ));
    if (whopRow) {
      const membership = await whopServer().memberships.retrieve({ id: whopRow.subscription_id });
      if (membership.user_id !== whopRow.customer_id || !membership.manage_url) {
        return NextResponse.json({ error: 'Whop billing management is unavailable for this account.' }, { status: 503 });
      }
      const url = new URL(membership.manage_url);
      if (url.protocol !== 'https:' || !['whop.com','sandbox.whop.com','www.whop.com'].includes(url.hostname)) {
        throw new Error('Untrusted Whop management URL.');
      }
      return NextResponse.json({ url: url.toString() }, { headers:{ 'Cache-Control':'private, no-store' } });
    }
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
