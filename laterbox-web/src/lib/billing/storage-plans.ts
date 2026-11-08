// Shared, public product labels and quotas. Never import server payment SDKs into client bundles.
export const WHOP_STORAGE_PLANS = {
  plus_month: { storage: 'plus', interval: 'month', bytes: 10 * 1024 ** 3, usd: 2.99 },
  plus_year: { storage: 'plus', interval: 'year', bytes: 10 * 1024 ** 3, usd: 29.99 },
  vault_month: { storage: 'vault', interval: 'month', bytes: 100 * 1024 ** 3, usd: 6.99 },
  vault_year: { storage: 'vault', interval: 'year', bytes: 100 * 1024 ** 3, usd: 69.99 },
} as const;
export type WhopPlanKey = keyof typeof WHOP_STORAGE_PLANS;
export const FREE_STORAGE_BYTES = 500_000_000;
export const LEGACY_PRO_STORAGE_BYTES = 10 * 1024 ** 3;
export function parseWhopPlan(value: unknown): WhopPlanKey | null {
  return typeof value === 'string' && Object.prototype.hasOwnProperty.call(WHOP_STORAGE_PLANS, value)
    ? value as WhopPlanKey : null;
}
