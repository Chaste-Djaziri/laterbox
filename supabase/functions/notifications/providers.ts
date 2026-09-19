import { importPKCS8, SignJWT } from 'npm:jose@6.1.0';
import webpush from 'npm:web-push@3.6.7';

export type Delivery = {
  event_id: string; installation_id: string; lease_id: string; item_id: string;
  user_id: string; kind: 'save' | 'return'; platform: string;
  transport: 'apns' | 'fcm' | 'web'; token: string | null;
  subscription: { endpoint: string; keys: { p256dh: string; auth: string } } | null;
  attempts: number;
};
export class DeliveryError extends Error {
  constructor(public status: number, public expired = false) { super(`Provider status ${status}`); }
}
const env = (name: string) => {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing ${name}`);
  return value.replaceAll('\\n', '\n');
};
const bodyFor = (kind: string) => kind === 'return' ? 'An item is ready in your inbox.' : 'An item was added to your inbox.';
let apnsAuth: { token: string; until: number } | undefined;
let googleAuth: { token: string; until: number } | undefined;

async function appleToken() {
  if (apnsAuth && apnsAuth.until > Date.now()) return apnsAuth.token;
  const key = await importPKCS8(env('APNS_PRIVATE_KEY'), 'ES256');
  const token = await new SignJWT({}).setProtectedHeader({ alg: 'ES256', kid: env('APNS_KEY_ID') })
    .setIssuer(env('APNS_TEAM_ID')).setIssuedAt().sign(key);
  apnsAuth = { token, until: Date.now() + 45 * 60_000 };
  return token;
}
async function firebaseToken() {
  if (googleAuth && googleAuth.until > Date.now()) return googleAuth.token;
  const key = await importPKCS8(env('FCM_PRIVATE_KEY'), 'RS256');
  const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/firebase.messaging' })
    .setProtectedHeader({ alg: 'RS256' }).setIssuer(env('FCM_CLIENT_EMAIL'))
    .setAudience('https://oauth2.googleapis.com/token').setIssuedAt().setExpirationTime('1h').sign(key);
  const response = await fetch('https://oauth2.googleapis.com/token', { method: 'POST',
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }), signal: AbortSignal.timeout(15000) });
  if (!response.ok) throw new DeliveryError(response.status);
  const data = await response.json();
  googleAuth = { token: data.access_token, until: Date.now() + 45 * 60_000 };
  return googleAuth.token;
}
export function validPushEndpoint(endpoint: string): boolean {
  try {
    const url = new URL(endpoint);
    // Web subscriptions are user input. Do not permit arbitrary server-side URLs.
    return url.protocol === 'https:' && !url.username && !url.password && (!url.port || url.port === '443') &&
      (url.hostname === 'fcm.googleapis.com' || url.hostname === 'updates.push.services.mozilla.com' ||
       url.hostname.endsWith('.push.services.mozilla.com') || url.hostname === 'web.push.apple.com' ||
       url.hostname.endsWith('.notify.windows.com'));
  } catch { return false; }
}
export async function sendDelivery(d: Delivery) {
  const data = { item_id: d.item_id, user_id: d.user_id, event_id: d.event_id, kind: d.kind };
  if (d.transport === 'web') {
    if (!d.subscription || !validPushEndpoint(d.subscription.endpoint)) throw new DeliveryError(410, true);
    try {
      await webpush.sendNotification(d.subscription, JSON.stringify({ ...data, title: 'LaterBox', body: bodyFor(d.kind) }), {
        TTL: 3600, timeout: 15000, urgency: 'normal',
        vapidDetails: { subject: env('WEB_PUSH_SUBJECT'), publicKey: env('WEB_PUSH_PUBLIC_KEY'), privateKey: env('WEB_PUSH_PRIVATE_KEY') },
      });
    } catch (error) {
      const status = (error as { statusCode?: number }).statusCode;
      if (status) throw new DeliveryError(status, status === 404 || status === 410);
      throw error;
    }
    return;
  }
  if (!d.token) throw new DeliveryError(410, true);
  let response: Response;
  if (d.transport === 'apns') {
    if (!/^[a-f0-9]{32,256}$/i.test(d.token)) throw new DeliveryError(410, true);
    const host = Deno.env.get('APNS_ENVIRONMENT') === 'development' ? 'api.sandbox.push.apple.com' : 'api.push.apple.com';
    const topic = d.platform === 'macos' ? (Deno.env.get('APNS_MACOS_TOPIC') || env('APNS_TOPIC')) : env('APNS_TOPIC');
    response = await fetch(`https://${host}/3/device/${d.token}`, { method: 'POST', signal: AbortSignal.timeout(15000), headers: {
      authorization: `bearer ${await appleToken()}`, 'apns-topic': topic, 'apns-push-type': 'alert',
      'apns-priority': '10', 'apns-collapse-id': d.event_id, 'apns-expiration': String(Math.floor(Date.now()/1000)+3600),
    }, body: JSON.stringify({ aps: { alert: { title: 'LaterBox', body: bodyFor(d.kind) }, sound: 'default', 'thread-id': 'inbox' }, ...data }) });
    if (!response.ok) {
      const result = await response.json().catch(() => ({}));
      throw new DeliveryError(response.status, response.status === 410 || result.reason === 'BadDeviceToken' || result.reason === 'DeviceTokenNotForTopic');
    }
  } else {
    response = await fetch(`https://fcm.googleapis.com/v1/projects/${env('FCM_PROJECT_ID')}/messages:send`, {
      method: 'POST', signal: AbortSignal.timeout(15000), headers: { authorization: `Bearer ${await firebaseToken()}`, 'content-type': 'application/json' },
      body: JSON.stringify({ message: { token: d.token, data,
        notification: { title: 'LaterBox', body: bodyFor(d.kind) },
        android: { priority: 'HIGH', ttl: '3600s', notification: { channel_id: 'laterbox_inbox', tag: d.event_id, icon: 'ic_notification' } },
      } }),
    });
    if (!response.ok) {
      const result = await response.json().catch(() => ({}));
      const expired = result.error?.details?.some((x: { errorCode?: string }) => x.errorCode === 'UNREGISTERED');
      throw new DeliveryError(response.status, !!expired);
    }
  }
}
