// laterbox-web/src/lib/billing/whop-prices.ts
// Whop is the source of truth for displayed subscription prices, not our provisioning defaults.
import { WHOP_STORAGE_PLANS, type WhopPlanKey } from './storage-plans';

export const WHOP_PLAN_KEYS = Object.keys(WHOP_STORAGE_PLANS) as WhopPlanKey[];

export type WhopPlanQuote = {
  id: string;
  currency: string;
  renewalPrice: number;
  initialPrice: number;
  interval: 'month' | 'year';
  billingPeriodDays: number;
  trialDays: number;
  taxType: 'inclusive' | 'exclusive' | 'unspecified';
  collectTax: boolean;
};

export type WhopPriceCatalog = Record<WhopPlanKey, WhopPlanQuote>;

type SourcePlan = {
  id: string;
  currency: string;
  renewal_price: number;
  initial_price: number;
  billing_period: number | null;
  trial_period_days?: number | null;
  plan_type: string;
  tax_type?: string | null;
  collect_tax?: boolean | null;
};

export function normalizeWhopPlan(key: WhopPlanKey, plan: SourcePlan): WhopPlanQuote {
  const interval = WHOP_STORAGE_PLANS[key].interval;
  const expectedDays = interval === 'month' ? 30 : 365;
  if (!/^plan_[\w-]+$/.test(plan.id) || plan.plan_type !== 'renewal' ||
      plan.billing_period !== expectedDays || !/^[a-z]{3}$/i.test(plan.currency) ||
      !Number.isFinite(plan.renewal_price) || plan.renewal_price <= 0 ||
      !Number.isFinite(plan.initial_price) || plan.initial_price < 0) {
    throw new Error(`Whop returned unsupported pricing for ${key}.`);
  }
  return {
    id: plan.id,
    currency: plan.currency.toUpperCase(),
    renewalPrice: plan.renewal_price,
    initialPrice: plan.initial_price,
    interval,
    billingPeriodDays: plan.billing_period,
    trialDays: Math.max(0, plan.trial_period_days ?? 0),
    taxType: plan.tax_type === 'inclusive' || plan.tax_type === 'exclusive'
      ? plan.tax_type : 'unspecified',
    collectTax: Boolean(plan.collect_tax),
  };
}

export function formatWhopPrice(amount: number, currency: string): string {
  return new Intl.NumberFormat('en', { style: 'currency', currency: currency.toUpperCase() }).format(amount);
}

export function yearlySavings(month: WhopPlanQuote | undefined, year: WhopPlanQuote | undefined): number | null {
  if (!month || !year || month.currency !== year.currency) return null;
  const difference = month.renewalPrice * 12 - year.renewalPrice;
  return difference > 0 ? Math.round((difference / (month.renewalPrice * 12)) * 100) : null;
}
