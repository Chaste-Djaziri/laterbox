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
  whopCatalogQuery, whopProductCreateBody, whopPlanCreateBody,
  type WhopPlanRecord, type WhopProductRecord,
} from '../src/lib/billing/whop-catalog';

loadEnvConfig(process.cwd());
const args = new Set(process.argv.slice(2));
const apply = args.has('--apply');
const inspect = args.has('--inspect');
if (apply && inspect) throw new Error('Use --inspect OR --apply, not both.');
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
    const query = whopCatalogQuery(business, after);
    const result = await request<Page<T>>(`/${resource}?${query}`);
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

/** Read-only pagination trace; prints no credentials, titles, IDs or opaque cursors. */
async function inspectPagination(
  request: ReturnType<typeof makeRequest>,
  resource: 'products' | 'plans',
  business: string,
) {
  const seenIds = new Set<string>();
  let cursor: string | undefined;
  console.log(`\nInspecting ${resource} (read-only, first 3 pages maximum)...`);
  for (let page = 1; page <= 3; page++) {
    const query = whopCatalogQuery(business, cursor);
    const result = await request<Page<{id?: string}>>(`/${resource}?${query}`);
    if (!Array.isArray(result.data)) throw new Error(`Whop returned an invalid ${resource} response.`);
    const before = seenIds.size;
    for (const item of result.data) {
      if (item && typeof item.id === 'string') seenIds.add(item.id);
      if (resource === 'plans' && item && typeof item.id === 'string') {
        const row=item as {id:string;title?:string;plan_type?:string;billing_period?:number;initial_price?:number;renewal_price?:number;currency?:string};
        console.log(`    Plan: ${row.title??'unnamed'} / ${row.billing_period??'none'}d / ${row.currency??'?'} ${row.renewal_price??'?'} / initial ${row.initial_price??'?'} / type ${row.plan_type??'?'}`);
      }
    }
    const newIds = seenIds.size - before;
    const hasNext = result.page_info?.has_next_page;
    const nextCursor = result.page_info?.end_cursor;
    console.log(`  Page ${page}: rows=${result.data.length}, newIds=${newIds}, hasNext=${String(hasNext)}, cursorChanged=${nextCursor != null && nextCursor !== cursor}`);
    if (!hasNext) break;
    if (!nextCursor || nextCursor === cursor) {
      console.log('  STOP: pagination cursor missing or repeated.');
      break;
    }
    cursor = nextCursor;
  }
  console.log('Read-only inspection finished. No products or plans created.');
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
    console.log('\nUsage: npm run whop:provision [-- --inspect|--apply --sandbox|--production]');
    return;
  }
  describeCatalog();
  if (!apply && !inspect) {
    console.log('\nDRY RUN: No Whop requests made or products created.');
    console.log('Set WHOP_COMPANY_API_KEY and WHOP_COMPANY_ID in .env.local, then use --apply --sandbox for testing.');
    console.log('Live provisioning: WHOP_CONFIRM_PRODUCTION=CREATE_LIVE_CATALOG npm run whop:provision -- --apply --production');
    return;
  }
  if (!environment) throw new Error('--inspect or --apply requires either --sandbox or --production.');
  if (production && apply && process.env.WHOP_CONFIRM_PRODUCTION !== 'CREATE_LIVE_CATALOG') {
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
  if (inspect) {
    await inspectPagination(request, 'products', companyId);
    await inspectPagination(request, 'plans', companyId);
    return;
  }
  console.log(`\\nChecking existing ${environment} products and plans for ${companyId}...`);
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
      body: JSON.stringify(whopProductCreateBody(companyId, desired)),
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
    // Whop's list endpoint can omit plan_type, which the safety validator
    // requires. Retrieve the matching full plan before checking its terms.
    const named = plans.filter(plan => plan.product?.id === productId && plan.title === desired.title);
    if (named.length > 1) throw new Error(`Duplicate plan title: ${desired.title}`);
    const complete = named[0]
      ? await request<WhopPlanRecord>(`/plans/${named[0].id}`) : null;
    if (complete) {
      console.log('Existing plan terms (no secrets):', JSON.stringify({
        title:complete.title, planType:complete.plan_type,billingPeriod:complete.billing_period,
        renewal:complete.renewal_price,initial:complete.initial_price,
        currency:complete.currency,product:complete.product?.id,
      }));
    }
    const found = complete ? existingWhopPlan([complete], productId, desired) : null;
    const record = found ?? await request<WhopPlanRecord>('/plans', {
      method: 'POST',
      body: JSON.stringify(whopPlanCreateBody(companyId, productId, desired)),
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
