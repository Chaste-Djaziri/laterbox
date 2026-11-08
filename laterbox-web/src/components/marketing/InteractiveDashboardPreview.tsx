// laterbox-web/src/components/marketing/InteractiveDashboardPreview.tsx
'use client';

import { useEffect, useId, useMemo, useRef, useState, type FormEvent } from 'react';
import {
  Archive, ArrowRight, Bookmark, CalendarDays, Check, CheckCircle2,
  Clock3, FileText, FolderOpen, Home, Inbox, Link2, Plus, RotateCcw,
  Search, Sparkles, Star, Video, X,
} from 'lucide-react';
import {
  changeDemoItem, DEMO_ITEMS, demoCount, demoVisibleItems, makeDemoItem,
  type DemoBucket, type DemoCollection, type DemoItem, type DemoKind, type DemoView,
} from './dashboard-preview-model';

type PendingBucket = Exclude<DemoBucket, 'done'>;

const navigation: { view: DemoView; label: string; icon: typeof Home }[] = [
  { view: 'home', label: 'Home', icon: Home },
  { view: 'inbox', label: 'Inbox', icon: Inbox },
  { view: 'today', label: 'Today', icon: Clock3 },
  { view: 'upcoming', label: 'Upcoming', icon: CalendarDays },
  { view: 'someday', label: 'Someday', icon: Archive },
  { view: 'collections', label: 'Collections', icon: FolderOpen },
  { view: 'starred', label: 'Starred', icon: Star },
  { view: 'done', label: 'Completed', icon: CheckCircle2 },
];

const bucketOptions: { key: PendingBucket; label: string }[] = [
  { key: 'inbox', label: 'Inbox' },
  { key: 'today', label: 'Today' },
  { key: 'upcoming', label: 'Upcoming' },
  { key: 'someday', label: 'Someday' },
];

const bucketNames: Record<DemoBucket, string> = {
  inbox: 'In your inbox', today: 'Today', upcoming: 'Coming up', someday: 'Someday', done: 'Completed',
};

const bucketLabel: Record<DemoView, string> = {
  home: 'Home', inbox: 'Inbox', today: 'Due today', upcoming: 'Upcoming', someday: 'Someday',
  collections: 'Collections', starred: 'Starred', done: 'Completed',
};

const bucketDescriptions: Record<DemoView, string> = {
  home: 'Everything worth keeping, in one calm place.',
  inbox: 'New things waiting for the right moment.',
  today: 'A little nudge for the things you saved.',
  upcoming: 'Keep an eye on what comes next.',
  someday: 'Good ideas without a deadline.',
  collections: 'The things that belong together.',
  starred: 'The ones you want to keep close.',
  done: 'Look what you came back to.',
};

const kindIcons: Record<DemoKind, typeof FileText> = {
  article: FileText, video: Video, file: FileText, link: Link2,
};

const kindTone: Record<DemoKind, string> = {
  article: 'bg-[#e6edb0]/70 text-[#3b4826]',
  video: 'bg-[#efe8f7] text-[#755991]',
  file: 'bg-[#f6e7e0] text-[#a4684d]',
  link: 'bg-[#e5eef4] text-[#54708c]',
};

function copySeedItems(): DemoItem[] {
  return DEMO_ITEMS.map(item => ({ ...item }));
}

