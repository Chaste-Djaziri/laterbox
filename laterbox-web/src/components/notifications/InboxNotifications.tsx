'use client';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { useItems } from '@/lib/store/ItemContext';
import { hasCloudRegistration, isNotificationHandedOff, withItemNotificationLock, notificationWorker, preferences, refreshRegistration, savePreferences, supported, testNotification } from '@/lib/notifications/client';

export function InboxNotificationController() {
  const { user, loading: authLoading } = useAuth(); const { isPro, loading: billingLoading } = useBilling(); const { items, loading, syncNow } = useItems();
  const router = useRouter();
  const latest = useRef({ items, loading, syncNow }); latest.current = { items, loading, syncNow };
  useEffect(() => {
    if (authLoading || billingLoading) return;
    let stopped = false; let running = false; let baseline = Date.now();
    const tick = async () => {
      if (running || stopped) return;
      running = true;
      try {
        const prefs = preferences(user?.id);
        const state = await refreshRegistration(user?.id, isPro).catch((error) => ({
          cloud: hasCloudRegistration(user?.id), message: error instanceof Error ? error.message : 'Notifications could not update.',
        }));
        window.dispatchEvent(new CustomEvent('laterbox-notification-status', { detail: state.message }));
        if (!prefs.enabled || !prefs.returns || !supported() || Notification.permission !== 'granted' || latest.current.loading) { baseline = Date.now(); return; }
        const now = Date.now();
        for (const item of latest.current.items) {
          const due = item.return_at ? Date.parse(item.return_at) : 0;
          if (!due || due <= baseline || due > now || item.deleted_at || !['inbox', 'deferred'].includes(item.status)) continue;
          const pending = JSON.parse(localStorage.getItem(`laterbox_pending_captures_${user?.id}`) || '{}');
          if (state.cloud && !pending[item.id]) continue;
          const event = `local:${user?.id || 'guest'}:${item.id}:${item.return_at}`;
          const deliver = async () => {
            if (stopped || localStorage.getItem(event)) return;
            if (state.cloud && isNotificationHandedOff(item.id, item.return_at)) return;
            const reg = await notificationWorker();
            await reg.showNotification('LaterBox', { body: 'An item is ready in your inbox.', tag: event, data: { item_id: item.id, user_id: user?.id || null } });
            localStorage.setItem(event, String(now));
          };
          // A cross-tab lock prevents two running tabs showing the same reminder.
          if (navigator.locks || document.visibilityState === 'visible') await withItemNotificationLock(item.id, deliver);
        }
        baseline = now;
      } catch (error) {
        window.dispatchEvent(new CustomEvent('laterbox-notification-status', { detail: error instanceof Error ? error.message : 'Notifications could not update.' }));
      } finally { running = false; }
    };
    void tick();
    const timer = setInterval(() => void tick(), 15_000);
    const refresh = () => void tick();
    window.addEventListener('laterbox-notifications', refresh); window.addEventListener('storage', refresh); window.addEventListener('focus', refresh);
    return () => { stopped = true; clearInterval(timer); window.removeEventListener('laterbox-notifications', refresh); window.removeEventListener('storage', refresh); window.removeEventListener('focus', refresh); };
  }, [user?.id, isPro, authLoading, billingLoading]);
  useEffect(() => {
    const itemId = new URLSearchParams(window.location.search).get('notificationItem');
    if (!itemId || loading || authLoading) return;
    let stopped = false;
    void syncNow().finally(() => {
      if (stopped) return;
      const item = latest.current.items.find((entry) => entry.id === itemId && !entry.deleted_at && entry.user_id === (user?.id || null));
      router.replace(item ? `/item/${item.id}` : '/inbox');
    });
    return () => { stopped = true; };
  }, [loading, authLoading, router, syncNow, user?.id]);
  return null;
}

export function InboxNotificationSettings() {
  const { user } = useAuth();
  const [prefs, setPrefs] = useState({ enabled: false, returns: true, saves: true });
  const [message, setMessage] = useState('Enable notifications for this browser. On iOS, first add LaterBox to your Home Screen.');
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    setPrefs(preferences(user?.id));
    const status = (event: Event) => setMessage((event as CustomEvent<string>).detail);
    window.addEventListener('laterbox-notification-status', status);
    return () => window.removeEventListener('laterbox-notification-status', status);
  }, [user?.id]);
  const update = async (key: 'enabled' | 'returns' | 'saves', value: boolean) => {
    setBusy(true);
    try {
      if (key === 'enabled' && value) {
        if (!supported()) throw new Error('Add LaterBox to your Home Screen on iOS, or use a supported browser.');
        if (await Notification.requestPermission() !== 'granted') throw new Error('Allow notifications in browser settings.');
      }
      const next = { ...prefs, [key]: value }; savePreferences(next, user?.id); setPrefs(next);
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Could not enable notifications.'); }
    finally { setBusy(false); }
  };
  return <section className="rounded-2xl border border-black/10 bg-white p-6 space-y-4">
    <h2 className="text-lg font-bold">Device notifications</h2>
    <p className="text-sm text-gray-600" role="status">{message}</p>
    {([['enabled', 'Enable on this device'], ['returns', 'Scheduled returns'], ['saves', 'Saves from other devices']] as const).map(([key, label]) =>
      <label key={key} className="flex items-center justify-between gap-4"><span>{label}</span><input type="checkbox" checked={prefs[key]} disabled={busy || (key !== 'enabled' && !prefs.enabled)} onChange={(event) => void update(key, event.target.checked)} /></label>)}
    <button type="button" className="rounded-xl bg-black text-white px-4 py-2" disabled={busy} onClick={() => void testNotification(user?.id).catch((error) => setMessage(error.message))}>Send test notification</button>
  </section>;
}
