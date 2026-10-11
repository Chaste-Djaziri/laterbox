import test from 'node:test';
import assert from 'node:assert/strict';

let message: unknown;
(globalThis as any).chrome = { runtime: { sendMessage: async (request: unknown) => {
  message = request;
  return { connected: true, userId: 'private-user', accessToken: 'private-token' };
} } };
const { installDashboardBridge } = await import('../src/content/dashboard-bridge');

test('dashboard bridge ignores untrusted sites and exposes only connection status', async () => {
  let listener: ((event: unknown) => void) | undefined;
  const replies: any[] = [];
  const page = { addEventListener: (_type: string, callback: typeof listener) => { listener = callback; },
    postMessage: (data: unknown) => { replies.push(data); } };
  (globalThis as any).window = page;
  (globalThis as any).location = { protocol: 'https:', hostname: 'other.example', origin: 'https://other.example' };
  installDashboardBridge();
  assert.equal(listener, undefined);
  (globalThis as any).location = { protocol: 'https:', hostname: 'app.laterbox.dev', origin: 'https://app.laterbox.dev' };
  installDashboardBridge();
  assert.ok(listener);
  const request = { source: 'laterbox-dashboard', requestId: 'request', action: 'status', userId: 'account' };
  listener!({ source: page, origin: 'https://other.example', data: request });
  assert.equal(message, undefined);
  listener!({ source: page, origin: 'https://app.laterbox.dev', data: request });
  await new Promise(resolve => setTimeout(resolve, 0));
  assert.deepEqual(message, { type: 'dashboard-status', userId: 'account' });
  assert.equal(replies[0].connected, true);
  assert.equal(replies[0].accessToken, undefined);
  assert.equal(replies[0].userId, undefined);
});


test('local import bridge requires the exact approved origin and hides credentials', async () => {
 let listener: ((event: any) => void) | undefined;
 const replies: any[] = [];
 const page = { addEventListener: (_: string, callback: typeof listener) => { listener = callback; }, postMessage: (value: unknown) => replies.push(value) };
 (globalThis as any).window = page;
 const request = { source: 'laterbox-dashboard', requestId: 'local', action: 'local-import' };
 const url = new URL('https://untrusted.example');
 (globalThis as any).location = { origin: 'https://untrusted.example', hostname: url.hostname, protocol: url.protocol };
 installDashboardBridge();
 assert.equal(listener, undefined);
 const origin = 'https://app.laterbox.dev';
 (globalThis as any).location = { origin, hostname: 'app.laterbox.dev', protocol: 'https:' };
 installDashboardBridge();
 assert.ok(listener);
 message = undefined;
 listener!({ source: {}, origin, data: request }); assert.equal(message, undefined);
 listener!({ source: page, origin: 'https://untrusted.example', data: request }); assert.equal(message, undefined);
 listener!({ source: page, origin, data: request });
 await new Promise(resolve => setTimeout(resolve, 0));
 assert.deepEqual(message, { type: 'local-import', ids: undefined });
 assert.equal(replies[0].accessToken, undefined); assert.equal(replies[0].userId, undefined);
});
