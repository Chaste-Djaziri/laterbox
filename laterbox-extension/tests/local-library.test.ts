import test from 'node:test';
import assert from 'node:assert/strict';
let stored: Record<string, any> = { captureMode: 'local' };
let fail = false;
(globalThis as any).chrome = {
 storage: { local: {
  get: async () => structuredClone(stored),
  set: async (next: object) => { if (fail) throw new Error('quota'); Object.assign(stored, structuredClone(next)); },
 } },
 action: { setBadgeText: async () => {}, setTitle: async () => {} },
};
const { saveLocalCapture, readLocalCaptures, acknowledgeLocalCaptures, isLocalMode } = await import('../src/lib/local-library');
const capture = (id: string) => ({ captureId: id, source: 'browserExtension' as const,
 createdAt: new Date().toISOString(), url: 'https://example.com', markdown: '# Article', text: 'Quote', selector: { exact: 'Quote', before: 'Before' } });
test('local captures serialize, persist across reads, deduplicate and acknowledge only requested IDs', async () => {
 stored = { captureMode: 'local', pendingCaptures: [{ userId: 'account' }] };
 assert.equal(await isLocalMode(), true);
 await Promise.all([saveLocalCapture(capture('one')), saveLocalCapture(capture('two'))]);
 assert.equal((await saveLocalCapture(capture('one'))).local, true);
 assert.deepEqual((await readLocalCaptures()).map(c => c.captureId), ['one', 'two']);
 assert.equal((await readLocalCaptures())[0].markdown, '# Article');
 assert.equal((await readLocalCaptures())[0].selector?.exact, 'Quote');
 await acknowledgeLocalCaptures(['one']);
 assert.deepEqual((await readLocalCaptures()).map(c => c.captureId), ['two']);
 assert.equal(stored.pendingCaptures[0].userId, 'account');
 stored.captureMode = 'account'; assert.equal(await isLocalMode(), false);
 stored.captureMode = 'local'; assert.equal((await readLocalCaptures()).length, 1);
});
test('failed storage never acknowledges a local capture or removes originals', async () => {
 fail = true;
 await assert.rejects(saveLocalCapture(capture('three')), /quota/);
 await assert.rejects(acknowledgeLocalCaptures(['two']), /quota/);
 fail = false;
 assert.deepEqual((await readLocalCaptures()).map(c => c.captureId), ['two']);
 await saveLocalCapture(capture('three')); assert.equal((await readLocalCaptures()).length, 2);
});
