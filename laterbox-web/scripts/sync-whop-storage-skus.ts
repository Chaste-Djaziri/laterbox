// laterbox-web/scripts/sync-whop-storage-skus.ts
// Idempotently sync verified Whop price IDs and storage quotas to production.
// Run: npx tsx scripts/sync-whop-storage-skus.ts [--apply]
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createClient} from '@supabase/supabase-js';
import {WHOP_STORAGE_PLANS, type WhopPlanKey} from '../src/lib/billing/storage-plans';
import {planEnvName,referralTrialPlanEnvName} from '../src/lib/billing/whop';

async function main() {
 const content=await readFile(resolve(process.cwd(),'.env'),'utf8');
 const env:Record<string,string>={};
 for(const line of content.split(/\r?\n/)) {
   const match=line.match(/^([A-Z_0-9]+)=(.*)$/);
   if(match)env[match[1]]=match[2].replace(/^["']|["']$/g,'');
 }
 const isApply=process.argv.includes('--apply');
 const url=env.NEXT_PUBLIC_SUPABASE_URL;
 const token=env.SUPABASE_SERVICE_ROLE_KEY;
 if(env.WHOP_SANDBOX!=='false' || !url?.match(/^https:\/\/[\w-]+\.supabase\.co\/?$/) || !token)
   throw Error('Production Supabase and Whop configuration required.');
 const rows:{provider_price_id:string;sku_key:string;family:'plus'|'vault';quota_bytes:number;trial_days:number}[]=[];
 for(const [key,plan] of Object.entries(WHOP_STORAGE_PLANS) as [WhopPlanKey,(typeof WHOP_STORAGE_PLANS)[WhopPlanKey]][]) {
   for(const trial of [false,true]){
     const variable=trial?referralTrialPlanEnvName(key):planEnvName(key);
     const id=env[variable];
     if(!id || !/^plan_[A-Za-z0-9_-]+$/.test(id))throw Error('Missing verified '+variable);
     rows.push({
       provider_price_id:id,
       sku_key:trial?key+'_referral_trial':key,
       family:plan.storage,
       quota_bytes:plan.bytes,
       trial_days:trial?30:0,
     });
   }
 }
 if(new Set(rows.map(r=>r.provider_price_id)).size!==rows.length)throw Error('Duplicate plan IDs');
 if(!isApply){ console.log('Dry run: '+rows.length+' storage SKUs validated; no database writes.');return; }
 const db=createClient(url,token,{auth:{persistSession:false,autoRefreshToken:false}});
 const {error}=await db.from('billing_storage_skus').upsert(rows,{onConflict:'provider_price_id'});
 if(error)throw error;
 const ids=rows.map(r=>r.provider_price_id);
 const {data,error:verifyError}=await db.from('billing_storage_skus')
   .select('provider_price_id,sku_key,quota_bytes,trial_days').in('provider_price_id',ids);
 if(verifyError)throw verifyError;
 if((data??[]).length!==rows.length || data?.some(row=>{
   const expected=rows.find(s=>s.provider_price_id===row.provider_price_id);
   return !expected || expected.sku_key!==row.sku_key ||
     Number(expected.quota_bytes)!==Number(row.quota_bytes) || expected.trial_days!==row.trial_days;
 }))throw Error('Storage SKU verification failed.');
 console.log('Verified '+rows.length+' production Whop storage SKUs: 14 standard and 14 referral trials.');
}
main().catch(error=>{console.error(error instanceof Error?error.message:'SKU sync failed');process.exitCode=1;});
