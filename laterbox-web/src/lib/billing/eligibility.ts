/** Mirrors the database entitlement predicates; Apple grace is supplied by Apple. */
export type SubscriptionAccess = {
  provider: string;
  status: string;
  current_period_ends_at: string | null;
  past_due_at?: string | null;
  updated_at: string;
  revoked_at?: string | null;
};

export function subscriptionHasAccess(row: SubscriptionAccess, now = Date.now()): boolean {
  if (row.revoked_at) return false;
  const end = row.current_period_ends_at ? Date.parse(row.current_period_ends_at) : null;
  if (end !== null && (!Number.isFinite(end) || end <= now)) return false;
  if (row.status === 'active' || row.status === 'trialing') {
    return row.provider !== 'apple' || end !== null;
  }
  if (row.status === 'canceled') return end !== null;
  if (row.status !== 'past_due') return false;
  if (row.provider === 'apple') return end !== null;
  return now < Date.parse(row.past_due_at || row.updated_at) + 7 * 86_400_000;
}
