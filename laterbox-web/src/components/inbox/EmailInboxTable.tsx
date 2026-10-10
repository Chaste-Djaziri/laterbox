'use client';

import React, { useState, useMemo, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LaterBoxItem } from '@/lib/supabase/types';
import { useItems } from '@/lib/store/ItemContext';
import { resolveReturnPreset, ReturnPreset } from '@/lib/utils/schedule';
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
} from 'lucide-react';
import {
  InboxSearchFilters,
  DEFAULT_SEARCH_FILTERS,
  formatEmailDate,
  getEmailSender,
  itemMatchesFilters,
  itemMatchesQuery,
} from '@/lib/utils/emailFormatters';

interface EmailInboxTableProps {
  items: LaterBoxItem[];
  onOpenCapture: () => void;
  searchQuery?: string;
  isSearchSubmitted?: boolean;
  searchFilters?: InboxSearchFilters;
  onUpdateFilters?: (updater: (prev: InboxSearchFilters) => InboxSearchFilters) => void;
  onClearSearch?: () => void;
}

type TabKey = 'primary' | 'articles' | 'media' | 'updates';

export function EmailInboxTable({
  items,
  onOpenCapture,
  searchQuery = '',
  isSearchSubmitted = false,
  searchFilters,
  onUpdateFilters,
  onClearSearch,
}: EmailInboxTableProps) {
  const router = useRouter();
  const { setFavorite, archiveItem, deleteItem, reschedule, syncNow, now, syncStatus } = useItems();

  const [activeTab, setActiveTab] = useState<TabKey>('primary');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [page, setPage] = useState(1);
  const pageSize = 50;
  const [sortOrder, setSortOrder] = useState<'latest' | 'oldest'>('latest');

  // Local fallback filters if not provided by parent
  const [localFilters, setLocalFilters] = useState<InboxSearchFilters>(DEFAULT_SEARCH_FILTERS);
  const filters = searchFilters || localFilters;
  const updateFilters = onUpdateFilters || setLocalFilters;

  // Menus state
  const [selectMenuOpen, setSelectMenuOpen] = useState(false);
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [snoozeMenuForId, setSnoozeMenuForId] = useState<string | null>(null);
  const [bulkSnoozeOpen, setBulkSnoozeOpen] = useState(false);
  const [filterMenuOpen, setFilterMenuOpen] = useState<'format' | 'date' | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const selectMenuRef = useRef<HTMLDivElement>(null);
  const moreMenuRef = useRef<HTMLDivElement>(null);
  const snoozeMenuRef = useRef<HTMLDivElement>(null);
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
      if (snoozeMenuRef.current && !snoozeMenuRef.current.contains(target)) {
        setSnoozeMenuForId(null);
        setBulkSnoozeOpen(false);
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
    <div className="bg-white border border-[#e4e0d5] rounded-2xl shadow-2xs overflow-hidden flex flex-col">
      {/* ===================================================================== */}
      {/* TOP TOOLBAR: Controls, Batch Actions, Pagination */}
      {/* ===================================================================== */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-[#e4e0d5] bg-white text-[#6c6b63] text-xs min-h-[46px] select-none">
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

              <div className="relative" ref={snoozeMenuRef}>
                <button
                  type="button"
                  onClick={() => setBulkSnoozeOpen(!bulkSnoozeOpen)}
                  title="Snooze selected"
                  className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                >
                  <Clock className="w-4 h-4" />
                </button>

                {bulkSnoozeOpen && (
                  <div className="absolute left-0 top-full mt-1 w-48 bg-white border border-[#e4e0d5] rounded-xl shadow-lg py-1.5 z-40 text-xs text-[#171711]">
                    <div className="px-3 py-1 text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider">
                      Snooze until
                    </div>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('laterToday')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>Later today</span>
                      <span className="text-[#9e9b92]">+3 hrs</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('tomorrow')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>Tomorrow</span>
                      <span className="text-[#9e9b92]">9:00 AM</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('weekend')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>This weekend</span>
                      <span className="text-[#9e9b92]">Sat 9 AM</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleBulkPreset('someday')}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                    >
                      <span>Someday</span>
                      <span className="text-[#9e9b92]">Vault</span>
                    </button>
                  </div>
                )}
              </div>
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

      {/* ===================================================================== */}
      {/* FILTER BAR / CATEGORY TABS */}
      {/* ===================================================================== */}
      {isSearchActive ? (
        /* SEARCH FILTER PILLS BAR (Image 1 style) */
        <div className="flex flex-wrap items-center justify-between gap-2 px-3 sm:px-4 py-2.5 border-b border-[#e4e0d5] bg-[#faf8f5]/60 text-xs">
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
                <div className="absolute left-0 top-full mt-1 w-40 bg-white border border-[#e4e0d5] rounded-xl shadow-lg py-1 z-50 text-xs text-[#171711]">
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
                <div className="absolute left-0 top-full mt-1 w-40 bg-white border border-[#e4e0d5] rounded-xl shadow-lg py-1 z-50 text-xs text-[#171711]">
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
        <div className="flex items-center border-b border-[#e4e0d5] bg-white overflow-x-auto scrollbar-none">
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
      )}

      {/* ===================================================================== */}
      {/* EMAIL LIST ROWS */}
      {/* ===================================================================== */}
      {pagedItems.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 px-4 text-center space-y-3">
          <div className="w-12 h-12 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
            {isSearchActive ? <Search className="w-6 h-6 stroke-[1.5]" /> : <Mail className="w-6 h-6 stroke-[1.5]" />}
          </div>
          <div>
            <h3 className="text-sm font-bold text-[#171711]">
              {isSearchActive
                ? `No results match "${searchQuery}"`
                : searchQuery
                ? 'No items match your search'
                : `Your ${activeTab} inbox is clear`}
            </h3>
            <p className="text-xs text-[#8e8d87] max-w-sm mx-auto mt-0.5">
              {isSearchActive
                ? 'Try adjusting your filters or searching for different keywords.'
                : searchQuery
                ? 'Try a different keyword or clear the search filter.'
                : 'Items captured or scheduled for this category will appear here.'}
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
          ) : (
            <button
              type="button"
              onClick={onOpenCapture}
              className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#171711] hover:bg-black text-white text-xs font-bold shadow-xs transition-all cursor-pointer mt-2"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Save item to inbox</span>
            </button>
          )}
        </div>
      ) : (
        <div className="divide-y divide-[#f0ede4]">
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
                onClick={() => router.push(`/item/${item.id}`)}
                className={`group relative flex items-center gap-2.5 sm:gap-3 px-3 sm:px-4 py-2.5 transition-colors cursor-pointer select-none overflow-hidden ${
                  isSelected
                    ? 'bg-[#f5f8df] hover:bg-[#eef3d0]'
                    : 'bg-white hover:bg-[#faf8f5]'
                }`}
              >
                {/* Anime-card style right-aligned fading OG image watermark */}
                {item.metadata?.preview_image_url && (
                  <div className="absolute right-0 top-0 bottom-0 w-48 sm:w-72 md:w-96 pointer-events-none overflow-hidden select-none z-0">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={item.metadata.preview_image_url}
                      alt=""
                      className="w-full h-full object-cover object-right opacity-65 group-hover:opacity-85 transition-opacity duration-300"
                      style={{
                        maskImage: 'linear-gradient(to left, rgba(0,0,0,1) 0%, rgba(0,0,0,0.85) 35%, rgba(0,0,0,0.4) 65%, rgba(0,0,0,0) 100%)',
                        WebkitMaskImage: 'linear-gradient(to left, rgba(0,0,0,1) 0%, rgba(0,0,0,0.85) 35%, rgba(0,0,0,0.4) 65%, rgba(0,0,0,0) 100%)',
                      }}
                      onError={(e) => {
                        (e.currentTarget as HTMLElement).style.display = 'none';
                      }}
                    />
                    <div className="absolute inset-0 bg-gradient-to-r from-white/95 via-transparent to-transparent group-hover:from-[#faf8f5]/95 pointer-events-none" />
                  </div>
                )}

                {/* 1. Checkbox */}
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
                </div>

                {/* 5. Right Actions & Timestamp */}
                <div className="shrink-0 flex items-center justify-end min-w-[90px] sm:min-w-[130px] text-right relative z-10">
                  {/* Quick Action Icons visible on Hover */}
                  <div className="hidden group-hover:flex items-center gap-1 text-[#6c6b63] bg-white/90 backdrop-blur-xs px-1.5 py-0.5 rounded-lg border border-[#e4e0d5]/60 shadow-2xs">
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

                    {/* Snooze / Reschedule */}
                    <div className="relative">
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setSnoozeMenuForId(snoozeMenuForId === item.id ? null : item.id);
                        }}
                        title="Snooze"
                        className="p-1.5 rounded-lg hover:bg-[#ebe7dc] hover:text-[#171711] transition-colors cursor-pointer"
                      >
                        <Clock className="w-3.5 h-3.5" />
                      </button>

                      {snoozeMenuForId === item.id && (
                        <div
                          onClick={(e) => e.stopPropagation()}
                          className="absolute right-0 top-full mt-1 w-44 bg-white border border-[#e4e0d5] rounded-xl shadow-lg py-1.5 z-40 text-xs text-[#171711] text-left"
                        >
                          <div className="px-3 py-1 text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider">
                            Snooze until
                          </div>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'laterToday')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>Later today</span>
                            <span className="text-[#9e9b92]">+3 hrs</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'tomorrow')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>Tomorrow</span>
                            <span className="text-[#9e9b92]">9:00 AM</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'weekend')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>This weekend</span>
                            <span className="text-[#9e9b92]">Sat 9 AM</span>
                          </button>
                          <button
                            type="button"
                            onClick={() => handleApplyPreset(item.id, 'someday')}
                            className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer flex justify-between"
                          >
                            <span>Someday</span>
                            <span className="text-[#9e9b92]">Vault</span>
                          </button>
                        </div>
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
                  <span className="group-hover:hidden text-[11px] sm:text-xs font-semibold text-[#171711] sm:text-[#6c6b63] tabular-nums bg-white/75 backdrop-blur-xs px-2 py-0.5 rounded-md border border-[#e4e0d5]/40 shadow-2xs">
                    {formatEmailDate(item.created_at)}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
