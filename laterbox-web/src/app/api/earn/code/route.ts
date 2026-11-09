// laterbox-web/src/app/api/earn/code/route.ts
import {NextResponse} from 'next/server';
import {getRequestUser} from '@/lib/billing/server';
import {customizeReferralCode, ensureEarnProfile, lookupReferral, referralCodeAllowed} from '@/lib/earn/affiliate';
export const dynamic='force-dynamic';

export async function GET(request:Request) {
  const user=await getRequestUser(request);
  if(!user?.id)return NextResponse.json({error:'Sign in first.'},{status:401});
  const code=new URL(request.url).searchParams.get('code');
  if(!referralCodeAllowed(code))return NextResponse.json({available:false,reason:'Use 4–32 letters, numbers, underscores or hyphens.'});
  try {
    const existing=await lookupReferral(code);
    const profile=await ensureEarnProfile(user.id);
    return NextResponse.json({available:!existing||existing.user_id===user.id,
      ownCode:existing?.user_id===user.id},{headers:{'Cache-Control':'no-store'}});
  }catch {
    return NextResponse.json({error:'Could not check code availability.'},{status:503});
  }
}
export async function PATCH(request:Request) {
  const user=await getRequestUser(request);
  if(!user?.id)return NextResponse.json({error:'Sign in first.'},{status:401});
  let body:{code?:unknown};
  try{body=await request.json();}catch{return NextResponse.json({error:'Invalid JSON.'},{status:400});}
  try{
    const result=await customizeReferralCode(user.id,body.code);
    return NextResponse.json(result,{status:result.status,headers:{'Cache-Control':'no-store'}});
  }catch{
    return NextResponse.json({error:'Could not update your code.'},{status:503});
  }
}
