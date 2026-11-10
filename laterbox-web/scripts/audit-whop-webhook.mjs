// laterbox-web/scripts/audit-whop-webhook.mjs
// Read-only Whop webhook audit. Does not print API keys, signing secrets, or
// private webhook IDs. Called from the LaterBox production environment.
import nextEnv from '@next/env';
const {loadEnvConfig}=nextEnv;
loadEnvConfig(new URL('../', import.meta.url).pathname);

const apiKey=process.env.WHOP_COMPANY_API_KEY;
const companyId=process.env.WHOP_COMPANY_ID;
if(!apiKey?.startsWith('apik_')||!companyId?.startsWith('biz_')) throw Error('Missing Whop business API key or company ID.');
const url='https://app.laterbox.dev/api/billing/whop/webhook';
const expected=new Set([
  'payment.succeeded','payment.failed','payment.pending',
  'membership.activated','membership.deactivated','membership.updated',
  'membership.cancel_at_period_end_changed','refund.created','refund.updated',
  'dispute.created','dispute.updated',
]);
const response=await fetch('https://api.whop.com/api/v1/webhooks?first=100&account_id='+encodeURIComponent(companyId),{
  headers:{Authorization:`Bearer ${apiKey}`},cache:'no-store',
  signal:AbortSignal.timeout(16000),
});
const body=await response.json().catch(()=>({}));
if(!response.ok) {
  console.error('Whop webhook listing rejected:',response.status, JSON.stringify(body?.error||{}).slice(0,350));
  process.exitCode=1;
} else {
  const hooks=Array.isArray(body.data)?body.data:[];
  console.log('Whop webhook audit:',hooks.length,'configured endpoints visible to this API key');
  for(const [idx,hook] of hooks.entries()) {
    const target=hook.url===url;
    const account=hook.resource_id===companyId;
    const events=new Set(Array.isArray(hook.events)?hook.events:[]);
    const missing=[...expected].filter(event=>!events.has(event));
    console.log('Webhook',idx+1,{matchesLaterBoxURL:target,matchesCompany:account,
      enabled:hook.enabled,apiVersion:hook.api_version,
      actualEvents:target?[...events].sort():undefined,
      missingRequiredEvents:target?missing:undefined});
  }
  if(!hooks.some(h=>h.url===url))console.log('Action required: no webhook pointing at the LaterBox production endpoint was visible.');
}
