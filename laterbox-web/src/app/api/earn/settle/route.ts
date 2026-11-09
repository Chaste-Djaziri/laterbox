// laterbox-web/src/app/api/earn/settle/route.ts
// Protected daily reconciliation. Enable only after deploying the migration,
// verifying Whop payout permissions and approving commission policy.
import { NextResponse } from 'next/server';
import { timingSafeEqual } from 'node:crypto';
import { getBillingAdminClient } from '@/lib/billing/server';
import { earnSettings } from '@/lib/earn/affiliate';
import { whopEnvironment } from '@/lib/billing/whop';

export const dynamic = 'force-dynamic';

function authorized(request:Request):boolean {
  const configured=process.env.EARN_CRON_SECRET;
  const provided=request.headers.get('x-earn-cron-secret');
  if(!configured || !provided || configured.length<24) return false;
  const a=Buffer.from(configured),b=Buffer.from(provided);
  return a.length===b.length && timingSafeEqual(a,b);
}

export async function POST(request:Request) {
  if(!authorized(request))return NextResponse.json({error:'Unauthorized.'},{status:401});
  try {
    const config=await earnSettings();
    if(!config.enabled)return NextResponse.json({status:'disabled',released:0,payouts:0});
    const admin=getBillingAdminClient();
    // Converting pending -> available is idempotent. Refund events reverse a
    // commission while still pending or available.
    const {data:released,error:releaseError}=await admin.from('affiliate_commissions')
      .update({status:'available'})
      .eq('status','pending').lte('hold_until',new Date().toISOString())
      .select('id');
    if(releaseError)throw releaseError;
    if(!config.automatic_payouts) {
      return NextResponse.json({status:'pending_payout_configuration',released:released?.length??0,payouts:0});
    }
    const origin=process.env.WHOP_BUSINESS_ID || process.env.WHOP_COMPANY_ID;
    const apiKey=process.env.WHOP_COMPANY_API_KEY;
    if(!origin || !/^biz_[A-Za-z0-9_-]+$/.test(origin) || !apiKey) {
      throw new Error('Whop origin account and API key must be configured.');
    }
    // Only administrator-verified recipients can receive automated transfers.
    const {data:eligible,error:profileError}=await admin.from('affiliate_profiles')
      .select('user_id,verified_whop_user_id').eq('status','active')
      .not('verified_whop_user_id','is',null).limit(100);
    if(profileError)throw profileError;
    for(const profile of eligible??[]) {
      const {error}=await admin.rpc('affiliate_claim_payout',{
        target_affiliate:profile.user_id,
        payout_minimum:config.minimum_payout_cents,
      });
      if(error)throw error;
    }
    // Existing processing transfers are retried with their SAME idempotence
    // key after a network failure; no new payout rows are created on retry.
    const {data:queued,error:queueError}=await admin.from('affiliate_payouts')
      .select('id,affiliate_user_id,amount_cents,idempotence_key,whop_transfer_id')
      .eq('status','processing').order('created_at',{ascending:true}).limit(50);
    if(queueError)throw queueError;
    let paid=0,failed=0;
    const base=whopEnvironment()==='production'
      ? 'https://api.whop.com/api/v1'
      : 'https://sandbox-api.whop.com/api/v1';
    const markTransferred = async (payoutId:string,transferId:string) => {
      const now=new Date().toISOString();
      const {error:payoutError}=await admin.from('affiliate_payouts').update({
        status:'paid',paid_at:now,whop_transfer_id:transferId,failure_message:null,
      }).eq('id',payoutId).eq('status','processing');
      if(payoutError)throw payoutError;
      const {error:commError}=await admin.from('affiliate_commissions')
        .update({status:'paid',paid_at:now})
        .eq('payout_id',payoutId).eq('status','processing');
      if(commError)throw commError;
      paid++;
    };
    for(const payout of queued??[]) {
      const {data:recipient,error:recipientError}=await admin.from('affiliate_profiles')
        .select('verified_whop_user_id,status').eq('user_id',payout.affiliate_user_id).maybeSingle();
      if(recipientError)throw recipientError;
      if(!recipient?.verified_whop_user_id || recipient.status!=='active')continue;
      try {
        // Once the provider returns a transfer ID, never issue a second
        // transfer. Poll its settlement status until Whop confirms success.
        const existingTransfer=payout.whop_transfer_id as string|null;
        const response=existingTransfer
          ? await fetch(`${base}/transfers/${encodeURIComponent(existingTransfer)}`,{
              cache:'no-store',headers:{Authorization:`Bearer ${apiKey}`},
            })
          : await fetch(`${base}/transfers`,{
              method:'POST',cache:'no-store',
              headers:{
                Authorization:`Bearer ${apiKey}`,'Content-Type':'application/json',
                'Idempotency-Key':payout.idempotence_key,
              },
              body:JSON.stringify({
                type:'balance',
                origin_id:origin,destination_id:recipient.verified_whop_user_id,
                currency:'usd',amount:payout.amount_cents/100,
                idempotence_key:payout.idempotence_key,
                notes:'LaterBox Earn commission',
                metadata:{laterbox_payout_id:payout.id},
              }),
            });
        const result=await response.json() as {id?:string;status?:string;error?:{message?:string}};
        if(!response.ok || !result.id?.startsWith('ctt_')) {
          throw new Error(result.error?.message||`Whop transfer HTTP ${response.status}`);
        }
        if(!existingTransfer) {
          const {error:trackError}=await admin.from('affiliate_payouts')
            .update({whop_transfer_id:result.id,failure_message:null})
            .eq('id',payout.id).eq('status','processing');
          if(trackError)throw trackError;
        }
        if(result.status==='succeeded') {
          await markTransferred(payout.id,result.id);
        } else if(result.status==='failed') {
          // Do not silently issue another transfer after a definitive failure.
          const {error:failError}=await admin.from('affiliate_payouts')
            .update({status:'failed',failure_message:'Whop declined the balance transfer.'})
            .eq('id',payout.id).eq('status','processing');
          if(failError)throw failError;
          // Whop confirmed no money moved: return these commissions to
          // available, but block future automatic claims until an admin reviews
          // the failed payout (affiliate_claim_payout checks failed payouts).
          const {error:releaseError}=await admin.from('affiliate_commissions')
            .update({status:'available',payout_id:null}).eq('payout_id',payout.id)
            .eq('status','processing');
          if(releaseError)throw releaseError;
          failed++;
        }
      }catch(error) {
        failed++;
        const reason=error instanceof Error?error.message:'Whop transfer failed.';
        console.error('[earn] transfer not confirmed:',payout.id,reason);
        await admin.from('affiliate_payouts').update({
          failure_message:reason.slice(0,250)
        }).eq('id',payout.id);
      }
    }
    return NextResponse.json({status:'reconciled',released:released?.length??0,paid,failed});
  }catch(error){
    console.error('[earn] settlement error',error);
    return NextResponse.json({error:'Earn settlement is unavailable.'},{status:503});
  }
}
