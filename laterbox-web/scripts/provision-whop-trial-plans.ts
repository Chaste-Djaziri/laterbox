// laterbox-web/scripts/provision-whop-trial-plans.ts
// Creates hidden Whop 30-day referral trial prices. Idempotent, never modifies
// standard subscription prices. Live creation needs explicit confirmation.
// Run with: npx tsx scripts/provision-whop-trial-plans.ts --production
import {loadEnvConfig} from '@next/env';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {WHOP_STORAGE_PLANS,type WhopPlanKey} from '../src/lib/billing/storage-plans';
import {referralTrialPlanEnvName} from '../src/lib/billing/whop';
loadEnvConfig(process.cwd());
const live=process.argv.includes('--production');
const apply=process.argv.includes('--apply');
if(apply&&live&&process.env.WHOP_CONFIRM_PRODUCTION!=='CREATE_LIVE_CATALOG')
  throw Error('Explicit production confirmation required.');
const company=process.env.WHOP_COMPANY_ID;
const key=process.env.WHOP_COMPANY_API_KEY;
if(!company?.startsWith('biz_')||!key?.startsWith('apik_'))throw Error('Whop company credentials missing');
const base=live?'https://api.whop.com/api/v1':'https://sandbox-api.whop.com/api/v1';
type WhopPlanInfo = {id:string;title:string;product:{id:string};renewal_price:number;
 billing_period:number;trial_period_days:number;visibility:string};
async function req<T=Record<string,unknown>>(path:string,init:RequestInit={}):Promise<T> {
 const response=await fetch(base+path,{...init,headers:{Authorization:`Bearer ${key}`,'Content-Type':'application/json'},
 signal:AbortSignal.timeout(15000)});
 const body=await response.json().catch(()=>({})) as T & {error?:unknown};
 if(!response.ok)throw Error(`Whop HTTP ${response.status}: ${JSON.stringify(body.error||{}).slice(0,400)}`);
 return body;
}
async function main() {
const products=await req<{data:{title:string;id:string}[]}>('/products?account_id='+company+'&first=100');
const productMap={
 plus:products.data?.find((p:{title:string})=>p.title==='LaterBox Plus')?.id,
 vault:products.data?.find((p:{title:string})=>p.title==='LaterBox Vault')?.id,
};
if(!productMap.plus||!productMap.vault)throw Error('Existing LaterBox Whop products not found');
const page=await req<{data:WhopPlanInfo[]}>('/plans?account_id='+company+'&first=100');
const plans=page.data??[];
const ids:Record<string,string>={};
for(const [sku,plan] of Object.entries(WHOP_STORAGE_PLANS) as [WhopPlanKey,(typeof WHOP_STORAGE_PLANS)[WhopPlanKey]][]) {
 const title=`${plan.label} ${plan.interval==='month'?'Monthly':'Yearly'} Referral Trial`;
 const productId=productMap[plan.storage];
 const named=plans.filter((p:{title?:string;product?:{id?:string}})=>p.title===title&&p.product?.id===productId);
 if(named.length>1)throw Error('Duplicate hidden trial plan: '+title);
 let record=named[0] ? await req<WhopPlanInfo>('/plans/'+named[0].id) : null;
 if(record) {
   if(record.renewal_price!==plan.usd||record.billing_period!==(plan.interval==='month'?30:365)||
      record.trial_period_days!==30||record.visibility!=='hidden')
     throw Error('Trial plan has mismatched billing terms: '+title);
 } else if(apply) {
   record=await req<WhopPlanInfo>('/plans',{method:'POST',body:JSON.stringify({
     account_id:company,product_id:productId,title,
     description:`30-day LaterBox referral trial for ${plan.quotaLabel}. Trial storage is limited to 10 GiB; full capacity unlocks upon paid billing.`,
     plan_type:'renewal',release_method:'buy_now',visibility:'hidden',
     currency:'usd',billing_period:plan.interval==='month'?30:365,
     renewal_price:plan.usd,initial_price:0,trial_period_days:30,
     unlimited_stock:true,
   })});
 }
 if(record) {
   if(!record.id?.startsWith('plan_'))throw Error('Invalid Whop trial plan ID');
   ids[referralTrialPlanEnvName(sku)]=record.id;
   console.log(named[0]?'Reused':'Created',title,record.id);
 } else console.log('Dry-run would create',title);
}
if(apply) {
 const path=resolve(process.cwd(),'.env.local');
 const lines=(await readFile(path,'utf8').catch(()=>'' )).trimEnd().split(/\r?\n/);
 for(const [name,id] of Object.entries(ids)){
   const i=lines.findIndex(x=>x.startsWith(name+'='));
   if(i>=0)lines[i]=name+'='+id;else lines.push(name+'='+id);
 }
 await writeFile(path,lines.join('\n')+'\n',{mode:0o600});
 console.log('Verified trial IDs stored locally; all trial plans are hidden.');
}
}
main().catch(error=>{console.error(error instanceof Error?error.message:'Provisioning failed');process.exitCode=1;});
