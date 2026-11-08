import { WhopClient, WhopEnvironment } from '@whop/sdk';
import { type WhopPlanKey } from './storage-plans';
export { WHOP_STORAGE_PLANS, FREE_STORAGE_BYTES, LEGACY_PRO_STORAGE_BYTES, parseWhopPlan } from './storage-plans';

const PLAN_ENV: Record<WhopPlanKey, string> = {
  plus_month: 'WHOP_PLUS_MONTHLY_PLAN_ID',
  plus_year: 'WHOP_PLUS_YEARLY_PLAN_ID',
  vault_month: 'WHOP_VAULT_MONTHLY_PLAN_ID',
  vault_year: 'WHOP_VAULT_YEARLY_PLAN_ID',
};

export function whopPlanId(key: WhopPlanKey): string {
  const id = process.env[PLAN_ENV[key]]?.trim();
  if (!id || !/^plan_[a-zA-Z0-9_-]+$/.test(id)) {
    throw new Error(`Whop price ${key} is not configured.`);
  }
  return id;
}
export function storagePlanForWhopId(planId: string): WhopPlanKey | null {
  for (const key of Object.keys(PLAN_ENV) as WhopPlanKey[]) {
    if (process.env[PLAN_ENV[key]] === planId) return key;
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
