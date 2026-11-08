// laterbox-web/src/components/marketing/dashboard-preview-model.ts
/** In-memory fixture data for the public marketing preview. No account, API, or storage. */
export type DemoBucket = 'inbox' | 'today' | 'upcoming' | 'someday' | 'done';
export type DemoView = 'home' | DemoBucket | 'collections' | 'starred';
export type DemoKind = 'article' | 'video' | 'file' | 'link';
export type DemoCollection = 'Design' | 'Learning' | 'Ideas' | null;

export interface DemoItem {
  id: string;
  title: string;
  source: string;
  url: string;
  kind: DemoKind;
  bucket: DemoBucket;
  collection: DemoCollection;
  starred: boolean;
}

export const DEMO_ITEMS: readonly DemoItem[] = [
  { id: 'idea-01', title: 'A guide to a calmer digital workspace', source: 'designnotes.example', url: 'https://example.com/workspace', kind: 'article', bucket: 'today', collection: 'Design', starred: true },
  { id: 'idea-02', title: 'The little details that make a product great', source: 'video.example', url: 'https://example.com/design-video', kind: 'video', bucket: 'inbox', collection: 'Design', starred: false },
  { id: 'idea-03', title: 'Inspiration for my next project', source: 'inspiration.example', url: 'https://example.com/ideas', kind: 'link', bucket: 'inbox', collection: 'Ideas', starred: false },
  { id: 'idea-04', title: 'Notes on learning something new', source: 'journal.example', url: 'https://example.com/notes', kind: 'article', bucket: 'upcoming', collection: 'Learning', starred: true },
  { id: 'idea-05', title: 'An interesting podcast to revisit', source: 'listen.example', url: 'https://example.com/podcast', kind: 'link', bucket: 'someday', collection: 'Ideas', starred: false },
  { id: 'idea-06', title: 'Creative reference board.pdf', source: 'PDF document', url: 'https://example.com/board.pdf', kind: 'file', bucket: 'inbox', collection: 'Design', starred: false },
  { id: 'idea-07', title: 'Ideas for a weekend side project', source: 'projects.example', url: 'https://example.com/weekend', kind: 'article', bucket: 'today', collection: 'Ideas', starred: false },
  { id: 'idea-08', title: 'A playlist worth keeping', source: 'music.example', url: 'https://example.com/music', kind: 'video', bucket: 'someday', collection: null, starred: false },
  { id: 'idea-09', title: 'The article I finally came back to', source: 'reading.example', url: 'https://example.com/finished', kind: 'article', bucket: 'done', collection: 'Learning', starred: false },
];

export type DemoAction =
  | { type: 'star'; id: string }
  | { type: 'complete'; id: string }
  | { type: 'move'; id: string; bucket: Exclude<DemoBucket, 'done'> }
  | { type: 'delete'; id: string };

export function changeDemoItem(items: readonly DemoItem[], action: DemoAction): DemoItem[] {
  if (action.type === 'delete') return items.filter(item => item.id !== action.id);
  return items.map(item => {
    if (item.id !== action.id) return item;
    switch (action.type) {
      case 'star': return { ...item, starred: !item.starred };
      case 'complete': return { ...item, bucket: item.bucket === 'done' ? 'inbox' as const : 'done' as const };
      case 'move': return { ...item, bucket: action.bucket };
    }
  });
}

export function demoCount(items: readonly DemoItem[], view: DemoView): number {
  return demoVisibleItems(items, view).length;
}

export function demoVisibleItems(items: readonly DemoItem[], view: DemoView, query = '', collection: DemoCollection | 'all' = 'all'): DemoItem[] {
  const normalized = query.trim().toLocaleLowerCase();
  return items.filter(item => {
    const matchesView = view === 'home' ? item.bucket !== 'done'
      : view === 'collections' ? item.collection !== null && item.bucket !== 'done'
      : view === 'starred' ? item.starred && item.bucket !== 'done'
      : item.bucket === view;
    const matchesCollection = collection === 'all' || item.collection === collection;
    const matchesQuery = !normalized || [item.title, item.source, item.collection ?? ''].some(text => text.toLocaleLowerCase().includes(normalized));
    return matchesView && matchesCollection && matchesQuery;
  });
}

export function makeDemoItem(id: string, url: string, title: string, bucket: Exclude<DemoBucket, 'done'>): DemoItem | null {
  const trimmed = title.trim();
  if (!trimmed || trimmed.length > 150) return null;
  try {
    const parsed = new URL(url.trim());
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return null;
    if (!parsed.hostname.includes('.')) return null;
    return {
      id,
      title: trimmed,
      source: parsed.hostname,
      url: parsed.toString(),
      kind: 'link',
      bucket,
      collection: null,
      starred: false,
    };
  } catch {
    return null;
  }
}
