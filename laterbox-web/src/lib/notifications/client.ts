import { getSupabaseClient } from '../supabase/client';

export type NotificationPreferences = { enabled: boolean; returns: boolean; saves: boolean };
export const defaultPreferences: NotificationPreferences = { enabled: false, returns: true, saves: true };
export function installationId(): string {
  const key = 'laterbox_notification_installation';
  let id = localStorage.getItem(key);
  if (!id) { id = crypto.randomUUID(); localStorage.setItem(key, id); }
  return id;
}
export function preferences(userId?: string): NotificationPreferences {
  try { return { ...defaultPreferences, ...JSON.parse(localStorage.getItem(`laterbox_notifications_${userId || 'guest'}`) || '{}') }; }
  catch { return defaultPreferences; }
}
export function savePreferences(value: NotificationPreferences, userId?: string) {
  localStorage.setItem(`laterbox_notifications_${userId || 'guest'}`, JSON.stringify(value));
  window.dispatchEvent(new Event('laterbox-notifications'));
}
export function supported() {
  return window.isSecureContext && 'Notification' in window && 'serviceWorker' in navigator;
}
export async function notificationWorker() {
  if (!supported()) throw new Error('Install LaterBox on your Home Screen on iOS, or use a browser that supports notifications.');
  const registration = await navigator.serviceWorker.register('/notifications-sw.js', { scope: '/' });
  await navigator.serviceWorker.ready;
  return registration;
}
function applicationKey(value: string): ArrayBuffer {
  const raw = atob(value.replaceAll('-', '+').replaceAll('_', '/') + '='.repeat((4 - value.length % 4) % 4));
  return Uint8Array.from(raw, (c) => c.charCodeAt(0)).buffer;
}
export async function setWorkerAccount(reg: ServiceWorkerRegistration, userId: string | null, prefs: NotificationPreferences) {
  const worker = reg.active;
  if (!worker) throw new Error('Notification worker is not ready yet. Try again.');
  await new Promise<void>((resolve, reject) => {
    const channel = new MessageChannel();
    const timeout = setTimeout(() => reject(new Error('Notification worker did not respond.')), 5000);
    channel.port1.onmessage = () => { clearTimeout(timeout); channel.port1.close(); resolve(); };
    worker.postMessage({ type: 'configure', userId, preferences: prefs }, [channel.port2]);
  });
}
let signature: string | null = null;
const registeredUserKey = 'laterbox_notification_registered_user';
const suspendedUserKey = 'laterbox_notification_suspended_user';
export function suspendCloudNotifications(userId?: string) {
  if (userId) localStorage.setItem(suspendedUserKey, userId);
}
export function resumeCloudNotifications() { localStorage.removeItem(suspendedUserKey); }
export function hasCloudRegistration(userId?: string) { return !!userId && localStorage.getItem(registeredUserKey) === userId; }
export async function withItemNotificationLock<T>(itemId: string, action: () => Promise<T>): Promise<T> {
  return typeof navigator !== 'undefined' && navigator.locks ? navigator.locks.request(`laterbox-notification-item-${itemId}`, action) : action();
}
export function isNotificationHandedOff(itemId: string, returnAt?: string | null) {
  return localStorage.getItem(`laterbox_notification_handoff_${itemId}`) === (returnAt || 'none');
}
export async function uploadWithNotificationHandoff<T>(itemId: string, returnAt: string | null | undefined, action: () => Promise<T>): Promise<T> {
  return withItemNotificationLock(itemId, async () => {
    const key = `laterbox_notification_handoff_${itemId}`;
    localStorage.setItem(key, returnAt || 'none');
    try { return await action(); } catch (error) { localStorage.removeItem(key); throw error; }
  });
}

export async function refreshRegistration(userId: string | undefined, isPro: boolean) {
  const prefs = preferences(userId);
  if (userId && localStorage.getItem(suspendedUserKey) === userId) return { cloud: false, message: 'Notifications disconnected.' };
  if (!supported()) return { cloud: false, message: 'Install the web app on your Home Screen on iOS to enable notifications.' };
  if (!prefs.enabled || Notification.permission !== 'granted') {
    await disableCloudNotifications();
    return { cloud: false, message: prefs.enabled ? 'Notifications are blocked in browser settings.' : 'Notifications are off in this browser.' };
  }
  const reg = await notificationWorker();
  await setWorkerAccount(reg, userId || null, prefs);
  const vapid = process.env.NEXT_PUBLIC_WEB_PUSH_PUBLIC_KEY;
  if (!userId || !isPro || !vapid || !('PushManager' in window)) {
    return { cloud: false, message: userId && isPro ? 'Local reminders enabled. Web Push needs provider setup.' : 'Local reminders work while this page is running.' };
  }
  const client = getSupabaseClient();
  const { data: auth } = await client.auth.getSession();
  if (auth.session?.user.id !== userId || localStorage.getItem(suspendedUserKey) === userId) return { cloud: false, message: 'Notifications disconnected.' };
  const subscription = await reg.pushManager.getSubscription() || await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: applicationKey(vapid) });
  const next = JSON.stringify([userId, prefs, subscription.toJSON()]);
  if (signature !== next) {
    const { error } = await getSupabaseClient().rpc('register_notification_installation', {
      installation_id: installationId(), device_platform: 'web', delivery_transport: 'web',
      web_subscription: subscription.toJSON(), notifications_enabled: true, returns_enabled: prefs.returns, saves_enabled: prefs.saves,
    });
    if (error) throw new Error('Cloud notifications could not register. Check connection and server setup.');
    signature = next;
    localStorage.setItem(registeredUserKey, userId);
  }
  return { cloud: true, message: 'Notifications can arrive even when this page is closed.' };
}
export async function disableCloudNotifications() {
  signature = null;
  if ('serviceWorker' in navigator) {
    const reg = await navigator.serviceWorker.getRegistration('/');
    if (reg?.active?.scriptURL.endsWith('/notifications-sw.js')) {
      await setWorkerAccount(reg, null, defaultPreferences);
      await (await reg.pushManager?.getSubscription())?.unsubscribe();
      for (const notification of await reg.getNotifications()) notification.close();
    }
  }
  const client = getSupabaseClient();
  const { data } = await client.auth.getSession();
  if (data.session && hasCloudRegistration(data.session.user.id)) {
    const { error } = await client.from('notification_installations').delete().eq('id', installationId());
    if (error) throw new Error('Could not disconnect cloud notifications. Please retry.');
    localStorage.removeItem(registeredUserKey);
  }
}
export async function testNotification(userId?: string) {
  if (!supported()) throw new Error('Install the app on your Home Screen on iOS or use a supported browser.');
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') throw new Error('Allow notifications in browser settings.');
  const reg = await notificationWorker();
  await reg.showNotification('LaterBox', { body: 'Notifications are ready on this device.', tag: 'laterbox-test', data: { user_id: userId || null } });
}
