// laterbox-web/src/lib/utils/itemDetailPresentation.ts
import type { LaterBoxItem } from '@/lib/supabase/types';

const NON_ARTICLE_TYPES = new Set([
  'task', 'note', 'file', 'image', 'video', 'music', 'audio',
  'document', 'pdf', 'design', 'social', 'tweet', 'podcast',
]);

const MEDIA_DOMAINS = [
  'youtube.com', 'youtu.be', 'vimeo.com', 'spotify.com',
  'soundcloud.com', 'tiktok.com', 'instagram.com', 'music.apple.com',
];

export function safeExternalItemUrl(url: string | null | undefined): string | null {
  if (!url) return null;
  try {
    const parsed = new URL(url.trim());
    return (parsed.protocol === 'http:' || parsed.protocol === 'https:') && parsed.hostname
      ? parsed.href
      : null;
  } catch {
    return null;
  }
}

/** Completion is represented by the existing archived lifecycle state. */
export function isTaskComplete(item: LaterBoxItem): boolean {
  return item.type === 'task' && item.status === 'archived' && !item.deleted_at;
}

/**
 * Reader mode is only for real web articles/page snapshots, never for notes,
 * tasks, files, generic URL previews, or arbitrary plain text.
 */
export function shouldShowArticleReader(
  item: LaterBoxItem,
  markdown: string | null | undefined,
  html: string | null | undefined,
): boolean {
  const contentType = (item.metadata?.content_type || '').toLowerCase();
  const itemType = item.type.toLowerCase();

  if (NON_ARTICLE_TYPES.has(itemType) || NON_ARTICLE_TYPES.has(contentType)) return false;
  if (item.attachments?.length) return false;
  const url = safeExternalItemUrl(item.url);
  if (!url) return false;
  const hostname = new URL(url).hostname.toLowerCase();
  if (MEDIA_DOMAINS.some(host => hostname === host || hostname.endsWith('.' + host))) return false;

  const markdownBody = markdown?.trim() || '';
  const htmlBody = html?.trim() || '';
  if (!markdownBody && !htmlBody) return false;

  const classifiedArticle = itemType === 'article' || contentType === 'article';
  // A substantial saved page body also qualifies even when content_type was
  // initially recorded as a generic "link".
  const substantialSnapshot = item.content?.kind === 'page'
    && (markdownBody.length >= 250 || htmlBody.length >= 300);
  return classifiedArticle || substantialSnapshot;
}
