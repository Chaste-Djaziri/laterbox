import { NextResponse } from 'next/server';
import { getBillingAdminClient, getRequestUser } from '@/lib/billing/server';
import { filterUnseenInboxItems, sendUnseenInboxDigestEmail } from '@/lib/email/resend';
import { renderUnseenDigestHtml, renderUnseenDigestText } from '@/lib/email/unseen-digest-template';
import { UnseenDigestItem } from '@/lib/email/types';

export const dynamic = 'force-dynamic';

const SAMPLE_ITEMS: UnseenDigestItem[] = [
  {
    id: 'demo-1',
    title: 'Designing Fluid Interfaces and Modern Web Interactions',
    url: 'https://developer.apple.com/design/fluid-interfaces',
    type: 'article',
    status: 'inbox',
    seen: false,
    created_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    metadata: {
      domain: 'developer.apple.com',
      site_name: 'Apple Developer',
      description: 'An in-depth exploration of gesture-driven animations, tactile feedback, and natural user interfaces.',
      content_type: 'article',
    },
  },
  {
    id: 'demo-2',
    title: 'Building Liquid Glass & Micro-Interactions in SwiftUI',
    url: 'https://youtube.com/watch?v=sample123',
    type: 'video',
    status: 'inbox',
    seen: false,
    created_at: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
    metadata: {
      domain: 'youtube.com',
      site_name: 'YouTube',
      description: 'Step-by-step walkthrough of creating dynamic blur effects, responsive gesture sheets, and spring physics.',
      content_type: 'video',
    },
  },
  {
    id: 'demo-3',
    title: 'Quarterly Planning and Reading List Notes',
    text_content: 'Review product roadmap priorities, evaluate cloud sync performance improvements, and read offline architecture papers.',
    type: 'note',
    status: 'inbox',
    seen: false,
    created_at: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(),
  },
];

export async function GET(request: Request) {
  try {
    const user = await getRequestUser(request);
    let items: UnseenDigestItem[] = [];

    if (user) {
      const admin = getBillingAdminClient();
      const { data } = await admin
        .from('items')
        .select('id, title, url, text_content, type, status, seen, created_at, return_at, metadata:item_metadata(*), note:item_notes(*)')
        .eq('user_id', user.id)
        .eq('status', 'inbox')
        .or('seen.is.null,seen.eq.false')
        .order('created_at', { ascending: true })
        .limit(20);

      if (data && data.length > 0) {
        items = filterUnseenInboxItems(data as unknown as UnseenDigestItem[], { minAgeDays: 0 });
      }
    }

    if (items.length === 0) {
      items = SAMPLE_ITEMS;
    }

    const html = renderUnseenDigestHtml({
      to: user?.email || 'demo@laterbox.dev',
      recipientName: user?.user_metadata?.full_name || (user?.email ? user.email.split('@')[0] : 'there'),
      items,
      totalUnseenCount: items.length,
    });

    return new Response(html, {
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-store',
      },
    });
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Failed to generate preview' },
      { status: 500 }
    );
  }
}

interface DigestRequestBody {
  to?: string;
  items?: UnseenDigestItem[];
  minAgeDays?: number;
  preview?: boolean;
  recipientName?: string;
  totalUnseenCount?: number;
  subject?: string;
  appBaseUrl?: string;
  customScheme?: string;
  apiKey?: string;
}

export async function POST(request: Request) {
  try {
    const body = ((await request.json().catch(() => ({}))) || {}) as DigestRequestBody;
    const user = await getRequestUser(request);

    const to = body.to || user?.email;
    if (!to) {
      return NextResponse.json(
        { error: 'Recipient email address ("to") is required.' },
        { status: 400 }
      );
    }

    let items: UnseenDigestItem[] = body.items || [];

    if (items.length === 0 && user) {
      const admin = getBillingAdminClient();
      const { data, error } = await admin
        .from('items')
        .select('id, title, url, text_content, type, status, seen, created_at, return_at, metadata:item_metadata(*), note:item_notes(*)')
        .eq('user_id', user.id)
        .eq('status', 'inbox')
        .or('seen.is.null,seen.eq.false')
        .order('created_at', { ascending: true })
        .limit(50);

      if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 });
      }

      const minDays = typeof body.minAgeDays === 'number' ? body.minAgeDays : 3;
      items = filterUnseenInboxItems((data || []) as unknown as UnseenDigestItem[], { minAgeDays: minDays });
    }

    if (items.length === 0 && body.preview) {
      items = SAMPLE_ITEMS;
    }

    if (items.length === 0) {
      return NextResponse.json(
        { error: 'No unseen items found waiting in the inbox.' },
        { status: 404 }
      );
    }

    const options = {
      to,
      recipientName: body.recipientName || user?.user_metadata?.full_name || (to.includes('@') ? to.split('@')[0] : undefined),
      items,
      totalUnseenCount: body.totalUnseenCount || items.length,
      subject: body.subject,
      appBaseUrl: body.appBaseUrl,
      customScheme: body.customScheme,
    };

    if (body.preview) {
      return NextResponse.json({
        preview: true,
        subject: options.subject || `${items.length} unseen items waiting in your LaterBox inbox`,
        html: renderUnseenDigestHtml(options),
        text: renderUnseenDigestText(options),
      });
    }

    const result = await sendUnseenInboxDigestEmail({
      ...options,
      apiKey: body.apiKey,
    });

    if (!result.success) {
      return NextResponse.json({ error: result.error }, { status: 502 });
    }

    return NextResponse.json(
      { success: true, id: result.id, itemsSent: items.length },
      { status: 200 }
    );
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'Internal error processing digest request' },
      { status: 500 }
    );
  }
}
