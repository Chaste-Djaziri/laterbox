// laterbox-web/src/lib/platform/operations.ts
import {getBillingAdminClient} from '@/lib/billing/server';

export const featureKeys=['referrals','checkout','support','ai'] as const;
export type FeatureKey=typeof featureKeys[number];
export type FeatureFlags=Record<FeatureKey,boolean>;
export type MaintenanceMode='off'|'scheduled'|'active';
export type PlatformOperations={
 features:FeatureFlags;
 maintenanceMode:MaintenanceMode;
 maintenanceStartsAt:string|null;
 maintenanceEndsAt:string|null;
 maintenanceMessage:string;
 updatedAt:string|null;
 updatedBy:string|null;
};
const DEFAULT:PlatformOperations={
 features:{referrals:false,checkout:true,support:true,ai:true},
 maintenanceMode:'off',maintenanceStartsAt:null,maintenanceEndsAt:null,
 maintenanceMessage:'We are improving LaterBox. Please check back shortly.',
 updatedAt:null,updatedBy:null,
};
export async function readOperations():Promise<PlatformOperations>{
 const {data,error}=await getBillingAdminClient().from('platform_operations')
  .select('features,maintenance_mode,maintenance_starts_at,maintenance_ends_at,maintenance_message,updated_at,updated_by')
  .eq('id',true).single();
 if(error)throw error;
 const f=data.features && typeof data.features==='object'&&!Array.isArray(data.features)?data.features as Record<string,unknown>:{};
 const flags={...DEFAULT.features};
 for(const key of featureKeys)if(typeof f[key]==='boolean')flags[key]=f[key] as boolean;
 return {features:flags,maintenanceMode:data.maintenance_mode as MaintenanceMode,
  maintenanceStartsAt:data.maintenance_starts_at,maintenanceEndsAt:data.maintenance_ends_at,
  maintenanceMessage:data.maintenance_message,updatedAt:data.updated_at,updatedBy:data.updated_by};
}
export function maintenanceState(ops:PlatformOperations,now=Date.now()):'off'|'upcoming'|'active'{
 if(ops.maintenanceMode==='off')return 'off';
 const start=ops.maintenanceStartsAt?Date.parse(ops.maintenanceStartsAt):null;
 const end=ops.maintenanceEndsAt?Date.parse(ops.maintenanceEndsAt):null;
 if(end!==null && now>=end)return 'off';
 if(ops.maintenanceMode==='active')return 'active';
 if(start!==null&&now<start)return 'upcoming';
 return 'active';
}
export async function requireFeature(key:FeatureKey):Promise<boolean>{
 // Cloudflare explicitly enables runtime enforcement; local unit mocks remain isolated.
 if(process.env.PLATFORM_OPERATIONS_ENFORCED!=='true')return true;
 const ops=await readOperations();
 return ops.features[key] && maintenanceState(ops)!=='active';
}
export function publicOperations(ops:PlatformOperations){
 return {maintenance:{state:maintenanceState(ops),mode:ops.maintenanceMode,
   startsAt:ops.maintenanceStartsAt,endsAt:ops.maintenanceEndsAt,message:ops.maintenanceMessage},
  features:ops.features,serverTime:new Date().toISOString()};
}
