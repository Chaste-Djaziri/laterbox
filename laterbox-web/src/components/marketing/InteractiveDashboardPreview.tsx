// laterbox-web/src/components/marketing/InteractiveDashboardPreview.tsx
'use client';

import React, { useEffect, useId, useMemo, useRef, useState, type FormEvent } from 'react';
import {
  Archive,
  ArrowRight,
  ArrowUpDown,
  Bookmark,
  Calendar,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Clock,
  Clock3,
  ExternalLink,
  Eye,
  FileText,
  FolderOpen,
  Inbox,
  Link2,
  LucideIcon,
  MoreVertical,
  Paperclip,
  Plus,
  RefreshCw,
  RotateCcw,
  Search,
  Sparkles,
  Star,
  Tag,
  Trash2,
  Video,
  X,
} from 'lucide-react';
import {
  changeDemoItem,
  DEMO_ITEMS,
  demoCount,
  demoVisibleItems,
  makeDemoItem,
  type DemoBucket,
  type DemoCollection,
  type DemoItem,
  type DemoView,
} from './dashboard-preview-model';

type PendingBucket = Exclude<DemoBucket, 'done'>;
type CategoryTab = 'primary' | 'articles' | 'media' | 'updates';

interface SidebarNavItem {
  view: DemoView;
  label: string;
  icon: LucideIcon;
  countKey?: DemoView;
}

const sidebarNav: SidebarNavItem[] = [
  { view: 'inbox', label: 'Inbox', icon: Inbox, countKey: 'inbox' },
  { view: 'today', label: 'Today', icon: Clock3, countKey: 'today' },
  { view: 'upcoming', label: 'Upcoming', icon: Calendar, countKey: 'upcoming' },
  { view: 'someday', label: 'Someday', icon: Archive, countKey: 'someday' },
  { view: 'starred', label: 'Starred', icon: Star, countKey: 'starred' },
  { view: 'done', label: 'Completed', icon: CheckCircle2, countKey: 'done' },
];

function copySeedItems(): DemoItem[] {
  return DEMO_ITEMS.map((item) => ({ ...item }));
}

