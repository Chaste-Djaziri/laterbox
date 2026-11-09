// laterbox-web/src/components/marketing/InteractiveDashboardPreview.tsx
'use client';

import React, { useMemo, useRef, useState, type FormEvent } from 'react';
import Image from 'next/image';
import {
  Archive,
  ArrowLeft,
  ArrowUpDown,
  BookOpen,
  CalendarClock,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Clock,
  Cloud,
  Compass,
  Copy,
  Crown,
  Download,
  ExternalLink,
  FileText,
  FolderOpen,
  FolderPlus,
  HelpCircle,
  Inbox,
  MessageSquare,
  MoreVertical,
  Play,
  Plus,
  RefreshCw,
  Search,
  Settings,
  Sparkles,
  Star,
  Tag,
  Trash2,
  Video,
  X,
} from 'lucide-react';

interface PreviewTag {
  label: string;
  icon?: 'video' | 'book';
  color?: 'red' | 'green' | 'amber' | 'slate';
}

interface RealPreviewItem {
  id: string;
  source: string;
  title: string;
  snippet: string;
  timeLabel: string;
  tags: PreviewTag[];
  starred: boolean;
  categoryTab: 'primary' | 'articles' | 'media' | 'updates';
  url: string;
  hasAttachment?: boolean;
}

const INITIAL_REAL_ITEMS: RealPreviewItem[] = [
  {
    id: 'item-01',
    source: 'disneyplus.com',
    title: 'Watch Miraculous: Tales Of Ladybug & Cat Noir | F...',
    snippet: 'Superheroes Ladybug and Cat Noir protect the city.',
    timeLabel: 'In Inbox for 15 hrs, 29 min',
    tags: [],
    starred: false,
    categoryTab: 'primary',
    url: 'https://disneyplus.com',
  },
  {
    id: 'item-02',
    source: 'facebook.com',
    title: '2M views • 48K reactions | Part 5 | Retro Film Rollin...',
    snippet: 'Part 5 | Retro Film Rolling Effect #capcut #capcutpioner...',
    timeLabel: 'In Inbox for 6 days, 9 hrs',
    tags: [
      { label: 'Video', icon: 'video', color: 'red' },
      { label: 'Reading', icon: 'book', color: 'green' },
    ],
    starred: false,
    categoryTab: 'media',
    url: 'https://facebook.com',
  },
  {
    id: 'item-03',
    source: 'facebook.com',
    title: '1.4M views • 27K reactions | Part 8 | Rolling Intro Ef...',
    snippet: 'Part 8 | Rolling Intro Effect #capcut #capcutpioner...',
    timeLabel: 'In Inbox for 19 hrs, 10 min',
    tags: [
      { label: 'Video', icon: 'video', color: 'red' },
      { label: 'Reading', icon: 'book', color: 'green' },
    ],
    starred: false,
    categoryTab: 'media',
    url: 'https://facebook.com',
  },
  {
    id: 'item-04',
    source: 'Instagram',
    title: 'Joshua J. Terrazas on Instagram: "Damn, she got m..."',
    snippet: '586K likes, 4,496 comments - joshuajterrazas on August 20, 2026...',
    timeLabel: 'In Inbox for 7 days, 3 hrs',
    tags: [],
    starred: false,
    categoryTab: 'primary',
    url: 'https://instagram.com',
  },
  {
    id: 'item-05',
    source: 'Threads',
    title: 'Jason Chen 陳以 (@jasondchen) on Threads - POV: he has an answer for everything',
    snippet: 'POV: he has an answer for everything @luseeyalu',
    timeLabel: 'In Inbox for 7 days, 21 hrs',
    tags: [{ label: 'Reading', icon: 'book', color: 'green' }],
    starred: false,
    categoryTab: 'articles',
    url: 'https://threads.net',
  },
  {
    id: 'item-06',
    source: 'Instagram',
    title: 'Zedois on Instagram: "Always so peak🔥"',
    snippet: '141K likes, 642 comments - zdoist on October 24, 2026...',
    timeLabel: 'In Inbox for 4 days, 21 hrs',
    tags: [],
    starred: true,
    categoryTab: 'primary',
    url: 'https://instagram.com',
  },
  {
    id: 'item-07',
    source: 'Instagram',
    title: 'Jaden Fong on Instagram: "!! Egg does NOT releas..."',
    snippet: 'jadenfong on September 25, 2026: "!! Egg does NOT release on day 1 !!"',
    timeLabel: 'In Inbox for 7 days, 2 hrs',
    tags: [],
    starred: false,
    categoryTab: 'primary',
    url: 'https://instagram.com',
  },
  {
    id: 'item-08',
    source: 'Instagram',
    title: 'PACIL on Instagram: "YOUTUBE SONGS YOU FORG..."',
    snippet: '9,797 likes, 205 comments - pacil.g on October 30, 2026...',
    timeLabel: 'In Inbox for 7 days, 3 hrs',
    tags: [],
    starred: false,
    categoryTab: 'primary',
    url: 'https://instagram.com',
  },
  {
    id: 'item-09',
    source: 'Instagram',
    title: 'KIZxIE on Instagram: "Psalm 104:33 \'I will sing to t...\'"',
    snippet: '22K likes, 288 comments - kizxiecore on August 9, 2026...',
    timeLabel: 'In Inbox for 7 days, 21 hrs',
    tags: [],
    starred: false,
    categoryTab: 'primary',
    url: 'https://instagram.com',
  },
  {
    id: 'item-10',
    source: 'Instagram',
    title: 'UXUI_COACH on Instagram: "Your design is good! ..."',
    snippet: '142K likes, 191 comments - uxui_shrut on October 27, 2026...',
    timeLabel: 'In Inbox for 7 days, 21 hrs',
    tags: [],
    starred: false,
    categoryTab: 'articles',
    url: 'https://instagram.com',
  },
  {
    id: 'item-11',
    source: 'Instagram',
    title: 'Billy Han on Instagram: "If I pause my anime for yo..."',
    snippet: '43K likes, 353 comments - billyhan_ on September 22, 2026...',
    timeLabel: 'In Inbox for 7 days, 21 hrs',
    tags: [],
    starred: false,
    categoryTab: 'primary',
    url: 'https://instagram.com',
  },
  {
    id: 'item-12',
    source: 'Instagram',
    title: 'Instagram - 199 likes, 169 comments - fianeedsajob...',
    snippet: 'is this the most gatekept side hustle of 2026??',
    timeLabel: 'Oct 21',
    tags: [{ label: 'Reading', icon: 'book', color: 'green' }],
    starred: false,
    categoryTab: 'articles',
    url: 'https://instagram.com',
  },
  {
    id: 'item-13',
    source: 'RADWIMPS • YouTube',
    title: 'RADWIMPS - すずめ feat.十明 [Official Lyric Video]',
    snippet: 'Enjoy the videos and music you love, upload original content...',
    timeLabel: 'Oct 17',
    tags: [
      { label: 'Video', icon: 'video', color: 'red' },
      { label: 'Watch Later', color: 'slate' },
    ],
    starred: false,
    categoryTab: 'media',
    url: 'https://youtube.com',
  },
  {
    id: 'item-14',
    source: 'Bill Gates',
    title: 'The choices we make about AI now are critical | Bill G...',
    snippet: 'Both of these experiences inform my perspective on artificial intelligence...',
    timeLabel: 'Oct 17',
    tags: [],
    starred: false,
    categoryTab: 'articles',
    url: 'https://gatesnotes.com',
  },
  {
    id: 'item-15',
    source: 'YouTube',
    title: 'POV: Scammers are TOO advanced #skit #funny #c...',
    snippet: 'Video by Nathan Doan Comedy on YouTube',
    timeLabel: 'In Inbox for 17 days, 3 hrs',
    tags: [
      { label: 'Video', icon: 'video', color: 'red' },
      { label: 'Entertainment', color: 'amber' },
    ],
    starred: false,
    categoryTab: 'media',
    url: 'https://youtube.com',
  },
  {
    id: 'item-16',
    source: 'YouTube',
    title: 'First 5 things to do when you get an iPad - Do this first when you get an iPad',
    snippet: '#ipad #ipadti...',
    timeLabel: 'Sep 14',
    tags: [
      { label: 'Video', icon: 'video', color: 'red' },
      { label: 'Watch Later', color: 'slate' },
      { label: 'Tech & Arch...', color: 'slate' },
    ],
    starred: false,
    categoryTab: 'media',
    url: 'https://youtube.com',
  },
  {
    id: 'item-17',
    source: 'YouTube',
    title: '【女性が歌う】小さな恋のうた/MONGOL800(Full Cov...',
    snippet: 'YouTube by kobasolo',
    timeLabel: 'In Inbox for 17 days, 3 hrs',
    tags: [
      { label: 'Video', icon: 'video', color: 'red' },
      { label: 'Watch Later', color: 'slate' },
    ],
    starred: false,
    categoryTab: 'media',
    url: 'https://youtube.com',
  },
  {
    id: 'item-18',
    source: 'kobasolo • YouTube',
    title: '【時かけ】変わらないもの/奥華子(Covered by コバソロ &...',
    snippet: 'https://www.youtube.com/watch?v=CmUfGOtidPw&l...',
    timeLabel: 'Aug 24',
    tags: [
      { label: 'Video', icon: 'video', color: 'red' },
      { label: 'Watch Later', color: 'slate' },
    ],
    starred: false,
    categoryTab: 'media',
    url: 'https://youtube.com',
  },
];

