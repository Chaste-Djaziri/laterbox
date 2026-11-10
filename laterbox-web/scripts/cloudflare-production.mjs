// laterbox-web/scripts/cloudflare-production.mjs
// Deploy the LaterBox production Worker without leaking local Supabase values or Whop secrets.
// Use: npm run cf:sync-secrets ; npm run cf:deploy-production
import { readFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const mode = process.argv[2];
if (!['validate', 'sync-secrets', 'sync-earn-secrets', 'deploy', 'upload', 'activate-upload'].includes(mode)) {
  throw new Error('Expected one of: validate | sync-secrets | sync-earn-secrets | deploy | upload | activate-upload');
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
const referralTrialPlanKeys = ['PLUS','PLUS50','VAULT','VAULT250','VAULT500','VAULT1TB','VAULT2TB']
  .flatMap(tier => ['MONTHLY','YEARLY'].map(period => `WHOP_${tier}_${period}_REFERRAL_TRIAL_PLAN_ID`));
const optionalEarnSecrets = [
  'WHOP_CLIENT_ID','WHOP_CLIENT_SECRET','WHOP_OAUTH_REDIRECT_URI',
  'EARN_OAUTH_COOKIE_SECRET','EARN_CRON_SECRET','WHOP_BUSINESS_ID',
];
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
  ...referralTrialPlanKeys,
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
const secretPayload = Object.fromEntries(
  [...required,...optionalEarnSecrets.filter(name => Boolean(env[name]))]
    .map(name => [name, env[name]])
);
const missingEarnSecrets=optionalEarnSecrets.filter(name=>!env[name]);
if(missingEarnSecrets.length) console.log('Optional Earn production variables not configured:',missingEarnSecrets.join(', '));
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

if (mode === 'validate') {
  console.log('Validated production Whop, Supabase, 14 standard and 14 referral-trial plan bindings. No changes made.');
} else if (mode === 'sync-earn-secrets') {
  if (missingEarnSecrets.length) throw new Error('Earn variables missing; nothing was synchronized.');
  const earnSecrets = Object.fromEntries(optionalEarnSecrets.map(name=>[name,env[name]]));
  console.log('Syncing '+Object.keys(earnSecrets).length+' Earn-only encrypted bindings; existing billing variables are untouched.');
  await run('npx',['wrangler','secret','bulk','--name','laterbox-web'],{stdin:JSON.stringify(earnSecrets)});
  console.log('Whop Earn OAuth and settlement secrets synchronized.');
} else if (mode === 'sync-secrets') {
  console.log(`Syncing ${Object.keys(secretPayload).length} encrypted runtime variables to Worker laterbox-web.`);
  console.log('Secret values will not be displayed, written to disk, or committed.');
  await run('npx', ['wrangler', 'secret', 'bulk', '--name', 'laterbox-web'], {
    stdin: JSON.stringify(secretPayload),
  });
  console.log('Cloudflare Worker secrets updated.');
} else if (mode === 'activate-upload') {
  console.log('Activating most recently uploaded Worker version without changing domain routes.');
  await run('npx',['wrangler','versions','deploy','--name','laterbox-web','--yes']);
} else {
  console.log('Deploying LaterBox to Cloudflare with production Supabase and app origin.');
  console.log('Next.js build will not use .env.local to override production values.');
  await run('npm', ['run', mode === 'upload' ? 'upload' : 'deploy']);
  console.log(mode === 'upload' ? 'Production Worker version uploaded; activation still required.' : 'Production Worker deployment completed.');
}
