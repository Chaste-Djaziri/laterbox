import { getBillingAdminClient } from '../src/lib/billing/server';
import { deleteApplicationAccount } from '../src/lib/auth/delete-account';

const execute = process.argv.includes('--execute');
const { data,error } = await getBillingAdminClient().from('account_deletion_jobs').select('account_id').is('completed_at',null);
if (error) throw new Error('Unable to list pending deletion jobs.');
let completed = 0;
let failed = 0;
if (execute) for (const job of data || []) {
  try { await deleteApplicationAccount(job.account_id); completed++; }
  catch { failed++; console.error(`Cleanup remains pending for ${job.account_id}.`); }
}
console.info(JSON.stringify({ mode: execute ? 'execute' : 'dry-run',pending: data?.length || 0,completed,failed }));
if (failed) process.exitCode = 1;
