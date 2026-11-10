// laterbox-web/src/app/api/account/role/route.ts
import {NextResponse} from 'next/server';
import {getRequestUser} from '@/lib/billing/server';
import {resolveRole} from '@/lib/admin/platform-roles';
export const dynamic='force-dynamic';
export async function GET(request:Request){
 const user=await getRequestUser(request);
 if(!user)return NextResponse.json({error:'Sign in first.'},{status:401});
 try{
  return NextResponse.json(await resolveRole(user.id,true),{headers:{'Cache-Control':'private, no-store'}});
 }catch(e){console.error('[roles] resolve failed',e);return NextResponse.json({error:'Account role unavailable.'},{status:503});}
}
