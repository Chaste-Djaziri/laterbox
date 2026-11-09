import { NextResponse } from 'next/server';
import { earnSettings } from '@/lib/earn/affiliate';
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

    // A client retry should reuse a still-valid account-owned checkout, not
    // create an unnecessary second opportunity to charge the same subscriber.
    const { data: pending, error: pendingError } = await admin.from('billing_checkout_intents')
      .select('id,checkout_id').eq('user_id', user.id).eq('provider','whop')
      .eq('plan_key', key).eq('plan_id',planId).eq('status','pending')
      .gt('expires_at', new Date().toISOString())
      .not('checkout_id','is',null)
      .order('created_at', { ascending:false }).limit(1).maybeSingle();
    if (pendingError) throw pendingError;
    if (pending?.checkout_id) return NextResponse.json({
      checkoutId: pending.checkout_id, intentId: pending.id, environment: whopEnvironment(),
    }, { headers: { 'Cache-Control': 'private, no-store' } });


    // Only pre-enrolled, active members receive an attribution. The browser
    // cannot supply an affiliate ID or override the server-recorded snapshot.
    let affiliateUserId: string | null = null;
    const referralCode = request.headers.get('cookie')?.split(';').map(value=>value.trim()).find(value=>value.startsWith('laterbox_ref='))?.slice('laterbox_ref='.length);
    // Earn rewards only the FIRST paid subscription by a LaterBox account.
    // Returning buyers may purchase normally but cannot trigger a new commission.
    if ((subscriptions ?? []).length === 0 &&
        referralCode && /^lb_[a-f0-9]{24}$/.test(referralCode)) {
      try {
        if ((await earnSettings()).enabled) {
          const { data: affiliate } = await admin.from('affiliate_profiles')
            .select('user_id').eq('referral_code',referralCode)
            .eq('status','active').maybeSingle();
          if (affiliate?.user_id && affiliate.user_id !== user.id) affiliateUserId = affiliate.user_id;
        }
      } catch { /* Earn migration not activated; checkout must continue normally. */ }
    }
    const intentId = crypto.randomUUID();
    const { error: intentError } = await admin.from('billing_checkout_intents').insert({
      id: intentId,
      user_id: user.id,
      provider: 'whop',
      plan_key: key,
      plan_id: planId,
      ...(affiliateUserId ? { affiliate_user_id: affiliateUserId } : {}),
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
