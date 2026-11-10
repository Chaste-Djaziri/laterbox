// laterbox-web/src/app/r/[code]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getBillingAdminClient } from '@/lib/billing/server';
import { earnSettings, referralCodeAllowed } from '@/lib/earn/affiliate';

// A server-verified redirect creates a 30-day, HTTP-only attribution cookie.
// Unlike client localStorage, the code cannot be replaced by a later page script.
export async function GET(request: NextRequest, context: { params: Promise<{code:string}> }) {
  const {code} = await context.params;
  const target = new URL('/signup', request.url);
  if(!referralCodeAllowed(code)) return NextResponse.redirect(target,303);
  try {
    if(!(await earnSettings()).enabled) return NextResponse.redirect(target,303);
    const { data, error } = await getBillingAdminClient().from('affiliate_profiles')
      .select('user_id').eq('referral_code',code).eq('status','active').not('verified_whop_user_id','is',null).not('age_confirmed_at','is',null).maybeSingle();
    if(error || !data) return NextResponse.redirect(target,303);
    const response = NextResponse.redirect(target,303);
    response.cookies.set('laterbox_ref',code,{
      path:'/',httpOnly:true,sameSite:'lax',secure:process.env.NODE_ENV==='production',
      maxAge:30*24*60*60,
      // Both laterbox.dev and app.laterbox.dev can complete the purchase.
      ...(process.env.NODE_ENV==='production'?{domain:'.laterbox.dev'}:{}),
    });
    return response;
  } catch {
    return NextResponse.redirect(target,303);
  }
}