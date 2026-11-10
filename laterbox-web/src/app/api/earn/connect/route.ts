// laterbox-web/src/app/api/earn/connect/route.ts
import {NextResponse} from 'next/server';
import {getRequestUser} from '@/lib/billing/server';
import {ensureEarnProfile} from '@/lib/earn/affiliate';
import {EARN_OAUTH_COOKIE,newOAuthState,signOAuthState,authorizeWhopURL,whopOauthConfiguration,OAUTH_MAX_AGE} from '@/lib/earn/whop-connect';

export const dynamic='force-dynamic';
export async function POST(request:Request) {
  const user=await getRequestUser(request);
  if(!user?.id)return NextResponse.json({error:'Sign in to LaterBox first.'},{status:401});
  try {
    const profile=await ensureEarnProfile(user.id);
    if(profile.status!=='active') return NextResponse.json({error:'Whop linking is unavailable for this account.'},{status:403});
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
