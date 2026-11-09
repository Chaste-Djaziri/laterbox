// laterbox-web/src/app/api/earn/validate/route.ts
import {NextResponse} from 'next/server';
import {getRequestUser,getBillingAdminClient} from '@/lib/billing/server';
import {earnSettings,lookupReferral} from '@/lib/earn/affiliate';
import {parseWhopPlan} from '@/lib/billing/storage-plans';
import {whopReferralTrialPlanId} from '@/lib/billing/whop';
export const dynamic='force-dynamic';

export async function POST(request:Request) {
  const user=await getRequestUser(request);
  if(!user?.id)return NextResponse.json({error:'Sign in to use a referral code.'},{status:401});
  let body:{code?:unknown;plan?:unknown};
  try{body=await request.json();}catch{return NextResponse.json({error:'Invalid request.'},{status:400});}
  const plan=parseWhopPlan(body.plan);
  if(!plan)return NextResponse.json({error:'Select a valid plan.'},{status:400});
  try {
    const settings=await earnSettings();
    if(!settings.enabled||!settings.trial_enabled) {
      return NextResponse.json({valid:false,error:'The referral trial promotion is not active yet.'});
    }
    const affiliate=await lookupReferral(body.code,user.id);
    if(!affiliate)return NextResponse.json({valid:false,error:'Referral code not found or cannot be used.'});
    whopReferralTrialPlanId(plan);
    const db=getBillingAdminClient();
    const [{count:history,error:subsError},{count:claims,error:claimsError}]=await Promise.all([
      db.from('billing_subscriptions').select('subscription_id',{head:true,count:'exact'}).eq('user_id',user.id),
      db.from('affiliate_trial_claims').select('buyer_user_id',{head:true,count:'exact'}).eq('buyer_user_id',user.id),
    ]);
    if(subsError||claimsError)throw subsError??claimsError;
    if((history??0)>0||(claims??0)>0) {
      return NextResponse.json({valid:false,error:'A referral trial is only available to new subscribers who have not used a trial.'});
    }
    return NextResponse.json({valid:true,code:affiliate.referral_code,
      trialDays:settings.trial_days,trialUploadLimitGiB:10,
      note:'Free for 30 days. Payment method required. Your selected plan renews automatically at the displayed rate unless canceled.'},
      {headers:{'Cache-Control':'private, no-store'}});
  }catch(error){
    console.error('[earn] validation unavailable',error);
    return NextResponse.json({error:'Cannot verify referral trial right now.'},{status:503});
  }
}
