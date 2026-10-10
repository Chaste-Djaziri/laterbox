import type { LaterBoxItem } from '../supabase/types';
export const LOCAL_ORIGIN = 'http://localhost:8080';
export const LOCAL_KEY = 'laterbox_local_items_guest';
type LocalCapture = {
  captureId: string; kind?: 'page' | 'link' | 'highlight' | 'social'; url?: string;
  canonicalUrl?: string; text?: string; markdown?: string; title?: string;
  description?: string; author?: string; publishedAt?: string; truncated?: boolean;
  previewImageUrl?: string; faviconUrl?: string; siteName?: string;
  selector?: { exact?: string; before?: string; after?: string }; createdAt: string;
};
export function localCaptureItem(raw: unknown): LaterBoxItem {
  if (!raw || typeof raw !== 'object') throw new Error('Invalid local capture');
  const c = raw as LocalCapture;
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(c.captureId)
    || typeof c.createdAt !== 'string' || !Number.isFinite(Date.parse(c.createdAt))) throw new Error('Invalid capture identity');
  for (const field of ['url','canonicalUrl','text','markdown','title','description','author','publishedAt','previewImageUrl','faviconUrl','siteName'] as const) {
    if (c[field] !== undefined && typeof c[field] !== 'string') throw new Error('Invalid capture field');
  }
  if ((c.url && !/^https?:\/\//i.test(c.url)) || (c.url?.length || 0) > 8192
    || (c.text?.length || 0) > 10000 || new TextEncoder().encode(c.markdown || '').length > 204800) throw new Error('Capture exceeds limits');
  if (c.kind && !['page','link','highlight','social'].includes(c.kind)) throw new Error('Invalid capture kind');
  const domain = c.url ? new URL(c.url).hostname : null;
  return {
    id: c.captureId, user_id: null, url: c.url || null, title: c.title || domain || 'Capture',
    text_content: c.text || null, text_selector: c.selector ? JSON.stringify(c.selector) : null,
    type: 'link', status: 'deferred', return_at: null, favorite: false,
    created_at: c.createdAt, updated_at: c.createdAt, attachments: [],
    content: { item_id: c.captureId, user_id: '', capture_id: c.captureId,
      kind: c.kind || 'page', source_url: c.url, canonical_url: c.canonicalUrl,
      markdown: c.markdown || '', author: c.author, published_at: c.publishedAt, truncated: c.truncated === true },
    metadata: { item_id: c.captureId, user_id: null, domain, site_name: c.siteName || domain,
      title: c.title, description: c.description, preview_image_url: c.previewImageUrl,
      favicon_url: c.faviconUrl, status: 'enriched', attempt_count: 0,
      content_type: c.markdown ? 'article' : 'link', classification_source: 'browserExtension',
      created_at: c.createdAt, updated_at: c.createdAt },
  };
}
function request(action: 'local-import' | 'local-ack', ids?: string[]): Promise<{ captures?: unknown[]; ok?: boolean }> {
  return new Promise((resolve, reject) => {
    const requestId = crypto.randomUUID();
    const timer = setTimeout(() => { cleanup(); if (action === 'local-import') resolve({ captures: [] }); else reject(new Error('Local import acknowledgement interrupted')); }, 4000);
    const cleanup = () => { clearTimeout(timer); window.removeEventListener('message', receive); };
    const receive = (event: MessageEvent) => {
      if (event.source !== window || event.origin !== LOCAL_ORIGIN || event.data?.source !== 'laterbox-extension' || event.data?.requestId !== requestId) return;
      cleanup(); resolve(event.data);
    };
    window.addEventListener('message', receive);
    window.postMessage({ source: 'laterbox-dashboard', requestId, action, ids }, LOCAL_ORIGIN);
  });
}
export async function importLocalCaptures(): Promise<boolean> {
  if (window.location.origin !== LOCAL_ORIGIN) return false;
  // Serialize tabs as well as imports; storage write and acknowledgement share the lock.
  return navigator.locks.request('laterbox-local-library', async () => {
    const response = await request('local-import');
    if (!Array.isArray(response.captures) || !response.captures.length) return false;
    const incoming = response.captures.map(localCaptureItem);
    const current = JSON.parse(localStorage.getItem(LOCAL_KEY) || '[]') as LaterBoxItem[];
    const deleted = JSON.parse(localStorage.getItem('laterbox_local_deleted_items_guest') || '[]') as LaterBoxItem[];
    const known = new Set([...current, ...deleted].map(item => item.id));
    const additions = incoming.filter(item => !known.has(item.id));
    localStorage.setItem(LOCAL_KEY, JSON.stringify([...additions, ...current]));
    // A storage failure throws before acknowledgement; the extension retains the originals.
    await request('local-ack', incoming.map(item => item.id));
    return true;
  });
}
