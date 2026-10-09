export type ExtensionStatus = { installed: boolean; connected: boolean; error?: string };
export const CHROME_EXTENSION_URL = 'https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp?authuser=0&hl=en';

// Successful connection checks are cached in sessionStorage (cleared when the browser
// session closes) and keyed by user + auth session, so a new sign-in invalidates them.
const STATUS_CACHE_KEY = 'laterbox_extension_status';

/** Stable per-login identifier: the JWT `session_id` claim survives token refreshes. */
export function extensionSessionKey(userId?: string, accessToken?: string): string {
  if (!userId) return '';
  let sessionId = '';
  try {
    const payload = accessToken?.split('.')[1];
    if (payload) sessionId = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/'))).session_id || '';
  } catch { /* Fall back to user-only key. */ }
  return `${userId}:${sessionId}`;
}

export function getCachedExtensionConnected(key: string): boolean {
  if (!key || typeof sessionStorage === 'undefined') return false;
  try { return sessionStorage.getItem(STATUS_CACHE_KEY) === key; } catch { return false; }
}

export function cacheExtensionConnected(key: string): void {
  if (!key || typeof sessionStorage === 'undefined') return;
  try { sessionStorage.setItem(STATUS_CACHE_KEY, key); } catch { /* Storage unavailable. */ }
}

export function clearExtensionStatusCache(): void {
  if (typeof sessionStorage === 'undefined') return;
  try { sessionStorage.removeItem(STATUS_CACHE_KEY); } catch { /* Storage unavailable. */ }
}

export function requestExtension(action: 'status' | 'connect', userId: string, signal?: AbortSignal, timeoutMs = action === 'connect' ? 20000 : 2000): Promise<ExtensionStatus> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) { reject(new DOMException('Aborted', 'AbortError')); return; }
    const requestId = crypto.randomUUID();
    const cleanup = () => {
      clearTimeout(timer);
      window.removeEventListener('message', receive);
      signal?.removeEventListener('abort', abort);
    };
    const abort = () => { cleanup(); reject(new DOMException('Aborted', 'AbortError')); };
    const receive = (event: MessageEvent) => {
      if (event.source !== window || event.origin !== window.location.origin) return;
      const response = event.data;
      if (!response || response.source !== 'laterbox-extension' || response.requestId !== requestId) return;
      cleanup();
      resolve({ installed: response.installed === true, connected: response.installed === true && response.connected === true,
        error: typeof response.error === 'string' ? response.error : undefined });
    };
    const timer = setTimeout(() => {
      cleanup();
      resolve({ installed: false, connected: false });
    }, timeoutMs);
    window.addEventListener('message', receive);
    signal?.addEventListener('abort', abort, { once: true });
    window.postMessage({ source: 'laterbox-dashboard', requestId, action, userId }, window.location.origin);
  });
}
