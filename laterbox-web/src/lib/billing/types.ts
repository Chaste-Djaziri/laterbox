export type EntitlementTier = 'free' | 'pro';
export type EntitlementProvider = 'paddle' | 'apple' | null;
export type EntitlementStatus =
  | 'free'
  | 'granted'
  | 'trialing'
  | 'active'
  | 'past_due'
  | 'paused'
  | 'canceled';

export interface Entitlement {
  tier: EntitlementTier;
  status: EntitlementStatus;
  provider: EntitlementProvider;
  trialEndsAt: string | null;
  accessEndsAt: string | null;
  willCancel: boolean;
  billingWarning: string | null;
}

export const FREE_ENTITLEMENT: Entitlement = {
  tier: 'free',
  status: 'free',
  provider: null,
  trialEndsAt: null,
  accessEndsAt: null,
  willCancel: false,
  billingWarning: null,
};

export function hasProAccess(entitlement: Entitlement): boolean {
  if (entitlement.tier !== 'pro') return false;
  return !entitlement.accessEndsAt || new Date(entitlement.accessEndsAt).getTime() > Date.now();
}
