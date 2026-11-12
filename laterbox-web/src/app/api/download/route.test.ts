// laterbox-web/src/app/api/download/route.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { NextRequest } from 'next/server';
import { GET } from './[filename]/route';

test('Android public APK downloads remain paused', async () => {
  const response = await GET(
    new NextRequest('https://laterbox.dev/api/download/laterbox.apk'),
    { params: Promise.resolve({ filename: 'laterbox.apk' }) },
  );
  assert.equal(response.status, 410);
  assert.match(await response.text(), /coming soon/i);
});

test('Android bundles remain paused', async () => {
  const response = await GET(
    new NextRequest('https://laterbox.dev/api/download/laterbox-android-release.aab'),
    { params: Promise.resolve({ filename: 'laterbox-android-release.aab' }) },
  );
  assert.equal(response.status, 410);
});
