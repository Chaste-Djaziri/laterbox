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

test('enabled fallback rejects a verified free account before contacting Gemini', async () => {
  const originalFlag = process.env.IOS_GEMINI_FALLBACK_ENABLED;
  const originalServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const originalFetch = globalThis.fetch;
  let geminiCalls = 0;
  process.env.IOS_GEMINI_FALLBACK_ENABLED = 'true';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-key';
  globalThis.fetch = async (input) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
    if (url.includes('/auth/v1/user')) return new Response(JSON.stringify({ id: '00000000-0000-4000-8000-000000000001', aud: 'authenticated', email: 'test@example.com' }), { headers: { 'Content-Type': 'application/json' } });
    if (url.includes('/rest/v1/rpc/has_pro_entitlement')) return new Response('false', { headers: { 'Content-Type': 'application/json' } });
    if (url.includes('generativelanguage.googleapis.com')) geminiCalls++;
    throw new Error('Unexpected network request');
  };
  try {
    const response = await POST(new Request('https://laterbox.dev/api/ai/ios', { method: 'POST', headers: { Authorization: 'Bearer test-token' }, body: JSON.stringify({ prompt: 'hello' }) }));
    assert.equal(response.status, 403);
    assert.equal(geminiCalls, 0);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalFlag === undefined) delete process.env.IOS_GEMINI_FALLBACK_ENABLED; else process.env.IOS_GEMINI_FALLBACK_ENABLED = originalFlag;
    if (originalServiceKey === undefined) delete process.env.SUPABASE_SERVICE_ROLE_KEY; else process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceKey;
  }
});

test('Pro fallback validates structured actions using the configured model with storage disabled', async () => {
  const previous = { flag: process.env.IOS_GEMINI_FALLBACK_ENABLED, key: process.env.GEMINI_API_KEY, model: process.env.IOS_GEMINI_MODEL, service: process.env.SUPABASE_SERVICE_ROLE_KEY };
  const originalFetch = globalThis.fetch;
  const action = { intent: 'chat', reply: 'Hello', content: '', title: '', category: '', contentType: '', tags: [], summary: '', formattedContent: '', query: '', returnDate: '' };
  let geminiCalls = 0;
  process.env.IOS_GEMINI_FALLBACK_ENABLED = 'true'; process.env.GEMINI_API_KEY = 'fake'; process.env.IOS_GEMINI_MODEL = 'test-model'; process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service';
  globalThis.fetch = async (input, init) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
    if (url.includes('/auth/v1/user')) return new Response(JSON.stringify({ id: '00000000-0000-4000-8000-000000000001', aud: 'authenticated' }), { headers: { 'Content-Type': 'application/json' } });
    if (url.includes('/rest/v1/rpc/has_pro_entitlement')) return new Response('true', { headers: { 'Content-Type': 'application/json' } });
    assert.equal(url, 'https://generativelanguage.googleapis.com/v1beta/interactions');
    geminiCalls++;
    const request = JSON.parse(String(init?.body));
    assert.equal(request.model, 'test-model');
    assert.equal(request.store, false);
    assert.ok(request.response_format.schema.required.includes('tags'));
    return new Response(JSON.stringify({ status: 'completed', steps: [{ type: 'model_output', content: [{ type: 'text', text: JSON.stringify(action) }] }] }), { headers: { 'Content-Type': 'application/json' } });
  };
  try {
    const response = await POST(new Request('https://laterbox.dev/api/ai/ios', { method: 'POST', headers: { Authorization: 'Bearer test-token' }, body: JSON.stringify({ prompt: 'Hello' }) }));
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { action });
    assert.equal(geminiCalls, 1);
  } finally {
    globalThis.fetch = originalFetch;
    for (const [key, value] of Object.entries({ IOS_GEMINI_FALLBACK_ENABLED: previous.flag, GEMINI_API_KEY: previous.key, IOS_GEMINI_MODEL: previous.model, SUPABASE_SERVICE_ROLE_KEY: previous.service })) {
      if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
  }
});