export function InteractiveDashboardPreview({
  id,
  className = '',
}: {
  id?: string;
  className?: string;
}) {
  const [items, setItems] = useState<DemoItem[]>(copySeedItems);
  const [view, setView] = useState<DemoView>('inbox');
  const [activeCategoryTab, setActiveCategoryTab] = useState<CategoryTab>('primary');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [selectedDetailItem, setSelectedDetailItem] = useState<DemoItem | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [sortOrder, setSortOrder] = useState<'latest' | 'oldest'>('latest');

  // Quick save modal state
  const [captureOpen, setCaptureOpen] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newUrl, setNewUrl] = useState('');
  const [newBucket, setNewBucket] = useState<PendingBucket>('inbox');
  const [inputError, setInputError] = useState('');
  const [toastMessage, setToastMessage] = useState('');

  // Dropdown states
  const [selectMenuOpen, setSelectMenuOpen] = useState(false);
  const [snoozeMenuForId, setSnoozeMenuForId] = useState<string | null>(null);

  const searchInputRef = useRef<HTMLInputElement>(null);
  const nextItemId = useRef(100);

  // Filter items based on view, category tab, and search query
  const visibleItems = useMemo(() => {
    let result = demoVisibleItems(items, view, searchQuery);

    // If no search query and in inbox view, apply category tabs
    if (!searchQuery.trim() && view === 'inbox') {
      result = result.filter((item) => {
        if (activeCategoryTab === 'primary') return !item.categoryTab || item.categoryTab === 'primary';
        return item.categoryTab === activeCategoryTab;
      });
    }

    if (sortOrder === 'oldest') {
      return [...result].reverse();
    }
    return result;
  }, [items, view, activeCategoryTab, searchQuery, sortOrder]);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage('');
    }, 3200);
  };

  const handleRefresh = () => {
    setIsRefreshing(true);
    setTimeout(() => {
      setIsRefreshing(false);
      showToast('Dashboard synced with local library');
    }, 600);
  };

  const resetDemo = () => {
    setItems(copySeedItems());
    setView('inbox');
    setActiveCategoryTab('primary');
    setSearchQuery('');
    setSelectedIds(new Set());
    setSelectedDetailItem(null);
    showToast('Reset to sample library');
  };

  const handleToggleStar = (id: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setItems((prev) => changeDemoItem(prev, { type: 'star', id }));
    const target = items.find((i) => i.id === id);
    showToast(target?.starred ? 'Removed from starred' : 'Starred item');
  };

  const handleToggleComplete = (id: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setItems((prev) => changeDemoItem(prev, { type: 'complete', id }));
    const target = items.find((i) => i.id === id);
    showToast(target?.bucket === 'done' ? 'Moved back to inbox' : 'Completed and archived');
  };

  const handleSnooze = (id: string, bucket: PendingBucket, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setItems((prev) => changeDemoItem(prev, { type: 'move', id, bucket }));
    setSnoozeMenuForId(null);
    showToast(
      bucket === 'today'
        ? 'Scheduled for Today'
        : bucket === 'upcoming'
        ? 'Scheduled for Tomorrow'
        : 'Moved to Someday Vault'
    );
  };

  const handleDeleteItem = (id: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setItems((prev) => changeDemoItem(prev, { type: 'delete', id }));
    if (selectedDetailItem?.id === id) {
      setSelectedDetailItem(null);
    }
    showToast('Item deleted from demo');
  };

  const toggleSelectRow = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleSelectAll = () => {
    if (selectedIds.size === visibleItems.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(visibleItems.map((i) => i.id)));
    }
  };

  const handleSaveItem = (e: FormEvent) => {
    e.preventDefault();
    setInputError('');

    if (!newTitle.trim()) {
      setInputError('Please enter a title');
      return;
    }

    const urlToUse = newUrl.trim()
      ? newUrl.trim().startsWith('http')
        ? newUrl.trim()
        : `https://${newUrl.trim()}`
      : 'https://laterbox.dev';

    const created = makeDemoItem(`custom-${nextItemId.current++}`, urlToUse, newTitle.trim(), newBucket);
    if (!created) {
      setInputError('Please enter a valid URL');
      return;
    }

    setItems((prev) => [created, ...prev]);
    setCaptureOpen(false);
    setNewTitle('');
    setNewUrl('');
    setNewBucket('inbox');
    showToast('Saved to Inbox (Interactive demo)');
  };

  // Category Tab Counts
  const tabCounts = useMemo(() => {
    const inboxItems = items.filter((i) => i.bucket === 'inbox');
    return {
      primary: inboxItems.filter((i) => !i.categoryTab || i.categoryTab === 'primary').length,
      articles: inboxItems.filter((i) => i.categoryTab === 'articles').length,
      media: inboxItems.filter((i) => i.categoryTab === 'media').length,
      updates: inboxItems.filter((i) => i.categoryTab === 'updates').length,
    };
  }, [items]);

  const allSelected = visibleItems.length > 0 && selectedIds.size === visibleItems.length;
  const someSelected = selectedIds.size > 0 && !allSelected;

  return (
    <section
      id={id}
      aria-label="Interactive LaterBox dashboard demo"
      className={`relative min-w-0 overflow-hidden rounded-[26px] sm:rounded-[30px] border border-[#dedfd4] bg-white text-left text-[#192018] shadow-[0_25px_80px_rgba(24,27,20,0.14)] ${className}`}
    >
      {/* ===================================================================== */}
      {/* MAC-STYLE APP WINDOW HEADER & OMNIBAR SEARCH */}
      {/* ===================================================================== */}
      <div className="flex min-h-[50px] items-center justify-between gap-3 border-b border-[#e5e4dc] bg-[#f7f6f0] px-4 py-2 sm:px-5 select-none">
        {/* Left macOS Window Controls */}
        <div className="flex shrink-0 items-center gap-2" aria-hidden="true">
          <span className="h-3 w-3 rounded-full bg-[#ff5f56] border border-[#e0443e]/40 shadow-2xs" />
          <span className="h-3 w-3 rounded-full bg-[#ffbd2e] border border-[#dea123]/40 shadow-2xs" />
          <span className="h-3 w-3 rounded-full bg-[#27c93f] border border-[#1aab29]/40 shadow-2xs" />
        </div>

        {/* Center Omnibar Search Bar */}
        <div className="flex-1 max-w-lg mx-2 sm:mx-6">
          <div className="relative flex items-center w-full">
            <Search className="absolute left-3 w-3.5 h-3.5 text-[#8c8a80] pointer-events-none" />
            <input
              ref={searchInputRef}
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search in LaterBox or type command..."
              className="w-full h-8 pl-8 pr-16 rounded-full bg-white border border-[#dedad0] text-xs text-[#171711] placeholder-[#8c8a80] focus:outline-none focus:border-[#171711] focus:ring-1 focus:ring-[#171711] shadow-2xs transition-all"
            />
            {searchQuery ? (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="absolute right-2.5 p-0.5 rounded-full hover:bg-[#ece8df] text-[#8c8a80] hover:text-[#171711]"
              >
                <X className="w-3 h-3" />
              </button>
            ) : (
              <span className="absolute right-2.5 px-1.5 py-0.5 rounded text-[10px] font-mono font-semibold bg-[#f0ede4] text-[#8c8a80] border border-[#e2ded4] pointer-events-none">
                ⌘K
              </span>
            )}
          </div>
        </div>

        {/* Right Action Icons & Status Pill */}
        <div className="flex items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={() => showToast('AI Organize analyzed and grouped your inbox items')}
            className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#e6edb0] border border-[#d2df88] text-[#171711] text-[11px] font-extrabold hover:bg-[#dbe69b] shadow-2xs transition-all cursor-pointer"
          >
            <Sparkles className="w-3 h-3 text-[#171711]" />
            <span>AI Organize</span>
          </button>

          <button
            type="button"
            onClick={resetDemo}
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-bold text-[#606c54] hover:bg-[#ece8df] hover:text-[#171711] transition-colors cursor-pointer"
            title="Reset sample demo"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span className="hidden md:inline">Reset</span>
          </button>

          {/* User profile avatar badge */}
          <div className="flex items-center gap-1.5 pl-1.5 border-l border-[#dedad0]">
            <div className="w-6 h-6 rounded-full bg-[#171711] text-[#e6edb0] text-[10px] font-black flex items-center justify-center select-none shadow-2xs">
              LB
            </div>
            <span className="text-[11px] font-bold text-[#6c6b63] hidden lg:inline">
              Guest Sandbox
            </span>
          </div>
        </div>
      </div>

      {/* ===================================================================== */}
      {/* MAIN LAYOUT: SIDEBAR RAIL + EMAIL INBOX TABLE */}
      {/* ===================================================================== */}
      <div className="flex min-h-[580px] sm:min-h-[640px] flex-col md:flex-row bg-[#faf8f5]">
        {/* Left App Sidebar Rail */}
        <aside
          aria-label="Dashboard sidebar"
          className="w-full md:w-[76px] lg:w-[84px] shrink-0 border-b md:border-b-0 md:border-r border-[#e5e4dc] bg-[#f7f6f0] flex md:flex-col items-center justify-between p-2 md:py-4 select-none z-20"
        >
          {/* Top Brand Cube + Quick Save button */}
          <div className="flex md:flex-col items-center gap-3 w-full">
            <span
              role="img"
              aria-label="LaterBox"
              className="flex h-10 w-10 md:h-12 md:w-12 items-center justify-center rounded-2xl bg-[#e6edb0] border border-[#d2df88] text-[#171711] shadow-2xs"
            >
              <Bookmark className="h-5 w-5 md:h-6 md:w-6" strokeWidth={2.4} />
            </span>

            {/* + Save Item Button */}
            <button
              type="button"
              onClick={() => setCaptureOpen(true)}
              title="Quick save new link or idea"
              className="group flex h-10 w-10 md:h-12 md:w-12 items-center justify-center rounded-2xl bg-[#171711] hover:bg-[#2c2b26] text-[#e6edb0] shadow-sm transition-all duration-150 cursor-pointer"
            >
              <Plus className="h-5 w-5 md:h-6 md:w-6 group-hover:scale-110 transition-transform" strokeWidth={2.5} />
            </button>
          </div>

          {/* Navigation Rails */}
          <nav
            aria-label="Main sections"
            className="flex md:flex-col items-center justify-center gap-1 md:gap-1.5 my-1 md:my-6 overflow-x-auto scrollbar-none w-full"
          >
            {sidebarNav.map((item) => {
              const Icon = item.icon;
              const isActive = view === item.view;
              const count = item.countKey ? demoCount(items, item.countKey) : 0;

              return (
                <button
                  key={item.view}
                  type="button"
                  onClick={() => {
                    setView(item.view);
                    setSelectedDetailItem(null);
                  }}
                  className={`relative flex items-center justify-center h-10 w-10 md:h-12 md:w-12 rounded-2xl transition-all cursor-pointer group ${
                    isActive
                      ? 'bg-[#e6edb0] text-[#171711] shadow-2xs border border-[#d2df88]'
                      : 'text-[#6c6b63] hover:bg-white hover:text-[#171711]'
                  }`}
                  title={`${item.label} (${count})`}
                >
                  <Icon className="w-5 h-5" strokeWidth={isActive ? 2.5 : 2} />

                  {/* Badge count */}
                  {count > 0 && (
                    <span
                      className={`absolute -top-1 -right-1 px-1.5 min-w-4 h-4 rounded-full text-[9px] font-black flex items-center justify-center ${
                        isActive
                          ? 'bg-[#171711] text-[#e6edb0]'
                          : 'bg-[#dedad0] text-[#171711] group-hover:bg-[#171711] group-hover:text-white'
                      }`}
                    >
                      {count}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>

          {/* Bottom Sidebar Status Indicator */}
          <div className="hidden md:flex flex-col items-center gap-2 pt-2 border-t border-[#dedad0] w-full">
            <div className="flex items-center gap-1" title="Offline core ready · Cloud sync active">
              <span className="w-2 h-2 rounded-full bg-[#678144] animate-pulse" />
            </div>
            <span className="text-[9px] font-extrabold uppercase tracking-wider text-[#8c8a80]">
              Ready
            </span>
          </div>
        </aside>

        {/* ===================================================================== */}
        {/* EMAIL INBOX TABLE CONTAINER */}
        {/* ===================================================================== */}
        <div className="flex-1 flex flex-col min-w-0 min-h-0 bg-white overflow-hidden">
          {/* Table Action Toolbar */}
          <div className="shrink-0 flex items-center justify-between px-3 sm:px-4 py-2 border-b border-[#e5e4dc] bg-white text-xs text-[#6c6b63] min-h-[46px] select-none">
            {/* Left Controls: Select All, Refresh, Filter */}
            <div className="flex items-center gap-1 sm:gap-2">
              <div className="relative flex items-center">
                <input
                  type="checkbox"
                  checked={allSelected}
                  ref={(el) => {
                    if (el) el.indeterminate = someSelected;
                  }}
                  onChange={toggleSelectAll}
                  className="w-4 h-4 rounded border-[#dedad0] accent-[#171711] cursor-pointer"
                  title="Select all"
                />
                <button
                  type="button"
                  onClick={() => setSelectMenuOpen(!selectMenuOpen)}
                  className="p-1 text-[#8c8a80] hover:text-[#171711] transition-colors cursor-pointer"
                  title="Selection options"
                >
                  <ChevronDown className="w-3 h-3" />
                </button>

                {selectMenuOpen && (
                  <div className="absolute left-0 top-full mt-1 w-32 bg-white border border-[#dedad0] rounded-xl shadow-lg py-1 z-30 text-xs font-semibold text-[#171711] animate-in fade-in duration-100">
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedIds(new Set(visibleItems.map((i) => i.id)));
                        setSelectMenuOpen(false);
                      }}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                    >
                      All
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedIds(new Set());
                        setSelectMenuOpen(false);
                      }}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                    >
                      None
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedIds(new Set(visibleItems.filter((i) => i.starred).map((i) => i.id)));
                        setSelectMenuOpen(false);
                      }}
                      className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] cursor-pointer"
                    >
                      Starred
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
                <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
              </button>

              {/* Bulk Actions if items selected */}
              {selectedIds.size > 0 && (
                <div className="flex items-center gap-1.5 pl-2 border-l border-[#dedad0] animate-in fade-in duration-150">
                  <span className="text-[11px] font-bold text-[#171711]">
                    {selectedIds.size} selected
                  </span>
                  <button
                    type="button"
                    onClick={() => {
                      selectedIds.forEach((id) => handleToggleComplete(id));
                      setSelectedIds(new Set());
                    }}
                    className="px-2 py-0.5 rounded-md bg-[#faf8f5] hover:bg-[#171711] hover:text-white border border-[#dedad0] text-[10px] font-bold uppercase transition-colors"
                  >
                    Archive
                  </button>
                </div>
              )}
            </div>

            {/* Right Controls: Item Count & Sort Toggle */}
            <div className="flex items-center gap-2">
              <span className="text-[11px] font-bold text-[#8c8a80]">
                {visibleItems.length > 0 ? `1–${visibleItems.length} of ${visibleItems.length}` : '0 items'}
              </span>

              <div className="flex items-center gap-0.5">
                <button
                  type="button"
                  disabled
                  className="p-1 rounded-lg text-[#8c8a80] opacity-40 cursor-not-allowed"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  disabled
                  className="p-1 rounded-lg text-[#8c8a80] opacity-40 cursor-not-allowed"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>

              <button
                type="button"
                onClick={() => {
                  setSortOrder((prev) => (prev === 'latest' ? 'oldest' : 'latest'));
                  showToast(sortOrder === 'latest' ? 'Showing oldest first' : 'Showing newest first');
                }}
                title={sortOrder === 'latest' ? 'Showing newest first' : 'Showing oldest first'}
                className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
              >
                <ArrowUpDown className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          {/* ================================================================= */}
          {/* CATEGORY TABS (Primary / Articles / Media / Updates) */}
          {/* ================================================================= */}
          {!searchQuery.trim() && view === 'inbox' && (
            <div className="shrink-0 flex items-center border-b border-[#e5e4dc] bg-white overflow-x-auto scrollbar-none select-none">
              {/* Primary Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('primary')}
                className={`relative flex-1 min-w-[140px] sm:min-w-[180px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'primary' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'primary' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <Inbox className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className={`text-xs tracking-tight truncate ${activeCategoryTab === 'primary' ? 'font-black text-[#171711]' : 'font-bold text-[#6c6b63]'}`}>
                      Primary
                    </span>
                    {tabCounts.primary > 0 && (
                      <span className="px-1.5 py-0.2 rounded-full text-[9px] font-extrabold bg-[#e6edb0] text-[#171711]">
                        {tabCounts.primary} new
                      </span>
                    )}
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    Core saves &amp; urgent links
                  </p>
                </div>
              </button>

              {/* Articles Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('articles')}
                className={`relative flex-1 min-w-[140px] sm:min-w-[180px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'articles' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'articles' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <FileText className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className={`text-xs tracking-tight truncate ${activeCategoryTab === 'articles' ? 'font-black text-[#171711]' : 'font-bold text-[#6c6b63]'}`}>
                      Articles
                    </span>
                    {tabCounts.articles > 0 && (
                      <span className="px-1.5 py-0.2 rounded-full text-[9px] font-extrabold bg-[#efe8f7] text-[#6b4785]">
                        {tabCounts.articles} new
                      </span>
                    )}
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    Long reads &amp; newsletters
                  </p>
                </div>
              </button>

              {/* Media Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('media')}
                className={`relative flex-1 min-w-[140px] sm:min-w-[180px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'media' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'media' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <Video className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className={`text-xs tracking-tight truncate ${activeCategoryTab === 'media' ? 'font-black text-[#171711]' : 'font-bold text-[#6c6b63]'}`}>
                      Media
                    </span>
                    {tabCounts.media > 0 && (
                      <span className="px-1.5 py-0.2 rounded-full text-[9px] font-extrabold bg-[#e5eef4] text-[#345b78]">
                        {tabCounts.media} new
                      </span>
                    )}
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    Videos &amp; audio streams
                  </p>
                </div>
              </button>

              {/* Updates Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('updates')}
                className={`relative flex-1 min-w-[140px] sm:min-w-[180px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'updates' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'updates' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <Tag className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className={`text-xs tracking-tight truncate ${activeCategoryTab === 'updates' ? 'font-black text-[#171711]' : 'font-bold text-[#6c6b63]'}`}>
                      Updates
                    </span>
                    {tabCounts.updates > 0 && (
                      <span className="px-1.5 py-0.2 rounded-full text-[9px] font-extrabold bg-[#f6e7e0] text-[#935235]">
                        {tabCounts.updates}
                      </span>
                    )}
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    Notes, tasks &amp; receipts
                  </p>
                </div>
              </button>
            </div>
          )}

          {/* Search Active Filter Pills */}
          {searchQuery.trim() && (
            <div className="shrink-0 flex items-center justify-between px-4 py-2 border-b border-[#e5e4dc] bg-[#faf8f5] text-xs">
              <div className="flex items-center gap-2">
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#171711] text-[#e6edb0]">
                  <Search className="w-3 h-3" />
                  <span>Results for &ldquo;{searchQuery}&rdquo;</span>
                </span>
                <span className="text-xs text-[#8c8a80]">
                  {visibleItems.length} {visibleItems.length === 1 ? 'match' : 'matches'} found
                </span>
              </div>
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="text-xs font-bold text-[#6c6b63] hover:text-[#171711] underline cursor-pointer"
              >
                Clear search
              </button>
            </div>
          )}

          {/* ================================================================= */}
          {/* EMAIL TABLE ROWS */}
          {/* ================================================================= */}
          <div className="flex-1 overflow-y-auto divide-y divide-[#e5e4dc] bg-white">
            {visibleItems.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-20 px-4 text-center space-y-3">
                <div className="w-12 h-12 rounded-2xl bg-[#faf8f5] border border-[#dedad0] flex items-center justify-center text-[#8c8a80]">
                  <Inbox className="w-6 h-6" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-[#171711]">No items here</h4>
                  <p className="text-xs text-[#8c8a80] mt-1 max-w-xs">
                    Try switching tabs, clearing search, or clicking &ldquo;+ Save&rdquo; to add something new.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={resetDemo}
                  className="px-3.5 py-1.5 rounded-full bg-[#171711] text-white text-xs font-bold hover:bg-[#2e2d26] transition-colors"
                >
                  Reset Sample Library
                </button>
              </div>
            ) : (
              visibleItems.map((item) => {
                const isSelected = selectedIds.has(item.id);
                const isExpanded = selectedDetailItem?.id === item.id;

                return (
                  <div
                    key={item.id}
                    onClick={() => setSelectedDetailItem(isExpanded ? null : item)}
                    className={`group relative flex items-center gap-2 sm:gap-3.5 px-3 sm:px-4 py-3 sm:py-3.5 transition-all duration-150 cursor-pointer ${
                      isSelected
                        ? 'bg-[#f4f7ea]'
                        : isExpanded
                        ? 'bg-[#faf8f5] shadow-xs'
                        : 'hover:bg-[#faf8f5]'
                    }`}
                  >
                    {/* Select Checkbox */}
                    <div className="shrink-0 flex items-center" onClick={(e) => toggleSelectRow(item.id, e)}>
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => {}}
                        className="w-4 h-4 rounded border-[#dedad0] accent-[#171711] cursor-pointer"
                      />
                    </div>

                    {/* Star Toggle Button */}
                    <button
                      type="button"
                      onClick={(e) => handleToggleStar(item.id, e)}
                      title={item.starred ? 'Unstar item' : 'Star item'}
                      className="shrink-0 p-1 rounded-md text-[#8c8a80] hover:text-amber-500 transition-colors"
                    >
                      <Star
                        className={`w-4 h-4 ${
                          item.starred ? 'fill-amber-400 text-amber-500' : 'hover:fill-amber-200'
                        }`}
                      />
                    </button>

                    {/* Sender / Source domain pill */}
                    <div className="w-24 sm:w-32 shrink-0 truncate">
                      <span className="text-xs font-bold text-[#171711] truncate block">
                        {item.senderName || item.source}
                      </span>
                    </div>

                    {/* Title & Preview Snippet */}
                    <div className="flex-1 min-w-0 flex items-center gap-2">
                      <span className="text-xs sm:text-[13px] font-bold text-[#171711] truncate">
                        {item.title}
                      </span>
                      {item.snippet && (
                        <span className="text-xs text-[#8c8a80] truncate hidden md:inline">
                          — {item.snippet}
                        </span>
                      )}
                    </div>

                    {/* Collection / Category Badge */}
                    {item.collection && (
                      <span className="shrink-0 hidden lg:inline-block px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#faf8f5] border border-[#dedad0] text-[#6c6b63]">
                        {item.collection}
                      </span>
                    )}

                    {/* Attachment Icon */}
                    {item.hasAttachment && (
                      <span className="shrink-0 text-[#8c8a80]" title="Has attachment">
                        <Paperclip className="w-3.5 h-3.5" />
                      </span>
                    )}

                    {/* Scheduled / Return Time Badge */}
                    <div className="shrink-0 text-right w-20 sm:w-28">
                      <span className="text-[11px] font-bold text-[#6c6b63] whitespace-nowrap">
                        {item.scheduledLabel || item.timeLabel || 'Inbox'}
                      </span>
                    </div>

                    {/* Hover Quick Action Buttons */}
                    <div className="absolute right-3 top-1/2 -translate-y-1/2 hidden group-hover:flex items-center gap-1 bg-white/95 backdrop-blur-xs px-1.5 py-1 rounded-xl border border-[#dedad0] shadow-sm z-10">
                      {/* Complete / Keep */}
                      <button
                        type="button"
                        onClick={(e) => handleToggleComplete(item.id, e)}
                        title={item.bucket === 'done' ? 'Move back to inbox' : 'Mark completed & archive'}
                        className="p-1.5 rounded-lg hover:bg-[#e6edb0] text-[#171711] transition-colors"
                      >
                        <Check className="w-3.5 h-3.5" />
                      </button>

                      {/* Snooze Dropdown */}
                      <div className="relative">
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setSnoozeMenuForId(snoozeMenuForId === item.id ? null : item.id);
                          }}
                          title="Snooze / Reschedule"
                          className="p-1.5 rounded-lg hover:bg-[#e6edb0] text-[#171711] transition-colors"
                        >
                          <Clock className="w-3.5 h-3.5" />
                        </button>

                        {snoozeMenuForId === item.id && (
                          <div
                            onClick={(e) => e.stopPropagation()}
                            className="absolute right-0 top-full mt-1 w-36 bg-white border border-[#dedad0] rounded-xl shadow-xl py-1 z-50 text-xs font-semibold text-[#171711] animate-in fade-in duration-100"
                          >
                            <div className="px-3 py-1 text-[10px] font-bold text-[#8c8a80] uppercase tracking-wider">
                              Return when
                            </div>
                            <button
                              type="button"
                              onClick={(e) => handleSnooze(item.id, 'today', e)}
                              className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] flex justify-between"
                            >
                              <span>Today</span>
                              <span className="text-[#8c8a80]">Evening</span>
                            </button>
                            <button
                              type="button"
                              onClick={(e) => handleSnooze(item.id, 'upcoming', e)}
                              className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] flex justify-between"
                            >
                              <span>Tomorrow</span>
                              <span className="text-[#8c8a80]">9:00 AM</span>
                            </button>
                            <button
                              type="button"
                              onClick={(e) => handleSnooze(item.id, 'someday', e)}
                              className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5] flex justify-between"
                            >
                              <span>Someday</span>
                              <span className="text-[#8c8a80]">Vault</span>
                            </button>
                          </div>
                        )}
                      </div>

                      {/* Open Link */}
                      <a
                        href={item.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        onClick={(e) => e.stopPropagation()}
                        title="Open external source"
                        className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors"
                      >
                        <ExternalLink className="w-3.5 h-3.5" />
                      </a>

                      {/* Delete */}
                      <button
                        type="button"
                        onClick={(e) => handleDeleteItem(item.id, e)}
                        title="Delete item"
                        className="p-1.5 rounded-lg hover:bg-red-50 text-[#8c8a80] hover:text-red-600 transition-colors"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* ================================================================= */}
          {/* SLIDE-UP ITEM DETAIL PREVIEW (When an item is clicked) */}
          {/* ================================================================= */}
          {selectedDetailItem && (
            <div className="shrink-0 p-4 border-t border-[#e5e4dc] bg-[#faf8f5] animate-in slide-in-from-bottom-2 duration-150">
              <div className="flex items-start justify-between gap-4">
                <div className="space-y-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-[10px] font-black uppercase tracking-wider text-[#6c6b63] px-2 py-0.5 rounded-full bg-white border border-[#dedad0]">
                      {selectedDetailItem.source}
                    </span>
                    <span className="text-xs text-[#8c8a80] font-semibold">
                      Scheduled: {selectedDetailItem.scheduledLabel || 'Inbox'}
                    </span>
                  </div>
                  <h4 className="text-sm font-black text-[#171711] tracking-tight">
                    {selectedDetailItem.title}
                  </h4>
                  <p className="text-xs text-[#6c6b63] leading-relaxed max-w-2xl">
                    {selectedDetailItem.snippet || 'No extra notes attached to this item.'}
                  </p>
                </div>

                <div className="flex items-center gap-2 shrink-0">
                  <button
                    type="button"
                    onClick={(e) => handleToggleComplete(selectedDetailItem.id, e)}
                    className="px-3 py-1.5 rounded-xl bg-[#171711] text-[#e6edb0] text-xs font-bold hover:bg-[#2e2d26] transition-colors flex items-center gap-1.5"
                  >
                    <Check className="w-3.5 h-3.5" />
                    <span>{selectedDetailItem.bucket === 'done' ? 'Reopen' : 'Archive'}</span>
                  </button>
                  <a
                    href={selectedDetailItem.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="px-3 py-1.5 rounded-xl bg-white border border-[#dedad0] text-[#171711] text-xs font-bold hover:bg-[#faf8f5] transition-colors flex items-center gap-1.5"
                  >
                    <span>Open link</span>
                    <ExternalLink className="w-3.5 h-3.5" />
                  </a>
                  <button
                    type="button"
                    onClick={() => setSelectedDetailItem(null)}
                    className="p-1.5 rounded-lg text-[#8c8a80] hover:text-[#171711] hover:bg-white transition-colors"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ===================================================================== */}
      {/* QUICK SAVE MODAL DIALOG */}
      {/* ===================================================================== */}
      {captureOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="absolute inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-2xs p-4 animate-in fade-in duration-150"
        >
          <div className="w-full max-w-md rounded-2xl sm:rounded-3xl bg-white border border-[#dedad0] p-6 shadow-2xl text-left space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-[#e6edb0] flex items-center justify-center text-[#171711]">
                  <Plus className="w-4 h-4" />
                </div>
                <h3 className="text-base font-black text-[#171711]">Quick Save Item</h3>
              </div>
              <button
                type="button"
                onClick={() => setCaptureOpen(false)}
                className="p-1 rounded-lg text-[#8c8a80] hover:text-[#171711]"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSaveItem} className="space-y-3.5">
              <div>
                <label className="block text-[11px] font-bold text-[#6c6b63] mb-1">
                  Title or Note
                </label>
                <input
                  type="text"
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="e.g. Read about React 19 Compiler"
                  autoFocus
                  className="w-full px-3.5 py-2.5 rounded-xl border border-[#dedad0] text-xs text-[#171711] focus:outline-none focus:border-[#171711]"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-[#6c6b63] mb-1">
                  URL or Source (optional)
                </label>
                <input
                  type="text"
                  value={newUrl}
                  onChange={(e) => setNewUrl(e.target.value)}
                  placeholder="e.g. https://react.dev/blog"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-[#dedad0] text-xs text-[#171711] focus:outline-none focus:border-[#171711]"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-[#6c6b63] mb-1.5">
                  When to return
                </label>
                <div className="grid grid-cols-4 gap-2">
                  {(
                    [
                      { key: 'inbox', label: 'Inbox' },
                      { key: 'today', label: 'Today' },
                      { key: 'upcoming', label: 'Tomorrow' },
                      { key: 'someday', label: 'Someday' },
                    ] as const
                  ).map((b) => (
                    <button
                      key={b.key}
                      type="button"
                      onClick={() => setNewBucket(b.key)}
                      className={`py-2 px-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                        newBucket === b.key
                          ? 'bg-[#171711] text-[#e6edb0] shadow-2xs'
                          : 'bg-[#faf8f5] border border-[#dedad0] text-[#6c6b63] hover:border-[#171711]'
                      }`}
                    >
                      {b.label}
                    </button>
                  ))}
                </div>
              </div>

              {inputError && (
                <p className="text-xs text-red-600 font-semibold">{inputError}</p>
              )}

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-[#e5e4dc]">
                <button
                  type="button"
                  onClick={() => setCaptureOpen(false)}
                  className="px-4 py-2 rounded-full text-xs font-bold text-[#6c6b63] hover:text-[#171711]"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-full bg-[#171711] hover:bg-[#2c2b26] text-white text-xs font-extrabold shadow-sm transition-all"
                >
                  Save to Demo
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ===================================================================== */}
      {/* ACTION FEEDBACK TOAST */}
      {/* ===================================================================== */}
      {toastMessage && (
        <div className="absolute bottom-4 right-4 z-50 px-4 py-2 rounded-full bg-[#171711] text-[#e6edb0] text-xs font-bold shadow-xl animate-in fade-in slide-in-from-bottom-2 duration-150 flex items-center gap-2">
          <span className="w-1.5 h-1.5 rounded-full bg-[#e6edb0]" />
          <span>{toastMessage}</span>
        </div>
      )}
    </section>
  );
}
