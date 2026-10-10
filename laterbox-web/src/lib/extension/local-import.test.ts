import test from 'node:test';
import assert from 'node:assert/strict';
import { importLocalCaptures, localCaptureItem, LOCAL_KEY, LOCAL_ORIGIN } from './local-import';
const capture = { captureId: '00000000-0000-4000-8000-000000000010', createdAt: '2026-10-10T12:00:00Z',
 url: 'https://example.com', kind: 'highlight', markdown: '# Article', text: 'Quote', selector: { exact: 'Quote', before: 'Before' } };
test('local snapshot conversion preserves content and rejects invalid captures', () => {
 const item = localCaptureItem(capture);
 assert.equal(item.user_id, null); assert.equal(item.content?.markdown, '# Article');
 assert.equal(JSON.parse(item.text_selector!).exact, 'Quote');
 for (const invalid of [{ ...capture, captureId: 'bad' }, { ...capture, url: 'javascript:alert(1)' }, { ...capture, markdown: 'é'.repeat(102401) }]) {
  assert.throws(() => localCaptureItem(invalid));
 }
});
test('imports persist before acknowledgement, retry without duplicates, and serialize tabs', async () => {
 const listeners = new Set<(event: any) => void>();
 const data = new Map<string, string>(); let quota = false; let acks = 0; let interrupted = true;
 const page = { location: { origin: LOCAL_ORIGIN },
  addEventListener: (_: string, listener: (event: any) => void) => listeners.add(listener),
  removeEventListener: (_: string, listener: (event: any) => void) => listeners.delete(listener),
  postMessage: (request: any) => {
   const response: any = { source: 'laterbox-extension', requestId: request.requestId };
   if (request.action === 'local-import') response.captures = [capture];
   else {
    assert.equal(JSON.parse(data.get(LOCAL_KEY)!)[0].id, capture.captureId);
    acks++; response.ok = !interrupted;
   }
   // Untrusted replies cannot replace the expected payload.
   for (const listener of [...listeners]) listener({ source: {}, origin: LOCAL_ORIGIN, data: response });
   for (const listener of [...listeners]) listener({ source: page, origin: 'http://localhost:3000', data: response });
   for (const listener of [...listeners]) listener({ source: page, origin: LOCAL_ORIGIN, data: response });
  },
 };
 Object.defineProperty(globalThis, 'window', { value: page, configurable: true });
 Object.defineProperty(globalThis, 'localStorage', { value: {
  getItem: (key: string) => data.get(key) || null,
  setItem: (key: string, value: string) => { if (quota) throw new Error('quota'); data.set(key, value); },
 }, configurable: true });
 let tail = Promise.resolve();
 Object.defineProperty(globalThis, 'navigator', { value: { locks: { request: (_: string, run: () => Promise<any>) => {
  const next = tail.then(run, run); tail = next.catch(() => {}); return next;
 } } }, configurable: true });
 quota = true; await assert.rejects(importLocalCaptures(), /quota/); assert.equal(acks, 0);
 quota = false; await importLocalCaptures(); interrupted = false;
 await Promise.all([importLocalCaptures(), importLocalCaptures()]);
 assert.equal(JSON.parse(data.get(LOCAL_KEY)!).length, 1); assert.equal(acks, 3);
 page.location.origin = 'https://app.laterbox.dev'; assert.equal(await importLocalCaptures(), false);
});
