import { NextResponse } from 'next/server';
import { FREE_ENTITLEMENT, type Entitlement } from '@/lib/billing/types';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';

export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
  const user = await getRequestUser(request);
  if (!user) return NextResponse.json({ error: 'Authentication required.' }, { status: 401 });

  try {
    const admin = getBillingAdminClient();
    const now = Date.now();
    const [{ data: subscriptions, error: subscriptionError }, { data: grants, error: grantError }] =
      await Promise.all([
        admin
          .from('billing_subscriptions')
          .select('*')
          .eq('user_id', user.id)
          .order('current_period_ends_at', { ascending: false, nullsFirst: false }),
        admin
          .from('billing_entitlement_grants')
          .select('*')
          .eq('user_id', user.id)
          .lte('starts_at', new Date(now).toISOString())
          .gt('expires_at', new Date(now).toISOString())
          .order('expires_at', { ascending: false }),
      ]);
    if (subscriptionError) throw subscriptionError;
    if (grantError) throw grantError;

    const eligible = (subscriptions ?? []).find((row) => {
      if (row.status === 'active' || row.status === 'trialing') return true;
      const periodEnd = row.current_period_ends_at
        ? new Date(row.current_period_ends_at).getTime()
        : 0;
      if (row.status === 'canceled') return periodEnd > now;
      if (row.status !== 'past_due') return false;
      if (row.provider === 'apple') return periodEnd > now;
      const pastDueStart = new Date(row.past_due_at || row.updated_at).getTime();
      return now < pastDueStart + 7 * 24 * 60 * 60 * 1000;
    });

    let entitlement: Entitlement = FREE_ENTITLEMENT;
    if (eligible) {
      const pastDueLimit = new Date(
        new Date(eligible.past_due_at || eligible.updated_at).getTime() +
          7 * 24 * 60 * 60 * 1000
      ).toISOString();
      const graceEndsAt = eligible.provider === 'apple'
        ? eligible.current_period_ends_at
        : [eligible.current_period_ends_at, pastDueLimit].filter(Boolean).sort()[0] ?? pastDueLimit;
      entitlement = {
        tier: 'pro',
        status: eligible.status,
        provider: eligible.provider,
        trialEndsAt: eligible.trial_ends_at,
        accessEndsAt:
          eligible.status === 'past_due'
            ? graceEndsAt
            : eligible.current_period_ends_at,
        willCancel: eligible.scheduled_change_action === 'cancel',
        billingWarning: eligible.status === 'past_due' ? 'payment_past_due' : null,
        phaseStartsAt:
          eligible.status === 'past_due'
            ? eligible.past_due_at || eligible.updated_at
            : eligible.current_period_starts_at || eligible.created_at,
        phaseEndsAt:
          eligible.status === 'trialing'
            ? eligible.trial_ends_at || eligible.current_period_ends_at
            : eligible.status === 'past_due'
              ? graceEndsAt
              : eligible.current_period_ends_at,
      };
    } else if (grants?.[0]) {
      entitlement = {
        tier: 'pro',
        status: 'granted',
        provider: null,
        trialEndsAt: null,
        accessEndsAt: grants[0].expires_at,
        willCancel: false,
        billingWarning: null,
        phaseStartsAt: grants[0].starts_at,
        phaseEndsAt: grants[0].expires_at,
      };
    }

    return NextResponse.json(entitlement, {
      headers: { 'Cache-Control': 'private, no-store' },
    });
  } catch (error) {
    console.error('[billing] entitlement lookup failed', error);
    return NextResponse.json({ error: 'Unable to load subscription status.' }, { status: 503 });
  }
}
