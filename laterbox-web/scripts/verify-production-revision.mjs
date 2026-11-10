// laterbox-web/scripts/verify-production-revision.mjs
// Refuse to report success unless the public LaterBox domain serves this Git commit.
const expected=process.argv[2];
if(!expected||!/^[0-9a-f]{40}$/.test(expected))throw Error('Expected a full 40-character Git commit SHA.');
let observed='unavailable',status=0;
for(let attempt=1;attempt<=6;attempt++){
 try{
  const response=await fetch('https://app.laterbox.dev/api/health',{cache:'no-store',headers:{'Cache-Control':'no-cache'}});
  status=response.status;
  const result=await response.json();
  observed=typeof result?.revision==='string'?result.revision:'missing';
  if(response.ok&&result?.status==='ok'&&observed===expected){
   console.log('Verified production app.laterbox.dev serves Git commit '+expected);
   process.exit(0);
  }
 }catch{observed='unavailable';}
 if(attempt<6)await new Promise(resolve=>setTimeout(resolve,5000));
}
console.error('Production verification failed: health status '+status+', revision '+observed+'; expected '+expected+'. Check Cloudflare account and domain routing.');
process.exit(1);
