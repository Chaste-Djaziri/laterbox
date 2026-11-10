// laterbox-web/scripts/verify-whop-oauth-env.mjs
// Read-only OAuth configuration validation, never print credential values.
import {readFile} from 'node:fs/promises';
for(const file of ['.env','.env.local']){
 const values={};
 for(const line of (await readFile(file,'utf8')).split(/\r?\n/)){
  const match=line.match(/^([A-Z][A-Z0-9_]*)=(.*)$/);
  if(match)values[match[1]]=match[2].replace(/^['"]|['"]$/g,'').trim();
 }
 const required=['WHOP_CLIENT_ID','WHOP_CLIENT_SECRET','WHOP_OAUTH_REDIRECT_URI','EARN_OAUTH_COOKIE_SECRET'];
 console.log(file,JSON.stringify({
  required:Object.fromEntries(required.map(k=>[k,Boolean(values[k])])),
  idFormat:/^app_[A-Za-z0-9_-]+$/.test(values.WHOP_CLIENT_ID??''),
  secretFormat: /^apik_[A-Za-z0-9_-]+$/.test(values.WHOP_CLIENT_SECRET??''),
  callbackValid:values.WHOP_OAUTH_REDIRECT_URI==='https://app.laterbox.dev/api/earn/connect/callback',
  cookieLengthAtLeast32:(values.EARN_OAUTH_COOKIE_SECRET?.length??0)>=32,
  matchingPublicApp:values.WHOP_CLIENT_ID===values.NEXT_PUBLIC_WHOP_APP_ID
 }));
}
