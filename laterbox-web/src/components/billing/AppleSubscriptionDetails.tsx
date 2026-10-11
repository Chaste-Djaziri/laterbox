import type { Entitlement } from '@/lib/billing/types';

export const APPLE_SUBSCRIPTIONS_URL = 'https://apps.apple.com/account/subscriptions';

export function AppleSubscriptionDetails({ entitlement, compact = false }: { entitlement: Entitlement; compact?: boolean }) {
  const end = entitlement.accessEndsAt ? new Date(entitlement.accessEndsAt) : null;
  const date = end && Number.isFinite(end.getTime()) ? end.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' }) : null;
  const phase = entitlement.willCancel || entitlement.status === 'canceled'
    ? 'Access ends'
    : entitlement.status === 'trialing' ? 'Trial ends' : entitlement.status === 'past_due' ? 'Grace period ends' : 'Renews';
  return (
    <div className="space-y-2 text-xs text-zinc-200">
      {!compact && <>
        <p className="font-bold">LaterBox Pro{entitlement.billingInterval ? ` · ${entitlement.billingInterval === 'year' ? 'Annual' : 'Monthly'}` : ''} · Managed by Apple</p>
        {date && <p>{phase} {date}</p>}
        {entitlement.appleEnvironment === 'Sandbox' && <p>TestFlight subscription · No real payment</p>}
        <p className="max-w-md text-zinc-300">To switch to web billing, cancel renewal with Apple and subscribe here after your current access ends.</p>
      </>}
      <a href={APPLE_SUBSCRIPTIONS_URL} target="_blank" rel="noopener noreferrer" className="inline-block rounded-xl border border-white/30 px-4 py-2.5 font-bold hover:bg-white/10">
        Manage in App Store ↗
      </a>
    </div>
  );
}
