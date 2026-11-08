// laterbox-web/scripts/provision-whop-catalog.ts
/**
 * Idempotent LaterBox product + plan provisioning.
 *
 * Dry run (no network requests):
 *   npm run whop:provision
 *
 * Live creation requires a deliberate, separate confirmation:
 *   WHOP_CONFIRM_PRODUCTION=CREATE_LIVE_CATALOG npm run whop:provision -- --apply --production
 *
 * Whop API credentials must be server-side secrets in .env.local or the
 * execution environment. This script never logs or writes the API key.
 */
import { loadEnvConfig } from '@next/env';
import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import {
  WHOP_CATALOG_PLANS, WHOP_CATALOG_PRODUCTS,
  existingWhopPlan, existingWhopProduct,
  type WhopPlanRecord, type WhopProductRecord,
} from '../src/lib/billing/whop-catalog';

loadEnvConfig(process.cwd());
const args = new Set(process.argv.slice(2));
const apply = args.has('--apply');
const production = args.has('--production');
const sandbox = args.has('--sandbox');
if (production && sandbox) throw new Error('Choose --production or --sandbox, not both.');

const environment = production ? 'production' : sandbox ? 'sandbox' : null;
const companyId = process.env.WHOP_COMPANY_ID?.trim();
const apiKey = process.env.WHOP_COMPANY_API_KEY?.trim();

function describeCatalog() {
  console.log('\nLaterBox Whop catalog (USD):');
  for (const product of WHOP_CATALOG_PRODUCTS) {
    console.log(`  Product: ${product.title}`);
    for (const plan of WHOP_CATALOG_PLANS.filter(plan => plan.product === product.tier)) {
      console.log(`    ${plan.title}: $${plan.renewalPrice.toFixed(2)} / ${plan.billingPeriod} days`);
    }
  }
}

interface Page<T> {
  data: T[];
  page_info?: { end_cursor?: string | null; has_next_page?: boolean };
}

function makeRequest(base: string, token: string) {
  return async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const response = await fetch(base + path, {
      ...init,
      signal: AbortSignal.timeout(15000),
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...init.headers,
      },
    });
    const payload: unknown = await response.json().catch(() => null);
    if (!response.ok) {
      const detail =
        payload && typeof payload === 'object' && 'error' in payload
          ? JSON.stringify(payload.error).slice(0, 400)
          : `HTTP ${response.status}`;
      throw new Error(`Whop ${init.method ?? 'GET'} ${path.split('?')[0]} failed (${response.status}): ${detail}`);
    }
    return payload as T;
  };
}

async function allPages<T>(
  request: ReturnType<typeof makeRequest>,
  resource: 'products' | 'plans',
  business: string,
): Promise<T[]> {
  let after: string | undefined;
  const all: T[] = [];
  for (let page = 0; page < 30; page++) {
    const query = new URLSearchParams({ company_id: business, first: '100' });
    if (after) query.set('after', after);
    const result = await request<Page<T>>(`/${resource}?${query.toString()}`);
    if (!Array.isArray(result.data)) throw new Error(`Whop returned an invalid ${resource} response.`);
    all.push(...result.data);
    if (!result.page_info?.has_next_page) return all;
    if (!result.page_info.end_cursor || result.page_info.end_cursor === after) {
      throw new Error(`Cannot paginate Whop ${resource} safely; refusing to create duplicates.`);
    }
    after = result.page_info.end_cursor;
  }
  throw new Error(`Too many Whop ${resource} pages; refusing to create duplicates.`);
}

async function persistLocalPlanIds(
  ids: Record<string, string>,
): Promise<void> {
  const path = resolve(process.cwd(), '.env.local');
  const oldContent = await readFile(path, 'utf8').catch(error => {
    if (error?.code === 'ENOENT') return '';
    throw error;
  });
  const lines = oldContent ? oldContent.replace(/\n$/, '').split(/\r?\n/) : [];
  for (const [name, value] of Object.entries(ids)) {
    if (!/^[A-Z0-9_]+$/.test(name) || !/^[a-zA-Z0-9_-]+$/.test(value)) {
      throw new Error('Refusing to write invalid Whop environment values.');
    }
    const i = lines.findIndex(line => new RegExp(`^\\s*${name}=`).test(line));
    if (i >= 0) lines[i] = `${name}=${value}`;
    else lines.push(`${name}=${value}`);
  }
  await writeFile(path, lines.join('\n') + '\n', { mode: 0o600 });
}

