// laterbox-web/scripts/cloudflare-production.mjs
// Deploy the LaterBox production Worker without leaking local Supabase values or Whop secrets.
// Use: npm run cf:sync-secrets ; npm run cf:deploy-production
import { readFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const mode = process.argv[2];
if (!['sync-secrets', 'deploy'].includes(mode)) {
  throw new Error('Expected one of: sync-secrets | deploy');
}

function parseDotEnv(content) {
  const values = {};
  for (const line of content.split(/\r?\n/)) {
    const match = line.match(/^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!match) continue;
    let value = match[2].trim();
    if (/^["']/.test(value) && value.at(-1) === value[0]) value = value.slice(1, -1);
    values[match[1]] = value;
  }
  return values;
}

const env = parseDotEnv(await readFile(resolve(root, '.env'), 'utf8'));
const required = [
  'WHOP_COMPANY_ID',
  'WHOP_COMPANY_API_KEY',
  'WHOP_WEBHOOK_SECRET',
  'WHOP_PLUS_MONTHLY_PLAN_ID',
  'WHOP_PLUS_YEARLY_PLAN_ID',
  'WHOP_VAULT_MONTHLY_PLAN_ID',
  'WHOP_VAULT_YEARLY_PLAN_ID',
  'WHOP_PLUS50_MONTHLY_PLAN_ID',
  'WHOP_PLUS50_YEARLY_PLAN_ID',
  'WHOP_VAULT250_MONTHLY_PLAN_ID',
  'WHOP_VAULT250_YEARLY_PLAN_ID',
  'WHOP_VAULT500_MONTHLY_PLAN_ID',
  'WHOP_VAULT500_YEARLY_PLAN_ID',
  'WHOP_VAULT1TB_MONTHLY_PLAN_ID',
  'WHOP_VAULT1TB_YEARLY_PLAN_ID',
  'WHOP_VAULT2TB_MONTHLY_PLAN_ID',
  'WHOP_VAULT2TB_YEARLY_PLAN_ID',
  'WHOP_SANDBOX',
  'NEXT_PUBLIC_SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  'SUPABASE_SERVICE_ROLE_KEY',
];
for (const name of required) {
  if (!env[name]) throw new Error(`Production .env is missing ${name}. No changes were made.`);
}
if (env.WHOP_SANDBOX !== 'false') throw new Error('Refusing to deploy sandbox billing to production.');
if (!/^https:\/\/[\w.-]+\.supabase\.co\/?$/.test(env.NEXT_PUBLIC_SUPABASE_URL)) {
  throw new Error('Production Supabase must be an HTTPS *.supabase.co endpoint.');
}
if (!/^biz_[\w-]+$/.test(env.WHOP_COMPANY_ID)) throw new Error('Invalid Whop business ID.');
if (!/^apik_[\w-]+$/.test(env.WHOP_COMPANY_API_KEY)) throw new Error('Invalid Whop company API key.');
if (!/^ws_[\w-]+$/.test(env.WHOP_WEBHOOK_SECRET)) throw new Error('Invalid Whop webhook signing key.');
for (const key of required.filter(name => name.endsWith('_PLAN_ID'))) {
  if (!/^plan_[\w-]+$/.test(env[key])) throw new Error(`Invalid ${key}.`);
}
// The user runs local Supabase in .env.local. Never allow its values in a production build.
const dev = parseDotEnv(await readFile(resolve(root, '.env.local'), 'utf8').catch(() => ''));
const missingProductionOverrides = Object.keys(dev).filter(k => !(k in env));
if (missingProductionOverrides.length) {
  throw new Error(`Production .env is missing local overrides for: ${missingProductionOverrides.join(', ')}`);
}
const productionOrigin = 'https://app.laterbox.dev';
const prodEnv = {
  ...process.env,
  ...env,
  NODE_ENV: 'production',
  NEXTJS_ENV: 'production',
  NEXT_PUBLIC_APP_ORIGIN: productionOrigin,
};
const secretPayload = Object.fromEntries(required.map(name => [name, env[name]]));
secretPayload.NEXT_PUBLIC_APP_ORIGIN = productionOrigin;
const privateValues = Object.values(secretPayload).filter(value => value.length > 8);
function redact(message) {
  return privateValues.reduce((text, secret) => text.replaceAll(secret, '[REDACTED]'), String(message));
}

function run(executable, argv, { stdin } = {}) {
  return new Promise((resolveRun, rejectRun) => {
    const child = spawn(executable, argv, { cwd: root, env: prodEnv, stdio: [stdin ? 'pipe' : 'ignore', 'pipe', 'pipe'] });
    child.stdout.on('data', chunk => process.stdout.write(redact(chunk.toString())));
    child.stderr.on('data', chunk => process.stderr.write(redact(chunk.toString())));
    child.on('error', rejectRun);
    child.on('close', code => code === 0 ? resolveRun() : rejectRun(new Error(`${argv.join(' ')} failed (exit ${code}).`)));
    if (stdin) child.stdin.end(stdin);
  });
}

if (mode === 'sync-secrets') {
  console.log(`Syncing ${Object.keys(secretPayload).length} encrypted runtime variables to Worker laterbox-web.`);
  console.log('Secret values will not be displayed, written to disk, or committed.');
  await run('npx', ['wrangler', 'secret', 'bulk', '--name', 'laterbox-web'], {
    stdin: JSON.stringify(secretPayload),
  });
  console.log('Cloudflare Worker secrets updated.');
} else {
  console.log('Deploying LaterBox to Cloudflare with production Supabase and app origin.');
  console.log('Next.js build will not use .env.local to override production values.');
  await run('npm', ['run', 'deploy']);
  console.log('Production Worker deployment completed.');
}