type ViewKey = 'inbox' | 'today' | 'upcoming' | 'someday' | 'starred' | 'kept' | 'archived' | 'trash';
type CategoryTab = 'primary' | 'articles' | 'media' | 'updates';

export function InteractiveDashboardPreview({
  id,
  className = '',
}: {
  id?: string;
  className?: string;
}) {
  const [items, setItems] = useState<RealPreviewItem[]>(INITIAL_REAL_ITEMS);
  const [activeView, setActiveView] = useState<ViewKey>('inbox');
  const [activeCategoryTab, setActiveCategoryTab] = useState<CategoryTab>('primary');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [hoveredRowId, setHoveredRowId] = useState<string | null>(null);
  const [selectedDetailItem, setSelectedDetailItem] = useState<RealPreviewItem | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [sortOrder, setSortOrder] = useState<'latest' | 'oldest'>('latest');

  // Quick Save Modal State
  const [captureOpen, setCaptureOpen] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newUrl, setNewUrl] = useState('');
  const [newSchedule, setNewSchedule] = useState<'inbox' | 'today' | 'upcoming' | 'someday'>('inbox');
  const [toastMessage, setToastMessage] = useState('');

  // Dropdown menus
  const [selectMenuOpen, setSelectMenuOpen] = useState(false);
  const [snoozeMenuForId, setSnoozeMenuForId] = useState<string | null>(null);

  const searchInputRef = useRef<HTMLInputElement>(null);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3000);
  };

  const handleRefresh = () => {
    setIsRefreshing(true);
    setTimeout(() => {
      setIsRefreshing(false);
      showToast('Dashboard synced with cloud');
    }, 600);
  };

  const toggleStar = (itemId: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setItems((prev) =>
      prev.map((item) => (item.id === itemId ? { ...item, starred: !item.starred } : item))
    );
    setSelectedDetailItem((prev) =>
      prev && prev.id === itemId ? { ...prev, starred: !prev.starred } : prev
    );
    const item = items.find((i) => i.id === itemId);
    showToast(item?.starred ? 'Removed from starred' : 'Starred item');
  };

  const toggleSelectRow = (itemId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(itemId)) next.delete(itemId);
      else next.add(itemId);
      return next;
    });
  };

  const toggleSelectAll = () => {
    if (selectedIds.size === filteredItems.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(filteredItems.map((i) => i.id)));
    }
  };

  const handleBulkArchive = () => {
    setItems((prev) => prev.filter((i) => !selectedIds.has(i.id)));
    showToast(`Archived ${selectedIds.size} item${selectedIds.size === 1 ? '' : 's'}`);
    setSelectedIds(new Set());
  };

  const handleBulkDelete = () => {
    setItems((prev) => prev.filter((i) => !selectedIds.has(i.id)));
    showToast(`Moved ${selectedIds.size} item${selectedIds.size === 1 ? '' : 's'} to trash`);
    setSelectedIds(new Set());
  };

  const handleBulkStar = () => {
    setItems((prev) =>
      prev.map((i) => (selectedIds.has(i.id) ? { ...i, starred: true } : i))
    );
    showToast(`Starred ${selectedIds.size} item${selectedIds.size === 1 ? '' : 's'}`);
    setSelectedIds(new Set());
  };

  const deleteItem = (itemId: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    setItems((prev) => prev.filter((i) => i.id !== itemId));
    if (selectedDetailItem?.id === itemId) setSelectedDetailItem(null);
    showToast('Moved to Recently Deleted');
  };

  const handleSaveItem = (e: FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;

    const newItem: RealPreviewItem = {
      id: `item-${Date.now()}`,
      source: newUrl.trim() ? new URL(newUrl.startsWith('http') ? newUrl : `https://${newUrl}`).hostname : 'Quick Save',
      title: newTitle.trim(),
      snippet: 'Saved from interactive marketing preview.',
      timeLabel: newSchedule === 'today' ? 'Scheduled Today' : newSchedule === 'upcoming' ? 'Tomorrow 9:00 AM' : 'In Inbox for 1 min',
      tags: [],
      starred: false,
      categoryTab: 'primary',
      url: newUrl.trim() || 'https://laterbox.dev',
    };

    setItems((prev) => [newItem, ...prev]);
    setCaptureOpen(false);
    setNewTitle('');
    setNewUrl('');
    showToast('Saved to Inbox (Interactive demo)');
  };

  // Filtered Items based on active view, category tab, and search query
  const filteredItems = useMemo(() => {
    let list = items;

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      list = list.filter(
        (i) =>
          i.title.toLowerCase().includes(q) ||
          i.source.toLowerCase().includes(q) ||
          i.snippet.toLowerCase().includes(q)
      );
    } else {
      if (activeView === 'starred') {
        list = list.filter((i) => i.starred);
      } else if (activeView === 'today') {
        list = list.filter((_, idx) => idx % 6 === 0);
      } else if (activeView === 'upcoming') {
        list = list.filter((_, idx) => idx % 5 === 0);
      } else if (activeView === 'someday') {
        list = list.filter((_, idx) => idx % 4 === 0);
      } else if (activeView === 'kept') {
        list = list.filter((_, idx) => idx % 7 === 0);
      } else if (activeView === 'trash') {
        list = [];
      } else if (activeView === 'inbox') {
        if (activeCategoryTab === 'articles') {
          list = list.filter((i) => i.categoryTab === 'articles');
        } else if (activeCategoryTab === 'media') {
          list = list.filter((i) => i.categoryTab === 'media');
        } else if (activeCategoryTab === 'updates') {
          list = list.filter((i) => i.categoryTab === 'updates');
        }
      }
    }

    if (sortOrder === 'oldest') {
      return [...list].reverse();
    }
    return list;
  }, [items, activeView, activeCategoryTab, searchQuery, sortOrder]);

  const selectedDetailIndex = useMemo(() => {
    if (!selectedDetailItem) return -1;
    return filteredItems.findIndex((item) => item.id === selectedDetailItem.id);
  }, [selectedDetailItem, filteredItems]);

  const viewTitles: Record<ViewKey, string> = {
    inbox: 'Inbox',
    today: 'Today',
    upcoming: 'Upcoming',
    someday: 'Someday',
    starred: 'Starred',
    kept: 'Kept',
    archived: 'Archived',
    trash: 'Recently Deleted',
  };

  const allSelected = filteredItems.length > 0 && selectedIds.size === filteredItems.length;
  const someSelected = selectedIds.size > 0 && !allSelected;

  return (
    <section
      id={id}
      aria-label="Interactive LaterBox dashboard demo"
      className={`relative min-w-0 overflow-hidden rounded-[24px] sm:rounded-[32px] border border-[#dedfd4] bg-[#faf8f5] text-left text-[#192018] shadow-[0_25px_80px_rgba(24,27,20,0.14)] flex flex-col h-[680px] sm:h-[720px] lg:h-[760px] ${className}`}
    >
      {/* ===================================================================== */}
      {/* TOP BAR (LaterBox Monogram Logo + Title, Center Omnibar, Right Controls) */}
      {/* ===================================================================== */}
      <div className="shrink-0 flex min-h-[60px] sm:min-h-[68px] items-center justify-between gap-3 px-4 sm:px-6 py-2.5 select-none">
        {/* Left: Cube Monogram + Active Page Title */}
        <div className="flex items-center gap-3 shrink-0">
          <div className="relative flex h-10 w-10 sm:h-11 sm:w-11 items-center justify-center overflow-hidden rounded-xl sm:rounded-2xl border border-[#cbd79c] bg-[#e6edb0] shadow-2xs">
            <Image
              src="/branding/laterbox-icon.png"
              alt="LaterBox"
              fill
              sizes="44px"
              className="object-contain p-1"
            />
          </div>
          <h2 className="text-xl sm:text-2xl lg:text-[26px] font-black tracking-tight text-[#171711]">
            {viewTitles[activeView]}
          </h2>
        </div>

        {/* Center: Real Omnibar Search Input */}
        <div className="flex-1 max-w-lg mx-2 sm:mx-6">
          <div className="relative flex items-center w-full">
            <Search className="absolute left-3.5 w-3.5 h-3.5 text-[#8c8a80] pointer-events-none" />
            <input
              ref={searchInputRef}
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search in inbox or web library... (⌘K)"
              className="w-full h-9 sm:h-10 pl-9 pr-10 rounded-full bg-white border border-[#dedad0] text-xs text-[#171711] placeholder-[#8c8a80] focus:outline-none focus:border-[#171711] focus:ring-1 focus:ring-[#171711] shadow-2xs transition-all"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="absolute right-3 p-0.5 rounded-full hover:bg-[#ece8df] text-[#8c8a80] hover:text-[#171711]"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>

        {/* Right: AI Organize Pill, Settings Cog, User Profile */}
        <div className="flex items-center gap-2 sm:gap-2.5 shrink-0">
          <button
            type="button"
            onClick={() => showToast('AI organize analyzed and grouped your inbox items')}
            className="inline-flex items-center gap-1.5 px-3.5 py-1.5 sm:py-2 rounded-full bg-[#e6edb0] border border-[#d2df88] text-[#171711] text-xs font-black hover:bg-[#dbe69b] shadow-2xs transition-all cursor-pointer"
          >
            <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
            <span className="hidden sm:inline">AI organize</span>
          </button>

          <button
            type="button"
            onClick={() => showToast('Settings: All preferences preserved in sandbox')}
            title="Settings"
            className="p-2 sm:p-2.5 rounded-xl bg-white border border-[#dedad0] text-[#6c6b63] hover:text-[#171711] shadow-2xs transition-colors cursor-pointer"
          >
            <Settings className="w-4 h-4" />
          </button>

          {/* User initials circle */}
          <div
            title="Signed in as demo curator"
            className="w-8 h-8 sm:w-9 sm:h-9 rounded-full bg-[#171711] text-white text-xs font-black flex items-center justify-center select-none shadow-2xs"
          >
            CD
          </div>
        </div>
      </div>

      {/* ===================================================================== */}
      {/* MAIN WORKSPACE: APP SIDEBAR RAIL + INBOX TABLE CARD */}
      {/* ===================================================================== */}
      <div className="flex-1 min-h-0 flex flex-col md:flex-row px-3 sm:px-5 pb-3 sm:pb-5 gap-3 sm:gap-4 items-stretch overflow-hidden">
        {/* =================================================================== */}
        {/* EXACT REAL DASHBOARD SIDEBAR RAIL (Matching Image 2 & AppSidebar) */}
        {/* =================================================================== */}
        <aside
          aria-label="Dashboard sidebar"
          className="w-full md:w-[72px] lg:w-[80px] shrink-0 flex md:flex-col items-center justify-between md:justify-start gap-1.5 py-1 md:py-0 select-none overflow-hidden h-full"
        >
          {/* Black Plus Save Button (matching Image 2) */}
          <button
            type="button"
            onClick={() => setCaptureOpen(true)}
            title="Save Item (Ctrl + Alt + L)"
            className="group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl bg-[#171711] text-[#e6edb0] shadow-[0_6px_14px_rgba(23,23,17,0.12)] transition-all hover:-translate-y-0.5 hover:bg-[#30372a] focus-visible:outline-2 focus-visible:outline-[#758a50] cursor-pointer"
          >
            <Plus className="h-6 w-6 sm:h-7 sm:w-7 transition-transform group-hover:rotate-90" strokeWidth={2.6} />
          </button>

          {/* Navigation Rails Icons */}
          <nav
            aria-label="Navigation rail"
            className="flex md:flex-col items-center gap-1.5 my-1 md:my-2 overflow-x-auto md:overflow-x-hidden md:overflow-y-auto scrollbar-none [scrollbar-width:none] [&::-webkit-scrollbar]:hidden w-full flex-1 min-h-0"
          >
            {/* 1. Inbox (Active) */}
            <button
              type="button"
              onClick={() => {
                setActiveView('inbox');
                setSelectedDetailItem(null);
              }}
              title="Inbox (18)"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'inbox'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <Inbox className="h-6 w-6" strokeWidth={activeView === 'inbox' ? 2.3 : 1.9} />
              <span className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-1 text-[9px] font-black leading-none text-white">
                18
              </span>
            </button>

            {/* 2. Today */}
            <button
              type="button"
              onClick={() => {
                setActiveView('today');
                setSelectedDetailItem(null);
              }}
              title="Today (2)"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'today'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <Clock className="h-6 w-6" strokeWidth={activeView === 'today' ? 2.3 : 1.9} />
              <span className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-1 text-[9px] font-black leading-none text-white">
                2
              </span>
            </button>

            {/* 3. Upcoming */}
            <button
              type="button"
              onClick={() => {
                setActiveView('upcoming');
                setSelectedDetailItem(null);
              }}
              title="Upcoming (3)"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'upcoming'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <CalendarDays className="h-6 w-6" strokeWidth={activeView === 'upcoming' ? 2.3 : 1.9} />
              <span className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-1 text-[9px] font-black leading-none text-white">
                3
              </span>
            </button>

            {/* 4. Someday */}
            <button
              type="button"
              onClick={() => {
                setActiveView('someday');
                setSelectedDetailItem(null);
              }}
              title="Someday (6)"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'someday'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <CalendarClock className="h-6 w-6" strokeWidth={activeView === 'someday' ? 2.3 : 1.9} />
              <span className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-1 text-[9px] font-black leading-none text-white">
                6
              </span>
            </button>

            {/* 5. Starred */}
            <button
              type="button"
              onClick={() => {
                setActiveView('starred');
                setSelectedDetailItem(null);
              }}
              title="Starred (2)"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'starred'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <Star className="h-6 w-6" strokeWidth={activeView === 'starred' ? 2.3 : 1.9} />
              <span className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-1 text-[9px] font-black leading-none text-white">
                2
              </span>
            </button>

            {/* 6. Kept */}
            <button
              type="button"
              onClick={() => {
                setActiveView('kept');
                setSelectedDetailItem(null);
              }}
              title="Kept (4)"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'kept'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <CheckCircle2 className="h-6 w-6" strokeWidth={activeView === 'kept' ? 2.3 : 1.9} />
              <span className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-1 text-[9px] font-black leading-none text-white">
                4
              </span>
            </button>

            {/* 7. Archived */}
            <button
              type="button"
              onClick={() => {
                setActiveView('archived');
                setSelectedDetailItem(null);
              }}
              title="Archived"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'archived'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <Archive className="h-6 w-6" strokeWidth={1.9} />
            </button>

            {/* 8. Trash */}
            <button
              type="button"
              onClick={() => {
                setActiveView('trash');
                setSelectedDetailItem(null);
              }}
              title="Recently Deleted"
              className={`relative group flex h-[48px] w-[48px] sm:h-[52px] sm:w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 cursor-pointer ${
                activeView === 'trash'
                  ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
                  : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
              }`}
            >
              <Trash2 className="h-6 w-6" strokeWidth={1.9} />
            </button>

            {/* Divider line matching Image 2 */}
            <div className="my-2 hidden md:flex justify-center" aria-hidden="true">
              <span className="h-px w-9 bg-[#e5e2d6]" />
            </div>

            {/* Collections button */}
            <button
              type="button"
              onClick={() => showToast('Collections: Design, Reading, Tech')}
              title="Collections"
              className="relative group hidden md:flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl border border-transparent text-[#85877c] hover:bg-white hover:text-[#171711] transition-all cursor-pointer"
            >
              <FolderOpen className="h-6 w-6" strokeWidth={1.9} />
              <span className="absolute -right-0.5 -top-0.5 h-2 w-2 rounded-full bg-[#7b9652]" />
            </button>

            {/* Divider line */}
            <div className="my-2 hidden md:flex justify-center" aria-hidden="true">
              <span className="h-px w-9 bg-[#e5e2d6]" />
            </div>

            {/* Guide */}
            <button
              type="button"
              onClick={() => showToast('Onboarding guide available in app')}
              title="Guide"
              className="group hidden md:flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl border border-transparent text-[#85877c] hover:bg-white hover:text-[#171711] transition-all cursor-pointer"
            >
              <Compass className="h-6 w-6" strokeWidth={1.9} />
            </button>

            {/* Downloads */}
            <button
              type="button"
              onClick={() => showToast('Apps for iOS, Android & Chrome Extension')}
              title="Downloads"
              className="group hidden md:flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl border border-transparent text-[#85877c] hover:bg-white hover:text-[#171711] transition-all cursor-pointer"
            >
              <Download className="h-6 w-6" strokeWidth={1.9} />
            </button>

            {/* Plans / Crown */}
            <button
              type="button"
              onClick={() => showToast('Pro Cloud Vault Plan: Unlimited sync & AI')}
              title="Plans"
              className="group hidden md:flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl border border-transparent text-[#85877c] hover:bg-white hover:text-[#171711] transition-all cursor-pointer"
            >
              <Crown className="h-6 w-6" strokeWidth={1.9} />
            </button>
          </nav>
        </aside>

        {/* =================================================================== */}
        {/* MAIN VIEW AREA: EMAIL TABLE CARD + SEPARATED SYNC FOOTER (Image 1) */}
        {/* =================================================================== */}
        <div className="flex-1 flex flex-col min-w-0 min-h-0 gap-2.5 sm:gap-3">
          {/* EMAIL TABLE CARD */}
          <div className="flex-1 flex flex-col min-w-0 min-h-0 bg-white border border-[#e4e0d5] rounded-2xl sm:rounded-3xl shadow-xs overflow-hidden">
          {/* Top Table Action Toolbar */}
          {selectedDetailItem ? (
            <div className="shrink-0 flex items-center justify-between px-3 sm:px-4 py-2 border-b border-[#e5e4dc] bg-[#fafaf6] text-xs min-h-[46px] select-none">
              {/* Left Controls: Back button + Divider + Action buttons */}
              <div className="flex items-center gap-1 sm:gap-2 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
                <button
                  type="button"
                  onClick={() => setSelectedDetailItem(null)}
                  className="inline-flex items-center gap-1.5 px-2.5 sm:px-3 py-1.5 rounded-xl text-xs font-bold transition-colors hover:bg-[#e6edb0] text-[#171711] cursor-pointer shrink-0"
                >
                  <ArrowLeft className="w-4 h-4" />
                  <span className="hidden sm:inline">Back to {viewTitles[activeView]}</span>
                  <span className="sm:hidden">Back</span>
                </button>

                <span className="h-5 w-px bg-[#e4e0d5] mx-1 shrink-0" aria-hidden="true" />

                {/* Star Toggle */}
                <button
                  type="button"
                  onClick={(e) => toggleStar(selectedDetailItem.id, e)}
                  className={`p-1.5 rounded-lg transition-colors cursor-pointer shrink-0 ${
                    selectedDetailItem.starred
                      ? 'text-amber-500 bg-amber-50'
                      : 'text-[#6c6b63] hover:text-[#171711] hover:bg-white'
                  }`}
                  title={selectedDetailItem.starred ? 'Starred' : 'Star'}
                >
                  <Star className={`w-4 h-4 ${selectedDetailItem.starred ? 'fill-amber-400 text-amber-500' : ''}`} />
                </button>

                {/* Keep Button */}
                <button
                  type="button"
                  onClick={() => {
                    showToast('Kept in library');
                    setSelectedDetailItem(null);
                  }}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-[#e6edb0] hover:bg-[#d9e6a0] text-[#27321c] text-xs font-bold transition-colors cursor-pointer shrink-0"
                  title="Keep in Library"
                >
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span className="hidden sm:inline">Keep</span>
                </button>

                {/* Archive Button */}
                <button
                  type="button"
                  onClick={() => {
                    showToast('Archived');
                    setSelectedDetailItem(null);
                  }}
                  className="p-1.5 rounded-lg text-[#6c6b63] hover:text-[#171711] hover:bg-white transition-colors cursor-pointer shrink-0"
                  title="Archive"
                >
                  <Archive className="w-4 h-4" />
                </button>

                {/* Add to Collections */}
                <button
                  type="button"
                  onClick={() => showToast('Saved to Collections')}
                  className="p-1.5 rounded-lg text-[#6c6b63] hover:text-[#171711] hover:bg-white transition-colors cursor-pointer shrink-0"
                  title="Add to Collection"
                >
                  <FolderPlus className="w-4 h-4" />
                </button>

                {/* Snooze / Reschedule */}
                <button
                  type="button"
                  onClick={() => showToast('Return time scheduled')}
                  className="p-1.5 rounded-lg text-[#6c6b63] hover:text-[#171711] hover:bg-white transition-colors cursor-pointer shrink-0"
                  title="Snooze"
                >
                  <CalendarClock className="w-4 h-4" />
                </button>

                {/* Copy Link */}
                <button
                  type="button"
                  onClick={() => {
                    navigator.clipboard?.writeText(selectedDetailItem.url);
                    showToast('Link copied to clipboard');
                  }}
                  className="p-1.5 rounded-lg text-[#6c6b63] hover:text-[#171711] hover:bg-white transition-colors cursor-pointer shrink-0"
                  title="Copy link"
                >
                  <Copy className="w-4 h-4" />
                </button>

                {/* Delete */}
                <button
                  type="button"
                  onClick={() => {
                    deleteItem(selectedDetailItem.id);
                    setSelectedDetailItem(null);
                  }}
                  className="p-1.5 rounded-lg text-[#8c8a80] hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer shrink-0"
                  title="Delete"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>

              {/* Right Controls: Pager */}
              <div className="flex items-center gap-1 sm:gap-1.5 pl-2 border-l border-[#e4e0d5] shrink-0">
                <span className="text-[11px] font-bold text-[#8c8a80] hidden sm:inline">
                  {selectedDetailIndex >= 0 ? `${selectedDetailIndex + 1} of ${filteredItems.length}` : 'Item details'}
                </span>
                <button
                  type="button"
                  disabled={selectedDetailIndex <= 0}
                  onClick={() => {
                    if (selectedDetailIndex > 0) {
                      setSelectedDetailItem(filteredItems[selectedDetailIndex - 1]);
                    }
                  }}
                  className="p-1.5 rounded-lg hover:bg-white text-[#5f655b] disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
                  title="Previous item"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  disabled={selectedDetailIndex < 0 || selectedDetailIndex >= filteredItems.length - 1}
                  onClick={() => {
                    if (selectedDetailIndex >= 0 && selectedDetailIndex < filteredItems.length - 1) {
                      setSelectedDetailItem(filteredItems[selectedDetailIndex + 1]);
                    }
                  }}
                  className="p-1.5 rounded-lg hover:bg-white text-[#5f655b] disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
                  title="Next item"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          ) : (
            <div className="shrink-0 flex items-center justify-between px-3 sm:px-4 py-2 border-b border-[#e5e4dc] bg-white text-xs text-[#6c6b63] min-h-[46px] select-none">
              {/* Left Controls: Select All, Refresh, More */}
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
                  >
                    <ChevronDown className="w-3 h-3" />
                  </button>

                  {selectMenuOpen && (
                    <div className="absolute left-0 top-full mt-1 w-32 bg-white border border-[#dedad0] rounded-xl shadow-lg py-1 z-30 text-xs font-semibold text-[#171711]">
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedIds(new Set(filteredItems.map((i) => i.id)));
                          setSelectMenuOpen(false);
                        }}
                        className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5]"
                      >
                        All
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedIds(new Set());
                          setSelectMenuOpen(false);
                        }}
                        className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5]"
                      >
                        None
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedIds(new Set(filteredItems.filter((i) => i.starred).map((i) => i.id)));
                          setSelectMenuOpen(false);
                        }}
                        className="w-full text-left px-3 py-1.5 hover:bg-[#faf8f5]"
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

                {/* More Vertical Options */}
                <button
                  type="button"
                  onClick={() => showToast('More actions available')}
                  className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                >
                  <MoreVertical className="w-3.5 h-3.5" />
                </button>

                {/* Bulk Actions when items are selected */}
                {selectedIds.size > 0 && (
                  <div className="flex items-center gap-1 pl-2 ml-1 border-l border-[#dedad0] animate-in fade-in duration-150">
                    <span className="text-[11px] font-bold text-[#171711] mr-1">
                      {selectedIds.size} selected
                    </span>

                    <button
                      type="button"
                      onClick={handleBulkArchive}
                      title="Archive selected"
                      className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                    >
                      <Archive className="w-3.5 h-3.5" />
                    </button>

                    <button
                      type="button"
                      onClick={handleBulkDelete}
                      title="Delete selected"
                      className="p-1.5 rounded-lg hover:bg-red-50 text-[#8c8a80] hover:text-red-600 transition-colors cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>

                    <button
                      type="button"
                      onClick={handleBulkStar}
                      title="Star selected"
                      className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-amber-500 transition-colors cursor-pointer"
                    >
                      <Star className="w-3.5 h-3.5" />
                    </button>
                  </div>
                )}
              </div>

              {/* Right Controls: 1-18 of 18, Chevrons, Sort Order */}
              <div className="flex items-center gap-2">
                <span className="text-[11px] font-bold text-[#8c8a80]">
                  {filteredItems.length > 0 ? `1–${filteredItems.length} of ${filteredItems.length}` : '0 items'}
                </span>

                <div className="flex items-center gap-0.5">
                  <button type="button" disabled className="p-1 rounded-lg text-[#8c8a80] opacity-35 cursor-not-allowed">
                    <ChevronLeft className="w-4 h-4" />
                  </button>
                  <button type="button" disabled className="p-1 rounded-lg text-[#8c8a80] opacity-35 cursor-not-allowed">
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
                  className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer ml-1"
                >
                  <ArrowUpDown className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}

          {/* ================================================================= */}
          {/* CATEGORY TABS (Primary 18 new, Articles 11 new, Media 7 new, Updates) */}
          {/* ================================================================= */}
          {!selectedDetailItem && !searchQuery.trim() && activeView === 'inbox' && (
            <div className="shrink-0 flex items-center border-b border-[#e5e4dc] bg-white overflow-x-auto scrollbar-none select-none">
              {/* Primary Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('primary')}
                className={`relative flex-1 min-w-[150px] sm:min-w-[200px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'primary' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'primary' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <Inbox className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-black text-[#171711] tracking-tight">Primary</span>
                    <span className="px-1.5 py-0.2 rounded-full text-[9px] font-extrabold bg-[#e6edb0] text-[#171711]">
                      18 new
                    </span>
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    kobasolo - YouTube - 【時かけ】変わらな...
                  </p>
                </div>
              </button>

              {/* Articles Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('articles')}
                className={`relative flex-1 min-w-[150px] sm:min-w-[200px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'articles' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'articles' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <FileText className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-[#6c6b63] tracking-tight">Articles</span>
                    <span className="px-1.5 py-0.2 rounded-full text-[9px] font-extrabold bg-[#d5f0d6] text-[#2b6830]">
                      11 new
                    </span>
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    Bill Gates - The choices we make about AI now ar...
                  </p>
                </div>
              </button>

              {/* Media Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('media')}
                className={`relative flex-1 min-w-[150px] sm:min-w-[200px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'media' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'media' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <Video className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-[#6c6b63] tracking-tight">Media</span>
                    <span className="px-1.5 py-0.2 rounded-full text-[9px] font-extrabold bg-[#e5eef4] text-[#345b78]">
                      7 new
                    </span>
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    kobasolo - YouTube - 【時かけ】変わらな...
                  </p>
                </div>
              </button>

              {/* Updates Tab */}
              <button
                type="button"
                onClick={() => setActiveCategoryTab('updates')}
                className={`relative flex-1 min-w-[150px] sm:min-w-[200px] py-3 px-4 flex items-center gap-3 transition-colors cursor-pointer text-left ${
                  activeCategoryTab === 'updates' ? 'bg-[#faf8f5]/80' : 'hover:bg-[#faf8f5]'
                }`}
              >
                {activeCategoryTab === 'updates' && (
                  <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
                )}
                <Tag className="w-4 h-4 text-[#171711] shrink-0" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-[#6c6b63] tracking-tight">Updates</span>
                  </div>
                  <p className="text-[10px] text-[#8c8a80] truncate mt-0.5 hidden sm:block">
                    Notes &amp; tasks
                  </p>
                </div>
              </button>
            </div>
          )}

          {/* ================================================================= */}
          {/* EMAIL TABLE CONTENT: ROWS OR EMBEDDED ITEM DETAILS */}
          {/* ================================================================= */}
          {selectedDetailItem ? (
            <div
              data-lenis-prevent
              className="flex-1 min-h-0 overflow-y-auto overscroll-contain bg-[#f7f5ee] p-4 sm:p-6 space-y-4"
            >
              {/* In Inbox Status Banner */}
              <div className="flex items-center gap-3 rounded-2xl border border-[#e4e0d5] bg-white px-4 py-3 text-sm text-[#171711] shadow-2xs">
                <Clock className="h-4 w-4 shrink-0 text-[#6c6b63]" aria-hidden="true" />
                <div>
                  <span className="font-bold text-xs uppercase tracking-wider text-[#171711]">In Inbox</span>
                  <p className="mt-0.5 text-xs text-[#6c6b63]">{selectedDetailItem.timeLabel}</p>
                </div>
              </div>

              {/* Real Platform Card Format */}
              <article className="rounded-[24px] sm:rounded-[32px] bg-white border-2 border-[#171711] shadow-[0_20px_60px_rgba(0,0,0,0.06)] overflow-hidden">
                {/* Visual Media Header */}
                {selectedDetailItem.categoryTab === 'media' || selectedDetailItem.source.includes('YouTube') || selectedDetailItem.tags.some((t) => t.icon === 'video') ? (
                  <div className="relative w-full h-48 sm:h-64 bg-neutral-950 overflow-hidden border-b border-[#e4e0d5] flex items-center justify-center">
                    <div className="absolute inset-0 bg-gradient-to-br from-neutral-900 via-neutral-800 to-neutral-950" />
                    <div className="absolute top-4 left-4 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-xs font-semibold flex items-center gap-1.5 shadow-sm">
                      <span>{selectedDetailItem.source}</span>
                    </div>
                    <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-[#ea4335] text-white text-xs font-bold flex items-center gap-1.5 shadow-sm">
                      <Play className="w-3 h-3 fill-white" />
                      <span>Video</span>
                    </div>
                    <button
                      type="button"
                      onClick={() => showToast('Playing media preview')}
                      className="relative z-10 w-16 h-16 rounded-full bg-white/95 text-[#171711] flex items-center justify-center pl-1 shadow-2xl transition-transform hover:scale-105 cursor-pointer"
                    >
                      <Play className="w-7 h-7 fill-[#171711]" />
                    </button>
                  </div>
                ) : selectedDetailItem.categoryTab === 'articles' || selectedDetailItem.source === 'Bill Gates' ? (
                  <div className="p-6 sm:p-7 border-b border-[#e4e0d5] bg-[#faf8f5]">
                    <div className="flex items-center gap-2 mb-3">
                      <span className="px-2.5 py-0.5 rounded-full bg-[#e6edb0] text-[#171711] text-[11px] font-black uppercase tracking-wider">
                        Article
                      </span>
                      <span className="text-xs text-[#6c6b63] font-semibold">5 min read</span>
                    </div>
                    <h2 className="text-lg sm:text-xl font-black text-[#171711] tracking-tight leading-snug">
                      {selectedDetailItem.title}
                    </h2>
                    <p className="mt-2 text-xs font-semibold text-[#8c8a80]">
                      By {selectedDetailItem.source} • {selectedDetailItem.timeLabel}
                    </p>
                  </div>
                ) : (
                  <div className="p-5 border-b border-[#e4e0d5] bg-gradient-to-r from-[#faf8f5] to-white flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-amber-500 via-rose-500 to-purple-600 p-0.5 shadow-xs">
                        <div className="w-full h-full rounded-[14px] bg-white flex items-center justify-center font-black text-xs text-[#171711]">
                          {selectedDetailItem.source.slice(0, 2).toUpperCase()}
                        </div>
                      </div>
                      <div>
                        <h4 className="text-xs font-bold text-[#171711]">{selectedDetailItem.source}</h4>
                        <p className="text-[11px] text-[#8c8a80]">{selectedDetailItem.timeLabel}</p>
                      </div>
                    </div>
                    <span className="px-3 py-1 rounded-full bg-[#f4f7ea] text-[#314125] text-xs font-bold">
                      Social Post
                    </span>
                  </div>
                )}

                {/* Content Body */}
                <div className="p-6 sm:p-7 space-y-4">
                  {!(selectedDetailItem.categoryTab === 'articles' || selectedDetailItem.source === 'Bill Gates') && (
                    <h3 className="text-base sm:text-lg font-black text-[#171711] tracking-tight leading-snug">
                      {selectedDetailItem.title}
                    </h3>
                  )}

                  <p className="text-xs sm:text-sm text-[#3b3a36] leading-relaxed">
                    {selectedDetailItem.snippet}
                  </p>

                  {selectedDetailItem.tags.length > 0 && (
                    <div className="flex flex-wrap items-center gap-1.5 pt-1">
                      {selectedDetailItem.tags.map((t, idx) => (
                        <span
                          key={idx}
                          className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-bold ${
                            t.color === 'red'
                              ? 'bg-rose-50 text-rose-700 border border-rose-200'
                              : t.color === 'green'
                              ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                              : t.color === 'amber'
                              ? 'bg-amber-50 text-amber-800 border border-amber-200'
                              : 'bg-slate-50 text-slate-700 border border-slate-200'
                          }`}
                        >
                          {t.icon === 'video' && <Play className="w-3 h-3 fill-current" />}
                          {t.icon === 'book' && <BookOpen className="w-3 h-3" />}
                          <span>{t.label}</span>
                        </span>
                      ))}
                    </div>
                  )}

                  {/* Source Link & Quick Action Buttons */}
                  <div className="pt-4 border-t border-[#e4e0d5] flex flex-wrap items-center justify-between gap-3 text-xs">
                    <a
                      href={selectedDetailItem.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 text-xs font-bold text-[#0369a1] hover:underline truncate max-w-xs sm:max-w-md"
                    >
                      <span>{selectedDetailItem.url}</span>
                      <ExternalLink className="w-3.5 h-3.5 shrink-0" />
                    </a>

                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          showToast('Kept in library');
                          setSelectedDetailItem(null);
                        }}
                        className="px-3.5 py-1.5 rounded-xl bg-[#e6edb0] hover:bg-[#d9e6a0] text-[#171711] text-xs font-bold transition-colors cursor-pointer"
                      >
                        Keep in Library
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          showToast('Archived item');
                          setSelectedDetailItem(null);
                        }}
                        className="px-3.5 py-1.5 rounded-xl bg-[#171711] hover:bg-black text-white text-xs font-bold transition-colors cursor-pointer"
                      >
                        Archive
                      </button>
                    </div>
                  </div>
                </div>
              </article>

              {/* Notes & Follow-ups Card */}
              <div className="rounded-2xl border border-[#e4e0d5] bg-white p-4 sm:p-5 shadow-2xs space-y-2.5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-[#171711] uppercase tracking-wider flex items-center gap-1.5">
                    <MessageSquare className="w-3.5 h-3.5 text-[#6c6b63]" />
                    <span>Notes &amp; Follow-ups</span>
                  </span>
                  <span className="text-[11px] text-[#8c8a80]">Synced across devices</span>
                </div>
                <div className="p-3 rounded-xl bg-[#faf8f5] border border-[#e5e4dc] text-xs text-[#6c6b63] leading-relaxed">
                  Quick save from mobile for later review. Synced to your local-first library and searchable with AI.
                </div>
              </div>
            </div>
          ) : (
            <div
              data-lenis-prevent
              className="flex-1 min-h-0 overflow-y-auto divide-y divide-[#eceae1] bg-white text-xs"
            >
              {filteredItems.map((item) => {
                const isSelected = selectedIds.has(item.id);
                const isHovered = hoveredRowId === item.id;

                return (
                  <div
                    key={item.id}
                    onMouseEnter={() => setHoveredRowId(item.id)}
                    onMouseLeave={() => setHoveredRowId(null)}
                    onClick={() => setSelectedDetailItem(item)}
                    className={`group relative flex items-center gap-2 sm:gap-3 px-3 sm:px-4 py-3 sm:py-3.5 transition-all duration-150 cursor-pointer ${
                      isSelected ? 'bg-[#f4f7ea]' : 'hover:bg-[#faf8f5]'
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

                    {/* Star Toggle */}
                    <button
                      type="button"
                      onClick={(e) => toggleStar(item.id, e)}
                      className="shrink-0 p-0.5 text-[#8c8a80] hover:text-amber-500 transition-colors"
                    >
                      <Star
                        className={`w-4 h-4 ${
                          item.starred ? 'fill-amber-400 text-amber-500' : 'hover:fill-amber-100'
                        }`}
                      />
                    </button>

                    {/* Sender / Source domain (e.g. disneyplus.com, facebook.com, Instagram) */}
                    <div className="w-24 sm:w-36 shrink-0 truncate">
                      <span className="font-bold text-[#171711] truncate block text-[13px]">
                        {item.source}
                      </span>
                    </div>

                    {/* Title & snippet */}
                    <div className="flex-1 min-w-0 flex items-center gap-2">
                      <span className="font-bold text-[#171711] truncate text-[13px]">
                        {item.title}
                      </span>
                      {item.snippet && (
                        <span className="text-[#8c8a80] truncate hidden lg:inline text-xs">
                          — {item.snippet}
                        </span>
                      )}
                    </div>

                    {/* Category Pills (Video, Reading, Entertainment, Watch Later) */}
                    {item.tags.length > 0 && (
                      <div className="hidden sm:flex items-center gap-1.5 shrink-0">
                        {item.tags.map((t, idx) => (
                          <span
                            key={idx}
                            className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold ${
                              t.color === 'red'
                                ? 'bg-rose-50 text-rose-700 border border-rose-200'
                                : t.color === 'green'
                                ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                                : t.color === 'amber'
                                ? 'bg-amber-50 text-amber-800 border border-amber-200'
                                : 'bg-slate-50 text-slate-700 border border-slate-200'
                            }`}
                          >
                            {t.icon === 'video' && <Play className="w-2.5 h-2.5 fill-current" />}
                            {t.icon === 'book' && <BookOpen className="w-2.5 h-2.5" />}
                            <span>{t.label}</span>
                          </span>
                        ))}
                      </div>
                    )}

                    {/* Timestamp Pill (e.g. In Inbox for 15 hrs, 29 min, Oct 21) */}
                    <div className="shrink-0 text-right w-28 sm:w-40">
                      <span className="text-[11px] font-semibold text-[#8c8a80] px-2 py-0.5 rounded-full bg-[#f5f4ed]">
                        {item.timeLabel}
                      </span>
                    </div>

                    {/* Hover Actions Menu (Matching Image 2 hover row) */}
                    <div
                      onClick={(e) => e.stopPropagation()}
                      className={`absolute right-3 top-1/2 -translate-y-1/2 items-center gap-1 bg-white/95 backdrop-blur-xs px-2 py-1 rounded-xl border border-[#dedad0] shadow-sm z-20 transition-all ${
                        isHovered ? 'flex' : 'hidden group-hover:flex'
                      }`}
                    >
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            showToast('Archived item');
                          }}
                          title="Archive"
                          className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711]"
                        >
                          <Check className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            showToast('Added to collection');
                          }}
                          title="Collection"
                          className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711]"
                        >
                          <FolderOpen className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={(e) => deleteItem(item.id, e)}
                          title="Delete"
                          className="p-1.5 rounded-lg hover:bg-red-50 text-[#8c8a80] hover:text-red-600"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setSnoozeMenuForId(snoozeMenuForId === item.id ? null : item.id);
                          }}
                          title="Snooze"
                          className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711]"
                        >
                          <Clock className="w-3.5 h-3.5" />
                        </button>
                        <a
                          href={item.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(e) => e.stopPropagation()}
                          title="Open Source Link"
                          className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711]"
                        >
                          <ExternalLink className="w-3.5 h-3.5" />
                        </a>
                      </div>
                    </div>
                );
              })}
            </div>
          )}

          {/* Close Email Table Card with its own rounded bottom */}
          </div>

          {/* ================================================================= */}
          {/* STANDALONE PRO CLOUD SYNC FOOTER (Separated from table, Image 1) */}
          {/* ================================================================= */}
          <div className="shrink-0 px-3.5 sm:px-4 py-2 sm:py-2.5 rounded-2xl bg-white border border-[#e4e0d5] shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs select-none">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-6 h-6 rounded-full bg-[#e6edb0] text-[#171711] flex items-center justify-center shrink-0">
                <Cloud className="w-3.5 h-3.5" />
              </div>
              <div className="flex items-center gap-2 min-w-0">
                <span className="font-bold text-[#171711] truncate">Pro Cloud Sync</span>
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black tracking-wider uppercase">
                  <CheckCircle2 className="w-3 h-3 text-[#171711]" />
                  <span>SYNCED</span>
                </span>
                <span className="hidden sm:inline text-[11px] text-[#8e8d87] truncate">
                  • All changes backed up to cloud
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={handleRefresh}
              className="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] font-bold text-xs transition-colors cursor-pointer shrink-0"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
              <span>Check Updates</span>
            </button>
          </div>
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
                  placeholder="e.g. Watch Miraculous Ladybug on Disney+"
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
                  placeholder="e.g. https://disneyplus.com"
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
                      onClick={() => setNewSchedule(b.key)}
                      className={`py-2 px-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                        newSchedule === b.key
                          ? 'bg-[#171711] text-[#e6edb0] shadow-2xs'
                          : 'bg-[#faf8f5] border border-[#dedad0] text-[#6c6b63] hover:border-[#171711]'
                      }`}
                    >
                      {b.label}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-[#e5e4dc]">
                <button
                  type="button"
                  onClick={() => setCaptureOpen(false)}
                  className="px-4 py-2 rounded-full text-xs font-bold text-[#6c6b63] hover:text-[#171711] cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-full bg-[#171711] hover:bg-[#2c2b26] text-white text-xs font-extrabold shadow-sm transition-all cursor-pointer"
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
