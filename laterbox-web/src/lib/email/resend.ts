import { LaterBoxItem } from '../supabase/types';
import { SendDigestEmailResult, UnseenDigestEmailOptions, UnseenDigestItem } from './types';
import { renderUnseenDigestHtml, renderUnseenDigestText } from './unseen-digest-template';

export interface FilterUnseenOptions {
  minAgeDays?: number;
  maxItems?: number;
  now?: Date;
}

export function filterUnseenInboxItems(
  items: (LaterBoxItem | UnseenDigestItem)[],
  options: FilterUnseenOptions = {}
): UnseenDigestItem[] {
  const minAgeDays = options.minAgeDays ?? 3;
  const maxItems = options.maxItems ?? 10;
  const now = options.now ?? new Date();
  const minAgeMs = minAgeDays * 24 * 60 * 60 * 1000;

  const filtered = items.filter((item) => {
    // Must be in inbox
    if (item.status !== 'inbox') return false;
    // Must not be seen
    if (item.seen === true) return false;

    // Check age
    try {
      const createdTime = new Date(item.created_at).getTime();
      const ageMs = now.getTime() - createdTime;
      return ageMs >= minAgeMs;
    } catch {
      return false;
    }
  });

  // Sort by oldest first so longest-waiting items appear prominently
  filtered.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

  return filtered.slice(0, maxItems) as UnseenDigestItem[];
}

export interface SendDigestOptions extends UnseenDigestEmailOptions {
  apiKey?: string;
  fetchFn?: typeof fetch;
}

export async function sendUnseenInboxDigestEmail(
  options: SendDigestOptions
): Promise<SendDigestEmailResult> {
  const apiKey = options.apiKey || process.env.RESEND_API_KEY;
  if (!apiKey) {
    return {
      success: false,
      error: 'RESEND_API_KEY is not set. Please set the environment variable or pass apiKey in options.',
    };
  }

  if (!options.to || !options.to.includes('@')) {
    return {
      success: false,
      error: 'Invalid recipient email address.',
    };
  }

  if (!options.items || options.items.length === 0) {
    return {
      success: false,
      error: 'No unseen items provided to include in the email digest.',
    };
  }

  const from = options.from || process.env.RESEND_FROM_EMAIL || 'LaterBox <notifications@laterbox.dev>';
  const count = options.items.length;
  const totalCount = options.totalUnseenCount || count;
  const subject = options.subject || `${totalCount} unseen ${totalCount === 1 ? 'item is' : 'items are'} waiting in your LaterBox inbox`;

  const html = renderUnseenDigestHtml(options);
  const text = renderUnseenDigestText(options);

  const payload: Record<string, unknown> = {
    from,
    to: [options.to],
    subject,
    html,
    text,
    headers: {
      'X-Entity-Ref-ID': `unseen-digest-${Date.now()}`,
    },
    tags: [
      { name: 'category', value: 'unseen_digest' },
      { name: 'item_count', value: String(count) },
    ],
  };

  if (options.replyTo) {
    payload.reply_to = options.replyTo;
  }

  const customFetch = options.fetchFn || fetch;

  try {
    const res = await customFetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = (await res.json().catch(() => ({}))) as Record<string, any>;

    if (!res.ok) {
      const errMsg = (data && (data.message || data.error)) || `Resend API returned status ${res.status}`;
      return {
        success: false,
        error: typeof errMsg === 'string' ? errMsg : JSON.stringify(errMsg),
      };
    }

    return {
      success: true,
      id: (data as { id?: string }).id,
    };
  } catch (err) {
    return {
      success: false,
      error: err instanceof Error ? err.message : 'Network error sending email via Resend',
    };
  }
}
