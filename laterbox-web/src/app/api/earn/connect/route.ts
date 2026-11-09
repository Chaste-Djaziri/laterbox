// laterbox-web/src/app/api/earn/connect/route.ts
import {NextResponse} from 'next/server';
import {getRequestUser} from '@/lib/billing/server';
import {earnSettings} from '@/lib/earn/affiliate';
import {EARN_OAUTH_COOKIE,newOAuthState,signOAuthState,authorizeWhopURL,whopOauthConfiguration,OAUTH_MAX_AGE} from '@/lib/earn/whop-connect';

export const dynamic='force-dynamic';
export async function POST(request:Request) {
  const user=await getRequestUser(request);
  if(!user?.id)return NextResponse.json({error:'Sign in to LaterBox first.'},{status:401});
  try {
    if(!(await earnSettings()).enabled) return NextResponse.json({error:'Earn is not accepting connections yet.'},{status:403});
    const {getBillingAdminClient}=await import('@/lib/billing/server');
    const {data:profile,error}=await getBillingAdminClient().from('affiliate_profiles')
      .select('status').eq('user_id',user.id).maybeSingle();
    if(error)throw error;
    if(profile?.status!=='active') return NextResponse.json({error:'Activate your affiliate account before connecting Whop.'},{status:403});
    const config=whopOauthConfiguration();
    const state=newOAuthState(user.id);
    const url=authorizeWhopURL(state,config);
    const response=NextResponse.json({url},{headers:{'Cache-Control':'private, no-store'}});
    response.cookies.set(EARN_OAUTH_COOKIE,signOAuthState(state,config.cookieSecret),{
      httpOnly:true,secure:process.env.NODE_ENV==='production',sameSite:'lax',
      path:'/api/earn/connect',maxAge:OAUTH_MAX_AGE,
    });
    return response;
  } catch(error) {
    console.error('[earn] Whop connect unavailable',error);
    return NextResponse.json({error:'Whop connection is not configured yet. Payout setup will be available after launch.'},{status:503});
  }
}
