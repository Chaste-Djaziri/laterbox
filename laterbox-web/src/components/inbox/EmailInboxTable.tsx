'use client';

import React, { useState, useMemo, useRef, useEffect, useSyncExternalStore } from 'react';
import dynamic from 'next/dynamic';
import { useRouter, usePathname } from 'next/navigation';
import { LaterBoxItem } from '@/lib/supabase/types';
import { useItems } from '@/lib/store/ItemContext';
import { resolveReturnPreset, ReturnPreset, scheduleItems, formatInboxAge } from '@/lib/utils/schedule';
import {
  Inbox,
  Tag,
  Video,
  Info,
  Star,
  Archive,
  Trash2,
  Clock,
  ExternalLink,
  RefreshCw,
  ChevronLeft,
  ChevronRight,
  ArrowLeft,
  ChevronDown,
  MoreVertical,
  Paperclip,
  Play,
  ArrowUpDown,
  Mail,
  Plus,
  Search,
  Check,
  X,
  RotateCcw,
  Folder,
  FolderPlus,
  CalendarDays,
  CalendarClock,
  CheckCircle,
  Copy,
} from 'lucide-react';
import {
  InboxSearchFilters,
  DEFAULT_SEARCH_FILTERS,
  formatEmailDate,
  getEmailSender,
  itemMatchesFilters,
  itemMatchesQuery,
  resolveItemPreviewImageUrl,
} from '@/lib/utils/emailFormatters';
const ItemDetailView = dynamic(
  () => import('@/components/item/ItemDetailView').then(module => module.ItemDetailView),
  { loading: () => (
    <div className="flex flex-1 items-center justify-center p-12 text-sm font-semibold text-[#8e8d87]">
      Loading item details…
    </div>
  ) }
);
import { AddToCollectionModal } from '@/components/collections/AddToCollectionModal';
import { fetchAttachmentDownloadUrl } from '@/lib/utils/attachment';
import { PortalMenu } from '@/components/ui/PortalMenu';
import { ToolbarTooltipRegion } from '@/components/ui/ToolbarTooltipRegion';
import { ExactScheduleModal } from '@/components/scheduling/ExactScheduleModal';
import { emailTableItemHref, readEmailTableItemId } from '@/lib/utils/tableItemNavigation';
import { isTaskComplete } from '@/lib/utils/itemDetailPresentation';

function InboxImageBackground({ item }: { item: LaterBoxItem }) {
  const asset = item.attachments?.find(a => a.mime_type?.startsWith('image/') ||
    /^(jpg|jpeg|png|gif|webp|avif|heic|heif)$/i.test(a.file_extension?.replace(/^\./, '') || ''));
  const [preview, setPreview] = useState<{ id: string; url: string } | null>(null);
  useEffect(() => {
    if (!asset) return;
    let active = true;
    fetchAttachmentDownloadUrl(asset.id, asset.user_id ?? item.user_id ?? null).then(url => {
      if (active && url) setPreview({ id: asset.id, url });
    });
    return () => { active = false; };
  }, [asset?.id, asset?.r2_object_key, asset?.user_id, item.user_id]);
  const url = asset ? (preview?.id === asset.id ? preview.url : null) : resolveItemPreviewImageUrl(item);
  if (!url) return null;
  return (
    <div className="absolute right-0 inset-y-0 w-[55%] max-w-96 pointer-events-none overflow-hidden select-none z-0" aria-hidden="true">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={url} alt="" loading="lazy"
        className="w-full h-full object-cover object-right opacity-65 group-hover:opacity-85 transition-opacity duration-300"
        style={{ maskImage: 'linear-gradient(to left, black, rgba(0,0,0,.85) 35%, rgba(0,0,0,.4) 65%, transparent)', WebkitMaskImage: 'linear-gradient(to left, black, rgba(0,0,0,.85) 35%, rgba(0,0,0,.4) 65%, transparent)' }}
        onError={event => { event.currentTarget.style.visibility = 'hidden'; }} />
      <div className="absolute inset-0 bg-gradient-to-r from-white/95 via-transparent to-transparent group-hover:from-[#faf8f5]/95" />
    </div>
  );
}

interface EmailInboxTableProps {
  items: LaterBoxItem[];
  onOpenCapture: () => void;
  title?: string;
  searchQuery?: string;
  isSearchSubmitted?: boolean;
  searchFilters?: InboxSearchFilters;
  onUpdateFilters?: (updater: (prev: InboxSearchFilters) => InboxSearchFilters) => void;
  onClearSearch?: () => void;
}

const TABLE_ITEM_CHANGED = 'laterbox:table-item-changed';

function subscribeToTableItem(onChange: () => void) {
  window.addEventListener('popstate', onChange);
  window.addEventListener(TABLE_ITEM_CHANGED, onChange);
  return () => {
    window.removeEventListener('popstate', onChange);
    window.removeEventListener(TABLE_ITEM_CHANGED, onChange);
  };
}

function readTableItemId() {
  return readEmailTableItemId(window.location.search);
}

function replaceTableItemUrl(id: string | null, replace = false) {
  const url = emailTableItemHref(window.location.href, id);
  const state = { ...window.history.state, laterboxTableItem: Boolean(id) };
  if (replace) window.history.replaceState(state, '', url);
  else window.history.pushState(state, '', url);
  window.dispatchEvent(new Event(TABLE_ITEM_CHANGED));
}

type TabKey = 'primary' | 'articles' | 'media' | 'updates';

