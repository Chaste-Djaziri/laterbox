/** Run with tsx --env-file=.env scripts/import-clerk-users.ts export.json [--execute]. */
import { readFile } from 'node:fs/promises';
import { clerkAdmin, linkClerk } from '../src/lib/auth/server';
import { getBillingAdminClient } from '../src/lib/billing/server';

async function main() {

type LegacyExport = { id: string; email: string | null; email_confirmed_at: string | null; encrypted_password?: string; raw_user_meta_data?: { display_name?: string }; mfa_enabled: boolean };
const file = process.argv[2];
if (!file || file.startsWith('--')) throw new Error('Supply a Supabase JSON export. The default is dry-run; add --execute to import.');
const execute = process.argv.includes('--execute');
const users = JSON.parse(await readFile(file,'utf8')) as LegacyExport[];
if (!Array.isArray(users)) throw new Error('Expected a JSON array.');
const admin = getBillingAdminClient();
const counts = { imported: 0, alreadyLinked: 0, eligible: 0, manual: 0, failed: 0 };
for (const user of users) {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(user.id) || typeof user.mfa_enabled !== 'boolean') throw new Error('Invalid export: every user must have a UUID and mfa_enabled boolean.');
  if (!user.email || user.mfa_enabled || (user.encrypted_password && !/^\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}$/.test(user.encrypted_password))) { counts.manual++; continue; }
  try {
    const { data: identity,error } = await admin.from('account_identities').select('subject').eq('provider','clerk').eq('account_id',user.id).maybeSingle();
    if (error) throw error;
    if (identity) { counts.alreadyLinked++; continue; }
    const { data: account,error: accountError } = await admin.from('accounts').select('id,state').eq('id',user.id).maybeSingle();
    if (accountError || !account || account.state !== 'active') throw new Error('Missing or inactive account. Apply migrations first.');
    counts.eligible++;
    if (!execute) continue;
    const clerk = clerkAdmin();
    const matches = await clerk.users.getUserList({ externalId: [user.id],limit: 1 });
    const rawName = user.raw_user_meta_data?.display_name;
    const fallbackName = user.email.split('@')[0].replace(/[._-]/g, ' ');
    const fullName = (rawName && rawName.trim()) || fallbackName;
    const nameParts = fullName.trim().split(/\s+/);
    const firstName = nameParts[0] || 'User';
    const lastName = nameParts.slice(1).join(' ') || undefined;

    const migrated = matches.data[0] || await clerk.users.createUser({
      externalId: user.id,
      emailAddress: [user.email],
      emailAddressIdentificationStatus: [user.email_confirmed_at ? 'verified' : 'reserved'],
      firstName,
      ...(lastName ? { lastName } : {}),
      skipLegalChecks: true,
      ...(user.encrypted_password ? { passwordDigest: user.encrypted_password,passwordHasher: 'bcrypt' as const } : { skipPasswordRequirement: true }),
    });
    await linkClerk(user.id,migrated.id);
    counts.imported++;
  } catch (cause) {
    counts.failed++;
    const errMsg = (cause as { errors?: { message?: string; longMessage?: string }[] })?.errors?.[0]?.longMessage ||
                   (cause as { errors?: { message?: string }[] })?.errors?.[0]?.message ||
                   (cause as Error)?.message || String(cause);
    console.error(`Import failed for account ${user.id}: ${errMsg}`);
  }
}
console.info(JSON.stringify({ mode: execute ? 'execute' : 'dry-run',...counts }));
if (counts.failed || counts.manual) process.exitCode = 1;
}
void main().catch(() => { console.error("Operation failed. Check the input and server configuration; credentials and provider responses are excluded from logs."); process.exitCode = 1; });
