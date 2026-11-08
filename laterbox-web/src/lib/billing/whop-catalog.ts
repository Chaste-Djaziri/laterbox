// laterbox-web/src/lib/billing/whop-catalog.ts
import { WHOP_STORAGE_PLANS, type WhopPlanKey } from './storage-plans';

export type WhopCatalogTier = 'plus' | 'vault';

export interface DesiredWhopPlan {
  key: WhopPlanKey;
  title: string;
  product: WhopCatalogTier;
  billingPeriod: 30 | 365;
  renewalPrice: number;
}

export interface DesiredWhopProduct {
  tier: WhopCatalogTier;
  title: string;
  description: string;
}

export const WHOP_CATALOG_PRODUCTS: readonly DesiredWhopProduct[] = [
  {
    tier: 'plus',
    title: 'LaterBox Plus',
    description: 'Save and organize more with 10 GB of LaterBox cloud storage.',
  },
  {
    tier: 'vault',
    title: 'LaterBox Vault',
    description: 'More room for everything worth keeping with 100 GB of LaterBox cloud storage.',
  },
];

export const WHOP_CATALOG_PLANS: readonly DesiredWhopPlan[] = (
  Object.entries(WHOP_STORAGE_PLANS) as [WhopPlanKey, (typeof WHOP_STORAGE_PLANS)[WhopPlanKey]][]
).map(([key, plan]) => ({
  key,
  product: plan.storage,
  title: `${plan.storage === 'plus' ? 'Plus' : 'Vault'} ${plan.interval === 'month' ? 'Monthly' : 'Yearly'}`,
  billingPeriod: plan.interval === 'month' ? 30 : 365,
  renewalPrice: plan.usd,
}));

export interface WhopProductRecord {
  id: string;
  title: string;
}

export interface WhopPlanRecord {
  id: string;
  title: string | null;
  product: { id: string } | null;
  plan_type: string;
  currency: string;
  billing_period: number | null;
  renewal_price: number;
  initial_price: number;
}

export function existingWhopProduct(
  products: readonly WhopProductRecord[],
  desired: DesiredWhopProduct,
): WhopProductRecord | null {
  const matches = products.filter(product => product.title === desired.title);
  if (matches.length > 1) throw new Error(`Multiple products named "${desired.title}" exist. Resolve the duplicate before provisioning.`);
  return matches[0] ?? null;
}

export function existingWhopPlan(
  plans: readonly WhopPlanRecord[],
  productId: string,
  desired: DesiredWhopPlan,
): WhopPlanRecord | null {
  const matches = plans.filter(plan => plan.product?.id === productId && plan.title === desired.title);
  if (matches.length > 1) {
    throw new Error(`Multiple "${desired.title}" plans exist on this product. Resolve duplicates before provisioning.`);
  }
  const match = matches[0];
  if (!match) return null;
  const correctPrice = Math.abs(match.renewal_price - desired.renewalPrice) < 0.0001;
  if (match.plan_type !== 'renewal' || match.currency.toLowerCase() !== 'usd' ||
      match.billing_period !== desired.billingPeriod || !correctPrice || match.initial_price !== 0) {
    throw new Error(`"${desired.title}" already exists with different billing terms. Review it manually instead of creating a duplicate.`);
  }
  return match;
}
