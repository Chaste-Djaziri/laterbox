import test from 'node:test';
import assert from 'node:assert/strict';
import {
  escapeHtml,
  formatDaysWaiting,
  getItemBadge,
  getItemDisplayTitle,
  getItemSnippet,
  renderUnseenDigestHtml,
  renderUnseenDigestText,
} from './unseen-digest-template';
import { filterUnseenInboxItems, sendUnseenInboxDigestEmail } from './resend';
import { UnseenDigestItem } from './types';

test('filterUnseenInboxItems isolates inbox items waiting unseen past threshold', () => {
  const now = new Date('2026-10-15T12:00:00Z');

  const items: UnseenDigestItem[] = [
    {
      id: 'item-1',
      title: 'Old unseen inbox item',
      status: 'inbox',
      seen: false,
      created_at: new Date('2026-10-08T12:00:00Z').toISOString(), // 7 days old
    },
    {
      id: 'item-2',
      title: 'Brand new unseen inbox item',
      status: 'inbox',
      seen: false,
      created_at: new Date('2026-10-14T12:00:00Z').toISOString(), // 1 day old
    },
    {
      id: 'item-3',
      title: 'Already seen inbox item',
      status: 'inbox',
      seen: true,
      created_at: new Date('2026-10-01T12:00:00Z').toISOString(), // 14 days old, but seen
    },
    {
      id: 'item-4',
      title: 'Archived item',
      status: 'archived',
      seen: false,
      created_at: new Date('2026-10-01T12:00:00Z').toISOString(),
    },
    {
      id: 'item-5',
      title: 'Very old unseen inbox item',
      status: 'inbox',
      seen: false,
      created_at: new Date('2026-10-01T12:00:00Z').toISOString(), // 14 days old
    },
  ];

  const result = filterUnseenInboxItems(items, { minAgeDays: 3, now });

  assert.equal(result.length, 2);
  // Oldest first
  assert.equal(result[0].id, 'item-5');
  assert.equal(result[1].id, 'item-1');
});

test('formatDaysWaiting formats durations correctly', () => {
  const base = new Date('2026-10-15T12:00:00Z');
  assert.equal(formatDaysWaiting('2026-10-15T10:00:00Z', base), 'Saved today');
  assert.equal(formatDaysWaiting('2026-10-14T10:00:00Z', base), 'Waiting 1 day');
  assert.equal(formatDaysWaiting('2026-10-11T10:00:00Z', base), 'Waiting 4 days');
  assert.equal(formatDaysWaiting('2026-10-08T10:00:00Z', base), 'Waiting 1 week');
  assert.equal(formatDaysWaiting('2026-10-01T10:00:00Z', base), 'Waiting 2 weeks');
  assert.equal(formatDaysWaiting('2026-09-01T10:00:00Z', base), 'Waiting 1 month');
});

test('getItemBadge and getItemDisplayTitle resolve metadata and types', () => {
  const itemVideo: UnseenDigestItem = {
    id: 'v1',
    url: 'https://www.youtube.com/watch?v=123',
    status: 'inbox',
    created_at: '2026-10-10T00:00:00Z',
    metadata: {
      domain: 'youtube.com',
      title: 'Cool Swift Demo',
      content_type: 'video',
    },
  };
  const badgeVideo = getItemBadge(itemVideo);
  assert.equal(badgeVideo.label, 'VIDEO');
  assert.equal(badgeVideo.domain, 'youtube.com');
  assert.equal(getItemDisplayTitle(itemVideo), 'Cool Swift Demo');

  const itemNote: UnseenDigestItem = {
    id: 'n1',
    text_content: 'Remember to pick up groceries and finish slides',
    status: 'inbox',
    type: 'note',
    created_at: '2026-10-10T00:00:00Z',
  };
  const badgeNote = getItemBadge(itemNote);
  assert.equal(badgeNote.label, 'NOTE');
  assert.equal(getItemDisplayTitle(itemNote), 'Remember to pick up groceries and finish slides');
  assert.equal(getItemSnippet(itemNote), 'Remember to pick up groceries and finish slides');
});

