// laterbox-web/src/lib/billing/pricing-proposal.ts
// BUSINESS RESEARCH DRAFT — NOT USED BY CHECKOUT, ENTITLEMENTS OR WHOP.
// This is a scenario model, not the active product catalog or a price change.
// All monetary values in USD; storage quotas in binary GiB (1024^3 bytes).
export type ProposedPlan = Readonly<{
  key: string;
  name: string;
  quotaGiB: number;
  monthUsd: number;
  yearUsd: number;
  operationsReservePerMonthUsd: number;
  featured?: boolean;
}>;

export const PROPOSED_LATERBOX_PLANS: readonly ProposedPlan[] = [
  { key: 'plus_10', name: 'Plus', quotaGiB: 10, monthUsd: 2.99, yearUsd: 29.99, operationsReservePerMonthUsd: 0.35, featured: true },
  { key: 'plus_50', name: 'Plus 50', quotaGiB: 50, monthUsd: 4.99, yearUsd: 49.99, operationsReservePerMonthUsd: 0.50 },
  { key: 'vault_100', name: 'Vault', quotaGiB: 100, monthUsd: 6.99, yearUsd: 69.99, operationsReservePerMonthUsd: 0.75, featured: true },
  { key: 'vault_250', name: 'Vault 250', quotaGiB: 250, monthUsd: 11.99, yearUsd: 119.99, operationsReservePerMonthUsd: 1.00 },
  { key: 'vault_500', name: 'Vault 500', quotaGiB: 500, monthUsd: 19.99, yearUsd: 209.99, operationsReservePerMonthUsd: 1.25, featured: true },
  { key: 'vault_1024', name: 'Vault 1 TB', quotaGiB: 1024, monthUsd: 39.99, yearUsd: 419.99, operationsReservePerMonthUsd: 2.00 },
  { key: 'vault_2048', name: 'Vault 2 TB', quotaGiB: 2048, monthUsd: 69.99, yearUsd: 739.99, operationsReservePerMonthUsd: 3.00 },
] as const;

// Public supplier rates verified Nov 9, 2026.
// R2 Standard $0.015 per *decimal* GB-month, and 1 GiB = 1.073741824 GB.
// See https://developers.cloudflare.com/r2/pricing/
// Whop domestic card payment 2.7% + $0.30; optional billing 0.5%
// and tax-handling 2% when taxes are collected.
// See https://whop.com/network/pricing/
// IMPORTANT: International/currency surcharges, refunds, payout charges,
// AI inference, support, infrastructure redundancy and business taxes are
// not included. Operations reserve is hypothetical, NOT measured usage.
export const PRICING_COST_ASSUMPTIONS = {
  r2StandardPerDecimalGBMonthUsd: 0.015,
  whopCardRate: 0.027,
  whopCardFixedUsd: 0.30,
  whopBillingRate: 0.005,
  whopTaxProcessingRate: 0.02,
  launchAffiliateRate: 0.15,
  ongoingAffiliateRate: 0.10,
} as const;

export type PricingScenario = Readonly<{
  period: 'month' | 'year';
  quotaUtilization: number;
  affiliateRate: number;
  extraVariableFeeRate: number;
}>;
export type PricingContribution = Readonly<{
  revenueUsd: number;
  paymentAndBillingFeesUsd: number;
  commissionUsd: number;
  r2StorageUsd: number;
  operationalReserveUsd: number;
  contributionUsd: number;
  contributionPercent: number;
}>;

export function scenarioContribution(
  plan: ProposedPlan,
  scenario: PricingScenario,
): PricingContribution {
  const { period, quotaUtilization, affiliateRate, extraVariableFeeRate } = scenario;
  if (![quotaUtilization, affiliateRate, extraVariableFeeRate].every(v =>
    Number.isFinite(v) && v >= 0 && v <= 1)) {
    throw new RangeError('Scenario rates must be between 0 and 1.');
  }
  const months = period === 'year' ? 12 : 1;
  const revenueUsd = period === 'year' ? plan.yearUsd : plan.monthUsd;
  const costs = PRICING_COST_ASSUMPTIONS;
  const percentageFees = costs.whopCardRate + costs.whopBillingRate
    + costs.whopTaxProcessingRate + extraVariableFeeRate;
  const paymentAndBillingFeesUsd = revenueUsd * percentageFees
    + costs.whopCardFixedUsd;
  const commissionUsd = (revenueUsd - paymentAndBillingFeesUsd) * affiliateRate;
  const r2StorageUsd = plan.quotaGiB * (1024 ** 3 / 1_000_000_000)
    * costs.r2StandardPerDecimalGBMonthUsd * months * quotaUtilization;
  const operationalReserveUsd = plan.operationsReservePerMonthUsd * months;
  const contributionUsd = revenueUsd - paymentAndBillingFeesUsd
    - commissionUsd - r2StorageUsd - operationalReserveUsd;
  return {
    revenueUsd, paymentAndBillingFeesUsd, commissionUsd, r2StorageUsd,
    operationalReserveUsd, contributionUsd,
    contributionPercent: revenueUsd ? contributionUsd / revenueUsd * 100 : 0,
  };
}
