import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';

export const dynamic = 'force-dynamic';
const packageName = 'pro.micorp.laterbox';
const products = new Set(['com.laterbox.pro.monthly', 'com.laterbox.pro.annual']);
const encode = (data: Uint8Array) => btoa(String.fromCharCode(...data)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
const encodeJSON = (value: unknown) => encode(new TextEncoder().encode(JSON.stringify(value)));

async function googleToken() {
  const config = JSON.parse(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON || '{}') as { client_email?: string; private_key?: string };
  if (!config.client_email || !config.private_key) throw new Error('Google Play verification is not configured');
  const keyBytes = Uint8Array.from(atob(config.private_key.replace(/-----[^-]+-----|\s/g, '')), c => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', keyBytes, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const now = Math.floor(Date.now() / 1000);
  const payload = encodeJSON({ alg: 'RS256', typ: 'JWT' }) + '.' + encodeJSON({ iss: config.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 600 });
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(payload));
  const response = await fetch('https://oauth2.googleapis.com/token', { method: 'POST', body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: payload + '.' + encode(new Uint8Array(signature)) }) });
  if (!response.ok) throw new Error('Unable to authorize purchase verification');
  return (await response.json() as { access_token: string }).access_token;
}
export async function POST(request: Request) {
  const user = await getRequestUser(request);
  if (!user) return NextResponse.json({ error: 'Authentication required.' }, { status: 401 });
  if (!process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON) return NextResponse.json({ error: 'Google Play verification is not configured.' }, { status: 503 });
  try {
    const body = await request.json() as { purchaseToken?: string; productId?: string };
    if (!body.purchaseToken || body.purchaseToken.length > 4096 || !body.productId || !products.has(body.productId)) return NextResponse.json({ error: 'Invalid purchase.' }, { status: 400 });
    const token = await googleToken();
    const headers = { Authorization: 'Bearer ' + token };
    const response = await fetch(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${encodeURIComponent(body.purchaseToken)}`, { headers });
    if (!response.ok) throw new Error('Unable to verify the purchase');
    const purchase = await response.json() as { subscriptionState?: string; acknowledgementState?: string; externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string }; lineItems?: { productId?: string; expiryTime?: string }[] };
    if (purchase.externalAccountIdentifiers?.obfuscatedExternalAccountId !== user.id) return NextResponse.json({ error: 'Purchase belongs to another account.' }, { status: 403 });
    const line = purchase.lineItems?.find(item => item.productId === body.productId);
    const expiry = line?.expiryTime;
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(body.purchaseToken));
    const reason = 'google-play:' + encode(new Uint8Array(digest));
    const admin = getBillingAdminClient();
    const active = ['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_CANCELED', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD'].includes(purchase.subscriptionState ?? '') && expiry && new Date(expiry).getTime() > Date.now();
    if (!active) {
      const { error } = await admin.from('billing_entitlement_grants').delete().eq('user_id', user.id).eq('reason', reason);
      if (error) throw error;
      return NextResponse.json({ error: 'Subscription is not active.' }, { status: 422 });
    }
    const { error } = await admin.from('billing_entitlement_grants').upsert({ user_id: user.id, tier: 'pro', reason, starts_at: new Date().toISOString(), expires_at: expiry }, { onConflict: 'user_id,reason' });
    if (error) throw error;
    if (purchase.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED') {
      const ack = await fetch(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${encodeURIComponent(body.productId)}/tokens/${encodeURIComponent(body.purchaseToken)}:acknowledge`, { method: 'POST', headers: { ...headers, 'Content-Type': 'application/json' }, body: '{}' });
      if (!ack.ok) throw new Error('Purchase acknowledgement failed');
    }
    return NextResponse.json({ verified: true }, { headers: { 'Cache-Control': 'no-store' } });
  } catch {
    return NextResponse.json({ error: 'Unable to verify the Google Play purchase. Retry restore.' }, { status: 422 });
  }
}
