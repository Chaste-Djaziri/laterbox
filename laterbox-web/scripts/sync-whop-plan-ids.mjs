// laterbox-web/scripts/sync-whop-plan-ids.mjs
// Copy verified standard and hidden referral-trial Whop plan IDs from .env.local into
// production .env. Never read or print private API keys, service keys or secrets.
import {readFile,writeFile} from 'node:fs/promises';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
const dir=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const standardKeys=['PLUS50','VAULT250','VAULT500','VAULT1TB','VAULT2TB']
  .flatMap(name=>['MONTHLY','YEARLY'].map(b=>`WHOP_${name}_${b}_PLAN_ID`));
const trialKeys=['PLUS','PLUS50','VAULT','VAULT250','VAULT500','VAULT1TB','VAULT2TB']
  .flatMap(name=>['MONTHLY','YEARLY'].map(b=>`WHOP_${name}_${b}_REFERRAL_TRIAL_PLAN_ID`));
const newKeys=[...standardKeys,...trialKeys];
function parse(text){
 const result={};for(const line of text.split(/\r?\n/)){
 const m=line.match(/^([A-Z_0-9]+)=(.*)$/);if(m)result[m[1]]=m[2].replace(/^["']|["']$/g,'');
 }return result;
}
const local=parse(await readFile(resolve(dir,'.env.local'),'utf8'));
const targetPath=resolve(dir,'.env');
let lines=(await readFile(targetPath,'utf8')).split(/\r?\n/);
for(const key of newKeys){
 const value=local[key];
 if(!/^plan_[A-Za-z0-9_-]+$/.test(value||''))throw Error(`Verified ${key} is missing in .env.local`);
 const index=lines.findIndex(line=>line.startsWith(key+'='));
 if(index<0)lines.push(`${key}=${value}`);
 else lines[index]=`${key}=${value}`;
}
await writeFile(targetPath,lines.join('\n').replace(/\n*$/,'\n'),{mode:0o600});
console.log('Synced',newKeys.length,'public Whop plan IDs to ignored production .env; values not displayed.');
