// laterbox-web/src/components/layout/AppSidebar.tsx
'use client';

import { useCallback, useEffect, useMemo, useRef, useState, type FormEvent } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  Archive, CalendarClock, CalendarDays, Check, CheckCircle2, Clock, Compass,
  Crown, Download, FolderOpen, HelpCircle, Inbox, Minus, Pencil, Plus,
  Settings, Star, Trash2, X,
} from 'lucide-react';
import { useItems } from '@/lib/store/ItemContext';
import { useBilling } from '@/lib/store/BillingContext';
import { presentEntitlement } from '@/lib/billing/types';
import { scheduleItems } from '@/lib/utils/schedule';
import { CloudSyncIndicator } from '../ui/CloudSyncIndicator';

interface AppSidebarProps {
  onOpenCapture: () => void;
}

export function AppSidebar({ onOpenCapture }: AppSidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const {
    inboxItems, starredItems, savedItems, archivedItems, deletedItems, items,
    collections, createCollection, renameCollection, deleteCollection,
  } = useItems();
  const { entitlement } = useBilling();

  const [now, setNow] = useState(() => new Date());
  const [collectionsOpen, setCollectionsOpen] = useState(false);
  const [isCreatingCollection, setIsCreatingCollection] = useState(false);
  const [newCollectionName, setNewCollectionName] = useState('');
  const [isSubmittingCollection, setIsSubmittingCollection] = useState(false);
  const [editingCollection, setEditingCollection] = useState<string | null>(null);
  const [collectionName, setCollectionName] = useState('');
  const [busyCollection, setBusyCollection] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);
  const [collectionError, setCollectionError] = useState('');

  const sidebarRef = useRef<HTMLElement>(null);
  const collectionPanelRef = useRef<HTMLDivElement>(null);
  const collectionButtonRef = useRef<HTMLButtonElement>(null);
  const collectionInputRef = useRef<HTMLInputElement>(null);
  const [panelAnchor, setPanelAnchor] = useState({ top: 88, arrowTop: 82 });

  const updateCollectionPosition = useCallback(() => {
    const button = collectionButtonRef.current;
    const sidebar = sidebarRef.current;
    if (!button || !sidebar) return;

    const iconRect = button.getBoundingClientRect();
    const sidebarRect = sidebar.getBoundingClientRect();
    const panelHeight = Math.min(420, window.innerHeight - 32);
    const anchorY = iconRect.top + iconRect.height / 2 - sidebarRect.top;
    const maxTop = Math.max(16, window.innerHeight - 16 - panelHeight - sidebarRect.top);
    const top = Math.max(16, Math.min(anchorY - 72, maxTop));
    const arrowTop = Math.max(24, Math.min(anchorY - top, panelHeight - 24));
    setPanelAnchor(previous =>
      previous.top === top && previous.arrowTop === arrowTop ? previous : { top, arrowTop }
    );
  }, []);

  useEffect(() => {
    if (!entitlement.phaseEndsAt) return;
    const timer = window.setInterval(() => setNow(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, [entitlement.phaseEndsAt]);

  useEffect(() => {
    if (collectionsOpen && isCreatingCollection) collectionInputRef.current?.focus();
  }, [collectionsOpen, isCreatingCollection]);

  useEffect(() => {
    if (!collectionsOpen) return;
    const onPointerDown = (event: PointerEvent) => {
      const target = event.target as Node;
      if (!collectionPanelRef.current?.contains(target) && !collectionButtonRef.current?.contains(target)) {
        setCollectionsOpen(false);
        setIsCreatingCollection(false);
        setEditingCollection(null);
        setConfirmDelete(null);
      }
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setCollectionsOpen(false);
        setIsCreatingCollection(false);
        setEditingCollection(null);
        setConfirmDelete(null);
        collectionButtonRef.current?.focus();
      }
    };
    document.addEventListener('pointerdown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('pointerdown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [collectionsOpen]);

  useEffect(() => {
    if (!collectionsOpen) return;
    window.addEventListener('resize', updateCollectionPosition);
    document.addEventListener('scroll', updateCollectionPosition, true);
    return () => {
      window.removeEventListener('resize', updateCollectionPosition);
      document.removeEventListener('scroll', updateCollectionPosition, true);
    };
  }, [collectionsOpen, updateCollectionPosition]);

  const todayCount = useMemo(() => scheduleItems(items, 'today', now).length, [items, now]);
  const upcomingCount = useMemo(() => scheduleItems(items, 'upcoming', now).length, [items, now]);
  const somedayCount = useMemo(() => scheduleItems(items, 'someday', now).length, [items, now]);
  const plan = useMemo(() => presentEntitlement(entitlement, now), [entitlement, now]);

  const coreLinks = [
    { href: '/inbox', label: 'Inbox', icon: Inbox, count: inboxItems.length },
    { href: '/starred', label: 'Starred', icon: Star, count: starredItems.length },
    { href: '/kept', label: 'Kept', icon: CheckCircle2, count: savedItems.length },
    { href: '/archived', label: 'Archived', icon: Archive, count: archivedItems.length },
    { href: '/trash', label: 'Recently Deleted', icon: Trash2, count: deletedItems.length },
    { href: '/today', label: 'Today', icon: Clock, count: todayCount },
    { href: '/upcoming', label: 'Upcoming', icon: CalendarDays, count: upcomingCount },
    { href: '/someday', label: 'Someday', icon: CalendarClock, count: somedayCount },
  ];

  const systemLinks = [
    { href: '/tutorial', label: 'Guide', icon: Compass },
    { href: '/downloads', label: 'Apps', icon: Download },
    { href: '/help', label: 'Help & FAQ', icon: HelpCircle },
    { href: '/settings', label: 'Settings', icon: Settings },
  ];

  const isActive = (href: string) => {
    if (href === '/inbox') return pathname === '/inbox' || pathname === '/';
    if (href === '/downloads') return pathname === '/downloads' || pathname === '/download';
    if (href === '/trash') return pathname === '/trash' || pathname === '/deleted';
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  const railItemClass = (active: boolean) =>
    `relative group flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#758a50] ${
      active
        ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
        : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
    }`;

  const renderLink = ({
    href, label, icon: Icon, count,
  }: {
    href: string; label: string; icon: typeof Inbox; count?: number;
  }) => {
    const active = isActive(href);
    return (
      <Link
        key={href}
        href={href}
        aria-label={label}
        aria-current={active ? 'page' : undefined}
        title={count ? `${label} (${count})` : label}
        className={railItemClass(active)}
      >
        <Icon className="h-[26px] w-[26px]" strokeWidth={active ? 2.3 : 1.85} aria-hidden="true" />
        {Boolean(count) && (
          <span
            aria-hidden="true"
            className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-0.5 text-[9px] font-black leading-none text-white"
          >
            {Math.min(count ?? 0, 99)}{count && count > 99 ? '+' : ''}
          </span>
        )}
      </Link>
    );
  };

  const closeCollections = () => {
    setCollectionsOpen(false);
    setIsCreatingCollection(false);
    setEditingCollection(null);
    setConfirmDelete(null);
    setCollectionError('');
  };

  const createNewCollection = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const name = newCollectionName.trim();
    if (!name || isSubmittingCollection) return;
    setIsSubmittingCollection(true);
    setCollectionError('');
    try {
      const created = await createCollection(name);
      setNewCollectionName('');
      closeCollections();
      if (created?.id) router.push(`/library/${created.id}`);
    } catch (error) {
      setCollectionError(error instanceof Error ? error.message : 'Could not create the collection.');
    } finally {
      setIsSubmittingCollection(false);
    }
  };

  const saveCollectionName = async (event: FormEvent<HTMLFormElement>, id: string) => {
    event.preventDefault();
    if (!collectionName.trim() || busyCollection) return;
    setBusyCollection(id);
    setCollectionError('');
    try {
      await renameCollection(id, collectionName.trim());
      setEditingCollection(null);
    } catch (error) {
      setCollectionError(error instanceof Error ? error.message : 'Could not rename the collection.');
    } finally {
      setBusyCollection(null);
    }
  };

  const removeCollection = async (id: string, active: boolean) => {
    if (busyCollection) return;
    setBusyCollection(id);
    setCollectionError('');
    try {
      await deleteCollection(id);
      setConfirmDelete(null);
      if (active) router.push('/inbox');
    } catch (error) {
      setCollectionError(error instanceof Error ? error.message : 'Could not delete the collection.');
    } finally {
      setBusyCollection(null);
    }
  };

  return (
    <aside
      ref={sidebarRef}
      aria-label="Dashboard sidebar"
      className="relative z-30 flex h-screen w-[84px] shrink-0 flex-col items-center bg-[#f7f5ee] px-3 pb-3 pt-4"
    >
      <Link
        href="/inbox"
        aria-label="LaterBox home"
        title="LaterBox home"
        className="relative flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl bg-[#e6edb0] transition-transform hover:-rotate-3 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#758a50]"
      >
        <Image src="/branding/laterbox-icon.png" alt="" fill priority sizes="52px" className="object-contain p-1.5" />
      </Link>

      <div className="my-4 h-px w-9 shrink-0 bg-[#e5e2d6]" aria-hidden="true" />

      <button
        type="button"
        onClick={onOpenCapture}
        aria-label="Save item"
        title="Save Item (Control + Option + L)"
        className="group flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl bg-[#171711] text-[#e6edb0] shadow-[0_6px_14px_rgba(23,23,17,0.12)] transition-all hover:-translate-y-0.5 hover:bg-[#30372a] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#758a50]"
      >
        <Plus className="h-[28px] w-[28px] transition-transform group-hover:rotate-90" strokeWidth={2.6} aria-hidden="true" />
      </button>

      <div className="mt-4 min-h-0 w-full flex-1 overflow-y-auto overflow-x-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        <nav aria-label="Dashboard navigation" className="flex flex-col items-center gap-1.5">
          {coreLinks.map(renderLink)}
        </nav>

        <div className="my-4 flex justify-center" aria-hidden="true"><span className="h-px w-9 bg-[#e5e2d6]" /></div>

        <button
          ref={collectionButtonRef}
          type="button"
          aria-label="Collections"
          aria-expanded={collectionsOpen}
          aria-controls="laterbox-collections-panel"
          title="Collections"
          onClick={() => {
            if (collectionsOpen) closeCollections();
            else {
              updateCollectionPosition();
              setCollectionsOpen(true);
              setCollectionError('');
            }
          }}
          className={railItemClass(collectionsOpen || pathname.startsWith('/library/')) + ' mx-auto'}
        >
          <FolderOpen className="h-[26px] w-[26px]" strokeWidth={2} aria-hidden="true" />
          {collections.length > 0 && (
            <span aria-hidden="true" className="absolute -right-0.5 -top-0.5 h-[8px] w-[8px] rounded-full bg-[#7b9652]" />
          )}
        </button>

        <div className="my-4 flex justify-center" aria-hidden="true"><span className="h-px w-9 bg-[#e5e2d6]" /></div>

        <nav aria-label="Dashboard utilities" className="flex flex-col items-center gap-1.5">
          {systemLinks.map(renderLink)}
        </nav>
      </div>

      <div className="mt-3 flex w-full shrink-0 flex-col items-center gap-2 border-t border-[#e5e2d6] pt-3">
        <Link
          href="/plans"
          aria-label={`Plans — ${plan.label || 'Free Plan'}`}
          title={`Plans — ${plan.label || 'Free Plan'}`}
          aria-current={isActive('/plans') ? 'page' : undefined}
          className={railItemClass(isActive('/plans'))}
        >
          <Crown className="h-[25px] w-[25px]" strokeWidth={1.9} aria-hidden="true" />
        </Link>
        <div className="flex h-[52px] w-[52px] items-center justify-center">
          <CloudSyncIndicator
            compact
            className="!flex !h-[52px] !w-[52px] !items-center !justify-center !rounded-2xl [&_svg]:!h-[25px] [&_svg]:!w-[25px]"
          />
        </div>
      </div>

      {collectionsOpen && (
        <div
          ref={collectionPanelRef}
          id="laterbox-collections-panel"
          role="region"
          aria-label="Manage collections"
          style={{ top: panelAnchor.top }}
          className="absolute left-[calc(100%+8px)] z-50 flex h-[420px] max-h-[calc(100dvh-32px)] w-[320px] max-w-[calc(100vw-112px)] flex-col rounded-[22px] border border-[#e4e0d5] bg-white text-[#171711] shadow-[0_22px_75px_rgba(23,23,17,0.18)]"
        >
          <span
            aria-hidden="true"
            style={{ top: panelAnchor.arrowTop - 9 }}
            className="pointer-events-none absolute -left-[9px] z-10 h-[18px] w-[18px] rotate-45 border-b border-l border-[#e4e0d5] bg-white"
          />
          <div className="flex shrink-0 items-start justify-between gap-3 border-b border-[#f0ede5] px-5 py-4">
            <div>
              <h2 className="text-sm font-black tracking-tight">Collections</h2>
              <p className="mt-1 text-[11px] text-[#929087]">Keep related items together.</p>
            </div>
            <button
              type="button"
              onClick={closeCollections}
              aria-label="Close collections"
              className="rounded-xl p-2 text-[#797c73] hover:bg-[#f2f3ed] focus-visible:outline-2 focus-visible:outline-[#758a50]"
            >
              <X className="h-[18px] w-[18px]" aria-hidden="true" />
            </button>
          </div>

          <div className="shrink-0 space-y-3 border-b border-[#f0ede5] p-3.5">
            <button
              type="button"
              onClick={() => {
                setIsCreatingCollection(true);
                setEditingCollection(null);
                setConfirmDelete(null);
                setCollectionError('');
              }}
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#e6edb0] px-3 py-3 text-xs font-bold text-[#29331d] transition-colors hover:bg-[#dae5a3] focus-visible:outline-2 focus-visible:outline-[#758a50]"
            >
              <Plus className="h-4 w-4" aria-hidden="true" /> Create collection
            </button>

            {isCreatingCollection && (
              <form onSubmit={createNewCollection} className="space-y-2 rounded-xl border border-[#e5e5dc] bg-[#fbfbf7] p-3">
                <label htmlFor="laterbox-new-collection" className="text-xs font-bold text-[#59614f]">New collection name</label>
                <input
                  ref={collectionInputRef}
                  id="laterbox-new-collection"
                  type="text"
                  maxLength={80}
                  required
                  value={newCollectionName}
                  disabled={isSubmittingCollection}
                  onChange={event => setNewCollectionName(event.target.value)}
                  className="w-full rounded-lg border border-[#e2e4d7] bg-white px-3 py-2 text-sm outline-none focus:border-[#9eaf71]"
                  onKeyDown={event => { if (event.key === 'Escape') setIsCreatingCollection(false); }}
                  placeholder="e.g. Design inspiration"
                />
                <div className="flex gap-2">
                  <button type="submit" disabled={!newCollectionName.trim() || isSubmittingCollection} className="flex-1 rounded-lg bg-[#20261b] px-3 py-2 text-xs font-bold text-white disabled:opacity-50">Save</button>
                  <button type="button" onClick={() => setIsCreatingCollection(false)} className="rounded-lg border border-[#e2e4d7] px-3 py-2 text-xs font-bold text-[#65705d]">Cancel</button>
                </div>
              </form>
            )}

          </div>

          <nav
            aria-label="Your collections"
            className="min-h-0 flex-1 space-y-1 overflow-y-auto overscroll-contain px-3.5 py-3 [scrollbar-width:thin]"
          >
              {collections.map(col => {
                const href = `/library/${col.id}`;
                const active = pathname === href;
                const count = items.filter(item => !item.deleted_at && item.collections?.some(c => c.id === col.id)).length;
                return (
                  <div key={col.id} className="rounded-xl border border-transparent bg-[#fafbf8] p-2 hover:border-[#e5e8db]">
                    {editingCollection === col.id ? (
                      <form onSubmit={event => saveCollectionName(event, col.id)} className="flex items-center gap-1.5">
                        <input
                          type="text"
                          aria-label="Collection name"
                          autoFocus
                          maxLength={80}
                          value={collectionName}
                          disabled={Boolean(busyCollection)}
                          onChange={event => setCollectionName(event.target.value)}
                          className="min-w-0 flex-1 rounded-lg border border-[#cbd7ae] bg-white px-2 py-2 text-xs outline-none"
                        />
                        <button type="submit" aria-label="Save collection name" disabled={!collectionName.trim() || Boolean(busyCollection)} className="rounded-lg bg-[#20261b] p-2 text-white disabled:opacity-40"><Check className="h-3.5 w-3.5" /></button>
                        <button type="button" aria-label="Cancel rename" onClick={() => setEditingCollection(null)} className="rounded-lg p-2 text-[#64715a]"><X className="h-3.5 w-3.5" /></button>
                      </form>
                    ) : confirmDelete === col.id ? (
                      <div className="flex flex-wrap items-center gap-2 text-xs">
                        <span className="flex-1 font-semibold text-[#8a403f]">Delete collection? Items stay saved.</span>
                        <button
                          type="button"
                          disabled={Boolean(busyCollection)}
                          onClick={() => removeCollection(col.id, active)}
                          className="rounded-lg bg-red-600 px-3 py-2 font-bold text-white disabled:opacity-40"
                        >Delete</button>
                        <button type="button" onClick={() => setConfirmDelete(null)} className="rounded-lg px-2 py-2 font-bold text-[#65705d]">Cancel</button>
                      </div>
                    ) : (
                      <div className="flex items-center gap-1">
                        <Link
                          href={href}
                          onClick={closeCollections}
                          aria-current={active ? 'page' : undefined}
                          className={`flex min-w-0 flex-1 items-center gap-2.5 rounded-lg px-2 py-2 text-xs font-semibold transition-colors ${
                            active ? 'bg-[#e6edb0] text-[#171711]' : 'text-[#5e6859] hover:bg-white hover:text-[#171711]'
                          }`}
                        >
                          <FolderOpen className="h-4 w-4 shrink-0" aria-hidden="true" />
                          <span className="truncate">{col.name}</span>
                          <span className="ml-auto text-[10px] text-[#8f9487]">{count}</span>
                        </Link>
                        <button
                          type="button"
                          title={`Rename ${col.name}`}
                          aria-label={`Rename ${col.name}`}
                          disabled={Boolean(busyCollection)}
                          onClick={() => { setCollectionName(col.name); setEditingCollection(col.id); setConfirmDelete(null); setCollectionError(''); }}
                          className="rounded-lg p-2 text-[#7d8575] hover:bg-white hover:text-[#171711] disabled:opacity-40"
                        >
                          <Pencil className="h-3.5 w-3.5" aria-hidden="true" />
                        </button>
                        <button
                          type="button"
                          title={`Delete ${col.name}`}
                          aria-label={`Delete ${col.name}, keep items`}
                          disabled={Boolean(busyCollection)}
                          onClick={() => { setConfirmDelete(col.id); setEditingCollection(null); }}
                          className="rounded-lg p-2 text-[#987571] hover:bg-red-50 hover:text-red-700 disabled:opacity-40"
                        >
                          <Minus className="h-3.5 w-3.5" aria-hidden="true" />
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
              {collections.length === 0 && !isCreatingCollection && (
                <p className="rounded-xl bg-[#f7f8f3] px-4 py-5 text-center text-xs leading-6 text-[#8a9582]">
                  No collections yet. Make one to group your saved things.
                </p>
              )}
          </nav>
          {collectionError && <p role="alert" className="shrink-0 border-t border-[#f0ede5] bg-red-50 px-4 py-3 text-xs font-semibold text-red-700">{collectionError}</p>}
        </div>
      )}
    </aside>
  );
}