test('renderUnseenDigestHtml includes LaterBox branding, logo, deep links and actions', () => {
  const items: UnseenDigestItem[] = [
    {
      id: 'abc-123',
      title: 'Building Liquid Glass in SwiftUI <script>alert(1)</script>',
      url: 'https://example.com/swift-guide',
      type: 'article',
      status: 'inbox',
      seen: false,
      created_at: new Date(Date.now() - 4 * 86400000).toISOString(),
      metadata: {
        domain: 'example.com',
        description: 'A deep dive into layered blur materials.',
      },
    },
  ];

  const html = renderUnseenDigestHtml({
    to: 'reader@example.com',
    recipientName: 'Alex',
    items,
    appBaseUrl: 'https://app.laterbox.dev',
    customScheme: 'laterbox://',
  });

  // Verify LaterBox brand logo and design
  assert.ok(html.includes('https://laterbox.dev/branding/laterbox-logo.png'), 'Must include brand logo');
  assert.ok(html.includes('#f4f2ea'), 'Must use warm canvas background color');
  assert.ok(html.includes('Hi Alex,'), 'Must greet recipient');
  assert.ok(html.includes('Catch up on what you saved'), 'Must have heading');

  // Verify security escaping
  assert.ok(!html.includes('<script>'), 'Must escape script tags');
  assert.ok(html.includes('&lt;script&gt;'), 'Must entity encode HTML');

  // Verify action links
  assert.ok(html.includes('https://app.laterbox.dev/item/abc-123'), 'Must link to web item');
  assert.ok(html.includes('https://app.laterbox.dev/item/abc-123?action=reschedule'), 'Must link to reschedule');
  assert.ok(html.includes('laterbox://item/abc-123'), 'Must include mobile app item link');
  assert.ok(html.includes('laterbox://inbox'), 'Must include mobile app inbox link');
  assert.ok(html.includes('https://app.laterbox.dev/inbox'), 'Must include web inbox link');
});

test('renderUnseenDigestText renders plain text fallback with item links and rescheduling', () => {
  const items: UnseenDigestItem[] = [
    {
      id: 'item-99',
      title: 'Clean Architecture in Rust',
      url: 'https://rust-lang.org',
      type: 'article',
      status: 'inbox',
      seen: false,
      created_at: new Date(Date.now() - 5 * 86400000).toISOString(),
    },
  ];

  const text = renderUnseenDigestText({
    to: 'user@example.com',
    recipientName: 'Morgan',
    items,
    appBaseUrl: 'https://app.laterbox.dev',
    customScheme: 'laterbox://',
  });

  assert.ok(text.includes('Hi Morgan,'));
  assert.ok(text.includes('Clean Architecture in Rust'));
  assert.ok(text.includes('Review on Web: https://app.laterbox.dev/item/item-99'));
  assert.ok(text.includes('Reschedule:    https://app.laterbox.dev/item/item-99?action=reschedule'));
  assert.ok(text.includes('Open in App:   laterbox://item/item-99'));
  assert.ok(text.includes('laterbox://inbox'));
});

test('sendUnseenInboxDigestEmail validates parameters and dispatches to Resend API', async () => {
  // Test missing api key
  const noKeyResult = await sendUnseenInboxDigestEmail({
    to: 'test@example.com',
    items: [{ id: '1', status: 'inbox', created_at: new Date().toISOString() }],
    apiKey: '',
  });
  assert.equal(noKeyResult.success, false);
  assert.ok(noKeyResult.error?.includes('RESEND_API_KEY'));

  // Test invalid email
  const invalidEmailResult = await sendUnseenInboxDigestEmail({
    to: 'invalid-email',
    items: [{ id: '1', status: 'inbox', created_at: new Date().toISOString() }],
    apiKey: 're_test_123',
  });
  assert.equal(invalidEmailResult.success, false);
  assert.ok(invalidEmailResult.error?.includes('Invalid recipient'));

  // Test empty items
  const noItemsResult = await sendUnseenInboxDigestEmail({
    to: 'valid@example.com',
    items: [],
    apiKey: 're_test_123',
  });
  assert.equal(noItemsResult.success, false);
  assert.ok(noItemsResult.error?.includes('No unseen items'));

  // Test successful dispatch with mock fetch
  let capturedUrl = '';
  let capturedHeaders: Record<string, string> = {};
  let capturedBody: any = null;

  const mockFetch = (async (url: string, init?: RequestInit) => {
    capturedUrl = url;
    capturedHeaders = (init?.headers as Record<string, string>) || {};
    capturedBody = JSON.parse(init?.body as string);

    return {
      ok: true,
      status: 200,
      json: async () => ({ id: 'resend_email_msg_12345' }),
    } as Response;
  }) as unknown as typeof fetch;

  const successResult = await sendUnseenInboxDigestEmail({
    to: 'user@laterbox.dev',
    items: [
      {
        id: 'item-success',
        title: 'Awesome Saved Link',
        url: 'https://laterbox.dev',
        status: 'inbox',
        seen: false,
        created_at: new Date(Date.now() - 3 * 86400000).toISOString(),
      },
    ],
    apiKey: 're_valid_key_test',
    fetchFn: mockFetch,
  });

  assert.equal(successResult.success, true);
  assert.equal(successResult.id, 'resend_email_msg_12345');
  assert.equal(capturedUrl, 'https://api.resend.com/emails');
  assert.equal(capturedHeaders['Authorization'], 'Bearer re_valid_key_test');
  assert.deepEqual(capturedBody.to, ['user@laterbox.dev']);
  assert.ok(capturedBody.subject.includes('1 unseen item'));
  assert.ok(capturedBody.html.includes('Awesome Saved Link'));
  assert.ok(capturedBody.text.includes('Awesome Saved Link'));
});
