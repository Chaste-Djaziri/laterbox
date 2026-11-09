import { WhopClient, WhopEnvironment } from '@whop/sdk';
import { WHOP_STORAGE_PLANS, type WhopPlanKey } from './storage-plans';
export { WHOP_STORAGE_PLANS, FREE_STORAGE_BYTES, LEGACY_PRO_STORAGE_BYTES, parseWhopPlan } from './storage-plans';

export function planEnvName(key: WhopPlanKey): string {
  return 'WHOP_' + key.toUpperCase()
    .replace('_MONTH', '_MONTHLY').replace('_YEAR', '_YEARLY') + '_PLAN_ID';
}
export function referralTrialPlanEnvName(key: WhopPlanKey): string {
  return planEnvName(key).replace('_PLAN_ID', '_REFERRAL_TRIAL_PLAN_ID');
}
export const REFERRAL_TRIAL_PLAN_ENV = Object.fromEntries(
  (Object.keys(WHOP_STORAGE_PLANS) as WhopPlanKey[])
    .map(key => [key, referralTrialPlanEnvName(key)])
) as Record<WhopPlanKey, string>;
export function whopReferralTrialPlanId(key: WhopPlanKey): string {
  const id = process.env[REFERRAL_TRIAL_PLAN_ENV[key]]?.trim();
  if (!id || !/^plan_[a-zA-Z0-9_-]+$/.test(id)) {
    throw new Error('Referral free-trial checkout has not been configured.');
  }
  return id;
}
export function isWhopReferralTrialPlan(planId: string): boolean {
  return Object.values(REFERRAL_TRIAL_PLAN_ENV).some(name=>process.env[name]===planId);
}

export function whopPlanId(key: WhopPlanKey): string {
  const id = process.env[planEnvName(key)]?.trim();
  if (!id || !/^plan_[a-zA-Z0-9_-]+$/.test(id)) {
    throw new Error(`Whop price ${key} is not configured.`);
  }
  return id;
}
export function storagePlanForWhopId(planId: string): WhopPlanKey | null {
  for (const key of Object.keys(WHOP_STORAGE_PLANS) as WhopPlanKey[]) {
    if (process.env[planEnvName(key)] === planId || process.env[REFERRAL_TRIAL_PLAN_ENV[key]] === planId) return key;
  }
  return null;
}
export function whopEnvironment(): 'sandbox' | 'production' {
  return process.env.WHOP_SANDBOX === 'false' ? 'production' : 'sandbox';
}

let sandboxClient: WhopClient | undefined;
let productionClient: WhopClient | undefined;
export function whopServer(): WhopClient {
  const token = process.env.WHOP_COMPANY_API_KEY;
  if (!token) throw new Error('WHOP_COMPANY_API_KEY is not configured.');
  if (whopEnvironment() === 'sandbox') {
    return sandboxClient ??= new WhopClient({ token, environment: WhopEnvironment.Sandbox });
  }
  return productionClient ??= new WhopClient({ token, environment: WhopEnvironment.Production });
}
