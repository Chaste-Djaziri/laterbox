'use client';
import { useEffect, useRef, useState } from 'react';
import { BellRing, CalendarClock, CheckCircle2, CircleAlert, Laptop, RotateCcw, Send, ShieldCheck } from 'lucide-react';
import { SettingsSwitch } from '@/components/settings/SettingsSwitch';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { useItems } from '@/lib/store/ItemContext';
import { hasCloudRegistration, isNotificationHandedOff, withItemNotificationLock, notificationWorker, preferences, refreshRegistration, savePreferences, supported, defaultPreferences, testNotification } from '@/lib/notifications/client';

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
            const rawTitle = item.title?.trim() || item.metadata?.title?.trim();
            const rawDesc = item.metadata?.description?.trim()
              || item.note?.content?.trim()
              || item.text_content?.trim()
              || item.content?.markdown?.trim()
              || item.url?.trim();
            const title = rawTitle || 'LaterBox';
            const body = (rawDesc && rawDesc !== rawTitle) ? rawDesc : (rawTitle ? 'Ready in your inbox.' : 'An item is ready in your inbox.');
            await reg.showNotification(title, { body, tag: event, data: { item_id: item.id, user_id: user?.id || null } });
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
  const [prefs, setPrefs] = useState(defaultPreferences);
  const [message, setMessage] = useState('Choose how this browser should notify you.');
  const [permission, setPermission] = useState<NotificationPermission | 'unsupported'>('unsupported');
  const [busy, setBusy] = useState(false);
  const [testing, setTesting] = useState(false);

  useEffect(() => {
    setPrefs(preferences(user?.id));
    const checkPermission = () => setPermission(
      supported() ? Notification.permission : 'unsupported'
    );
    checkPermission();
    const status = (event: Event) => {
      const detail = (event as CustomEvent<string>).detail;
      if (typeof detail === 'string') setMessage(detail);
      checkPermission();
    };
    window.addEventListener('laterbox-notification-status', status);
    window.addEventListener('focus', checkPermission);
    return () => {
      window.removeEventListener('laterbox-notification-status', status);
      window.removeEventListener('focus', checkPermission);
    };
  }, [user?.id]);

  const update = async (key: 'enabled' | 'returns' | 'saves', value: boolean) => {
    if (busy) return;
    setBusy(true);
    try {
      if (key === 'enabled' && value) {
        if (!supported()) throw new Error('Use a supported browser. On iOS, add LaterBox to your Home Screen first.');
        const grant = await Notification.requestPermission();
        setPermission(grant);
        if (grant !== 'granted') throw new Error('Notification permission was not granted. You can change it in browser settings.');
      }
      const next = { ...prefs, [key]: value };
      savePreferences(next, user?.id);
      setPrefs(next);
      setMessage(value ? 'Preference saved for this browser.' : 'Notification preference updated.');
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Could not update this preference.');
    } finally {
      setBusy(false);
    }
  };

  const reset = () => {
    if (busy || testing) return;
    savePreferences(defaultPreferences, user?.id);
    setPrefs({ ...defaultPreferences });
    setMessage('Notification preferences reset for this browser.');
  };

  const sendTest = async () => {
    if (busy || testing) return;
    setTesting(true);
    try {
      await testNotification(user?.id);
      setPermission(supported() ? Notification.permission : 'unsupported');
      setMessage('Test notification sent to your device.');
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Could not send a test notification.');
    } finally {
      setTesting(false);
    }
  };

  const permissionLabel =
    permission === 'granted' ? 'Permission granted'
    : permission === 'denied' ? 'Blocked by browser'
    : permission === 'unsupported' ? 'Not supported here'
    : 'Permission not requested';
  const isReady = prefs.enabled && permission === 'granted';

  return (
    <div className="space-y-5">
      <section className="overflow-hidden rounded-[24px] border border-[#e5e4da] bg-white shadow-[0_3px_20px_rgba(36,42,29,0.035)]">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#edede6] px-5 py-5 sm:px-6">
          <div className="flex items-center gap-3">
            <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#33452b]">
              <BellRing className="h-5 w-5" aria-hidden="true" />
            </span>
            <div>
              <h2 className="text-sm font-black text-[#242c20]">Device notifications</h2>
              <p className="mt-1 text-xs text-[#8c9187]">Control alerts for this browser.</p>
            </div>
          </div>
          <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-[11px] font-bold ${
            isReady ? 'bg-[#edf5de] text-[#4c733e]'
              : permission === 'denied' ? 'bg-[#fff0eb] text-[#98533f]'
              : 'bg-[#f3f3ed] text-[#767b72]'
          }`}>
            {isReady ? <CheckCircle2 className="h-3.5 w-3.5" aria-hidden="true" /> :
              <CircleAlert className="h-3.5 w-3.5" aria-hidden="true" />}
            {isReady ? 'Enabled on this device' : permissionLabel}
          </span>
        </div>
        <div className="divide-y divide-[#eeeae2]">
          <SettingsSwitch
            id="notifications-master"
            title="Allow notifications"
            description="Request browser permission and turn on alerts for this device."
            icon={BellRing}
            checked={prefs.enabled}
            onCheckedChange={checked => void update('enabled', checked)}
            disabled={busy || permission === 'unsupported'}
            label="Master switch"
          />
          <SettingsSwitch
            id="notifications-returns"
            title="Scheduled returns"
            description="Notify you when a saved item is due to return to your Inbox."
            icon={CalendarClock}
            checked={prefs.returns}
            onCheckedChange={checked => void update('returns', checked)}
            disabled={busy || !prefs.enabled}
          />
          <SettingsSwitch
            id="notifications-saves"
            title="Saves from other devices"
            description="Receive supported cross-device save alerts when cloud notifications are available."
            icon={Laptop}
            checked={prefs.saves}
            onCheckedChange={checked => void update('saves', checked)}
            disabled={busy || !prefs.enabled}
          />
        </div>
        <div className="flex flex-wrap items-center justify-between gap-3 border-t border-[#edece5] bg-[#fcfcf9] px-5 py-4 sm:px-6">
          <p role="status" aria-live="polite" className="max-w-xl text-xs leading-5 text-[#747d6e]">{message}</p>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={reset}
              disabled={busy || testing}
              className="inline-flex min-h-10 items-center gap-2 rounded-xl border border-[#e3e4d9] bg-white px-3.5 text-xs font-bold text-[#697664] transition-colors hover:bg-[#f3f7eb] disabled:opacity-40 focus-visible:outline-2 focus-visible:outline-[#7b9058]"
            >
              <RotateCcw className="h-3.5 w-3.5" aria-hidden="true" /> Reset
            </button>
            <button
              type="button"
              onClick={() => void sendTest()}
              disabled={busy || testing || !isReady}
              className="inline-flex min-h-10 items-center gap-2 rounded-xl bg-[#20271d] px-4 text-xs font-bold text-white transition-colors hover:bg-[#384a30] disabled:cursor-not-allowed disabled:opacity-40 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7b9058]"
            >
              <Send className="h-3.5 w-3.5" aria-hidden="true" />
              {testing ? 'Sending…' : 'Send test alert'}
            </button>
          </div>
        </div>
      </section>

      <section className="flex items-start gap-3 rounded-[20px] border border-[#e1e8d2] bg-[#f5f8ed] p-5 sm:p-6">
        <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-[#688252]" aria-hidden="true" />
        <div className="space-y-1.5">
          <h3 className="text-[13px] font-extrabold text-[#34472e]">Delivery and privacy</h3>
          <p className="text-xs leading-6 text-[#717f69]">
            These choices are stored in this browser. Local reminders may require LaterBox to remain open.
            Notifications while the app is closed depend on your account, plan, browser support and cloud registration.
            If alerts are blocked, allow them in your browser or device settings.
          </p>
        </div>
      </section>
    </div>
  );
}
