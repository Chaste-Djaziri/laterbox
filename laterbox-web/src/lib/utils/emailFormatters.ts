import { LaterBoxItem } from '@/lib/supabase/types';

export interface InboxSearchFilters {
  hasAttachment: boolean;
  dateRange: 'all' | '24h' | '7d' | '30d';
  starred: boolean;
  format: 'all' | 'articles' | 'media' | 'updates';
}

export const DEFAULT_SEARCH_FILTERS: InboxSearchFilters = {
  hasAttachment: false,
  dateRange: 'all',
  starred: false,
  format: 'all',
};

export function formatEmailDate(dateStr: string): string {
  try {
    const d = new Date(dateStr);
    const now = new Date();
    const isToday =
      d.getDate() === now.getDate() &&
      d.getMonth() === now.getMonth() &&
      d.getFullYear() === now.getFullYear();

    if (isToday) {
      return d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
    }
    const isThisYear = d.getFullYear() === now.getFullYear();
    if (isThisYear) {
      return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
    }
    return d.toLocaleDateString([], { month: 'numeric', day: 'numeric', year: '2-digit' });
  } catch {
    return dateStr;
  }
}

export function getEmailSender(item: LaterBoxItem): string {
  if (item.content?.author?.trim()) return item.content.author.trim();
  if (item.metadata?.site_name?.trim()) return item.metadata.site_name.trim();
  if (item.metadata?.domain?.trim()) return item.metadata.domain.trim();
  if (item.url) {
    try {
      const url = new URL(item.url);
      const host = url.hostname.replace(/^www\./, '');
      const parts = host.split('.');
      if (parts.length >= 2) {
        const main = parts[0];
        return main.charAt(0).toUpperCase() + main.slice(1);
      }
      return host;
    } catch {
      // fallback
    }
  }
  if (item.attachments && item.attachments.length > 0) {
    return 'File Attachment';
  }
  if (item.type === 'note') return 'Note';
  if (item.type === 'task') return 'Task';
  return 'LaterBox';
}

export function itemMatchesQuery(item: LaterBoxItem, query: string): boolean {
  if (!query.trim()) return true;
  const q = query.toLowerCase().trim();
  const title = (item.metadata?.title || item.title || '').toLowerCase();
  const domain = (item.metadata?.domain || item.url || '').toLowerCase();
  const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
  const author = (item.content?.author || item.metadata?.site_name || '').toLowerCase();
  const note = (item.note?.content || '').toLowerCase();

  if (
    title.includes(q) ||
    domain.includes(q) ||
    desc.includes(q) ||
    author.includes(q) ||
    note.includes(q)
  ) {
    return true;
  }

  if (
    item.attachments &&
    item.attachments.some((a) => (a.original_file_name || '').toLowerCase().includes(q))
  ) {
    return true;
  }

  return false;
}

export function itemMatchesFilters(item: LaterBoxItem, filters: InboxSearchFilters): boolean {
  if (filters.hasAttachment && (!item.attachments || item.attachments.length === 0)) {
    return false;
  }

  if (filters.starred && !item.favorite) {
    return false;
  }

  if (filters.dateRange !== 'all') {
    const itemTime = new Date(item.created_at).getTime();
    const now = Date.now();
    const maxAgeMs =
      filters.dateRange === '24h'
        ? 24 * 60 * 60 * 1000
        : filters.dateRange === '7d'
        ? 7 * 24 * 60 * 60 * 1000
        : 30 * 24 * 60 * 60 * 1000;
    if (now - itemTime > maxAgeMs) {
      return false;
    }
  }

  if (filters.format !== 'all') {
    const cType = item.metadata?.content_type || '';
    const url = item.url?.toLowerCase() || '';
    const isMedia =
      cType === 'video' ||
      cType === 'music' ||
      item.type === 'video' ||
      url.includes('youtube.com') ||
      url.includes('vimeo.com') ||
      url.includes('spotify.com');

    const isUpdate =
      item.type === 'note' ||
      item.type === 'task' ||
      (!item.url && Boolean(item.text_content)) ||
      (item.attachments && item.attachments.length > 0);

    if (filters.format === 'media' && !isMedia) return false;
    if (filters.format === 'updates' && !isUpdate) return false;
    if (filters.format === 'articles' && (isMedia || isUpdate)) return false;
  }

  return true;
}
