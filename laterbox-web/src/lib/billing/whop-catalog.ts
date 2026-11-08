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

/** Whop API v1 uses account_id. company_id is ignored on public product listing. */
export function whopCatalogQuery(accountId: string, after?: string): string {
  if (!/^biz_[a-zA-Z0-9_-]+$/.test(accountId)) throw new Error('Invalid Whop account ID.');
  const query = new URLSearchParams({ account_id: accountId, first: '100' });
  if (after) query.set('after', after);
  return query.toString();
}

export function whopProductCreateBody(accountId: string, desired: DesiredWhopProduct) {
  if (!/^biz_[a-zA-Z0-9_-]+$/.test(accountId)) throw new Error('Invalid Whop account ID.');
  return {
    account_id: accountId,
    title: desired.title,
    description: desired.description,
  };
}

export function whopPlanCreateBody(accountId: string, productId: string, desired: DesiredWhopPlan) {
  if (!/^biz_[a-zA-Z0-9_-]+$/.test(accountId)) throw new Error('Invalid Whop account ID.');
  if (!/^prod_[a-zA-Z0-9_-]+$/.test(productId)) throw new Error('Invalid Whop product ID.');
  return {
    account_id: accountId,
    product_id: productId,
    title: desired.title,
    description: `LaterBox ${desired.title} subscription`,
    plan_type: 'renewal' as const,
    release_method: 'buy_now' as const,
    visibility: 'visible' as const,
    currency: 'usd' as const,
    billing_period: desired.billingPeriod,
    initial_price: 0,
    renewal_price: desired.renewalPrice,
    unlimited_stock: true,
  };
}
