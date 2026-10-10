import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';
import { parseSupportRequest } from '@/lib/support/request';

export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  try {
    // Bound the actual body, including requests without Content-Length.
    const reader = request.body?.getReader();
    if (!reader) return NextResponse.json({ error: 'Please complete the form.' }, { status: 400 });
    const chunks: Uint8Array[] = [];
    let length = 0;
    while (true) {
      const chunk = await reader.read();
      if (chunk.done) break;
      length += chunk.value.byteLength;
      if (length > 24000) {
        await reader.cancel();
        return NextResponse.json({ error: 'Your report is too long.' }, { status: 413 });
      }
      chunks.push(chunk.value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
    let body: unknown;
    try { body = JSON.parse(new TextDecoder().decode(bytes)); }
    catch { return NextResponse.json({ error: 'Please complete the form.' }, { status: 400 }); }
    const report = parseSupportRequest(body);
    if (!report) return NextResponse.json({ error: 'Enter a valid email, a subject (3–160 characters), and a message (10–5,000 characters).' }, { status: 400 });
    const user = await getRequestUser(request);
    // Cloudflare supplies this header in production. Store only its hash.
    const sender = user ? `user:${user.id}` : `guest:${request.headers.get('cf-connecting-ip') || 'unknown'}`;
    const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(sender));
    const rateKey = Array.from(new Uint8Array(hash), byte => byte.toString(16).padStart(2, '0')).join('');
    const { data, error } = await getBillingAdminClient().rpc('submit_support_request', {
      sender_id: user?.id ?? null, reply_email: report.email, request_category: report.category,
      request_subject: report.subject, request_message: report.message, device_platform: report.platform,
      client_version: report.appVersion, sender_rate_key: rateKey,
    });
    if (error) {
      if (error.message.includes('support_rate_limit')) return NextResponse.json({ error: 'You have sent several requests. Please try again in an hour.' }, { status: 429 });
      throw error;
    }
    return NextResponse.json({ id: data }, { status: 201, headers: { 'Cache-Control': 'no-store' } });
  } catch {
    return NextResponse.json({ error: 'We could not send your request. Please try again.' }, { status: 503 });
  }
}

export async function GET(request: Request) {
  try {
    const user = await getRequestUser(request);
    const url = new URL(request.url);
    const idsParam = url.searchParams.get('ids');
    const ticketIds = idsParam
      ? idsParam
          .split(',')
          .map(s => s.trim())
          .filter(s => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s))
      : [];

    const admin = getBillingAdminClient();

    if (user) {
      let query = admin
        .from('support_requests')
        .select('id, email, category, subject, message, platform, app_version, status, created_at')
        .order('created_at', { ascending: false });

      if (ticketIds.length > 0) {
        query = query.or(`user_id.eq.${user.id},id.in.(${ticketIds.slice(0, 50).join(',')})`);
      } else {
        query = query.eq('user_id', user.id);
      }

      const { data, error } = await query;
      if (error) throw error;
      return NextResponse.json({ tickets: data || [] }, { headers: { 'Cache-Control': 'no-store' } });
    }

    if (ticketIds.length > 0) {
      const { data, error } = await admin
        .from('support_requests')
        .select('id, email, category, subject, message, platform, app_version, status, created_at')
        .in('id', ticketIds.slice(0, 50))
        .order('created_at', { ascending: false });
      if (error) throw error;
      return NextResponse.json({ tickets: data || [] }, { headers: { 'Cache-Control': 'no-store' } });
    }

    return NextResponse.json({ tickets: [] }, { headers: { 'Cache-Control': 'no-store' } });
  } catch {
    return NextResponse.json({ error: 'Failed to retrieve support requests.' }, { status: 500 });
  }
}
