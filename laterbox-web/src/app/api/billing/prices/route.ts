// laterbox-web/src/app/api/billing/prices/route.ts
import { NextResponse } from 'next/server';
import { WHOP_PLAN_KEYS, normalizeWhopPlan, type WhopPriceCatalog } from '@/lib/billing/whop-prices';
import { whopPlanId, whopServer } from '@/lib/billing/whop';

export const dynamic = 'force-dynamic';

// Public prices must come from the same configured plan IDs the purchase endpoint uses.
// No API keys or checkout identities are returned to browsers.
export async function GET() {
  try {
    const client = whopServer();
    const entries = await Promise.all(WHOP_PLAN_KEYS.map(async key => {
      const configuredId = whopPlanId(key);
      const plan = await client.plans.retrieve({ id: configuredId });
      if (plan.id !== configuredId) throw new Error('Whop plan ID mismatch.');
      return [key, normalizeWhopPlan(key, plan)] as const;
    }));
    const prices = Object.fromEntries(entries) as WhopPriceCatalog;
    return NextResponse.json({ prices }, { headers: { 'Cache-Control': 'no-store' } });
  } catch (error) {
    console.error('[whop] Failed to load live plan pricing', error);
    return NextResponse.json(
      { error: 'Live pricing is temporarily unavailable. Whop will confirm the final amount at checkout.' },
      { status: 503, headers: { 'Cache-Control': 'no-store' } },
    );
  }
}
