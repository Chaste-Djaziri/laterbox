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
  phaseStartsAt: string | null;
  phaseEndsAt: string | null;
}

export const FREE_ENTITLEMENT: Entitlement = {
  tier: 'free',
  status: 'free',
  provider: null,
  trialEndsAt: null,
  accessEndsAt: null,
  willCancel: false,
  billingWarning: null,
  phaseStartsAt: null,
  phaseEndsAt: null,
};

export function hasProAccess(entitlement: Entitlement): boolean {
  if (entitlement.tier !== 'pro') return false;
  return !entitlement.accessEndsAt || new Date(entitlement.accessEndsAt).getTime() > Date.now();
}

export type EntitlementPresentation = {
  label: string;
  description: string;
  actionLabel: 'View plans' | 'Manage' | 'Fix payment';
  tone: 'neutral' | 'success' | 'warning';
  remainingDays: number | null;
  progress: number | null;
};

export function presentEntitlement(
  entitlement: Entitlement,
  now = new Date(),
): EntitlementPresentation {
  const endValue = entitlement.phaseEndsAt || entitlement.accessEndsAt;
  const end = endValue ? new Date(endValue) : null;
  const start = entitlement.phaseStartsAt ? new Date(entitlement.phaseStartsAt) : null;
  const remainingMs = end ? Math.max(0, end.getTime() - now.getTime()) : null;
  const remainingDays = remainingMs === null ? null : Math.ceil(remainingMs / 86_400_000);
  const time = remainingDays === null
    ? ''
    : remainingDays === 0
      ? 'Ends today'
      : `${remainingDays} day${remainingDays === 1 ? '' : 's'} left`;
  const duration = start && end ? end.getTime() - start.getTime() : 0;
  const progress = duration > 0
    ? Math.min(1, Math.max(0, (now.getTime() - start!.getTime()) / duration))
    : null;

  const hasAccess = entitlement.tier === 'pro'
    && (!entitlement.accessEndsAt
      || new Date(entitlement.accessEndsAt).getTime() > now.getTime());
  if (!hasAccess) {
    return {
      label: 'Free',
      description: 'Local saving, reading, search, organization, and export.',
      actionLabel: 'View plans',
      tone: 'neutral',
      remainingDays: null,
      progress: null,
    };
  }
  if (entitlement.status === 'past_due') {
    return {
      label: `Grace period${time ? ` · ${time}` : ''}`,
      description: 'Update your payment method to keep Pro active.',
      actionLabel: 'Fix payment',
      tone: 'warning',
      remainingDays,
      progress,
    };
  }
  if (entitlement.status === 'trialing') {
    return {
      label: `Pro trial${time ? ` · ${time}` : ''}`,
      description: 'All connected features are available during your trial.',
      actionLabel: 'Manage',
      tone: 'success',
      remainingDays,
      progress,
    };
  }
  if (entitlement.status === 'granted') {
    return {
      label: `Launch Pro${time ? ` · ${time}` : ''}`,
      description: 'Temporary launch access includes all Pro features.',
      actionLabel: 'View plans',
      tone: 'success',
      remainingDays,
      progress,
    };
  }
  if (entitlement.willCancel) {
    return {
      label: `Pro${time ? ` · ${time}` : ''}`,
      description: 'Your plan stays active until the end of this period.',
      actionLabel: 'Manage',
      tone: 'warning',
      remainingDays,
      progress,
    };
  }
  return {
    label: 'Pro',
    description: 'Sync, cloud attachments, integrations, and automation are active.',
    actionLabel: 'Manage',
    tone: 'success',
    remainingDays: null,
    progress: null,
  };
}
