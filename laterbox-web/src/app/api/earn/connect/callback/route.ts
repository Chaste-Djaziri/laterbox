// laterbox-web/src/app/api/earn/connect/callback/route.ts
import {NextRequest,NextResponse} from 'next/server';
import {getBillingAdminClient} from '@/lib/billing/server';
import {EARN_OAUTH_COOKIE,verifyOAuthState,verifiedWhopUser,whopOauthConfiguration} from '@/lib/earn/whop-connect';

export const dynamic='force-dynamic';
export async function GET(request:NextRequest) {
  // Avoid leaking Whop OAuth authorization codes into LaterBox analytics or URLs.
  const redirect=new URL('/earn',request.url);
  const finish=(status:'connected'|'failed')=>{
    redirect.searchParams.set('whop',status);
    const res=NextResponse.redirect(redirect,303);
    res.cookies.set(EARN_OAUTH_COOKIE,'',{path:'/api/earn/connect',maxAge:0,httpOnly:true});
    return res;
  };
  const code=request.nextUrl.searchParams.get('code');
  const returnedState=request.nextUrl.searchParams.get('state');
  if(!code||!returnedState || code.length>2048)return finish('failed');
  try {
    const cfg=await whopOauthConfiguration();
    const transaction=verifyOAuthState(request.cookies.get(EARN_OAUTH_COOKIE)?.value??'',cfg.cookieSecret);
    if(!transaction||transaction.state!==returnedState) return finish('failed');
    const whopUserId=await verifiedWhopUser(code,transaction,cfg);
    const {data,error}=await getBillingAdminClient().from('affiliate_profiles')
      .update({verified_whop_user_id:whopUserId})
      .eq('user_id',transaction.userId).eq('status','active')
      .select('user_id').maybeSingle();
    if(error||!data)throw error??new Error('Affiliate profile not active.');
    return finish('connected');
  }catch(error) {
    console.error('[earn] Whop OAuth callback failed',error);
    return finish('failed');
  }
}
