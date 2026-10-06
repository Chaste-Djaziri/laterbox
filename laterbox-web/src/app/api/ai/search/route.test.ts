import test from 'node:test';
import assert from 'node:assert/strict';
import { POST } from './route';

test('rejects unauthenticated search requests before contacting Gemini', async () => {
  const originalFetch = globalThis.fetch;
  let calls = 0;
  globalThis.fetch = async () => {
    calls++;
    throw new Error('Network must not be used');
  };
  try {
    const response = await POST(
      new Request('https://laterbox.dev/api/ai/search', {
        method: 'POST',
        body: JSON.stringify({ query: 'a cideo i saved in october' }),
      })
    );
    assert.equal(response.status, 401);
    assert.equal(calls, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('rejects free/un-entitled account with 403 before contacting Gemini', async () => {
  const originalServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const originalFetch = globalThis.fetch;
  let geminiCalls = 0;
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-key';

  globalThis.fetch = async (input) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
    if (url.includes('/auth/v1/user')) {
      return new Response(
        JSON.stringify({
          id: '00000000-0000-4000-8000-000000000001',
          aud: 'authenticated',
          email: 'free-user@example.com',
        }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    }
    if (url.includes('/rest/v1/rpc/has_pro_entitlement')) {
      return new Response('false', { headers: { 'Content-Type': 'application/json' } });
    }
    if (url.includes('generativelanguage.googleapis.com')) {
      geminiCalls++;
    }
    throw new Error(`Unexpected network call to ${url}`);
  };

  try {
    const response = await POST(
      new Request('https://laterbox.dev/api/ai/search', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-token' },
        body: JSON.stringify({ query: 'a cideo i saved in october' }),
      })
    );
    assert.equal(response.status, 403);
    assert.equal(geminiCalls, 0);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalServiceKey === undefined) delete process.env.SUPABASE_SERVICE_ROLE_KEY;
    else process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceKey;
  }
});

test('allows Pro plan account to query Gemini and returns structured search results', async () => {
  const originalServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const originalApiKey = process.env.GEMINI_API_KEY;
  const originalFetch = globalThis.fetch;
  let geminiCalls = 0;

  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-key';
  process.env.GEMINI_API_KEY = 'test-gemini-key';

  globalThis.fetch = async (input) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
    if (url.includes('/auth/v1/user')) {
      return new Response(
        JSON.stringify({
          id: '00000000-0000-4000-8000-000000000002',
          aud: 'authenticated',
          email: 'pro-user@example.com',
        }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    }
    if (url.includes('/rest/v1/rpc/has_pro_entitlement')) {
      return new Response('true', { headers: { 'Content-Type': 'application/json' } });
    }
    if (url.includes('generativelanguage.googleapis.com')) {
      geminiCalls++;
      return new Response(
        JSON.stringify({
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: JSON.stringify({
                      contentType: 'video',
                      dateRange: { start: '2026-10-01T00:00:00Z', end: '2026-10-31T23:59:59Z', label: 'October 2026' },
                      semanticKeywords: ['recipes'],
                      rankedItemIds: ['item-1'],
                      explanations: { 'item-1': 'Matches video format and October save date.' },
                      summary: 'Found 1 video saved in October 2026.',
                    }),
                  },
                ],
              },
            },
          ],
        }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    }
    throw new Error(`Unexpected network call to ${url}`);
  };

  try {
    const response = await POST(
      new Request('https://laterbox.dev/api/ai/search', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-pro-token' },
        body: JSON.stringify({
          query: 'a cideo i saved in october about recipes',
          items: [{ id: 'item-1', title: 'Pasta Recipe', type: 'video', created_at: '2026-10-04T12:00:00Z' }],
        }),
      })
    );
    assert.equal(response.status, 200);
    assert.equal(geminiCalls, 1);
    const data = (await response.json()) as any;
    assert.equal(data.success, true);
    assert.equal(data.isAi, true);
    assert.equal(data.parsedFilters.contentType, 'video');
    assert.deepEqual(data.rankedItemIds, ['item-1']);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalServiceKey === undefined) delete process.env.SUPABASE_SERVICE_ROLE_KEY;
    else process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceKey;
    if (originalApiKey === undefined) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = originalApiKey;
  }
});
