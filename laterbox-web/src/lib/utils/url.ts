export function normalizeUrl(raw: string): string {
  const trimmed = raw.trim();
  try {
    const url = new URL(trimmed);
    if (!url.protocol.startsWith('http')) return trimmed;
    url.hostname = url.hostname.toLowerCase();
    url.protocol = url.protocol.toLowerCase();
    return url.toString();
  } catch {
    return trimmed;
  }
}

export function extractDomain(raw?: string | null): string | null {
  if (!raw) return null;
  try {
    const trimmed = raw.trim();
    const url = new URL(trimmed.startsWith('http') ? trimmed : `https://${trimmed}`);
    const host = url.hostname.toLowerCase();
    return host.startsWith('www.') ? host.slice(4) : host;
  } catch {
    return null;
  }
}

export function isUrl(raw: string): boolean {
  try {
    const trimmed = raw.trim();
    const url = new URL(trimmed);
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch {
    return false;
  }
}

export function buildTextFragmentUrl(
  url: string,
  text?: string | null,
  before?: string | null,
  after?: string | null
): string {
  if (!text || text.trim().length === 0) return url;
  const baseUrl = url.split('#')[0];
  const parts: string[] = [];
  if (before && before.trim().length > 0) {
    parts.push(`${encodeURIComponent(before.trim())}-,`);
  }
  parts.push(encodeURIComponent(text.trim()));
  if (after && after.trim().length > 0) {
    parts.push(`,-${encodeURIComponent(after.trim())}`);
  }
  return `${baseUrl}#:~:text=${parts.join('')}`;
}

export function formatTimeAgo(dateString: string): string {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) return 'just now';
    const diffInMinutes = Math.floor(diffInSeconds / 60);
    if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
    const diffInHours = Math.floor(diffInMinutes / 60);
    if (diffInHours < 24) return `${diffInHours}h ago`;
    const diffInDays = Math.floor(diffInHours / 24);
    if (diffInDays < 30) return `${diffInDays}d ago`;
    const diffInMonths = Math.floor(diffInDays / 30);
    if (diffInMonths < 12) return `${diffInMonths}mo ago`;
    const diffInYears = Math.floor(diffInDays / 365);
    return `${diffInYears}y ago`;
  } catch {
    return 'recently';
  }
}

export function formatBytes(bytes: number, decimals = 1): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
}
