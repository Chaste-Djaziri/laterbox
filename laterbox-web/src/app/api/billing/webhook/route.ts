import { NextResponse } from 'next/server';
import { processPaddleWebhook } from '@/lib/billing/process-webhook';

export const dynamic = 'force-dynamic';

function parseSignature(header: string) {
  const values = header.split(';').map((part) => part.split('='));
  return {
    timestamp: values.find(([key]) => key === 'ts')?.[1] ?? '',
    signatures: values.filter(([key]) => key === 'h1').map(([, value]) => value),
  };
}

function constantTimeEqual(left: string, right: string) {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

async function sign(secret: string, payload: string) {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const bytes = new Uint8Array(await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload)));
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
}

async function verify(rawBody: string, signatureHeader: string) {
  const secret = process.env.NEXT_PUBLIC_PADDLE_ENV === 'production'
    ? process.env.PADDLE_NOTIFICATION_WEBHOOK_SECRET_PROD ||
      process.env.PADDLE_NOTIFICATION_WEBHOOK_SECRET
    : process.env.PADDLE_NOTIFICATION_WEBHOOK_SECRET;
  if (!secret) throw new Error('Paddle webhook secret is not configured.');
  const { timestamp, signatures } = parseSignature(signatureHeader);
  const timestampSeconds = Number(timestamp);
  if (!timestamp || !Number.isFinite(timestampSeconds) || signatures.length === 0) {
    throw new Error('Malformed Paddle signature.');
  }
  if (Math.abs(Date.now() / 1000 - timestampSeconds) > 300) {
    throw new Error('Expired Paddle signature.');
  }
  const expected = await sign(secret, `${timestamp}:${rawBody}`);
  if (!signatures.some((candidate) => constantTimeEqual(candidate, expected))) {
    throw new Error('Invalid Paddle signature.');
  }
}

export async function POST(request: Request) {
  const rawBody = await request.text();
  const signature = request.headers.get('paddle-signature') ?? '';
  if (!rawBody || !signature) {
    return NextResponse.json({ error: 'Missing signature or body.' }, { status: 400 });
  }

  try {
    await verify(rawBody, signature);
    await processPaddleWebhook(JSON.parse(rawBody));
    return NextResponse.json({ received: true });
  } catch (error) {
    console.error('[billing] Paddle webhook failed', error);
    return NextResponse.json({ error: 'Webhook processing failed.' }, { status: 500 });
  }
}
