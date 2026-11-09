// laterbox-web/scripts/sync-whop-webhook.mjs
// Idempotent production webhook event sync. Never changes URL, API version,
// enabled state, or signing secret. Preserves all existing subscriptions.
import nextEnv from '@next/env';
const {loadEnvConfig}=nextEnv;
loadEnvConfig(new URL('../',import.meta.url).pathname);
const key=process.env.WHOP_COMPANY_API_KEY;
const company=process.env.WHOP_COMPANY_ID;
const target='https://app.laterbox.dev/api/billing/whop/webhook';
const apply=process.argv.includes('--apply');
if(!key?.startsWith('apik_')||!company?.startsWith('biz_'))throw Error('Missing company credentials');
const headers={Authorization:`Bearer ${key}`,'Content-Type':'application/json'};
const base='https://api.whop.com/api/v1';
const desired=[
  'payment.succeeded','payment.failed','payment.pending',
  'membership.activated','membership.deactivated',
  'membership.cancel_at_period_end_changed','membership.trial_ending_soon',
  'refund.created','refund.updated','dispute.created','dispute.updated',
];
async function request(path,init={}) {
  const res=await fetch(base+path,{...init,headers,signal:AbortSignal.timeout(15000)});
  const body=await res.json().catch(()=>({}));
  if(!res.ok)throw Error(`Whop HTTP ${res.status}: ${JSON.stringify(body.error||body).slice(0,400)}`);
  return body;
}
const list=await request('/webhooks?first=100&account_id='+encodeURIComponent(company));
const matched=(list.data||[]).filter(h=>h.url===target&&h.resource_id===company);
if(matched.length!==1)throw Error(`Expected exactly one matching LaterBox webhook, found ${matched.length}`);
const webhook=await request('/webhooks/'+encodeURIComponent(matched[0].id));
if(webhook.url!==target||webhook.api_version!=='v1'||!webhook.enabled)throw Error('Webhook target/version/enabled state changed');
const old=Array.isArray(webhook.events)?webhook.events:[];
const missing=desired.filter(ev=>!old.includes(ev));
console.log('Whop webhook:',{urlMatch:true,apiVersion:webhook.api_version,enabled:webhook.enabled,
  subscribed:old.length,missing,alreadyConfigured:missing.length===0});
if(!apply) {
  console.log('DRY RUN: no changes made. Pass --apply to add missing event subscriptions.');
} else if(missing.length) {
  const next=[...new Set([...old,...desired])];
  const response=await request('/webhooks/'+encodeURIComponent(webhook.id),{
    method:'PATCH',body:JSON.stringify({events:next})
  });
  if(!response?.id||response.url!==target)throw Error('Webhook PATCH returned unexpected endpoint');
  const reread=await request('/webhooks/'+encodeURIComponent(webhook.id));
  const missed=desired.filter(ev=>!(reread.events||[]).includes(ev));
  const lost=old.filter(ev=>!(reread.events||[]).includes(ev));
  if(missed.length||lost.length)throw Error(`Post-update verification failed. Missing:${missed.join(',')} Lost:${lost.join(',')}`);
  console.log('Webhook updated and verified:',{totalEvents:reread.events.length,added:missing});
} else console.log('Already up to date.');