export function EmailInboxTable({
  items,
  onOpenCapture,
  title: propTitle,
  searchQuery = '',
  isSearchSubmitted = false,
  searchFilters,
  onUpdateFilters,
  onClearSearch,
}: EmailInboxTableProps) {
  const router = useRouter();
  const pathname = usePathname();
  const {
    items: allItems,
    setFavorite,
    keepItem,
    archiveItem,
    markUnseen,
    deleteItem,
    restoreItem,
    permanentlyDeleteItem,
    reschedule,
    syncNow,
    now,
    syncStatus,
  } = useItems();

  const [activeTab, setActiveTab] = useState<TabKey>('primary');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const openedItemId = useSyncExternalStore(subscribeToTableItem, readTableItemId, () => null);
  const [page, setPage] = useState(1);
  const pageSize = 50;
  const [sortOrder, setSortOrder] = useState<'latest' | 'oldest'>('latest');

  const openItemDetails = (id: string, replace = false) => {
    setSnoozeMenuForId(null);
    setBulkSnoozeOpen(false);
    setExactSchedule(current => current?.source === 'detail' ? null : current);
    setDetailActionError('');
    setDetailCopied(false);
    replaceTableItemUrl(id, replace);
  };

  const closeItemDetails = () => {
    setExactSchedule(current => current?.source === 'detail' ? null : current);
    setDetailActionError('');
    if (window.history.state?.laterboxTableItem) {
      window.history.back();
    } else {
      replaceTableItemUrl(null, true);
    }
  };

  // Local fallback filters if not provided by parent
  const [localFilters, setLocalFilters] = useState<InboxSearchFilters>(DEFAULT_SEARCH_FILTERS);
  const filters = searchFilters || localFilters;
  const updateFilters = onUpdateFilters || setLocalFilters;

  // Menus state
  const [selectMenuOpen, setSelectMenuOpen] = useState(false);
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [snoozeMenuForId, setSnoozeMenuForId] = useState<string | null>(null);
  const [bulkSnoozeOpen, setBulkSnoozeOpen] = useState(false);
  const [exactSchedule, setExactSchedule] = useState<{ ids: string[]; initialValue?: string | null; source?: 'detail' } | null>(null);
  const [filterMenuOpen, setFilterMenuOpen] = useState<'format' | 'date' | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [collectionModalItem, setCollectionModalItem] = useState<LaterBoxItem | null>(null);
  const [detailActionPending, setDetailActionPending] = useState(false);
  const [detailActionError, setDetailActionError] = useState('');
  const [detailCopied, setDetailCopied] = useState(false);

  const selectMenuRef = useRef<HTMLDivElement>(null);
  const moreMenuRef = useRef<HTMLDivElement>(null);
  const snoozeTriggerRef = useRef<HTMLButtonElement>(null);
  const bulkSnoozeTriggerRef = useRef<HTMLButtonElement>(null);
  const filterMenuRef = useRef<HTMLDivElement>(null);

  // Close menus on outside click
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as Node;
      if (selectMenuRef.current && !selectMenuRef.current.contains(target)) {
        setSelectMenuOpen(false);
      }
      if (moreMenuRef.current && !moreMenuRef.current.contains(target)) {
        setMoreMenuOpen(false);
      }
      if (filterMenuRef.current && !filterMenuRef.current.contains(target)) {
        setFilterMenuOpen(null);
      }
    };
    window.addEventListener('mousedown', handleClickOutside);
    return () => window.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Filter items into the 4 Gmail tabs
  const tabBuckets = useMemo(() => {
    const articles: LaterBoxItem[] = [];
    const media: LaterBoxItem[] = [];
    const updates: LaterBoxItem[] = [];

    items.forEach((item) => {
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

      if (isMedia) {
        media.push(item);
      } else if (isUpdate) {
        updates.push(item);
      } else {
        articles.push(item);
      }
    });

    return {
      primary: items,
      articles,
      media,
      updates,
    };
  }, [items]);

  // Tab metadata
  const tabMetadata = [
    {
      id: 'primary' as const,
      label: 'Primary',
      icon: <Inbox className="w-4 h-4 shrink-0 text-[#171711]" />,
      count: tabBuckets.primary.length,
      snippet: tabBuckets.primary[0]
        ? `${getEmailSender(tabBuckets.primary[0])} — ${tabBuckets.primary[0].title || 'Saved item'}`
        : 'All inbox items',
      badgeBg: 'bg-[#e6edb0] text-[#171711]',
    },
    {
      id: 'articles' as const,
      label: 'Articles',
      icon: <Tag className="w-4 h-4 shrink-0 text-emerald-600" />,
      count: tabBuckets.articles.length,
      snippet: tabBuckets.articles[0]
        ? `${getEmailSender(tabBuckets.articles[0])} — ${tabBuckets.articles[0].title || 'Reading'}`
        : 'Articles & reads',
      badgeBg: 'bg-emerald-100 text-emerald-800',
    },
    {
      id: 'media' as const,
      label: 'Media',
      icon: <Video className="w-4 h-4 shrink-0 text-blue-600" />,
      count: tabBuckets.media.length,
      snippet: tabBuckets.media[0]
        ? `${getEmailSender(tabBuckets.media[0])} — ${tabBuckets.media[0].title || 'Media'}`
        : 'Videos & audio',
      badgeBg: 'bg-blue-100 text-blue-800',
    },
    {
      id: 'updates' as const,
      label: 'Updates',
      icon: <Info className="w-4 h-4 shrink-0 text-amber-600" />,
      count: tabBuckets.updates.length,
      snippet: tabBuckets.updates[0]
        ? `${getEmailSender(tabBuckets.updates[0])} — ${tabBuckets.updates[0].title || 'Note'}`
        : 'Notes & tasks',
      badgeBg: 'bg-amber-100 text-amber-800',
    },
  ];

  // Active search status
  const isSearchActive = Boolean(searchQuery && searchQuery.trim().length > 0 && isSearchSubmitted);

  // Active list filtered and sorted
  const currentTabItems = tabBuckets[activeTab];

  const processedItems = useMemo(() => {
    let list: LaterBoxItem[] = [];

    if (isSearchActive) {
      list = items.filter((item) => {
        return itemMatchesQuery(item, searchQuery) && itemMatchesFilters(item, filters);
      });
    } else {
      list = currentTabItems.filter((item) => {
        if (!searchQuery.trim()) return true;
        return itemMatchesQuery(item, searchQuery);
      });
    }

    list = [...list].sort((a, b) => {
      const timeA = new Date(a.created_at).getTime();
      const timeB = new Date(b.created_at).getTime();
      return sortOrder === 'latest' ? timeB - timeA : timeA - timeB;
    });

    return list;
  }, [isSearchActive, items, searchQuery, filters, currentTabItems, sortOrder]);

  const totalItems = processedItems.length;
  const startIndex = (page - 1) * pageSize;
  const endIndex = Math.min(startIndex + pageSize, totalItems);
  const pagedItems = processedItems.slice(startIndex, endIndex);
  const openedItem = openedItemId
    ? allItems.find(item => item.id === openedItemId) ?? items.find(item => item.id === openedItemId) ?? null
    : null;
  const openedExternalUrl = openedItem?.url && /^https?:\/\//i.test(openedItem.url) ? openedItem.url : null;
  const openedIndex = openedItemId ? processedItems.findIndex(item => item.id === openedItemId) : -1;
  const runDetailAction = async (action: () => Promise<unknown>, actionLabel: string, returnToList = false) => {
    if (detailActionPending) return;
    setDetailActionPending(true);
    setDetailActionError('');
    try {
      await action();
      if (returnToList) closeItemDetails();
    } catch {
      setDetailActionError(`Could not ${actionLabel}. Please try again.`);
    } finally {
      setDetailActionPending(false);
    }
  };

  const detailActionClass =
    'inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-[#77786f] transition-colors hover:bg-[#e9ebdf] hover:text-[#171711] focus-visible:outline-2 focus-visible:outline-[#73894e] disabled:cursor-not-allowed disabled:opacity-35';

  const previousItemId = openedIndex > 0 ? processedItems[openedIndex - 1].id : null;
  const nextItemId = openedIndex >= 0 && openedIndex < processedItems.length - 1
    ? processedItems[openedIndex + 1].id : null;


  // Dynamic empty state based on route, collection, or search filters
  const emptyStateConfig = useMemo(() => {
    // 1. Search filter is active
    if (isSearchActive) {
      return {
        icon: <Search className="w-6 h-6 stroke-[1.5]" />,
        title: `No results match "${searchQuery}"`,
        description: 'Try adjusting your search filters or searching for different keywords.',
        primaryAction: null,
      };
    }

    if (searchQuery) {
      return {
        icon: <Search className="w-6 h-6 stroke-[1.5]" />,
        title: 'No items match your search',
        description: 'Try a different keyword or clear the search query.',
        primaryAction: null,
      };
    }

    const currentTitle = propTitle || '';
    const isCollection =
      pathname.startsWith('/library/') ||
      (Boolean(currentTitle) &&
        !['Inbox', 'Starred', 'Kept', 'Archived', 'Recently Deleted', 'Today', 'Upcoming', 'Someday'].includes(
          currentTitle
        ));

    // Tab-specific naming
    const tabSuffix =
      activeTab === 'primary'
        ? ''
        : activeTab === 'articles'
        ? 'articles'
        : activeTab === 'media'
        ? 'media files'
        : 'notes or updates';

    // 2. Starred view
    if (pathname === '/starred' || currentTitle === 'Starred') {
      return {
        icon: <Star className="w-6 h-6 stroke-[1.5] text-amber-500 fill-amber-500/20" />,
        title: activeTab === 'primary' ? 'No starred items yet' : `No starred ${tabSuffix}`,
        description: 'Click the star icon on any item in your inbox or library to keep your top favorites here for quick access.',
        primaryAction: {
          label: 'Save item to inbox',
          onClick: onOpenCapture,
          icon: <Plus className="w-3.5 h-3.5" />,
        },
      };
    }

    // 3. Kept view
    if (pathname === '/kept' || currentTitle === 'Kept') {
      return {
        icon: <CheckCircle className="w-6 h-6 stroke-[1.5] text-[#171711]" />,
        title: activeTab === 'primary' ? 'No kept items in your library' : `No kept ${tabSuffix}`,
        description: 'Items you keep from your inbox will be preserved here permanently for quick reference.',
        primaryAction: {
          label: 'Save item to library',
          onClick: onOpenCapture,
          icon: <Plus className="w-3.5 h-3.5" />,
        },
      };
    }

    // 4. Archived view
    if (pathname === '/archived' || currentTitle === 'Archived') {
      return {
        icon: <Archive className="w-6 h-6 stroke-[1.5] text-[#6c6b63]" />,
        title: activeTab === 'primary' ? 'No archived items' : `No archived ${tabSuffix}`,
        description: 'Completed or processed items you archive will be stored here safely without cluttering your inbox.',
        primaryAction: null,
      };
    }

    // 5. Trash / Recently Deleted view
    if (pathname === '/trash' || pathname === '/deleted' || currentTitle === 'Recently Deleted') {
      return {
        icon: <Trash2 className="w-6 h-6 stroke-[1.5] text-[#9e9b92]" />,
        title: 'Trash is empty',
        description: 'Items you delete will appear here before being permanently removed.',
        primaryAction: null,
      };
    }

    // 6. Today view
    if (pathname === '/today' || currentTitle === 'Today') {
      return {
        icon: <Clock className="w-6 h-6 stroke-[1.5] text-[#171711]" />,
        title: activeTab === 'primary' ? 'Nothing scheduled for today' : `No ${tabSuffix} scheduled for today`,
        description: 'Items scheduled for today or deferred to resurface now will appear here.',
        primaryAction: {
          label: 'Schedule an item',
          onClick: onOpenCapture,
          icon: <Plus className="w-3.5 h-3.5" />,
        },
      };
    }

    // 7. Upcoming view
    if (pathname === '/upcoming' || currentTitle === 'Upcoming') {
      return {
        icon: <CalendarDays className="w-6 h-6 stroke-[1.5] text-[#171711]" />,
        title: activeTab === 'primary' ? 'No upcoming scheduled items' : `No upcoming ${tabSuffix}`,
        description: 'Postponed items with future return dates and scheduled reminders will appear here chronologically.',
        primaryAction: {
          label: 'Schedule an item',
          onClick: onOpenCapture,
          icon: <Plus className="w-3.5 h-3.5" />,
        },
      };
    }

    // 8. Someday view
    if (pathname === '/someday' || currentTitle === 'Someday') {
      return {
        icon: <CalendarClock className="w-6 h-6 stroke-[1.5] text-[#171711]" />,
        title: activeTab === 'primary' ? 'Your Someday vault is clear' : `No Someday ${tabSuffix}`,
        description: 'Ideas, reading lists, and backlog items postponed without a specific deadline will appear here.',
        primaryAction: {
          label: 'Save item for someday',
          onClick: onOpenCapture,
          icon: <Plus className="w-3.5 h-3.5" />,
        },
      };
    }

    // 9. Custom Collection view
    if (isCollection) {
      const collectionName = currentTitle || 'this collection';
      return {
        icon: <Folder className="w-6 h-6 stroke-[1.5] text-[#171711]" />,
        title: activeTab === 'primary' ? `No items in "${collectionName}"` : `No ${tabSuffix} in "${collectionName}"`,
        description: `Items assigned to "${collectionName}" will appear here. Use the collection control on any item to add it.`,
        primaryAction: {
          label: 'Save new item',
          onClick: onOpenCapture,
          icon: <Plus className="w-3.5 h-3.5" />,
        },
      };
    }

    // 10. Default: Primary Inbox
    const upcomingCount = scheduleItems(allItems || [], 'upcoming', now).length;
    if (upcomingCount > 0 && activeTab === 'primary') {
      return {
        icon: <CalendarDays className="w-6 h-6 stroke-[1.5] text-[#171711]" />,
        title: 'Inbox is clear — returns scheduled',
        description: `You have ${upcomingCount} item${upcomingCount === 1 ? '' : 's'} scheduled to return tomorrow or upcoming.`,
        primaryAction: {
          label: 'View Upcoming',
          onClick: () => router.push('/upcoming'),
          icon: <CalendarDays className="w-3.5 h-3.5" />,
        },
      };
    }
    return {
      icon: <Mail className="w-6 h-6 stroke-[1.5] text-[#171711]" />,
      title: activeTab === 'primary' ? 'Your inbox is all clear' : `No ${tabSuffix} in your inbox`,
      description: 'Items captured or scheduled for this category will appear here.',
      primaryAction: {
        label: 'Save item to inbox',
        onClick: onOpenCapture,
        icon: <Plus className="w-3.5 h-3.5" />,
      },
    };
  }, [isSearchActive, searchQuery, activeTab, pathname, propTitle, onOpenCapture, allItems, now, router]);

  // Selection helpers
  const allPagedSelected = pagedItems.length > 0 && pagedItems.every((i) => selectedIds.has(i.id));
  const somePagedSelected = pagedItems.some((i) => selectedIds.has(i.id));

  const toggleSelectAll = () => {
    if (allPagedSelected) {
      setSelectedIds(new Set());
    } else {
      const next = new Set(selectedIds);
      pagedItems.forEach((i) => next.add(i.id));
      setSelectedIds(next);
    }
  };

  const handleSelectType = (type: 'all' | 'none' | 'starred' | 'unstarred') => {
    setSelectMenuOpen(false);
    if (type === 'none') {
      setSelectedIds(new Set());
      return;
    }
    const next = new Set<string>();
    pagedItems.forEach((i) => {
      if (type === 'all') next.add(i.id);
      if (type === 'starred' && i.favorite) next.add(i.id);
      if (type === 'unstarred' && !i.favorite) next.add(i.id);
    });
    setSelectedIds(next);
  };

  const toggleItemSelect = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await syncNow();
    setTimeout(() => setIsRefreshing(false), 500);
  };

  // Bulk actions
  const handleBulkArchive = async () => {
    const ids = Array.from(selectedIds);
    for (const id of ids) {
      await archiveItem(id);
    }
    setSelectedIds(new Set());
  };

  const handleBulkDelete = async () => {
    const ids = Array.from(selectedIds);
    for (const id of ids) {
      await deleteItem(id);
    }
    setSelectedIds(new Set());
  };

  const handleBulkRestore = async () => {
    const ids = Array.from(selectedIds);
    for (const id of ids) {
      await restoreItem(id);
    }
    setSelectedIds(new Set());
  };

  const handleBulkPermanentDelete = async () => {
    if (!confirm('Permanently delete selected items? This cannot be undone.')) return;
    const ids = Array.from(selectedIds);
    for (const id of ids) {
      await permanentlyDeleteItem(id);
    }
    setSelectedIds(new Set());
  };

  const areSelectedItemsDeleted = useMemo(() => {
    if (selectedIds.size === 0) return false;
    for (const id of selectedIds) {
      const item = items.find((i) => i.id === id);
      if (item && !item.deleted_at) return false;
    }
    return true;
  }, [selectedIds, items]);

  const handleBulkStar = async () => {
    const ids = Array.from(selectedIds);
    for (const id of ids) {
      await setFavorite(id, true);
    }
  };

  const handleApplyPreset = async (itemId: string, preset: ReturnPreset) => {
    const returnAt = resolveReturnPreset(preset, now);
    await reschedule(itemId, returnAt);
    setSnoozeMenuForId(null);
  };

  const handleBulkPreset = async (preset: ReturnPreset) => {
    const returnAt = resolveReturnPreset(preset, now);
    const ids = Array.from(selectedIds);
    for (const id of ids) {
      await reschedule(id, returnAt);
    }
    setBulkSnoozeOpen(false);
    setSelectedIds(new Set());
  };

  return (
    <div className="bg-white border border-[#e4e0d5] rounded-2xl shadow-2xs flex flex-col flex-1 min-h-0 h-full overflow-hidden relative">
      {/* ===================================================================== */}
      {/* TOP TOOLBAR: Controls, Batch Actions, Pagination */}
      {/* ===================================================================== */}
      {openedItemId ? (
        <ToolbarTooltipRegion className="relative z-20 flex min-h-[60px] items-center gap-2 border-b border-[#e4e0d5] bg-[#fafaf6] px-2.5 py-2 text-[#171711] sm:gap-3 sm:px-4">
          <button
            type="button"
            onClick={closeItemDetails}
            data-tooltip={`Back to ${propTitle || 'items'}`}
            className="inline-flex min-h-9 shrink-0 items-center gap-2 rounded-xl px-2 text-xs font-bold transition-colors hover:bg-[#e6edb0] focus-visible:outline-2 focus-visible:outline-[#758a50] sm:px-3"
          >
            <ArrowLeft className="h-4 w-4" aria-hidden="true" />
            <span className="hidden sm:inline">Back to {propTitle || 'items'}</span>
            <span className="sm:hidden">Back</span>
          </button>

          <span className="h-6 w-px shrink-0 bg-[#e4e0d5]" aria-hidden="true" />

          <div role="toolbar" aria-label="Item actions" className="flex min-w-0 flex-1 items-center gap-1 overflow-x-auto py-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            {openedItem && (
              <>
                <button
                  type="button"
                  data-tooltip={openedItem.favorite ? 'Remove star' : 'Star item'}
                  aria-label={openedItem.favorite ? 'Remove star' : 'Star item'}
                  aria-pressed={Boolean(openedItem.favorite)}
                  disabled={detailActionPending}
                  onClick={() => void runDetailAction(() => setFavorite(openedItem.id, !openedItem.favorite), 'update star')}
                  className={detailActionClass + (openedItem.favorite ? ' text-amber-600' : '')}
                >
                  <Star className={`h-[18px] w-[18px] ${openedItem.favorite ? 'fill-amber-400' : ''}`} aria-hidden="true" />
                </button>

                {openedItem.type === 'task' ? (
                  <button
                    type="button"
                    role="checkbox"
                    aria-checked={isTaskComplete(openedItem)}
                    data-tooltip={isTaskComplete(openedItem) ? 'Reopen completed task' : 'Mark task complete'}
                    aria-label={isTaskComplete(openedItem) ? 'Reopen completed task' : 'Mark task complete'}
                    disabled={detailActionPending || Boolean(openedItem.deleted_at)}
                    onClick={() => void runDetailAction(
                       () => isTaskComplete(openedItem)
                        ? markUnseen(openedItem.id)
                        : archiveItem(openedItem.id),
                      'update task completion'
                    )}
                    className="inline-flex h-9 shrink-0 items-center gap-1.5 rounded-xl bg-[#e6edb0] px-3 text-xs font-bold text-[#27321c] transition-colors hover:bg-[#d9e6a0] focus-visible:outline-2 focus-visible:outline-[#758a50] disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    <CheckCircle className={`h-4 w-4 ${isTaskComplete(openedItem) ? 'fill-[#678b4a] text-white' : ''}`} aria-hidden="true" />
                    <span>{isTaskComplete(openedItem) ? 'Completed' : 'Complete'}</span>
                  </button>
                ) : (
                  <>
                    <button
                      type="button"
                      data-tooltip={openedItem.status === 'saved' ? 'Already kept' : 'Keep in library'}
                      aria-label={openedItem.status === 'saved' ? 'Already kept' : 'Keep in library'}
                      disabled={detailActionPending || Boolean(openedItem.deleted_at) || openedItem.status === 'saved'}
                      onClick={() => void runDetailAction(() => keepItem(openedItem.id), 'keep item')}
                      className="inline-flex h-9 shrink-0 items-center gap-1.5 rounded-xl bg-[#e6edb0] px-3 text-xs font-bold text-[#27321c] transition-colors hover:bg-[#d9e6a0] focus-visible:outline-2 focus-visible:outline-[#758a50] disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      <CheckCircle className="h-4 w-4" aria-hidden="true" />
                      <span>{openedItem.status === 'saved' ? 'Kept' : 'Keep'}</span>
                    </button>

                    <button
                      type="button"
                      data-tooltip={openedItem.status === 'archived' ? 'Already archived' : 'Archive item'}
                      aria-label={openedItem.status === 'archived' ? 'Already archived' : 'Archive item'}
                      disabled={detailActionPending || Boolean(openedItem.deleted_at) || openedItem.status === 'archived'}
                      onClick={() => void runDetailAction(() => archiveItem(openedItem.id), 'archive item')}
                      className={detailActionClass}
                    >
                      <Archive className="h-[18px] w-[18px]" aria-hidden="true" />
                    </button>
                  </>
                )}

                <button
                  type="button"
                  data-tooltip="Add to collections"
                  aria-label="Add to collections"
                  disabled={detailActionPending || Boolean(openedItem.deleted_at)}
                  onClick={() => setCollectionModalItem(openedItem)}
                  className={detailActionClass}
                >
                  <FolderPlus className="h-[18px] w-[18px]" aria-hidden="true" />
                </button>

                <button
                  type="button"
                  data-tooltip="Choose return date and time"
                  aria-label="Choose return date and time"
                  aria-haspopup="dialog"
                  disabled={detailActionPending || Boolean(openedItem.deleted_at)}
                  onClick={() => setExactSchedule({
                    ids: [openedItem.id],
                    initialValue: openedItem.return_at ?? null,
                    source: 'detail',
                  })}
                  className={detailActionClass}
                >
                  <CalendarClock className="h-[18px] w-[18px]" aria-hidden="true" />
                </button>

                <button
                  type="button"
                  data-tooltip={detailCopied ? 'Copied' : 'Copy item link or content'}
                  aria-label={detailCopied ? 'Copied' : 'Copy item link or content'}
                  disabled={detailActionPending}
                  onClick={async () => {
                    try {
                      await navigator.clipboard.writeText(
                        openedItem.url || openedItem.text_content || openedItem.title || 'Saved item'
                      );
                      setDetailCopied(true);
                    } catch {
                      setDetailActionError('Could not copy this item. Please try again.');
                    }
                  }}
                  className={detailActionClass}
                >
                  {detailCopied ? <Check className="h-[18px] w-[18px] text-emerald-700" /> : <Copy className="h-[18px] w-[18px]" />}
                </button>

                {openedExternalUrl && (
                  <a
                    href={openedExternalUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    data-tooltip="Open external source"
                    aria-label="Open external source in a new tab"
                    className={detailActionClass}
                  >
                    <ExternalLink className="h-[18px] w-[18px]" aria-hidden="true" />
                  </a>
                )}

                {openedItem.deleted_at ? (
                  <button
                    type="button"
                    data-tooltip="Restore item"
                    aria-label="Restore item"
                    disabled={detailActionPending}
                    onClick={() => void runDetailAction(() => restoreItem(openedItem.id), 'restore item', true)}
                    className={detailActionClass}
                  >
                    <RotateCcw className="h-[18px] w-[18px]" aria-hidden="true" />
                  </button>
                ) : (
                  <button
                    type="button"
                    data-tooltip="Delete item"
                    aria-label="Delete item"
                    disabled={detailActionPending}
                    onClick={() => {
                      if (window.confirm('Move this item to Recently Deleted?')) {
                        void runDetailAction(() => deleteItem(openedItem.id), 'delete item', true);
                      }
                    }}
                    className={detailActionClass + ' hover:bg-red-50 hover:text-red-700'}
                  >
                    <Trash2 className="h-[18px] w-[18px]" aria-hidden="true" />
                  </button>
                )}
              </>
            )}
          </div>

          <div className="flex shrink-0 items-center gap-1 border-l border-[#e4e0d5] pl-2 sm:pl-3">
            <span className="hidden text-[11px] font-semibold text-[#8e8d87] md:inline">
              {openedIndex >= 0 ? `${openedIndex + 1} of ${totalItems}` : 'Item details'}
            </span>
            <button
              type="button"
              aria-label="Previous item"
              data-tooltip="Previous item"
              disabled={!previousItemId}
              onClick={() => previousItemId && openItemDetails(previousItemId, true)}
              className="rounded-lg p-2 text-[#5f655b] transition-colors hover:bg-white disabled:cursor-not-allowed disabled:opacity-30 focus-visible:outline-2 focus-visible:outline-[#758a50]"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <button
              type="button"
              aria-label="Next item"
              data-tooltip="Next item"
              disabled={!nextItemId}
              onClick={() => nextItemId && openItemDetails(nextItemId, true)}
              className="rounded-lg p-2 text-[#5f655b] transition-colors hover:bg-white disabled:cursor-not-allowed disabled:opacity-30 focus-visible:outline-2 focus-visible:outline-[#758a50]"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
          {detailActionError && (
            <div role="alert" className="absolute right-3 top-full z-30 max-w-sm rounded-b-xl border border-red-200 bg-red-50 px-3 py-2 text-xs font-medium text-red-700 shadow-sm">
              {detailActionError}
            </div>
          )}
        </ToolbarTooltipRegion>
      ) : (
      <div className="shrink-0 flex items-center justify-between px-3 py-2 border-b border-[#e4e0d5] bg-white text-[#6c6b63] text-xs min-h-[46px] select-none rounded-t-2xl relative z-20">
        {/* Left Toolbar Controls */}
        <div className="flex items-center gap-1 sm:gap-2">
          {/* Checkbox & Dropdown */}
          <div className="relative flex items-center" ref={selectMenuRef}>
            <div className="flex items-center rounded-lg hover:bg-[#faf8f5] p-1 transition-colors">
              <input
                type="checkbox"
                checked={allPagedSelected}
                ref={(el) => {
                  if (el) el.indeterminate = somePagedSelected && !allPagedSelected;
                }}
                onChange={toggleSelectAll}
                className="w-4 h-4 rounded border-[#c2beb3] accent-[#171711] cursor-pointer"
                title="Select all"
              />
              <button
                type="button"
                onClick={() => setSelectMenuOpen(!selectMenuOpen)}
                className="p-1 text-[#9e9b92] hover:text-[#171711] transition-colors cursor-pointer"
                title="Select options"
              >
                <ChevronDown className="w-3 h-3" />
              </button>
            </div>

            {/* Select Dropdown Menu */}
            {selectMenuOpen && (
              <div className="absolute left-0 top-full mt-1 w-32 bg-white border border-[#e4e0d5] rounded-xl shadow-lg py-1 z-30 text-xs font-medium text-[#171711]">
                <button
                  type="button"
                  onClick={() => handleSelectType('all')}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                >
                  All
                </button>
                <button
                  type="button"
                  onClick={() => handleSelectType('none')}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                >
                  None
                </button>
                <button
                  type="button"
                  onClick={() => handleSelectType('starred')}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                >
                  Starred
                </button>
                <button
                  type="button"
                  onClick={() => handleSelectType('unstarred')}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                >
                  Unstarred
                </button>
              </div>
            )}
          </div>

          {/* Refresh Button */}
          <button
            type="button"
            onClick={handleRefresh}
            title="Refresh inbox"
            className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
          >
            <RefreshCw
              className={`w-4 h-4 ${isRefreshing || syncStatus === 'syncing' ? 'animate-spin' : ''}`}
            />
          </button>

          {/* More Menu */}
          <div className="relative" ref={moreMenuRef}>
            <button
              type="button"
              onClick={() => setMoreMenuOpen(!moreMenuOpen)}
              title="More actions"
              className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
            >
              <MoreVertical className="w-4 h-4" />
            </button>

            {moreMenuOpen && (
              <div className="absolute left-0 top-full mt-1 w-44 bg-white border border-[#e4e0d5] rounded-xl shadow-lg py-1 z-30 text-xs font-medium text-[#171711]">
                <button
                  type="button"
                  onClick={() => {
                    handleSelectType('all');
                    setMoreMenuOpen(false);
                  }}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                >
                  Select all on page
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setSelectedIds(new Set());
                    setMoreMenuOpen(false);
                  }}
                  className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                >
                  Clear selections
                </button>
              </div>
            )}
          </div>

          {/* Bulk Action Buttons (Visible when 1+ selected) */}
          {selectedIds.size > 0 && (
            <div className="flex items-center gap-1 pl-2 ml-1 border-l border-[#e4e0d5] animate-in fade-in duration-150">
              <span className="text-[11px] font-bold text-[#171711] mr-1">
                {selectedIds.size} selected
              </span>

              {areSelectedItemsDeleted ? (
                <>
                  <button
                    type="button"
                    onClick={handleBulkRestore}
                    title="Restore selected to inbox"
                    className="p-1.5 rounded-lg hover:bg-emerald-50 text-[#6c6b63] hover:text-emerald-700 transition-colors cursor-pointer"
                  >
                    <RotateCcw className="w-4 h-4" />
                  </button>

                  <button
                    type="button"
                    onClick={handleBulkPermanentDelete}
                    title="Delete selected forever"
                    className="p-1.5 rounded-lg hover:bg-rose-50 text-[#6c6b63] hover:text-rose-600 transition-colors cursor-pointer"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </>
              ) : (
                <>
                  <button
                    type="button"
                    onClick={handleBulkArchive}
                    title="Archive selected"
                    className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                  >
                    <Archive className="w-4 h-4" />
                  </button>

                  <button
                    type="button"
                    onClick={handleBulkDelete}
                    title="Delete selected"
                    className="p-1.5 rounded-lg hover:bg-rose-50 text-[#6c6b63] hover:text-rose-600 transition-colors cursor-pointer"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>

                  <button
                    type="button"
                    onClick={handleBulkStar}
                    title="Star selected"
                    className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-amber-500 transition-colors cursor-pointer"
                  >
                    <Star className="w-4 h-4" />
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      const firstSelected = items.find((i) => selectedIds.has(i.id));
                      if (firstSelected) {
                        setCollectionModalItem(firstSelected);
                      }
                    }}
                    title="Add to collection"
                    className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                  >
                    <FolderPlus className="w-4 h-4" />
                  </button>

                  <div className="relative">
                    <button
                      type="button"
                      ref={bulkSnoozeTriggerRef}
                      onClick={() => { setSnoozeMenuForId(null); setBulkSnoozeOpen(!bulkSnoozeOpen); }}
                      title="Snooze selected"
                      className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                    >
                      <Clock className="w-4 h-4" />
                    </button>

                {bulkSnoozeOpen && (
                  <PortalMenu open={bulkSnoozeOpen} onClose={() => setBulkSnoozeOpen(false)} triggerRef={bulkSnoozeTriggerRef} width={224}>
                    <div className="px-3 py-1 text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider">
                      Snooze until
                    </div>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('oneHour')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>In 1 hour</span>
                      <span className="text-[#9e9b92]">+1 hr</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('tomorrow')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>After 1 day</span>
                      <span className="text-[#9e9b92]">Tomorrow</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('oneWeek')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>A week</span>
                      <span className="text-[#9e9b92]">+7 days</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('oneMonth')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>A month</span>
                      <span className="text-[#9e9b92]">+1 mo</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('someday')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>Someday</span>
                      <span className="text-[#9e9b92]">Vault</span>
                    </button>
                    <div className="px-3 pt-2 pb-1 border-t border-[#e4e0d5] mt-1">
                      <div className="text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider mb-1">
                        Exact date & time
                      </div>
                      <button type="button" onClick={() => {
                        setExactSchedule({ ids: Array.from(selectedIds) });
                        setBulkSnoozeOpen(false);
                      }} className="w-full rounded-lg bg-[#f7f5ee] px-3 py-2 text-left text-xs font-semibold hover:bg-[#ebe7dc]">
                        Choose date & time…
                      </button>
                    </div>
                  </PortalMenu>
                )}
              </div>
            </>
          )}
        </div>
      )}
    </div>

        {/* Right Toolbar Controls: Pagination & Sorting */}
        <div className="flex items-center gap-2">
          {totalItems > 0 && (
            <span className="text-[11px] sm:text-xs font-medium text-[#6c6b63]">
              {startIndex + 1}–{endIndex} of {totalItems}
            </span>
          )}

          <div className="flex items-center gap-0.5">
            <button
              type="button"
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(p - 1, 1))}
              title="Previous page"
              className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] disabled:opacity-30 disabled:hover:bg-transparent transition-colors cursor-pointer"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              type="button"
              disabled={endIndex >= totalItems}
              onClick={() => setPage((p) => p + 1)}
              title="Next page"
              className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] disabled:opacity-30 disabled:hover:bg-transparent transition-colors cursor-pointer"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>

          <button
            type="button"
            onClick={() => setSortOrder((s) => (s === 'latest' ? 'oldest' : 'latest'))}
            title={sortOrder === 'latest' ? 'Showing newest first' : 'Showing oldest first'}
            className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer ml-1"
          >
            <ArrowUpDown className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
      )}

      {/* ===================================================================== */}
      {/* FILTER BAR / CATEGORY TABS */}
      {/* ===================================================================== */}
      {!openedItemId && (isSearchActive ? (
        /* SEARCH FILTER PILLS BAR (Image 1 style) */
        <div className="shrink-0 flex flex-wrap items-center justify-between gap-2 px-3 sm:px-4 py-2.5 border-b border-[#e4e0d5] bg-[#faf8f5]/60 text-xs relative z-30">
          <div className="flex flex-wrap items-center gap-1.5" ref={filterMenuRef}>
            {/* Search Pill Badge */}
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#171711] text-[#e6edb0] shadow-2xs">
              <Search className="w-3.5 h-3.5" />
              <span>Results for &ldquo;{searchQuery}&rdquo;</span>
            </span>

            {/* Format Dropdown Pill */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setFilterMenuOpen(filterMenuOpen === 'format' ? null : 'format')}
                className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold border transition-colors cursor-pointer ${
                  filters.format !== 'all'
                    ? 'bg-[#171711] text-[#e6edb0] border-[#171711] shadow-2xs'
                    : 'bg-white text-[#171711] border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
                }`}
              >
                <span>
                  {filters.format === 'all'
                    ? 'Format'
                    : filters.format === 'articles'
                    ? 'Articles'
                    : filters.format === 'media'
                    ? 'Media'
                    : 'Updates'}
                </span>
                <ChevronDown className="w-3 h-3 opacity-60" />
              </button>

              {filterMenuOpen === 'format' && (
                <div className="absolute left-0 top-full mt-1.5 w-44 bg-white border border-[#e4e0d5] rounded-xl shadow-xl py-1.5 z-50 text-xs text-[#171711] animate-in fade-in duration-100">
                  {[
                    { id: 'all', label: 'All formats' },
                    { id: 'articles', label: 'Articles' },
                    { id: 'media', label: 'Media (Video/Audio)' },
                    { id: 'updates', label: 'Notes & Tasks' },
                  ].map((fmt) => (
                    <button
                      key={fmt.id}
                      type="button"
                      onClick={() => {
                        updateFilters((prev) => ({ ...prev, format: fmt.id as any }));
                        setFilterMenuOpen(null);
                      }}
                      className={`w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] flex items-center justify-between cursor-pointer ${
                        filters.format === fmt.id ? 'font-bold text-[#171711]' : 'text-[#6c6b63]'
                      }`}
                    >
                      <span>{fmt.label}</span>
                      {filters.format === fmt.id && <Check className="w-3.5 h-3.5 text-[#171711]" />}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Any time Dropdown Pill */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setFilterMenuOpen(filterMenuOpen === 'date' ? null : 'date')}
                className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold border transition-colors cursor-pointer ${
                  filters.dateRange !== 'all'
                    ? 'bg-[#171711] text-[#e6edb0] border-[#171711] shadow-2xs'
                    : 'bg-white text-[#171711] border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
                }`}
              >
                <span>
                  {filters.dateRange === 'all'
                    ? 'Any time'
                    : filters.dateRange === '24h'
                    ? 'Last 24 hours'
                    : filters.dateRange === '7d'
                    ? 'Last 7 days'
                    : 'Last 30 days'}
                </span>
                <ChevronDown className="w-3 h-3 opacity-60" />
              </button>

              {filterMenuOpen === 'date' && (
                <div className="absolute left-0 top-full mt-1.5 w-44 bg-white border border-[#e4e0d5] rounded-xl shadow-xl py-1.5 z-50 text-xs text-[#171711] animate-in fade-in duration-100">
                  {[
                    { id: 'all', label: 'Any time' },
                    { id: '24h', label: 'Last 24 hours' },
                    { id: '7d', label: 'Last 7 days' },
                    { id: '30d', label: 'Last 30 days' },
                  ].map((range) => (
                    <button
                      key={range.id}
                      type="button"
                      onClick={() => {
                        updateFilters((prev) => ({ ...prev, dateRange: range.id as any }));
                        setFilterMenuOpen(null);
                      }}
                      className={`w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] flex items-center justify-between cursor-pointer ${
                        filters.dateRange === range.id ? 'font-bold text-[#171711]' : 'text-[#6c6b63]'
                      }`}
                    >
                      <span>{range.label}</span>
                      {filters.dateRange === range.id && <Check className="w-3.5 h-3.5 text-[#171711]" />}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Has attachment Toggle Pill */}
            <button
              type="button"
              onClick={() => updateFilters((prev) => ({ ...prev, hasAttachment: !prev.hasAttachment }))}
              className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold border transition-colors cursor-pointer ${
                filters.hasAttachment
                  ? 'bg-[#171711] text-[#e6edb0] border-[#171711] shadow-2xs'
                  : 'bg-white text-[#171711] border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
              }`}
            >
              <Paperclip className="w-3 h-3" />
              <span>Has attachment</span>
            </button>

            {/* Starred Toggle Pill */}
            <button
              type="button"
              onClick={() => updateFilters((prev) => ({ ...prev, starred: !prev.starred }))}
              className={`inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold border transition-colors cursor-pointer ${
                filters.starred
                  ? 'bg-[#171711] text-[#e6edb0] border-[#171711] shadow-2xs'
                  : 'bg-white text-[#171711] border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
              }`}
            >
              <Star className="w-3 h-3" />
              <span>Starred</span>
            </button>

            {/* Reset Filters if any active */}
            {(filters.hasAttachment || filters.starred || filters.dateRange !== 'all' || filters.format !== 'all') && (
              <button
                type="button"
                onClick={() => updateFilters(() => DEFAULT_SEARCH_FILTERS)}
                className="px-2.5 py-1 text-xs font-semibold text-[#8e8d87] hover:text-[#171711] transition-colors cursor-pointer underline underline-offset-2"
              >
                Reset filters
              </button>
            )}
          </div>

          {/* Clear Search Button */}
          {onClearSearch && (
            <button
              type="button"
              onClick={onClearSearch}
              className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold text-[#6c6b63] hover:text-[#171711] hover:bg-white border border-transparent hover:border-[#e4e0d5] transition-colors cursor-pointer ml-auto"
            >
              <X className="w-3.5 h-3.5" />
              <span>Clear search</span>
            </button>
          )}
        </div>
      ) : (
        /* Regular Category Tabs */
        <div className="shrink-0 flex items-center border-b border-[#e4e0d5] bg-white overflow-x-auto scrollbar-none">
          {tabMetadata.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => {
                  setActiveTab(tab.id);
                  setPage(1);
                  setSelectedIds(new Set());
                }}
                className={`relative flex-1 min-w-[150px] sm:min-w-[200px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left select-none ${
                  isActive ? 'bg-[#faf8f5]/60' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {/* Active Underline Indicator Bar */}
                {isActive && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}

                {/* Tab Icon */}
                <div className="shrink-0">{tab.icon}</div>

                {/* Tab Title, Badge & Subtitle */}
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span
                      className={`text-xs sm:text-sm tracking-tight truncate ${
                        isActive ? 'font-black text-[#171711]' : 'font-bold text-[#6c6b63]'
                      }`}
                    >
                      {tab.label}
                    </span>
                    {tab.count > 0 && (
                      <span
                        className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold shrink-0 ${tab.badgeBg}`}
                      >
                        {tab.count} new
                      </span>
                    )}
                  </div>
                  <p className="text-[11px] text-[#9e9b92] truncate mt-0.5 hidden sm:block">
                    {tab.snippet}
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      ))}

      {/* ===================================================================== */}
      {/* EMAIL LIST ROWS */}
      {/* ===================================================================== */}
      {openedItemId ? (
        <div className="flex-1 min-h-0 overflow-y-auto overscroll-contain rounded-b-2xl bg-[#f7f5ee]">
          <ItemDetailView
            key={openedItemId}
            id={openedItemId}
            backHref={pathname}
            onBack={closeItemDetails}
            embedded
          />
        </div>
      ) : pagedItems.length === 0 ? (
        <div className="flex-1 min-h-0 overflow-y-auto flex flex-col items-center justify-center py-16 px-4 text-center space-y-3 rounded-b-2xl">
          <div className="w-12 h-12 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92] shadow-2xs">
            {emptyStateConfig.icon}
          </div>
          <div>
            <h3 className="text-sm font-bold text-[#171711]">
              {emptyStateConfig.title}
            </h3>
            <p className="text-xs text-[#8e8d87] max-w-sm mx-auto mt-0.5 leading-relaxed">
              {emptyStateConfig.description}
            </p>
          </div>
          {isSearchActive ? (
            <div className="flex items-center gap-2 mt-2">
              <button
                type="button"
                onClick={() => updateFilters(() => DEFAULT_SEARCH_FILTERS)}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#e4e0d5] bg-white hover:bg-[#faf8f5] text-[#171711] text-xs font-bold transition-all cursor-pointer"
              >
                <span>Reset filters</span>
              </button>
              {onClearSearch && (
                <button
                  type="button"
                  onClick={onClearSearch}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#171711] hover:bg-black text-white text-xs font-bold transition-all cursor-pointer"
                >
                  <X className="w-3.5 h-3.5" />
                  <span>Clear search</span>
                </button>
              )}
            </div>
          ) : emptyStateConfig.primaryAction ? (
            <button
              type="button"
              onClick={emptyStateConfig.primaryAction.onClick}
              className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#171711] hover:bg-black text-white text-xs font-bold shadow-xs transition-all cursor-pointer mt-2"
            >
              {emptyStateConfig.primaryAction.icon}
              <span>{emptyStateConfig.primaryAction.label}</span>
            </button>
          ) : null}
        </div>
      ) : (
        /* FULL WIDTH ROWS (Standard View) */
        <div className="flex-1 min-h-0 overflow-y-auto divide-y divide-[#f0ede4] rounded-b-2xl">
          {pagedItems.map((item) => {
            const isSelected = selectedIds.has(item.id);
            const isStarred = Boolean(item.favorite);
            const sender = getEmailSender(item);
            const title =
              item.metadata?.title ||
              item.title ||
              item.attachments?.[0]?.original_file_name ||
              'Untitled item';
            const snippet =
              item.metadata?.description || item.text_content || item.url || 'No preview available';
            const hasAttachments = item.attachments && item.attachments.length > 0;
            const isVideo =
              item.metadata?.content_type === 'video' ||
              item.type === 'video' ||
              item.url?.includes('youtube.com');

            return (
              <div
                key={item.id}
                onClick={() => openItemDetails(item.id)}
                role="link"
                tabIndex={0}
                aria-label={`View details for ${title}`}
                onKeyDown={event => {
                  if (event.target === event.currentTarget && (event.key === 'Enter' || event.key === ' ')) {
                    event.preventDefault();
                    openItemDetails(item.id);
                  }
                }}
                className={`group relative flex items-center gap-2.5 sm:gap-3 px-3 sm:px-4 py-2.5 transition-colors cursor-pointer select-none overflow-hidden focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-[#7a9055] last:rounded-b-2xl ${
                  isSelected
                    ? 'bg-[#f5f8df] hover:bg-[#eef3d0]'
                    : 'bg-white hover:bg-[#faf8f5]'
                }`}
              >
                {/* 1. Checkbox */}
                <InboxImageBackground item={item} />
                <div
                  onClick={(e) => toggleItemSelect(item.id, e)}
                  className="p-1 -m-1 shrink-0 flex items-center relative z-10"
                >
                  <input
                    type="checkbox"
                    checked={isSelected}
                    onChange={() => {}}
                    className="w-4 h-4 rounded border-[#c2beb3] accent-[#171711] cursor-pointer"
                  />
                </div>

                {/* 2. Star Icon */}
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setFavorite(item.id, !isStarred);
                  }}
                  title={isStarred ? 'Unstar' : 'Star'}
                  className="p-1 -m-1 shrink-0 rounded hover:bg-[#faf8f5] transition-colors cursor-pointer relative z-10"
                >
                  <Star
                    className={`w-4 h-4 transition-colors ${
                      isStarred
                        ? 'fill-amber-400 text-amber-400'
                        : 'text-[#c2beb3] hover:text-[#9e9b92]'
                    }`}
                  />
                </button>

                {/* 3. Sender Column (Fixed Width, Truncated, Bold) */}
                <div className="w-28 sm:w-44 shrink-0 truncate relative z-10">
                  <span className="text-xs sm:text-sm font-bold text-[#171711] group-hover:text-black">
                    {sender}
                  </span>
                </div>

                {/* 4. Subject & Snippet Inline Flex */}
                <div className="flex-1 min-w-0 flex items-center gap-1.5 text-xs sm:text-sm overflow-hidden whitespace-nowrap relative z-10">
                  <span className="font-bold text-[#171711] truncate shrink-0 max-w-[50%] sm:max-w-[42%] group-hover:text-black">
                    {title}
                  </span>
                  <span className="text-[#9e9b92] shrink-0 font-bold">–</span>
                  <span className="text-[#6c6b63] truncate flex-1 min-w-0 font-normal">
                    {snippet}
                  </span>

                  {/* Attachment Chip Badge */}
                  {hasAttachments && (
                    <span className="shrink-0 inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-[#f0ede4] text-[#171711] border border-[#e4e0d5]">
                      <Paperclip className="w-2.5 h-2.5 text-[#6c6b63]" />
                      <span>{item.attachments?.[0]?.original_file_name || 'File'}</span>
                    </span>
                  )}

                  {/* Video Badge */}
                  {isVideo && (
                    <span className="shrink-0 inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-rose-50 text-rose-700 border border-rose-200">
                      <Play className="w-2.5 h-2.5 fill-rose-600 text-rose-600" />
                      <span>Video</span>
                    </span>
                  )}

                  {/* Collection Badges */}
                  {item.collections && item.collections.length > 0 && (
                    <span className="shrink-0 inline-flex items-center gap-1">
                      {item.collections.slice(0, 2).map((col) => (
                        <span
                          key={col.id}
                          onClick={(e) => {
                            e.stopPropagation();
                            setCollectionModalItem(item);
                          }}
                          title={`In collection: ${col.name} (Click to manage)`}
                          className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-[#e6edb0]/60 hover:bg-[#e6edb0] text-[#171711] border border-[#d0db84] transition-colors cursor-pointer"
                        >
                          <Folder className="w-2.5 h-2.5 text-[#171711]" />
                          <span className="max-w-[70px] truncate">{col.name}</span>
                        </span>
                      ))}
                      {item.collections.length > 2 && (
                        <span
                          onClick={(e) => {
                            e.stopPropagation();
                            setCollectionModalItem(item);
                          }}
                          title="Click to manage all collections"
                          className="px-1 py-0.5 rounded text-[9px] font-bold bg-[#ebe7dc] text-[#6c6b63] cursor-pointer hover:bg-[#e6edb0] hover:text-[#171711]"
                        >
                          +{item.collections.length - 2}
                        </span>
                      )}
                    </span>
                  )}
                </div>

                {/* 5. Right Actions & Timestamp */}
                <div className="shrink-0 flex items-center justify-end min-w-[90px] sm:min-w-[130px] text-right relative z-10">
                  {/* Quick Action Icons visible on Hover */}
                  <div className="hidden group-hover:flex items-center gap-1 text-[#6c6b63] bg-white/90 backdrop-blur-xs px-1.5 py-0.5 rounded-lg border border-[#e4e0d5]/60 shadow-2xs">
                    {item.deleted_at ? (
                      <>
                        {/* Restore to Inbox */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            restoreItem(item.id);
                          }}
                          title="Restore to inbox"
                          className="p-1.5 rounded-lg hover:bg-emerald-100 hover:text-emerald-700 transition-colors cursor-pointer"
                        >
                          <RotateCcw className="w-3.5 h-3.5" />
                        </button>

                        {/* Delete Permanently */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            if (confirm('Permanently delete this item? This cannot be undone.')) {
                              permanentlyDeleteItem(item.id);
                            }
                          }}
                          title="Delete forever"
                          className="p-1.5 rounded-lg hover:bg-rose-100 hover:text-rose-600 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </>
                    ) : (
                      <>
                        {/* Archive */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            archiveItem(item.id);
                          }}
                          title="Archive"
                          className="p-1.5 rounded-lg hover:bg-[#ebe7dc] hover:text-[#171711] transition-colors cursor-pointer"
                        >
                          <Archive className="w-3.5 h-3.5" />
                        </button>

                        {/* Delete */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            deleteItem(item.id);
                          }}
                          title="Delete"
                          className="p-1.5 rounded-lg hover:bg-rose-100 hover:text-rose-600 transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>

                        {/* Add to Collection */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setCollectionModalItem(item);
                          }}
                          title="Add to collection"
                          className="p-1.5 rounded-lg hover:bg-[#ebe7dc] hover:text-[#171711] transition-colors cursor-pointer"
                        >
                          <FolderPlus className="w-3.5 h-3.5" />
                        </button>
                      </>
                    )}

                    {/* Snooze / Reschedule */}
                    <div className="relative">
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          snoozeTriggerRef.current = e.currentTarget;
                          setBulkSnoozeOpen(false);
                          setSnoozeMenuForId(snoozeMenuForId === item.id ? null : item.id);
                        }}
                        title="Snooze"
                        className="p-1.5 rounded-lg hover:bg-[#ebe7dc] hover:text-[#171711] transition-colors cursor-pointer"
                      >
                        <Clock className="w-3.5 h-3.5" />
                      </button>

                      {snoozeMenuForId === item.id && (
                        <PortalMenu open={snoozeMenuForId === item.id} onClose={() => setSnoozeMenuForId(null)} triggerRef={snoozeTriggerRef} width={224}>
                          <div className="px-3 py-1 text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider">
                            Snooze until
                          </div>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'oneHour')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>In 1 hour</span>
                            <span className="text-[#9e9b92]">+1 hr</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'tomorrow')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>After 1 day</span>
                            <span className="text-[#9e9b92]">Tomorrow</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'oneWeek')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>A week</span>
                            <span className="text-[#9e9b92]">+7 days</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'oneMonth')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>A month</span>
                            <span className="text-[#9e9b92]">+1 mo</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'someday')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>Someday</span>
                            <span className="text-[#9e9b92]">Vault</span>
                          </button>
                          <div className="px-3 pt-2 pb-1 border-t border-[#e4e0d5] mt-1">
                            <div className="text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider mb-1">
                              Exact date & time
                            </div>
                            <button type="button" onClick={() => {
                              setExactSchedule({ ids: [item.id], initialValue: item.return_at });
                              setSnoozeMenuForId(null);
                            }} className="w-full rounded-lg bg-[#f7f5ee] px-3 py-2 text-left text-xs font-semibold hover:bg-[#ebe7dc]">
                              Choose date & time…
                            </button>
                          </div>
                        </PortalMenu>
                      )}
                    </div>

                    {/* External Link */}
                    {item.url && (
                      <a
                        href={item.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        onClick={(e) => e.stopPropagation()}
                        title="Open external link"
                        className="p-1.5 rounded-lg hover:bg-[#ebe7dc] hover:text-[#171711] transition-colors cursor-pointer"
                      >
                        <ExternalLink className="w-3.5 h-3.5" />
                      </a>
                    )}
                  </div>

                  {/* Date Time (Visible when NOT hovered) */}
                  <span
                    title={'Saved ' + formatEmailDate(item.created_at)}
                    className="group-hover:hidden text-[11px] sm:text-xs font-semibold text-[#171711] sm:text-[#6c6b63] tabular-nums bg-white/75 backdrop-blur-xs px-2 py-0.5 rounded-md border border-[#e4e0d5]/40 shadow-2xs"
                  >
                    {formatInboxAge(item, now) ?? formatEmailDate(item.created_at)}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Add To Collection Modal */}
      {exactSchedule && (
        <ExactScheduleModal
          count={exactSchedule.ids.length}
          initialValue={exactSchedule.initialValue}
          onClose={() => setExactSchedule(null)}
          onConfirm={async iso => {
            for (const id of exactSchedule.ids) await reschedule(id, iso);
            if (exactSchedule.source !== 'detail') setSelectedIds(new Set());
            setExactSchedule(null);
          }}
        />
      )}
      {collectionModalItem && (
        <AddToCollectionModal
          item={collectionModalItem}
          isOpen={Boolean(collectionModalItem)}
          onClose={() => setCollectionModalItem(null)}
        />
      )}
    </div>
  );
}
