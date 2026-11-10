// laterbox-web/scripts/configure-whop-oauth-from-clipboard.mjs
// Locally copy the user-provided Whop OAuth secret from the macOS clipboard
// into ignored env files without printing, committing, or transmitting its value.
import {readFile,writeFile,chmod} from 'node:fs/promises';
import {resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import {execFileSync} from 'node:child_process';

const paths=['.env','.env.local'].map(name=>resolve(process.cwd(),name));
const parse=(raw)=>Object.fromEntries([...raw.matchAll(/^([A-Z_][A-Z_0-9]*)=(.*)$/gm)]
  .map(([,key,value])=>[key,value.trim().replace(/^["']|["']$/g,'')]));
const content=await Promise.all(paths.map(path=>readFile(path,'utf8')));
const parsed=content.map(parse);
const appId=parsed[0].NEXT_PUBLIC_WHOP_APP_ID || parsed[1].NEXT_PUBLIC_WHOP_APP_ID;
if(!/^app_[A-Za-z0-9_-]+$/.test(appId??''))throw Error('Missing valid NEXT_PUBLIC_WHOP_APP_ID; no files changed.');
if(parsed.some(env=>env.NEXT_PUBLIC_WHOP_APP_ID && env.NEXT_PUBLIC_WHOP_APP_ID!==appId))
 throw Error('Whop app IDs disagree across env files; no files changed.');
const company=parsed[0].WHOP_COMPANY_ID || parsed[1].WHOP_COMPANY_ID;
if(!/^biz_[A-Za-z0-9_-]+$/.test(company??''))throw Error('Missing Whop business ID; no files changed.');
const clipboard=execFileSync('/usr/bin/pbpaste',[],{encoding:'utf8',timeout:5000,maxBuffer:8192}).trim();
if(!/^apik_[A-Za-z0-9_-]+$/.test(clipboard))throw Error('Clipboard does not contain a valid Whop client secret (apik_...). No files changed.');
const existing=parsed[0].WHOP_CLIENT_SECRET || parsed[1].WHOP_CLIENT_SECRET;
if(existing && existing!==clipboard)throw Error('Existing Whop client secret differs from clipboard; refusing overwrite.');
const cookie=parsed[0].EARN_OAUTH_COOKIE_SECRET || parsed[1].EARN_OAUTH_COOKIE_SECRET || randomBytes(48).toString('base64url');
const cron=parsed[0].EARN_CRON_SECRET || parsed[1].EARN_CRON_SECRET || randomBytes(48).toString('base64url');
const data={
 WHOP_CLIENT_ID:appId,
 WHOP_CLIENT_SECRET:clipboard,
 WHOP_OAUTH_REDIRECT_URI:'https://app.laterbox.dev/api/earn/connect/callback',
 EARN_OAUTH_COOKIE_SECRET:cookie,
 EARN_CRON_SECRET:cron,
 WHOP_BUSINESS_ID:company,
};
for(let i=0;i<paths.length;i++){
 let lines=content[i].trimEnd().split(/\r?\n/);
 for(const [key,value] of Object.entries(data)){
  const index=lines.findIndex(line=>line.startsWith(key+'='));
  if(index>=0)lines[index]=key+'='+value;
  else lines.push(key+'='+value);
 }
 await writeFile(paths[i],lines.join('\n')+'\n',{mode:0o600});
 await chmod(paths[i],0o600);
}
console.log('Whop OAuth client ID, private client secret, callback, and secure Earn secrets configured in both ignored env files.');
console.log('Client ID and secret values were not printed. Automatic payouts and referral activation remain unchanged.');
