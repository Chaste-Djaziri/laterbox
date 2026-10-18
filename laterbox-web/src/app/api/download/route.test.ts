import assert from 'node:assert/strict';
import { test } from 'node:test';
import { NextRequest } from 'next/server';
import { GET } from './[filename]/route';

const request = () => new NextRequest('https://laterbox.dev/api/download/laterbox.apk');
const context = { params: Promise.resolve({ filename: 'laterbox.apk' }) };

test('Android download redirects to the exact APK on the latest release', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => Response.json({ assets: [
    { name: 'laterbox.apk', browser_download_url: 'https://github.com/Chaste-Djaziri/laterbox/releases/download/release-main-123/laterbox.apk' },
  ] });
  try {
    const response = await GET(request(), context);
    assert.equal(response.status, 302);
    assert.match(response.headers.get('location') ?? '', /release-main-123\/laterbox\.apk$/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('Android download never falls back to an older APK', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => Response.json({ assets: [] });
  try {
    const response = await GET(request(), context);
    assert.equal(response.status, 404);
    assert.match(await response.text(), /temporarily unavailable/i);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
