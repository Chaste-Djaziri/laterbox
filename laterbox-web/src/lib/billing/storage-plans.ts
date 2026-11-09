// laterbox-web/src/lib/billing/storage-plans.ts
// Public plan definitions. Whop is the source of truth for current prices.
export const WHOP_STORAGE_PLANS = {
  plus_month: { storage: 'plus', interval: 'month', bytes: 10 * 1024 ** 3, usd: 2.99, label: 'Plus', quotaLabel: '10 GB' },
  plus_year: { storage: 'plus', interval: 'year', bytes: 10 * 1024 ** 3, usd: 29.99, label: 'Plus', quotaLabel: '10 GB' },
  plus50_month: { storage: 'plus', interval: 'month', bytes: 50 * 1024 ** 3, usd: 4.99, label: 'Plus 50', quotaLabel: '50 GB' },
  plus50_year: { storage: 'plus', interval: 'year', bytes: 50 * 1024 ** 3, usd: 49.99, label: 'Plus 50', quotaLabel: '50 GB' },
  vault_month: { storage: 'vault', interval: 'month', bytes: 100 * 1024 ** 3, usd: 6.99, label: 'Vault', quotaLabel: '100 GB' },
  vault_year: { storage: 'vault', interval: 'year', bytes: 100 * 1024 ** 3, usd: 69.99, label: 'Vault', quotaLabel: '100 GB' },
  vault250_month: { storage: 'vault', interval: 'month', bytes: 250 * 1024 ** 3, usd: 11.99, label: 'Vault 250', quotaLabel: '250 GB' },
  vault250_year: { storage: 'vault', interval: 'year', bytes: 250 * 1024 ** 3, usd: 119.99, label: 'Vault 250', quotaLabel: '250 GB' },
  vault500_month: { storage: 'vault', interval: 'month', bytes: 500 * 1024 ** 3, usd: 19.99, label: 'Vault 500', quotaLabel: '500 GB' },
  vault500_year: { storage: 'vault', interval: 'year', bytes: 500 * 1024 ** 3, usd: 209.99, label: 'Vault 500', quotaLabel: '500 GB' },
  vault1tb_month: { storage: 'vault', interval: 'month', bytes: 1024 * 1024 ** 3, usd: 39.99, label: 'Vault 1 TB', quotaLabel: '1 TB' },
  vault1tb_year: { storage: 'vault', interval: 'year', bytes: 1024 * 1024 ** 3, usd: 419.99, label: 'Vault 1 TB', quotaLabel: '1 TB' },
  vault2tb_month: { storage: 'vault', interval: 'month', bytes: 2048 * 1024 ** 3, usd: 69.99, label: 'Vault 2 TB', quotaLabel: '2 TB' },
  vault2tb_year: { storage: 'vault', interval: 'year', bytes: 2048 * 1024 ** 3, usd: 739.99, label: 'Vault 2 TB', quotaLabel: '2 TB' },
} as const;
export type WhopPlanKey = keyof typeof WHOP_STORAGE_PLANS;
export type PaidPlanFamily = (typeof WHOP_STORAGE_PLANS)[WhopPlanKey]['storage'];
export const FREE_STORAGE_BYTES = 500_000_000;
export const LEGACY_PRO_STORAGE_BYTES = 10 * 1024 ** 3;
export function parseWhopPlan(value: unknown): WhopPlanKey | null {
  return typeof value === 'string' && Object.prototype.hasOwnProperty.call(WHOP_STORAGE_PLANS, value)
    ? value as WhopPlanKey : null;
}
export function planFamilySlug(key: WhopPlanKey): string {
  return key.replace(/_(month|year)$/, '');
}
