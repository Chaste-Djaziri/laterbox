import test from 'node:test';
import assert from 'node:assert/strict';
import { requestExtension } from './dashboard';

test('extension checks accept only matching replies from this window and origin', async () => {
  const original = globalThis.window;
  let listener: ((event: unknown) => void) | undefined;
  let removed = false;
  const origin = 'https://app.laterbox.dev';
  const page = {
    location: { origin },
    addEventListener: (_type: string, callback: typeof listener) => { listener = callback; },
    removeEventListener: () => { removed = true; },
    postMessage: (request: { requestId: string; action: string; userId: string }, target: string) => {
      assert.equal(target, origin);
      assert.equal(request.userId, 'account');
      const data = { source: 'laterbox-extension', requestId: request.requestId, installed: true, connected: true };
      listener?.({ source: {}, origin, data });
      listener?.({ source: page, origin: 'https://other.example', data });
      listener?.({ source: page, origin, data: { ...data, requestId: 'stale' } });
      assert.equal(removed, false);
      listener?.({ source: page, origin, data });
    },
  };
  globalThis.window = page as unknown as Window & typeof globalThis;
  try {
    assert.deepEqual(await requestExtension('status', 'account'), { installed: true, connected: true, error: undefined });
    assert.equal(removed, true);
  } finally { globalThis.window = original; }
});

test('missing extension times out and cancelled account checks cannot update state', async () => {
  const original = globalThis.window;
  let removed = 0;
  globalThis.window = {
    location: { origin: 'https://app.laterbox.dev' },
    addEventListener() {}, removeEventListener() { removed++; }, postMessage() {},
  } as unknown as Window & typeof globalThis;
  try {
    assert.deepEqual(await requestExtension('status', '', undefined, 5), { installed: false, connected: false });
    const controller = new AbortController();
    const pending = requestExtension('status', 'old-account', controller.signal);
    controller.abort();
    await assert.rejects(pending, { name: 'AbortError' });
    assert.equal(removed, 2);
  } finally { globalThis.window = original; }
});
