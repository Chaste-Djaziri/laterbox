// laterbox-web/src/app/api/platform/status/route.ts
import {NextResponse} from 'next/server';
import {publicOperations,readOperations} from '@/lib/platform/operations';
export const dynamic='force-dynamic';
export async function GET(){
 try{return NextResponse.json(publicOperations(await readOperations()),{headers:{'Cache-Control':'no-store'}})}
 catch(error){console.error('[platform] status unavailable',error);return NextResponse.json({error:'Status temporarily unavailable'},{status:503,headers:{'Cache-Control':'no-store'}})}
}
