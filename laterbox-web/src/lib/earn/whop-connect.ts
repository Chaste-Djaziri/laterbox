// laterbox-web/src/lib/earn/whop-connect.ts
// Short-lived, HMAC-signed OAuth transaction. The browser never sees Whop
// access tokens or the app secret; recipients are verified via Whop userinfo.
import {createHmac, randomBytes, createHash, timingSafeEqual} from 'node:crypto';
import {whopEnvironment} from '@/lib/billing/whop';
import {getCloudflareContext} from '@opennextjs/cloudflare';

export interface EarnOAuthState {
  userId:string;
  nonce:string;
  state:string;
  verifier:string;
  created:number;
}
export const EARN_OAUTH_COOKIE='lb_earn_whop_oauth';
export const OAUTH_MAX_AGE=600;
export type WhopConnectFailure='missing_parameters'|'state_missing'|'state_invalid'|'configuration'|'token_exchange'|'token_response'|'userinfo'|'identity'|'database';
export class WhopConnectError extends Error {
  constructor(public readonly stage:WhopConnectFailure, public readonly httpStatus?:number){
    super('Whop OAuth '+stage+(httpStatus?' (HTTP '+httpStatus+')':''));
    this.name='WhopConnectError';
  }
}


export async function whopOauthConfiguration() {
  // OpenNext exposes encrypted Worker bindings through the Cloudflare context.
  // Fall back to process.env for local Next.js development and tests.
  let workerEnv:Record<string,unknown>={};
  try {workerEnv=(await getCloudflareContext({async:true})).env as unknown as Record<string,unknown>;} catch {/* Local Node.js process.env is the fallback. */}
  const value=(key:string):string|undefined=>{
    const binding=workerEnv[key];
    return typeof binding==='string'&&binding.length?binding:process.env[key];
  };
  const id=value('WHOP_CLIENT_ID');
  const secret=value('WHOP_CLIENT_SECRET');
  const uri=value('WHOP_OAUTH_REDIRECT_URI');
  const cookieSecret=value('EARN_OAUTH_COOKIE_SECRET');
  const missing=[
    !id?.startsWith('app_')?'WHOP_CLIENT_ID':null,
    !secret?'WHOP_CLIENT_SECRET':null,
    !cookieSecret||cookieSecret.length<32?'EARN_OAUTH_COOKIE_SECRET':null,
    !uri?'WHOP_OAUTH_REDIRECT_URI':null,
  ].filter((name):name is string=>Boolean(name));
  if(missing.length) {
    console.error('[earn] Missing or invalid Whop OAuth Worker bindings:',missing.join(', '));
    throw new Error('Whop Earn OAuth is not configured.');
  }
  const parsed=new URL(uri!);
  if(!['https:','http:'].includes(parsed.protocol) || (process.env.NODE_ENV==='production'&&parsed.protocol!=='https:')) {
    throw new Error('Whop OAuth callback must use a secure URL.');
  }
  if(!parsed.pathname.endsWith('/api/earn/connect/callback') || parsed.search || parsed.hash) {
    throw new Error('Whop OAuth callback is not registered correctly.');
  }
  return {
    id:id!,secret:secret!,uri:uri!,cookieSecret:cookieSecret!,
    host:whopEnvironment()==='production'?'https://api.whop.com':'https://sandbox-api.whop.com',
  };
}
export function newOAuthState(userId:string):EarnOAuthState {
  return {
    userId,state:randomBytes(24).toString('base64url'),
    verifier:randomBytes(36).toString('base64url'),
    nonce:randomBytes(24).toString('base64url'),created:Date.now(),
  };
}
export function signOAuthState(value:EarnOAuthState,secret:string):string {
  const payload=Buffer.from(JSON.stringify(value)).toString('base64url');
  const mac=createHmac('sha256',secret).update(payload).digest('base64url');
  return `${payload}.${mac}`;
}
export function verifyOAuthState(value:string,secret:string):EarnOAuthState|null {
  const parts=value.split('.');
  if(parts.length!==2)return null;
  const [payload,signature]=parts;
  if(!payload||!signature||payload.length>1800)return null;
  const expected=createHmac('sha256',secret).update(payload).digest();
  let actual:Buffer;
  try {actual=Buffer.from(signature,'base64url');}catch{return null;}
  if(actual.length!==expected.length||!timingSafeEqual(actual,expected))return null;
  let state:unknown;
  try{state=JSON.parse(Buffer.from(payload,'base64url').toString('utf8'));}catch{return null;}
  if(!state||typeof state!=='object')return null;
  const item=state as Record<string,unknown>;
  if(typeof item.userId!=='string'||!/^[-\w]{36}$/.test(item.userId) ||
     typeof item.verifier!=='string'||!item.verifier ||
     typeof item.state!=='string'||!item.state ||
     typeof item.nonce!=='string'||!item.nonce ||
     typeof item.created!=='number'||Date.now()-item.created>OAUTH_MAX_AGE*1000 ||
     item.created>Date.now()+30000) return null;
  return item as unknown as EarnOAuthState;
}
export function authorizeWhopURL(state:EarnOAuthState,config:Awaited<ReturnType<typeof whopOauthConfiguration>>):string {
  const challenge=createHash('sha256').update(state.verifier).digest('base64url');
  const url=new URL(`${config.host}/oauth/authorize`);
  url.search=new URLSearchParams({
    response_type:'code',client_id:config.id,redirect_uri:config.uri,
    scope:'openid profile email',state:state.state,nonce:state.nonce,
    code_challenge:challenge,code_challenge_method:'S256',
  }).toString();
  return url.toString();
}

export async function verifiedWhopUser(
  code:string,state:EarnOAuthState,config:Awaited<ReturnType<typeof whopOauthConfiguration>>
):Promise<string> {
  const tokenResponse=await fetch(`${config.host}/oauth/token`,{
    method:'POST',cache:'no-store',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({
      grant_type:'authorization_code',code,redirect_uri:config.uri,
      client_id:config.id,client_secret:config.secret,code_verifier:state.verifier,
    }),
  });
  if(!tokenResponse.ok)throw new WhopConnectError('token_exchange',tokenResponse.status);
  const tokens=await tokenResponse.json() as {access_token?:string;id_token?:string};
  if(!tokens.access_token)throw new WhopConnectError('token_response');
  if(tokens.id_token) {
    const parts=tokens.id_token.split('.');
    if(parts.length!==3)throw new WhopConnectError('identity');
    const body=JSON.parse(Buffer.from(parts[1],'base64url').toString('utf8')) as {nonce?:string};
    if(body.nonce!==state.nonce)throw new WhopConnectError('identity');
  }
  const response=await fetch(`${config.host}/oauth/userinfo`,{
    headers:{Authorization:`Bearer ${tokens.access_token}`},cache:'no-store',
  });
  if(!response.ok)throw new WhopConnectError('userinfo',response.status);
  const user=await response.json() as {sub?:string};
  if(!user.sub || !/^user_[A-Za-z0-9_-]+$/.test(user.sub))throw new WhopConnectError('identity');
  return user.sub;
}
