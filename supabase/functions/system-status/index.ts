import { loadMonitorStatus } from './monitors.ts';
import { loadIncidentIntervals, loadUptimeHistory, parseHistoryRange } from './history.ts';

let cached: Awaited<ReturnType<typeof loadMonitorStatus>> | undefined;
let cachedAt = 0;
let pending: Promise<Awaited<ReturnType<typeof loadMonitorStatus>>> | undefined;
let incidents: { data: Awaited<ReturnType<typeof loadIncidentIntervals>>; at: number } | undefined;
let incidentRequest: ReturnType<typeof loadIncidentIntervals> | undefined;
const historyCache = new Map<string, { data: Awaited<ReturnType<typeof loadUptimeHistory>>; at: number }>();
const historyRequests = new Map<string, ReturnType<typeof loadUptimeHistory>>();
const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'apikey, authorization, content-type', 'Access-Control-Allow-Methods': 'GET, OPTIONS' };

Deno.serve(async request => {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
  if (request.method !== 'GET') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers });
  const token = Deno.env.get('BETTERSTACK_UPTIME_TOKEN');
  if (!token) return new Response(JSON.stringify({ error: 'Service status is temporarily unavailable' }), { status: 503, headers });
  try {
    const query = new URL(request.url).searchParams;
    const range = query.get('history') === '1'
      ? parseHistoryRange(query.get('from'), query.get('to'), query.get('timeZone') || 'UTC') : null;
    if (!cached || Date.now() - cachedAt >= 60000) {
      pending ??= loadMonitorStatus(token);
      try { cached = await pending; cachedAt = Date.now(); }
      finally { pending = undefined; }
    }
    if (range) {
      const key = `${query.get('from')}|${query.get('to')}|${range.timeZone}`;
      let entry = historyCache.get(key);
      if (!entry || Date.now() - entry.at >= 300000) {
        if (!incidents || Date.now() - incidents.at >= 300000) {
          incidentRequest ??= loadIncidentIntervals(token);
          try { incidents = { data: await incidentRequest, at: Date.now() }; }
          finally { incidentRequest = undefined; }
        }
        let loading = historyRequests.get(key);
        if (!loading) {
          loading = loadUptimeHistory(token, cached!.monitors, range, incidents.data);
          historyRequests.set(key, loading);
        }
        try {
          entry = { data: await loading, at: Date.now() };
          if (historyCache.size >= 12) historyCache.delete(historyCache.keys().next().value!);
          historyCache.set(key, entry);
        } finally { historyRequests.delete(key); }
      }
      return new Response(JSON.stringify(entry.data), { headers: { ...headers, 'Cache-Control': 'public, max-age=60' } });
    }
    return new Response(JSON.stringify(cached), { headers: { ...headers, 'Cache-Control': 'public, max-age=30' } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof RangeError ? 'Choose a valid date range of up to 90 days.' : 'We could not refresh service status. Please try again.' }), { status: error instanceof RangeError ? 400 : 503, headers: { ...headers, 'Cache-Control': 'no-store' } });
  }
});