export function InteractiveDashboardPreview({ id, className = '' }: { id?: string; className?: string }) {
  const [items, setItems] = useState<DemoItem[]>(copySeedItems);
  const [view, setView] = useState<DemoView>('home');
  const [query, setQuery] = useState('');
  const [collection, setCollection] = useState<DemoCollection | 'all'>('all');
  const [selectedId, setSelectedId] = useState<string | null>('idea-01');
  const [addOpen, setAddOpen] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newUrl, setNewUrl] = useState('');
  const [newBucket, setNewBucket] = useState<PendingBucket>('inbox');
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const titleId = useId();
  const urlId = useId();
  const searchId = useId();
  const dialogTitleId = useId();
  const nextId = useRef(1);
  const searchInput = useRef<HTMLInputElement>(null);
  const addInput = useRef<HTMLInputElement>(null);
  const addButton = useRef<HTMLButtonElement>(null);
  const dialogRef = useRef<HTMLDivElement>(null);

  const visible = useMemo(() => demoVisibleItems(items, view, query, collection), [items, view, query, collection]);
  const selected = visible.find(item => item.id === selectedId) ?? visible[0] ?? null;
  const incompleteCount = demoCount(items, 'home');
  const todayCount = demoCount(items, 'today');

  useEffect(() => {
    if (!addOpen) return;
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setAddOpen(false);
        addButton.current?.focus();
      }
    };
    addInput.current?.focus();
    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [addOpen]);

  const navigate = (next: DemoView) => {
    setView(next);
    setCollection('all');
    setSelectedId(null);
    setNotice('');
  };

  const mutate = (action: Parameters<typeof changeDemoItem>[1], message: string) => {
    setItems(previous => changeDemoItem(previous, action));
    setNotice(message);
  };

  const reset = () => {
    setItems(copySeedItems());
    setView('home');
    setQuery('');
    setSelectedId('idea-01');
    setCollection('all');
    setAddOpen(false);
    setError('');
    setNotice('Demo reset. Your real LaterBox was never changed.');
  };

  const showAdd = () => {
    setNewTitle('');
    setNewUrl('');
    setNewBucket('inbox');
    setError('');
    setAddOpen(true);
    setNotice('');
  };

  const saveDemo = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const next = makeDemoItem(`visitor-demo-${nextId.current++}`, newUrl, newTitle, newBucket);
    if (!next) {
      setError('Enter a title and a valid http:// or https:// link to try saving.');
      return;
    }
    setItems(previous => [next, ...previous]);
    setView(next.bucket);
    setCollection('all');
    setQuery('');
    setSelectedId(next.id);
    setAddOpen(false);
    setNotice('Saved in this demo only. Reloading will restore the sample library.');
    addButton.current?.focus();
  };

  const renderNavButton = ({ view: target, label, icon: Icon }: (typeof navigation)[number], mobile = false) => (
    <button
      key={target}
      type="button"
      aria-current={view === target ? 'page' : undefined}
      onClick={() => navigate(target)}
      className={`group inline-flex items-center gap-2.5 text-left text-[12px] font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#768b4e] ${
        mobile ? 'shrink-0 rounded-full border px-3.5 py-2.5' : 'w-full rounded-xl px-3 py-2.5'
      } ${
        view === target
          ? 'border-[#d3df9e] bg-[#e6edb0] text-[#29351d]'
          : mobile ? 'border-[#e6e9df] bg-white text-[#6b7566] hover:bg-[#f1f5e7]' : 'border-transparent text-[#72796c] hover:bg-white hover:text-[#29351d]'
      }`}
    >
      <Icon className="h-4 w-4 shrink-0" strokeWidth={view === target ? 2.5 : 1.8} aria-hidden="true" />
      <span>{label}</span>
      {!mobile && target !== 'home' && <span className={`ml-auto rounded-md px-1.5 text-[10px] ${view === target ? 'bg-white/65' : 'text-[#a4aa9e]'}`}>{demoCount(items, target)}</span>}
    </button>
  );

  return (
    <section id={id} aria-label="Interactive LaterBox dashboard sample" className={`relative min-w-0 overflow-hidden rounded-[26px] border border-[#dedfd4] bg-white text-left text-[#24271f] shadow-[0_25px_70px_rgba(24,27,20,0.12)] sm:rounded-[30px] ${className}`}>
      <div className="flex min-h-[44px] items-center justify-between gap-3 border-b border-[#e8e9e1] bg-[#f8f9f5] px-4 py-2.5 sm:px-5">
        <div className="flex shrink-0 gap-1.5" aria-hidden="true">
          <span className="h-2.5 w-2.5 rounded-full bg-[#e5b6a5]" />
          <span className="h-2.5 w-2.5 rounded-full bg-[#eee0a6]" />
          <span className="h-2.5 w-2.5 rounded-full bg-[#b9cea7]" />
        </div>
        <p className="flex items-center gap-2 text-[10px] font-bold text-[#74806c] sm:text-xs">
          <span className="h-1.5 w-1.5 rounded-full bg-[#7f9958]" />
          Interactive sample · No account needed
        </p>
        <button type="button" onClick={reset} className="inline-flex shrink-0 items-center gap-1.5 rounded-lg px-2 py-1.5 text-[11px] font-bold text-[#606c54] transition-colors hover:bg-[#e6edb0] hover:text-[#24311a] focus-visible:outline-2 focus-visible:outline-[#768b4e]" title="Reset all sample changes">
          <RotateCcw className="h-3.5 w-3.5" aria-hidden="true" /> <span className="hidden sm:inline">Reset demo</span>
        </button>
      </div>

      <div className="flex min-h-[620px] flex-col lg:flex-row">
        <aside className="hidden w-[210px] shrink-0 flex-col border-r border-[#ecece4] bg-[#f7f8f3] p-4 lg:flex">
          <div className="flex items-center gap-2 px-2 py-3">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#e6edb0] text-[#303b24]"><Bookmark className="h-5 w-5" /></span>
            <div><p className="text-[15px] font-black tracking-[-0.05em] text-[#20261c]">laterbox<span className="text-[#91a664]">.</span></p><p className="text-[10px] text-[#9a9e93]">Your sample space</p></div>
          </div>
          <button ref={addButton} type="button" onClick={showAdd} className="mt-4 inline-flex min-h-10 items-center justify-center gap-2 rounded-xl bg-[#23271f] px-3 text-xs font-bold text-white transition-colors hover:bg-[#3b452f] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#768b4e]">
            <Plus className="h-4 w-4" /> Quick save
          </button>
          <nav aria-label="Sample dashboard sections" className="mt-6 space-y-1">
            {navigation.map(item => renderNavButton(item))}
          </nav>
          <div className="mt-auto rounded-2xl border border-[#e3e8d6] bg-white px-3.5 py-4">
            <div className="flex items-center gap-2 text-[11px] font-bold text-[#405535]"><Sparkles className="h-3.5 w-3.5" /> Give it a try</div>
            <p className="mt-2 text-[11px] leading-5 text-[#81897a]">Tap items, save a link, or choose when to return. It all stays inside this preview.</p>
          </div>
        </aside>

        <div className="min-w-0 flex-1 bg-white">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#eff0e9] px-4 py-3.5 sm:px-6">
            <label htmlFor={searchId} className="flex min-h-10 min-w-[160px] flex-1 items-center gap-2.5 rounded-xl border border-[#e8eae0] bg-[#f9faf7] px-3 text-[#8c9588] focus-within:border-[#94a46e] focus-within:ring-2 focus-within:ring-[#e6edb0]/40 sm:max-w-[420px]">
              <Search className="h-4 w-4 shrink-0" />
              <input
                ref={searchInput}
                id={searchId}
                type="search"
                value={query}
                onChange={event => setQuery(event.target.value)}
                placeholder="Search your saved things..."
                className="w-full min-w-0 bg-transparent py-2 text-xs font-medium text-[#2b3327] outline-none placeholder:text-[#a4aca1] sm:text-sm"
              />
            </label>
            <div className="flex items-center gap-2">
              <span className="hidden rounded-full bg-[#f3f5ed] px-3 py-1.5 text-[11px] font-semibold text-[#75836c] sm:inline-flex">Sample workspace</span>
              <button type="button" onClick={showAdd} className="inline-flex min-h-10 items-center gap-1.5 rounded-xl bg-[#20271c] px-3.5 text-xs font-bold text-white transition-colors hover:bg-[#36472c] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7f9659] lg:hidden">
                <Plus className="h-4 w-4" /> Save
              </button>
            </div>
          </div>

          <nav aria-label="Preview sections" className="flex gap-2 overflow-x-auto border-b border-[#eceee5] bg-[#fbfcf9] px-4 py-3 [scrollbar-width:thin] lg:hidden">
            {navigation.map(item => renderNavButton(item, true))}
          </nav>

          <div className="px-4 pb-7 pt-6 sm:px-6 lg:px-7 lg:pt-7">
            <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
              <div className="min-w-0">
                <p className="text-[10px] font-extrabold uppercase tracking-[0.17em] text-[#91a270]">YOUR LATERBOX · DEMO</p>
                <h3 className="mt-2 text-2xl font-black tracking-[-0.045em] text-[#212820] sm:text-3xl">{view === 'home' ? 'A good place to come back to.' : bucketLabel[view]}</h3>
                <p className="mt-1.5 text-xs leading-relaxed text-[#949b90] sm:text-sm">{bucketDescriptions[view]}</p>
              </div>
              <div className="inline-flex shrink-0 items-center gap-2 self-start rounded-full bg-[#eff4e4] px-3 py-2 text-[11px] font-bold text-[#62774e]">
                <CheckCircle2 className="h-4 w-4" /> Your attention, on your terms
              </div>
            </div>

            {view === 'home' && (
              <div className="mt-6 grid grid-cols-2 gap-3">
                <button type="button" onClick={() => navigate('today')} className="group flex items-center justify-between gap-3 rounded-2xl border border-[#e8ebdf] bg-[#f8faf4] p-4 text-left transition-all hover:border-[#bdcd95] hover:bg-[#f0f5e3] focus-visible:outline-2 focus-visible:outline-[#748953]">
                  <div><span className="text-[10px] font-bold uppercase tracking-[0.12em] text-[#89977b]">Ready today</span><p className="mt-1.5 text-2xl font-black text-[#28351e]">{todayCount}</p></div>
                  <Clock3 className="h-6 w-6 text-[#879d65] transition-transform group-hover:rotate-12" />
                </button>
                <button type="button" onClick={() => navigate('inbox')} className="group flex items-center justify-between gap-3 rounded-2xl border border-[#e8ebdf] bg-[#f8faf4] p-4 text-left transition-all hover:border-[#bdcd95] hover:bg-[#f0f5e3] focus-visible:outline-2 focus-visible:outline-[#748953]">
                  <div><span className="text-[10px] font-bold uppercase tracking-[0.12em] text-[#89977b]">Waiting for later</span><p className="mt-1.5 text-2xl font-black text-[#28351e]">{incompleteCount}</p></div>
                  <Inbox className="h-6 w-6 text-[#879d65] transition-transform group-hover:-rotate-12" />
                </button>
              </div>
            )}

            <div className="mt-6 grid gap-5 xl:grid-cols-[minmax(0,1fr)_250px]">
              <div className="min-w-0 rounded-[20px] border border-[#eceee6] bg-white">
                <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#eef0e9] px-4 py-4">
                  <div><h4 className="text-sm font-black text-[#313b2e]">{view === 'home' ? 'Saved for later' : bucketLabel[view]}</h4><p className="mt-0.5 text-[11px] text-[#9ba399]">{visible.length} {visible.length === 1 ? 'item' : 'items'} in this view</p></div>
                  {view === 'collections' && (
                    <label className="inline-flex items-center gap-2 text-xs text-[#7c8b71]">
                      <span className="sr-only">Filter sample collection</span>
                      <select aria-label="Filter sample collection" value={collection ?? 'all'} onChange={e => setCollection(e.target.value as DemoCollection | 'all')} className="max-w-36 rounded-lg border border-[#e3e7da] bg-[#fafbf8] p-2 text-[11px] font-bold text-[#4b5845]">
                        <option value="all">All collections</option><option value="Design">Design</option><option value="Learning">Learning</option><option value="Ideas">Ideas</option>
                      </select>
                    </label>
                  )}
                </div>
                <div className="min-h-[200px] p-2 sm:p-3">
                  {visible.length === 0 ? (
                    <div className="flex min-h-44 flex-col items-center justify-center px-4 text-center">
                      <Search className="h-7 w-7 text-[#bac5ae]" />
                      <p className="mt-3 text-sm font-bold text-[#56634f]">Nothing here yet</p>
                      <p className="mt-1 text-xs text-[#97a093]">Try a different section or search. You can always reset the demo.</p>
                    </div>
                  ) : (
                    <ul className="space-y-1.5">
                      {visible.map(item => {
                        const Icon = kindIcons[item.kind];
                        const active = selected?.id === item.id;
                        return <li key={item.id} className={`group rounded-[14px] border transition-all ${active ? 'border-[#cadaab] bg-[#f8faef]' : 'border-transparent hover:border-[#e5eadf] hover:bg-[#fafbf7]'}`}>
                          <div className="flex items-center gap-2.5 p-2.5 sm:gap-3 sm:p-3">
                            <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${kindTone[item.kind]}`}><Icon className="h-[18px] w-[18px]" aria-hidden="true" /></div>
                            <button type="button" onClick={() => { setSelectedId(item.id); setNotice(''); }} aria-pressed={active} className="min-w-0 flex-1 text-left focus-visible:rounded-md focus-visible:outline-2 focus-visible:outline-[#748953]">
                              <span className="block truncate text-[12px] font-bold text-[#2d352a] sm:text-[13px]">{item.title}</span>
                              <span className="mt-1 flex items-center gap-1.5 text-[10px] text-[#9ba39a]"><span className="max-w-[126px] truncate">{item.source}</span><span>·</span><span>{item.bucket === 'inbox' ? 'Unscheduled' : bucketNames[item.bucket]}</span></span>
                            </button>
                            <div className="flex shrink-0 items-center gap-0.5">
                              <button type="button" title={item.starred ? 'Unstar sample item' : 'Star sample item'} aria-label={item.starred ? `Unstar ${item.title}` : `Star ${item.title}`} aria-pressed={item.starred} onClick={() => mutate({ type: 'star', id: item.id }, item.starred ? 'Removed from starred.' : 'Added to starred.')} className="rounded-lg p-2 text-[#a0a89a] hover:bg-[#e6edb0] focus-visible:outline-2 focus-visible:outline-[#748953]">
                                <Star className={`h-4 w-4 ${item.starred ? 'fill-[#e5c15c] text-[#a68c35]' : ''}`} />
                              </button>
                              <button type="button" title={item.bucket === 'done' ? 'Restore sample item' : 'Mark sample item complete'} aria-label={item.bucket === 'done' ? `Restore ${item.title}` : `Complete ${item.title}`} onClick={() => mutate({ type: 'complete', id: item.id }, item.bucket === 'done' ? 'Returned to your sample inbox.' : 'Completed! Nice work.')} className="rounded-lg p-2 text-[#a0a89a] hover:bg-[#e6edb0] hover:text-[#566e36] focus-visible:outline-2 focus-visible:outline-[#748953]">
                                {item.bucket === 'done' ? <RotateCcw className="h-4 w-4" /> : <Check className="h-4 w-4" />}
                              </button>
                            </div>
                          </div>
                        </li>;
                      })}
                    </ul>
                  )}
                </div>
              </div>

              <aside className="grid gap-3 sm:grid-cols-2 xl:grid-cols-1" aria-label="Sample item tools">
                <div className="rounded-[20px] border border-[#e5e9dd] bg-[#f8faf5] p-4">
                  <p className="flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.13em] text-[#81926d]"><Sparkles className="h-3.5 w-3.5" /> Quick drop</p>
                  <p className="mt-3 text-sm font-bold text-[#2f3b2a]">Something caught your eye?</p>
                  <p className="mt-1.5 text-xs leading-5 text-[#8b9687]">Try saving a sample link. It stays right here, not in your actual account.</p>
                  <button type="button" onClick={showAdd} className="mt-4 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[#e6edb0] px-4 py-2.5 text-xs font-bold text-[#2d3827] hover:bg-[#dce8a0] focus-visible:outline-2 focus-visible:outline-[#748953]"><Plus className="h-4 w-4" /> Save a demo link</button>
                </div>
                <div className="rounded-[20px] border border-[#e9ebe2] bg-white p-4">
                  <p className="text-[11px] font-black uppercase tracking-[0.13em] text-[#899484]">Item details</p>
                  {selected ? (
                    <>
                      <p className="mt-3 line-clamp-2 text-[13px] font-black leading-5 text-[#303a2b]">{selected.title}</p>
                      <p className="mt-1.5 truncate text-[11px] text-[#96a092]">{selected.source}</p>
                      {selected.bucket === 'done' ? (
                        <button type="button" onClick={() => mutate({ type: 'complete', id: selected.id }, 'Item restored to inbox.')} className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl border border-[#e1e6d8] p-2.5 text-xs font-bold text-[#596e43] hover:bg-[#f1f6e8]"><RotateCcw className="h-3.5 w-3.5" /> Restore to inbox</button>
                      ) : (
                        <label className="mt-4 block text-xs font-bold text-[#728068]">
                          Bring it back
                          <select value={selected.bucket} aria-label={`Reschedule ${selected.title}`} onChange={event => mutate({ type: 'move', id: selected.id, bucket: event.target.value as PendingBucket }, 'Scheduled in your sample library.')} className="mt-2 block w-full rounded-xl border border-[#dfe6d8] bg-[#fafbf8] px-3 py-2.5 text-xs font-semibold text-[#2f3a29] focus-visible:outline-2 focus-visible:outline-[#748953]">
                            {bucketOptions.map(option => <option key={option.key} value={option.key}>{option.label}</option>)}
                          </select>
                        </label>
                      )}
                    </>
                  ) : (
                    <p className="mt-3 text-xs leading-5 text-[#99a196]">Select an item to see how scheduling works.</p>
                  )}
                </div>
              </aside>
            </div>
            <div aria-live="polite" aria-atomic="true" className={`mt-3 flex min-h-5 items-center gap-1.5 text-[11px] font-semibold text-[#6b8257] ${notice ? 'opacity-100' : 'opacity-0'}`}>
              <CheckCircle2 className="h-3.5 w-3.5 shrink-0" aria-hidden="true" /> {notice || ' '}
            </div>
          </div>
        </div>
      </div>

      {addOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center overflow-y-auto bg-[#1e271c]/60 p-4 backdrop-blur-[3px]">
          <div
            ref={dialogRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby={dialogTitleId}
            onKeyDown={event => {
              if (event.key !== 'Tab') return;
              const focusables = Array.from(dialogRef.current?.querySelectorAll<HTMLElement>(
                'button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),a[href]'
              ) ?? []);
              const first = focusables[0];
              const last = focusables[focusables.length - 1];
              if (!first || !last) return;
              if (event.shiftKey && document.activeElement === first) {
                event.preventDefault();
                last.focus();
              } else if (!event.shiftKey && document.activeElement === last) {
                event.preventDefault();
                first.focus();
              }
            }}
            className="max-h-[calc(100dvh-2rem)] w-full max-w-[420px] overflow-y-auto rounded-[22px] border border-[#e0e8d6] bg-white p-5 text-[#253020] shadow-[0_30px_90px_rgba(0,0,0,0.26)] sm:p-7"
          >
            <div className="flex items-start justify-between gap-3">
              <div><p className="text-[10px] font-black uppercase tracking-[0.15em] text-[#839a62]">Just a demo</p><h4 id={dialogTitleId} className="mt-1.5 text-xl font-black tracking-tight">Quick save</h4><p className="mt-2 text-xs leading-5 text-[#869180]">Nothing is sent to LaterBox or stored after you leave.</p></div>
              <button type="button" onClick={() => { setAddOpen(false); addButton.current?.focus(); }} aria-label="Close demo save" className="rounded-lg p-2 text-[#8a9385] hover:bg-[#f2f6e9] focus-visible:outline-2 focus-visible:outline-[#748953]"><X className="h-5 w-5" /></button>
            </div>
            <form onSubmit={saveDemo} className="mt-5 space-y-4">
              <div><label htmlFor={titleId} className="mb-1.5 block text-xs font-bold">Name your save</label><input ref={addInput} id={titleId} required maxLength={150} value={newTitle} onChange={event => setNewTitle(event.target.value)} placeholder="An interesting article" className="w-full rounded-xl border border-[#e1e5d8] bg-[#fafbf7] px-3.5 py-3 text-sm outline-none focus:border-[#91ab72] focus:ring-2 focus:ring-[#e6edb0]/40" /></div>
              <div><label htmlFor={urlId} className="mb-1.5 block text-xs font-bold">Link</label><input id={urlId} type="url" required value={newUrl} onChange={event => setNewUrl(event.target.value)} placeholder="https://example.com" className="w-full rounded-xl border border-[#e1e5d8] bg-[#fafbf7] px-3.5 py-3 text-sm outline-none focus:border-[#91ab72] focus:ring-2 focus:ring-[#e6edb0]/40" /></div>
              <div><label htmlFor={`${urlId}-when`} className="mb-1.5 block text-xs font-bold">When should it return?</label><select id={`${urlId}-when`} value={newBucket} onChange={event => setNewBucket(event.target.value as PendingBucket)} className="w-full rounded-xl border border-[#e1e5d8] bg-[#fafbf7] px-3.5 py-3 text-sm outline-none focus:border-[#91ab72] focus:ring-2 focus:ring-[#e6edb0]/40">{bucketOptions.map(option => <option key={option.key} value={option.key}>{option.label}</option>)}</select></div>
              {error && <p role="alert" className="text-xs font-semibold text-red-700">{error}</p>}
              <button type="submit" className="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#1f291c] px-5 text-sm font-bold text-white transition-colors hover:bg-[#36482b] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#748953]"><Bookmark className="h-4 w-4" /> Save in preview <ArrowRight className="h-4 w-4" /></button>
            </form>
          </div>
        </div>
      )}
    </section>
  );
}
