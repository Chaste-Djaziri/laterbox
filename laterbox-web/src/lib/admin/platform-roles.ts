// laterbox-web/src/lib/admin/platform-roles.ts
// Server-only roles. OAuth and Whop account status NEVER grant administrative privileges.
import 'server-only';
import {getBillingAdminClient,getRequestUser} from '@/lib/billing/server';
import {fetchWhopTeamRoles} from '@/lib/admin/whop-team';

export type PlatformRole='member'|'advocate'|'support'|'analyst'|'admin'|'owner';
export type StaffRole='support'|'analyst'|'admin'|'owner';
export interface ResolvedRole {
  role:PlatformRole;
  staffRole:StaffRole|null;
  whopConnected:boolean;
  whopTeamRole:string|null;
}
const privileged=new Set<PlatformRole>(['owner','admin','support','analyst']);

export async function resolveRole(userId:string,includeWhopTeam=false):Promise<ResolvedRole>{
  const db=getBillingAdminClient();
  const [{data:staff,error:roleError},{data:affiliate,error:affiliateError}]=await Promise.all([
    db.from('platform_roles').select('role').eq('user_id',userId).maybeSingle(),
    db.from('affiliate_profiles').select('verified_whop_user_id,status').eq('user_id',userId).maybeSingle(),
  ]);
  if(roleError||affiliateError)throw roleError??affiliateError;
  const whopConnected=Boolean(affiliate?.verified_whop_user_id);
  const staffRole=privileged.has(staff?.role as PlatformRole)?staff?.role as StaffRole:null;
  const whopTeamRole=includeWhopTeam && whopConnected && affiliate?.verified_whop_user_id
    ?(await fetchWhopTeamRoles()).get(affiliate.verified_whop_user_id)??null:null;
  return {role:staffRole??(whopConnected?'advocate':'member'),staffRole,whopConnected,whopTeamRole};
}

export async function authorizeAdmin(request:Request,minimum:'read'|'manage'|'owner'='read'){
 const host=new URL(request.url).hostname;
 if(host!=='admin.laterbox.dev' && host!=='admin.localhost' && host!=='localhost' && host!=='127.0.0.1')return {error:'The administration API is available only on admin.laterbox.dev.',status:404} as const;
 const user=await getRequestUser(request);
 if(!user)return {error:'Sign in to access the LaterBox dashboard.',status:401} as const;
 const roles=await resolveRole(user.id);
 const permitted=minimum==='owner'?roles.staffRole==='owner':
   minimum==='manage'?['owner','admin'].includes(roles.staffRole??''):['owner','admin'].includes(roles.staffRole??'');
 if(!permitted)return {error:'Your LaterBox role does not permit this operation.',status:403} as const;
 return {user,roles} as const;
}
