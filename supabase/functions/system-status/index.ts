import { loadMonitorStatus } from './monitors.ts';

let cached: Awaited<ReturnType<typeof loadMonitorStatus>> | undefined;
let cachedAt = 0;
let pending: Promise<Awaited<ReturnType<typeof loadMonitorStatus>>> | undefined;
const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'apikey, authorization, content-type', 'Access-Control-Allow-Methods': 'GET, OPTIONS' };

Deno.serve(async request => {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
  if (request.method !== 'GET') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers });
  const token = Deno.env.get('BETTERSTACK_UPTIME_TOKEN');
  if (!token) return new Response(JSON.stringify({ error: 'Service status is temporarily unavailable' }), { status: 503, headers });
  try {
    if (!cached || Date.now() - cachedAt >= 60000) {
      pending ??= loadMonitorStatus(token);
      try { cached = await pending; cachedAt = Date.now(); }
      finally { pending = undefined; }
    }
    return new Response(JSON.stringify(cached), { headers: { ...headers, 'Cache-Control': 'public, max-age=30' } });
  } catch {
    return new Response(JSON.stringify({ error: 'We could not refresh service status. Please try again.' }), { status: 503, headers: { ...headers, 'Cache-Control': 'no-store' } });
  }
});
