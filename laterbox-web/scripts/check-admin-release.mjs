// laterbox-web/scripts/check-admin-release.mjs
// Temporary, read-only release status check, no secrets or user data.
const r=await fetch('https://api.github.com/repos/Chaste-Djaziri/laterbox/actions/runs?per_page=12',{headers:{'User-Agent':'LaterBox-Release-Status'}});
if(!r.ok)throw Error('GitHub API HTTP '+r.status);
const data=await r.json();
for(const run of data.workflow_runs??[]){
 if(run.head_sha?.startsWith('b408c154')||run.head_sha?.startsWith('4ae8d95b')||run.head_sha?.startsWith('20739f04'))
  console.log(JSON.stringify({id:run.id,sha:run.head_sha.slice(0,9),name:run.name,status:run.status,conclusion:run.conclusion,url:run.html_url}));
}
