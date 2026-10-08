export type ExtensionStatus = { installed: boolean; connected: boolean; error?: string };
export const CHROME_EXTENSION_URL = 'https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp?authuser=0&hl=en';

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
