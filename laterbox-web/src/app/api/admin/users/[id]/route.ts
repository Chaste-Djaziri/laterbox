// laterbox-web/src/app/api/admin/users/[id]/route.ts
import {NextResponse} from 'next/server';
import {getBillingAdminClient} from '@/lib/billing/server';
import {authorizeAdmin} from '@/lib/admin/platform-roles';
import {deleteApplicationAccount} from '@/lib/auth/delete-account';
export const dynamic='force-dynamic';
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export async function DELETE(request:Request,{params}:{params:Promise<{id:string}>}){
 let auth:Awaited<ReturnType<typeof authorizeAdmin>>;
 try{auth=await authorizeAdmin(request,'owner')}catch{return NextResponse.json({error:'Authorization unavailable.'},{status:503})}
 if('error'in auth)return NextResponse.json({error:auth.error},{status:auth.status});
 const {id}=await params;
 if(!uuid.test(id)||id===auth.user.id)return NextResponse.json({error:'You cannot delete your own account.'},{status:403});
 let body:{confirmEmail?:unknown;reason?:unknown};
 try{body=await request.json()}catch{return NextResponse.json({error:'Confirmation required.'},{status:400})}
 const db=getBillingAdminClient();
 const [{data:staff,error:staffError},{data:user,error:userError}]=await Promise.all([
  db.from('platform_roles').select('role').eq('user_id',id).maybeSingle(),
  db.auth.admin.getUserById(id),
 ]);
 if(staffError||userError||!user?.user)return NextResponse.json({error:'User not found.'},{status:404});
 if(staff?.role==='owner')return NextResponse.json({error:'Owner accounts are protected from dashboard deletion.'},{status:403});
 const email=user.user.email;
 if(!email||typeof body.confirmEmail!=='string'||body.confirmEmail.trim().toLowerCase()!==email.toLowerCase())
  return NextResponse.json({error:'Enter the complete account email to confirm permanent deletion.'},{status:400});
 if(typeof body.reason!=='string'||body.reason.trim().length<10||body.reason.length>500)
  return NextResponse.json({error:'A 10–500 character deletion reason is required.'},{status:400});
 try{
  // The audit record preserves accountability if the account removal is interrupted.
  const audit=await db.from('platform_operations_audit').insert({
   actor_id:auth.user.id,action:'account_delete_requested',target:id,
   next:{email,reason:body.reason.trim()},
  });
  if(audit.error)throw audit.error;
  await deleteApplicationAccount(id);
  await db.from('platform_operations_audit').insert({actor_id:auth.user.id,action:'account_deleted',target:id,next:{email}});
  return NextResponse.json({deleted:true},{headers:{'Cache-Control':'no-store'}});
 }catch(error){
  console.error('[admin] account deletion incomplete',error);
  return NextResponse.json({error:'Deletion was started but did not complete. Review the deletion job before retrying.'},{status:503});
 }
}
