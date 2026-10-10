import { sendRuntimeMessage } from '../platform/messaging';

const trustedHosts = new Set(['laterbox.dev', 'www.laterbox.dev', 'app.laterbox.dev', 'laterbox.micorp.pro', 'app.laterbox.com']);

export function installDashboardBridge(): void {
  const trusted = (location.protocol === 'https:' && trustedHosts.has(location.hostname))
    || (location.hostname === 'localhost' && ['http:', 'https:'].includes(location.protocol));
  if (!trusted) return;
  window.addEventListener('message', event => {
    if (event.source !== window || event.origin !== location.origin) return;
    const request = event.data;
    if (!request || request.source !== 'laterbox-dashboard' || typeof request.requestId !== 'string'
      || request.requestId.length > 100 || !['status', 'connect', 'local-import', 'local-ack'].includes(request.action)) return;
    if (request.action === 'local-import' || request.action === 'local-ack') {
      if (location.origin !== 'http://localhost:8080') return;
      void sendRuntimeMessage({ type: request.action, ids: request.ids }).then(result => {
        window.postMessage({ source: 'laterbox-extension', requestId: request.requestId, ...result as object }, location.origin);
      }).catch(() => {});
      return;
    }
    const message = request.action === 'status'
      ? { type: 'dashboard-status', userId: typeof request.userId === 'string' ? request.userId : '' }
      : { type: 'connect-laterbox' };
    void sendRuntimeMessage<{ installed?: boolean; connected?: boolean; error?: string }>(message)
      .then(result => {
        window.postMessage({
          source: 'laterbox-extension', requestId: request.requestId,
          installed: true, connected: result?.connected === true,
          error: typeof result?.error === 'string' ? 'Open the extension popup and choose Connect to try again.' : undefined,
        }, location.origin);
      })
      .catch(() => {
        window.postMessage({ source: 'laterbox-extension', requestId: request.requestId, installed: true, connected: false,
          error: 'Refresh this page to reconnect to the extension.' }, location.origin);
      });
  });
}
