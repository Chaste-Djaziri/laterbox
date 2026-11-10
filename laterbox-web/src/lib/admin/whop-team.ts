// laterbox-web/src/lib/admin/whop-team.ts
// Whop team membership is display-only. It never grants LaterBox admin access.
import 'server-only';

export async function fetchWhopTeamRoles():Promise<Map<string,string>>{
 const key=process.env.WHOP_COMPANY_API_KEY;
 const business=process.env.WHOP_COMPANY_ID;
 const result=new Map<string,string>();
 if(!key||!/^biz_[\w-]+$/.test(business??''))return result;
 try{
  const url=new URL('https://api.whop.com/api/v1/authorized_users');
  url.searchParams.set('company_id',business!);
  url.searchParams.set('first','100');
  const response=await fetch(url,{headers:{Authorization:`Bearer ${key}`},cache:'no-store',signal:AbortSignal.timeout(3500)});
  if(!response.ok)return result;
  const json=await response.json() as {data?:{user?:{id?:string};role?:string;status?:string;company?:{id?:string}}[]};
  for(const item of json.data??[]){
   if(item.company?.id&&item.company.id!==business)continue;
   if(item.user?.id && typeof item.role==='string' && item.role.length<70 && item.status!=='pending')
    result.set(item.user.id,item.role);
  }
 }catch{/* Whop roles are optional metadata; never block LaterBox sign-in. */}
 return result;
}
