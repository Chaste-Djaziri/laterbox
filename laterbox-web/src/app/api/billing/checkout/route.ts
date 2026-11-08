import { NextResponse } from 'next/server';
import { subscriptionHasAccess } from '@/lib/billing/eligibility';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';
import { parseWhopPlan, whopEnvironment, whopPlanId, whopServer } from '@/lib/billing/whop';

export const dynamic = 'force-dynamic';

/** Create an account-bound checkout; never accept Whop plan IDs from the browser. */
export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user?.id || !user.email) {
    return NextResponse.json({ error: 'Sign in to purchase a storage plan.' }, { status: 401 });
  }
  let key;
  try {
    const body = await request.json() as { plan?: unknown };
    key = parseWhopPlan(body.plan);
  } catch {
    return NextResponse.json({ error: 'Invalid checkout request.' }, { status: 400 });
  }
  if (!key) return NextResponse.json({ error: 'Choose a valid storage plan.' }, { status: 400 });

  try {
    const planId = whopPlanId(key);
    const admin = getBillingAdminClient();
    const { data: subscriptions, error } = await admin.from('billing_subscriptions')
      .select('provider,status,current_period_ends_at,past_due_at,updated_at,revoked_at')
      .eq('user_id', user.id);
    if (error) throw error;
    const active = (subscriptions ?? []).find(row => subscriptionHasAccess(row));
    if (active) {
      return NextResponse.json({
        error: 'You already have an active subscription. Manage it before buying a second plan.',
        code: 'subscription_already_active',
      }, { status: 409 });
    }

    const intentId = crypto.randomUUID();
    const { error: intentError } = await admin.from('billing_checkout_intents').insert({
      id: intentId,
      user_id: user.id,
      provider: 'whop',
      plan_key: key,
      plan_id: planId,
    });
    if (intentError) throw intentError;

    // Metadata is the authoritative link back to this account. Do not depend on email matching.
    const checkout = await whopServer().checkoutConfigurations.create({
      plan_id: planId,
      mode: 'payment',
      metadata: { laterbox_intent_id: intentId },
    }, { idempotencyKey: `laterbox-${intentId}` });

    const { error: updateError } = await admin.from('billing_checkout_intents')
      .update({ checkout_id: checkout.id })
      .eq('id', intentId).eq('user_id', user.id);
    if (updateError) throw updateError;
    return NextResponse.json({ checkoutId: checkout.id, intentId, environment: whopEnvironment() }, {
      headers: { 'Cache-Control': 'private, no-store' },
    });
  } catch (error) {
    console.error('[whop] checkout creation failed', error);
    return NextResponse.json({ error: 'Checkout is unavailable. Check Whop configuration and database migrations.' }, { status: 503 });
  }
}
