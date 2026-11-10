// laterbox-web/src/app/api/earn/connect/callback/route.ts
import {NextRequest,NextResponse} from 'next/server';
import {getBillingAdminClient} from '@/lib/billing/server';
import {EARN_OAUTH_COOKIE,verifyOAuthState,verifiedWhopUser,whopOauthConfiguration,WhopConnectError,type WhopConnectFailure} from '@/lib/earn/whop-connect';

export const dynamic='force-dynamic';

export async function GET(request:NextRequest) {
  // Never echo the one-time code/state or provider descriptions in redirects or logs.
  const finish=(status:'connected'|'failed',reason?:WhopConnectFailure)=>{
    const destination=new URL('/earn','https://app.laterbox.dev');
    destination.searchParams.set('whop',status);
    if(status==='failed'&&reason)destination.searchParams.set('reason',reason);
    const res=NextResponse.redirect(destination,303);
    res.cookies.set(EARN_OAUTH_COOKIE,'',{
      path:'/api/earn/connect',maxAge:0,httpOnly:true,sameSite:'lax',
      secure:true,
    });
    return res;
  };

  const code=request.nextUrl.searchParams.get('code');
  const returnedState=request.nextUrl.searchParams.get('state');
  if(!code||!returnedState||code.length>2048)return finish('failed','missing_parameters');

  let stage:WhopConnectFailure='configuration';
  try {
    const config=await whopOauthConfiguration();
    const signedCookie=request.cookies.get(EARN_OAUTH_COOKIE)?.value;
    if(!signedCookie)return finish('failed','state_missing');
    stage='state_invalid';
    const transaction=verifyOAuthState(signedCookie,config.cookieSecret);
    if(!transaction||transaction.state!==returnedState)return finish('failed','state_invalid');

    stage='token_exchange';
    const whopUserId=await verifiedWhopUser(code,transaction,config);

    stage='database';
    const {data,error}=await getBillingAdminClient().from('affiliate_profiles')
      .update({verified_whop_user_id:whopUserId})
      .eq('user_id',transaction.userId).eq('status','active')
      .select('user_id').maybeSingle();

    if(error||!data){
      console.error('[earn] Whop verification database update rejected',{
        code:error?.code??'no_matching_profile',
      });
      return finish('failed','database');
    }
    return finish('connected');
  } catch(error){
    const reason=error instanceof WhopConnectError?error.stage:stage;
    console.error('[earn] Whop OAuth callback failed at stage',{
      reason,httpStatus:error instanceof WhopConnectError?error.httpStatus:undefined,
    });
    return finish('failed',reason);
  }
}
