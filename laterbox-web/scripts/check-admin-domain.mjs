// laterbox-web/scripts/check-admin-domain.mjs
// Read-only check for custom-domain binding in the authenticated Cloudflare account.
import {execFileSync} from 'node:child_process';
const raw=execFileSync('npx',['wrangler','auth','token','--json'],{encoding:'utf8',timeout:30000});
const auth=JSON.parse(raw.slice(raw.indexOf('{')));
if(!auth.token||auth.type!=='oauth')throw Error('Cloudflare OAuth profile unavailable.');
const res=await fetch('https://api.cloudflare.com/client/v4/accounts/98bf0ff395447a143a9b4c13c6a0d650/workers/domains',{headers:{Authorization:'Bearer '+auth.token}});
const data=await res.json();
if(!data.success)throw Error('Cloudflare domains request failed '+res.status);
for(const d of(data.result??[]).filter(d=>['admin.laterbox.dev','dash.laterbox.dev'].includes(d.hostname)))console.log(JSON.stringify({hostname:d.hostname,service:d.service,enabled:d.enabled,id:d.id}));
const dns=await fetch('https://cloudflare-dns.com/dns-query?name=admin.laterbox.dev&type=A',{headers:{Accept:'application/dns-json'}});
const answer=await dns.json();
console.log('Public DNS status:',answer.Status,'A records:',(answer.Answer??[]).filter(x=>x.type===1).length);


// Edge HTTPS verification independent of local DNS caches.
try{
 const d=await (await fetch('https://cloudflare-dns.com/dns-query?name=app.laterbox.dev&type=A',{headers:{Accept:'application/dns-json'}})).json();
 const ip=(d.Answer??[]).find(x=>x.type===1)?.data;
 if(!ip||String(ip).split('.').length!==4)throw Error('Cloudflare edge IP not found');
 for(const [host,path] of [['admin.laterbox.dev','/'],['admin.laterbox.dev','/api/admin/dashboard'],['app.laterbox.dev','/admin'],['dash.laterbox.dev','/']]){
  try{
   const url='https://'+host+path;
   const output=execFileSync('/usr/bin/curl',['-sS','-I','--max-time','15','--resolve',host+':443:'+ip,url],{encoding:'utf8',timeout:18000});
   const headers=output.split(String.fromCharCode(10)).filter(line=>line.startsWith('HTTP/')||line.toLowerCase().startsWith('location:')).map(line=>line.trim());
   console.log('Edge HTTPS verification:',host+path,headers.join(' | '));
  }catch(err){console.log('Edge HTTPS verification failed:',host+path,err instanceof Error?err.name:'error');}
 }
}catch(err){console.log('Edge check unavailable',err instanceof Error?err.message:'error');}


// Public operations status must load with safe defaults and no private data.
try{
 const d=await (await fetch('https://cloudflare-dns.com/dns-query?name=admin.laterbox.dev&type=A',{headers:{Accept:'application/dns-json'}})).json();
 const ip=(d.Answer??[]).find(x=>x.type===1)?.data;
 if(!ip)throw Error('Missing public DNS');
 const response=execFileSync('/usr/bin/curl',['-sS','--max-time','15','--resolve','admin.laterbox.dev:443:'+ip,'https://admin.laterbox.dev/api/platform/status'],{encoding:'utf8',timeout:18000});
 const status=JSON.parse(response);
 console.log('Platform public status:',JSON.stringify({maintenance:status.maintenance?.state,features:status.features,serverTimePresent:Boolean(status.serverTime)}));
}catch(e){console.log('Platform public status unavailable:',e instanceof Error?e.name:'error')}