async function main() {
  if (args.has('--help') || args.has('-h')) {
    describeCatalog();
    console.log('\nUsage: npm run whop:provision [-- --apply --sandbox|--production]');
    return;
  }
  describeCatalog();
  if (!apply) {
    console.log('\nDRY RUN: No Whop requests made or products created.');
    console.log('Set WHOP_COMPANY_API_KEY and WHOP_COMPANY_ID in .env.local, then use --apply --sandbox for testing.');
    console.log('Live provisioning: WHOP_CONFIRM_PRODUCTION=CREATE_LIVE_CATALOG npm run whop:provision -- --apply --production');
    return;
  }
  if (!environment) throw new Error('--apply requires either --sandbox or --production.');
  if (production && process.env.WHOP_CONFIRM_PRODUCTION !== 'CREATE_LIVE_CATALOG') {
    throw new Error('Live products require WHOP_CONFIRM_PRODUCTION=CREATE_LIVE_CATALOG. Prices will be charged to real customers.');
  }
  if (!companyId || !/^biz_[a-zA-Z0-9_-]+$/.test(companyId)) {
    throw new Error('Set WHOP_COMPANY_ID=biz_... in laterbox-web/.env.local.');
  }
  if (!apiKey?.startsWith('apik_')) {
    throw new Error('Set a Whop company API key (apik_...) as WHOP_COMPANY_API_KEY in .env.local; never use NEXT_PUBLIC_.');
  }
  const base = production
    ? 'https://api.whop.com/api/v1'
    : 'https://sandbox-api.whop.com/api/v1';
  const request = makeRequest(base, apiKey);
  console.log(`\nChecking existing ${environment} products and plans for ${companyId}...`);
  const products = await allPages<WhopProductRecord>(request, 'products', companyId);
  const plans = await allPages<WhopPlanRecord>(request, 'plans', companyId);
  const productIds = new Map<string, string>();
  for (const desired of WHOP_CATALOG_PRODUCTS) {
    const found = existingWhopProduct(products, desired);
    if (found) {
      console.log(`Reusing product ${found.title}: ${found.id}`);
      productIds.set(desired.tier, found.id);
      continue;
    }
    const created = await request<WhopProductRecord>('/products', {
      method: 'POST',
      body: JSON.stringify({
        company_id: companyId,
        title: desired.title,
        description: desired.description,
      }),
    });
    if (!created.id?.startsWith('prod_')) throw new Error('Whop did not return a valid product ID.');
    products.push(created);
    productIds.set(desired.tier, created.id);
    console.log(`Created product ${created.title}: ${created.id}`);
  }

  const ids: Record<string, string> = {
    WHOP_SANDBOX: production ? 'false' : 'true',
    WHOP_COMPANY_ID: companyId,
  };
  for (const desired of WHOP_CATALOG_PLANS) {
    const productId = productIds.get(desired.product);
    if (!productId) throw new Error(`Product not found for ${desired.key}.`);
    const found = existingWhopPlan(plans, productId, desired);
    const record = found ?? await request<WhopPlanRecord>('/plans', {
      method: 'POST',
      body: JSON.stringify({
        company_id: companyId,
        product_id: productId,
        title: desired.title,
        description: `LaterBox ${desired.title} subscription`,
        plan_type: 'renewal',
        release_method: 'buy_now',
        visibility: 'visible',
        currency: 'usd',
        billing_period: desired.billingPeriod,
        initial_price: 0,
        renewal_price: desired.renewalPrice,
        unlimited_stock: true,
      }),
    });
    if (!record.id?.startsWith('plan_')) throw new Error('Whop did not return a valid plan ID.');
    if (!found) plans.push(record);
    const envName = `WHOP_${desired.key.toUpperCase().replace('_MONTH', '_MONTHLY').replace('_YEAR', '_YEARLY')}_PLAN_ID`;
    ids[envName] = record.id;
    console.log(`${found ? 'Reusing' : 'Created'} ${desired.title}: ${record.id}`);
  }
  await persistLocalPlanIds(ids);
  console.log('\nCreated or verified the LaterBox catalog. Plan IDs were written to the ignored .env.local.');
  console.log('Keep WHOP_COMPANY_API_KEY server-only. Set corresponding values in your production server environment before deploying.');
}

main().catch(error => {
  console.error(error instanceof Error ? error.message : 'Whop catalog provisioning failed.');
  process.exitCode = 1;
});
