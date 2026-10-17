interface RawMonitor {
  id: string;
  attributes?: { pronounceable_name?: string; status?: string; paused?: boolean; last_checked_at?: string; check_frequency?: number };
}

const labels: Record<string, string> = {
  up: 'Operational', down: 'Service disruption', validating: 'Recovering', degraded: 'Degraded performance',
  maintenance: 'Maintenance', paused: 'Paused', pending: 'Awaiting first check', unknown: 'Status unavailable',
};

export async function loadMonitorStatus(token: string, fetcher: typeof fetch = fetch) {
  const raw: RawMonitor[] = [];
  let next: string | null = 'https://incidents.betterstack.com/api/v2/monitors';
  const visited = new Set<string>();
  while (next) {
    const url = new URL(next);
    if (url.protocol !== 'https:' || !['incidents.betterstack.com', 'uptime.betterstack.com'].includes(url.hostname) ||
        url.pathname !== '/api/v2/monitors' || url.username || url.password || url.port || visited.has(url.href)) {
      throw new Error('Invalid monitor pagination');
    }
    visited.add(url.href);
    const response = await fetcher(url.href, {
      headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(10000), redirect: 'error',
    });
    if (!response.ok) throw new Error(`Monitor service returned HTTP ${response.status}`);
    const page = await response.json() as { data?: RawMonitor[]; pagination?: { next?: string | null } };
    if (!Array.isArray(page.data)) throw new Error('Monitor service returned invalid data');
    raw.push(...page.data);
    next = page.pagination?.next || null;
  }
  // Explicitly select display fields: monitor URLs and request headers may contain secrets.
  const monitors = [...new Map(raw.map((monitor, index) => {
    const attributes = monitor.attributes || {};
    const status = attributes.paused ? 'paused' : (attributes.status && labels[attributes.status] ? attributes.status : 'unknown');
    return [monitor.id, { id: monitor.id, name: attributes.pronounceable_name?.trim() || `Monitor ${index + 1}`,
      status, label: labels[status], lastCheckedAt: attributes.last_checked_at && Number.isFinite(Date.parse(attributes.last_checked_at)) ? attributes.last_checked_at : null,
      checkFrequency: typeof attributes.check_frequency === 'number' && attributes.check_frequency > 0 ? attributes.check_frequency : null }];
  })).values()];
  let status = 'unknown';
  let label = monitors.length ? 'Monitoring paused or awaiting checks' : 'No monitors configured';
  const active = monitors.filter(monitor => monitor.status !== 'paused');
  if (active.some(monitor => monitor.status === 'down')) { status = 'outage'; label = 'Some services are unavailable'; }
  else if (active.some(monitor => ['validating', 'degraded'].includes(monitor.status))) { status = 'degraded'; label = 'Some services are recovering'; }
  else if (active.some(monitor => monitor.status === 'maintenance')) { status = 'maintenance'; label = 'Scheduled maintenance'; }
  else if (active.length && active.every(monitor => monitor.status === 'up')) { status = 'operational'; label = 'All systems operational'; }
  return { status, label, monitors, totalMonitors: monitors.length, timestamp: new Date().toISOString(), statusPageUrl: 'https://status.laterbox.dev' };
}
