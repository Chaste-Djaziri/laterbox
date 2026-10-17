export interface IncidentInterval { monitorId: string; start: number; end: number | null }
export interface HistoryRange { from: number; to: number; timeZone: string; unit: 'hour' | 'day' }
const day = 86400000;

export function parseHistoryRange(from: string | null, to: string | null, timeZone: string, now = Date.now()): HistoryRange {
  const start = Date.parse(from || '');
  const requestedEnd = Date.parse(to || '');
  const end = Math.min(requestedEnd, now);
  try { new Intl.DateTimeFormat('en', { timeZone }).format(); } catch { throw new RangeError('Invalid time zone'); }
  if (!Number.isFinite(start) || !Number.isFinite(end) || start >= end || requestedEnd - start > 91 * day || requestedEnd > now + 26 * 3600000) {
    throw new RangeError('Choose a past date range of up to 90 days');
  }
  return { from: start, to: end, timeZone, unit: requestedEnd - start <= 26 * 3600000 ? 'hour' : 'day' };
}

export async function loadIncidentIntervals(token: string, fetcher: typeof fetch = fetch): Promise<IncidentInterval[]> {
  let next: string | null = 'https://incidents.betterstack.com/api/v3/incidents?per_page=50';
  const visited = new Set<string>();
  const result: IncidentInterval[] = [];
  while (next) {
    const url = new URL(next);
    if (url.protocol !== 'https:' || !['incidents.betterstack.com', 'uptime.betterstack.com'].includes(url.hostname) ||
        url.pathname !== '/api/v3/incidents' || url.username || url.password || url.port || visited.has(url.href)) throw new Error('Invalid incident pagination');
    visited.add(url.href);
    const response = await fetcher(url.href, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(10000), redirect: 'error' });
    if (!response.ok) throw new Error('Incident history is unavailable');
    const page = await response.json() as { data?: { attributes: { started_at: string; resolved_at: string | null }; relationships?: { monitor?: { data?: { id?: string } } } }[]; pagination?: { next?: string | null } };
    if (!Array.isArray(page.data)) throw new Error('Invalid incident history');
    for (const incident of page.data) {
      const monitorId = incident.relationships?.monitor?.data?.id;
      if (!monitorId) continue;
      const start = Date.parse(incident.attributes.started_at);
      const end = incident.attributes.resolved_at ? Date.parse(incident.attributes.resolved_at) : null;
      if (!Number.isFinite(start) || (end !== null && (!Number.isFinite(end) || end < start))) throw new Error('Invalid incident dates');
      result.push({ monitorId, start, end });
    }
    next = page.pagination?.next || null;
  }
  return result;
}

function dateParts(value: number, timeZone: string) {
  const parts = new Intl.DateTimeFormat('en-GB', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23' }).formatToParts(value);
  const part = (name: string) => Number(parts.find(p => p.type === name)?.value);
  return { year: part('year'), month: part('month'), date: part('day'), hour: part('hour'), minute: part('minute'), second: part('second') };
}

function nextMidnight(value: number, timeZone: string) {
  const p = dateParts(value, timeZone);
  const desired = Date.UTC(p.year, p.month - 1, p.date + 1);
  let candidate = desired;
  // Resolve a local calendar boundary across daylight-saving offset changes.
  for (let i = 0; i < 3; i++) {
    const actual = dateParts(candidate, timeZone);
    const asUTC = Date.UTC(actual.year, actual.month - 1, actual.date, actual.hour, actual.minute, actual.second);
    candidate += desired - asUTC;
  }
  return candidate;
}

export function uptimeBuckets(range: HistoryRange, createdAt: string | null, incidents: IncidentInterval[]) {
  const created = createdAt ? Date.parse(createdAt) : NaN;
  const result: { start: string; end: string; availability: number | null; downtimeSeconds: number }[] = [];
  for (let start = range.from; start < range.to;) {
    const end = Math.min(range.to, range.unit === 'hour' ? start + 3600000 : nextMidnight(start, range.timeZone));
    if (end <= start) throw new Error('Invalid calendar boundary');
    const observedStart = Math.max(start, created);
    const duration = end - observedStart;
    const intervals = incidents.map(i => [Math.max(observedStart, i.start), Math.min(end, i.end ?? range.to)])
      .filter(([a, b]) => b > a).sort((a, b) => a[0] - b[0]);
    let downtime = 0;
    let previousEnd = observedStart;
    for (const [a, b] of intervals) { downtime += Math.max(0, b - Math.max(a, previousEnd)); previousEnd = Math.max(previousEnd, b); }
    result.push({ start: new Date(start).toISOString(), end: new Date(end).toISOString(),
      availability: Number.isFinite(duration) && duration > 0 ? Math.max(0, 100 * (1 - downtime / duration)) : null,
      downtimeSeconds: downtime / 1000 });
    start = end;
  }
  return result;
}

export async function loadUptimeHistory(token: string, monitors: { id: string; createdAt: string | null }[], range: HistoryRange,
  incidents: IncidentInterval[], fetcher: typeof fetch = fetch) {
  const results: { id: string; availability: number | null; downtimeSeconds: number | null; buckets: ReturnType<typeof uptimeBuckets> }[] = [];
  // Limit simultaneous summary requests to avoid a burst per monitor.
  let index = 0;
  await Promise.all(Array.from({ length: Math.min(4, monitors.length) }, async () => {
    while (index < monitors.length) {
      const monitor = monitors[index++];
      const url = new URL(`https://incidents.betterstack.com/api/v2/monitors/${encodeURIComponent(monitor.id)}/sla`);
      url.searchParams.set('from', new Date(range.from).toISOString());
      url.searchParams.set('to', new Date(range.to).toISOString());
      const response = await fetcher(url.href, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(10000), redirect: 'error' });
      if (!response.ok) throw new Error('Uptime summary is unavailable');
      const data = await response.json() as { data?: { attributes?: { availability?: number | string | null; total_downtime?: number | null } } };
      const attributes = data.data?.attributes;
      const availability = attributes?.availability == null ? NaN : Number(attributes.availability);
      results.push({ id: monitor.id, availability: Number.isFinite(availability) ? Math.max(0, Math.min(100, availability)) : null,
        downtimeSeconds: typeof attributes?.total_downtime === 'number' ? attributes.total_downtime : null,
        buckets: uptimeBuckets(range, monitor.createdAt, incidents.filter(i => i.monitorId === monitor.id)) });
    }
  }));
  return { from: new Date(range.from).toISOString(), to: new Date(range.to).toISOString(), timeZone: range.timeZone,
    unit: range.unit, monitors: results, timestamp: new Date().toISOString() };
}
