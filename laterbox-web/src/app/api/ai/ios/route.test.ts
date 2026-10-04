import test from 'node:test';
import assert from 'node:assert/strict';
import { POST } from './route';

test('disabled iOS fallback rejects without authentication or Gemini requests', async () => {
  const originalFlag = process.env.IOS_GEMINI_FALLBACK_ENABLED;
  const originalFetch = globalThis.fetch;
  let calls = 0;
  delete process.env.IOS_GEMINI_FALLBACK_ENABLED;
  globalThis.fetch = async () => { calls++; throw new Error('Network must not be used'); };
  try {
    const response = await POST(new Request('https://laterbox.dev/api/ai/ios', { method: 'POST', body: 'invalid JSON' }));
    assert.equal(response.status, 503);
    assert.equal(calls, 0);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalFlag === undefined) delete process.env.IOS_GEMINI_FALLBACK_ENABLED;
    else process.env.IOS_GEMINI_FALLBACK_ENABLED = originalFlag;
  }
});

test('enabled fallback rejects unauthenticated requests before contacting Gemini', async () => {
  const originalFlag = process.env.IOS_GEMINI_FALLBACK_ENABLED;
  const originalFetch = globalThis.fetch;
  let calls = 0;
  process.env.IOS_GEMINI_FALLBACK_ENABLED = 'true';
  globalThis.fetch = async () => { calls++; throw new Error('Network must not be used'); };
  try {
    const response = await POST(new Request('https://laterbox.dev/api/ai/ios', { method: 'POST' }));
    assert.equal(response.status, 401);
    assert.equal(calls, 0);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalFlag === undefined) delete process.env.IOS_GEMINI_FALLBACK_ENABLED;
    else process.env.IOS_GEMINI_FALLBACK_ENABLED = originalFlag;
  }
});
