// laterbox-web/src/app/api/earn/route.ts
import { NextResponse } from 'next/server';
import { getRequestUser } from '@/lib/billing/server';
import { enrollAffiliate, getEarnState } from '@/lib/earn/affiliate';

export const dynamic = 'force-dynamic';
export async function GET(request: Request) {
  const user = await getRequestUser(request);
  if(!user?.id) return NextResponse.json({error:'Sign in to LaterBox to view Earn.'},{status:401});
  try {
    return NextResponse.json(await getEarnState(user.id), {
      headers:{'Cache-Control':'private, no-store'},
    });
  } catch(error) {
    console.error('[earn] dashboard unavailable', error);
    return NextResponse.json({error:'Earn is being prepared. Please check back shortly.'},{status:503});
  }
}

export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if(!user?.id) return NextResponse.json({error:'Sign in to LaterBox to join Earn.'},{status:401});
  let body: { adult?: unknown; acceptedTerms?: unknown };
  try { body = await request.json(); }
  catch { return NextResponse.json({error:'Invalid request.'},{status:400}); }
  if(body.adult!==true || body.acceptedTerms!==true) {
    return NextResponse.json({error:'You must confirm you are at least 18 and accept the affiliate terms.'},{status:400});
  }
  try {
    const result = await enrollAffiliate(user.id);
    if(result === 'unavailable') return NextResponse.json({error:'Connect and verify your Whop account before joining Earn, or wait for the program to open.'},{status:403});
    return NextResponse.json({result,state:await getEarnState(user.id)},{headers:{'Cache-Control':'private, no-store'}});
  } catch(error) {
    console.error('[earn] enrollment error',error);
    return NextResponse.json({error:'Could not complete enrollment.'},{status:503});
  }
}