import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { createRequire } from 'node:module';
import { test } from 'node:test';

const require = createRequire(import.meta.url);
const transport = require('./apple-fetch.cjs') as typeof fetch & {
  default: (input: string, init?: RequestInit & { timeout?: number }) => Promise<Response & { buffer(): Promise<Buffer> }>;
  Headers: typeof Headers;
};

test('Apple transport preserves OCSP bytes, API errors, headers, and request timeouts', async () => {
  let contentType: string | undefined;
  const server = createServer((request, response) => {
    contentType = request.headers['content-type'];
    if (request.url === '/slow') {
      setTimeout(() => response.end('late'), 200);
    } else if (request.url === '/binary') {
      response.writeHead(200, { 'content-type': 'application/ocsp-response' });
      response.end(Buffer.from([0, 255, 128, 1]));
    } else {
      response.writeHead(403, { 'content-type': 'application/json' });
      response.end(JSON.stringify({ error: 'denied' }));
    }
  });
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const address = server.address();
    assert.ok(address && typeof address !== 'string');
    const url = `http://127.0.0.1:${address.port}`;
    assert.equal(transport.default, transport);
    const binary = await transport.default(`${url}/binary`, {
      method: 'POST', headers: new transport.Headers({ 'content-type': 'application/ocsp-request' }), body: Buffer.from([1, 2]),
    });
    assert.equal(contentType, 'application/ocsp-request');
    assert.equal(binary.ok, true);
    assert.equal(binary.headers.get('content-type'), 'application/ocsp-response');
    assert.deepEqual(await binary.buffer(), Buffer.from([0, 255, 128, 1]));
    const error = await transport.default(`${url}/json`);
    assert.equal(error.status, 403);
    assert.equal(error.ok, false);
    assert.deepEqual(await error.json(), { error: 'denied' });
    await assert.rejects(transport.default(`${url}/slow`, { timeout: 30 }), { name: 'TimeoutError' });
  } finally {
    server.closeAllConnections();
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});
