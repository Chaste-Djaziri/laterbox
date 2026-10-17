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

export function resolveItemPreviewImageUrl(item: LaterBoxItem): string | null {
  // 1. Check metadata preview_image_url
  let raw = item.metadata?.preview_image_url?.trim();
  if (raw) {
    if (raw.startsWith('//')) raw = `https:${raw}`;
    if (raw.includes('youtube.com') || raw.includes('ytimg.com')) {
      raw = raw.replace('/hqdefault.jpg', '/mqdefault.jpg')
               .replace('/sddefault.jpg', '/mqdefault.jpg');
    }
    if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('data:')) {
      return raw;
    }
  }

  // 2. YouTube derivation if url or text_content contains YouTube
  const youtubeUrl = item.url || (item.text_content?.includes('youtube.com') || item.text_content?.includes('youtu.be') ? item.text_content : undefined);
  if (youtubeUrl) {
    try {
      const match = youtubeUrl.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?.*v=|shorts\/|embed\/|live\/))([A-Za-z0-9_-]+)/);
      if (match && match[1]) {
        return `https://img.youtube.com/vi/${match[1]}/mqdefault.jpg`;
      }
    } catch {
      // ignore
    }
  }

  // 3. Stored attachment preview. Prefer this over external page images because
  // social CDN URLs can expire or reject browser requests after capture.
  if (item.attachments && item.attachments.length > 0) {
    const imgAtt = item.attachments.find(
      (a) =>
        (a.mime_type && a.mime_type.startsWith('image/')) ||
        (a.file_extension && ['png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'].includes(a.file_extension.toLowerCase().replace(/^\./, '')))
    );
    if (imgAtt) {
      if (imgAtt.thumbnail_object_key) return imgAtt.thumbnail_object_key;
      if (imgAtt.preview_object_key) return imgAtt.preview_object_key;
      if (imgAtt.local_path && (imgAtt.local_path.startsWith('http') || imgAtt.local_path.startsWith('data:'))) {
        return imgAtt.local_path;
      }
    }
  }

  // 4. Direct image URL if no stored attachment preview is available.
  if (item.type === 'image' || (item.url && /\.(?:png|jpg|jpeg|webp|gif|svg)(?:\?.*)?$/i.test(item.url))) {
    if (item.url && (item.url.startsWith('http://') || item.url.startsWith('https://'))) {
      return item.url;
    }
  }

  return null;
}

