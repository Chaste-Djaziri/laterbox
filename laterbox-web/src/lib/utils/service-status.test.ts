import test from 'node:test';
import assert from 'node:assert/strict';
import { loadMonitorStatus } from '../../../../supabase/functions/system-status/monitors';

test('all monitor pages are loaded and only public display fields are returned', async () => {
  const calls: string[] = [];
  const fetcher: typeof fetch = async (input, init) => {
    calls.push(String(input));
    assert.equal((init?.headers as Record<string, string>).Authorization, 'Bearer private-test-token');
    return Response.json(calls.length === 1 ? {
      data: [{ id: '1', attributes: { pronounceable_name: 'Cloud sync', status: 'up',
        url: 'https://internal.invalid?secret=private', request_headers: [{ value: 'credential' }],
        check_frequency: 180, last_checked_at: '2026-10-17T20:00:00Z' } }],
      pagination: { next: 'https://incidents.betterstack.com/api/v2/monitors?page=2' },
    } : { data: [{ id: '2', attributes: { pronounceable_name: 'Storage', status: 'paused' } }], pagination: { next: null } });
  };
  const result = await loadMonitorStatus('private-test-token', fetcher);
  assert.equal(calls.length, 2);
  assert.equal(result.monitors.length, 2);
  assert.equal(result.status, 'operational');
  assert.equal(result.monitors[1].status, 'paused');
  assert.equal(result.monitors[0].checkFrequency, 180);
  assert.doesNotMatch(JSON.stringify(result), /private|credential|request_headers|internal/);
});

test('outages, recovery, maintenance and pending checks are represented honestly', async () => {
  for (const [status, expected] of [['down', 'outage'], ['validating', 'degraded'],
    ['maintenance', 'maintenance'], ['pending', 'unknown'], ['paused', 'unknown']]) {
    const result = await loadMonitorStatus('test', async () => Response.json({ data: [{ id: '1', attributes: { status } }] }));
    assert.equal(result.status, expected);
  }
  const empty = await loadMonitorStatus('test', async () => Response.json({ data: [] }));
  assert.equal(empty.status, 'unknown');
});

test('monitor API failures never produce a healthy fallback', async () => {
  await assert.rejects(loadMonitorStatus('test', async () => new Response('Unavailable', { status: 503 })), /HTTP 503/);
  await assert.rejects(loadMonitorStatus('test', async () => Response.json({ error: 'Invalid response' })), /invalid data/);
});

test('pagination cannot send the server token to an unrelated host or loop forever', async () => {
  for (const next of ['https://example.invalid/api/v2/monitors', 'https://incidents.betterstack.com/api/v2/monitors']) {
    let calls = 0;
    await assert.rejects(loadMonitorStatus('test', async () => {
      calls++;
      return Response.json({ data: [], pagination: { next } });
    }), /Invalid monitor pagination/);
    assert.equal(calls, 1);
  }
});
