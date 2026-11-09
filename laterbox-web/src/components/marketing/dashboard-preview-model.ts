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
  snippet?: string;
  senderName?: string;
  timeLabel?: string;
  categoryTab?: 'primary' | 'articles' | 'media' | 'updates';
  hasAttachment?: boolean;
  scheduledLabel?: string;
}

export const DEMO_ITEMS: readonly DemoItem[] = [
  {
    id: 'idea-01',
    title: 'A guide to a calmer digital workspace',
    source: 'linear.app',
    url: 'https://linear.app/method',
    kind: 'article',
    bucket: 'today',
    collection: 'Design',
    starred: true,
    snippet: 'Principles for reducing noise, batching inputs, and maintaining deep focus across engineering teams.',
    senderName: 'Linear Method',
    timeLabel: '9:30 AM',
    categoryTab: 'primary',
    hasAttachment: false,
    scheduledLabel: 'Today, 10:00 AM',
  },
  {
    id: 'idea-02',
    title: 'Design Systems at Scale: 2026 Component Architecture',
    source: 'figma.com',
    url: 'https://figma.com/blog',
    kind: 'article',
    bucket: 'inbox',
    collection: 'Design',
    starred: false,
    snippet: 'How multi-brand design tokens and headless primitives evolve to support cross-platform apps.',
    senderName: 'Figma Design',
    timeLabel: 'Yesterday',
    categoryTab: 'articles',
    hasAttachment: true,
    scheduledLabel: 'Tomorrow',
  },
  {
    id: 'idea-03',
    title: 'Building Local-First Software with React 19 & SQLite',
    source: 'github.com',
    url: 'https://github.com/features',
    kind: 'link',
    bucket: 'inbox',
    collection: 'Ideas',
    starred: false,
    snippet: 'Offline-capable sync patterns, CRDTs, and zero-latency client state architectures in production.',
    senderName: 'GitHub Engineering',
    timeLabel: 'Oct 28',
    categoryTab: 'primary',
    hasAttachment: false,
    scheduledLabel: 'Inbox',
  },
  {
    id: 'idea-04',
    title: 'Next.js Turbopack & Server Components Deep Dive',
    source: 'youtube.com',
    url: 'https://youtube.com/watch?v=demo',
    kind: 'video',
    bucket: 'upcoming',
    collection: 'Learning',
    starred: true,
    snippet: 'Complete technical breakdown of incremental compilation, streaming SSR, and edge bundling.',
    senderName: 'Vercel Talks',
    timeLabel: '10:15 AM',
    categoryTab: 'media',
    hasAttachment: false,
    scheduledLabel: 'Thursday, 2:00 PM',
  },
  {
    id: 'idea-05',
    title: 'The Future of AI Assistants & Native UI Architecture',
    source: 'nytimes.com',
    url: 'https://nytimes.com/tech',
    kind: 'article',
    bucket: 'someday',
    collection: 'Ideas',
    starred: false,
    snippet: 'How personal software is shifting away from monolithic apps toward ambient, agent-driven interfaces.',
    senderName: 'The New York Times',
    timeLabel: 'Oct 24',
    categoryTab: 'articles',
    hasAttachment: false,
    scheduledLabel: 'Someday Vault',
  },
  {
    id: 'idea-06',
    title: 'Q4 Product Roadmap & Architecture Specification.pdf',
    source: 'Dropbox Paper',
    url: 'https://dropbox.com/spec.pdf',
    kind: 'file',
    bucket: 'inbox',
    collection: 'Design',
    starred: false,
    snippet: 'Complete wireframes, API endpoints, schema migration sequence, and milestone timelines.',
    senderName: 'Product Core',
    timeLabel: 'Oct 22',
    categoryTab: 'updates',
    hasAttachment: true,
    scheduledLabel: 'Inbox',
  },
  {
    id: 'idea-07',
    title: 'Synthesizer Jam Session & Ambient Soundscapes',
    source: 'spotify.com',
    url: 'https://spotify.com/playlist',
    kind: 'video',
    bucket: 'today',
    collection: 'Ideas',
    starred: false,
    snippet: '4-hour uninterrupted generative modular synthesizer recording for deep concentration.',
    senderName: 'Spotify Curated',
    timeLabel: '8:00 AM',
    categoryTab: 'media',
    hasAttachment: false,
    scheduledLabel: 'Today, 4:00 PM',
  },
  {
    id: 'idea-08',
    title: 'Podcast: The Local-First Software Movement',
    source: 'changelog.com',
    url: 'https://changelog.com/podcast',
    kind: 'link',
    bucket: 'someday',
    collection: null,
    starred: false,
    snippet: 'Interview with creators on peer-to-peer databases, client encryption, and user data sovereignty.',
    senderName: 'Changelog Media',
    timeLabel: 'Oct 19',
    categoryTab: 'media',
    hasAttachment: false,
    scheduledLabel: 'Someday Vault',
  },
  {
    id: 'idea-09',
    title: 'Quarterly Cloud & Storage Cost Audit',
    source: 'aws.amazon.com',
    url: 'https://aws.amazon.com/billing',
    kind: 'article',
    bucket: 'done',
    collection: 'Learning',
    starred: false,
    snippet: 'Consolidated summary of database queries, edge worker invocations, and asset CDN usage.',
    senderName: 'Cloud Infrastructure',
    timeLabel: 'Oct 15',
    categoryTab: 'updates',
    hasAttachment: true,
    scheduledLabel: 'Completed',
  },
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
    const matchesQuery = !normalized || [item.title, item.source, item.collection ?? '', item.snippet ?? '', item.senderName ?? ''].some(text => text.toLocaleLowerCase().includes(normalized));
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
      snippet: 'User captured bookmark saved in sandbox session.',
      senderName: parsed.hostname,
      timeLabel: 'Just now',
      categoryTab: 'primary',
      hasAttachment: false,
      scheduledLabel: bucket === 'inbox' ? 'Inbox' : bucket === 'today' ? 'Today' : bucket === 'upcoming' ? 'Upcoming' : 'Someday',
    };
  } catch {
    return null;
  }
}
