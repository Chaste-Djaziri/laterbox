'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { scheduleItems, returnLabel, type ScheduleView } from '@/lib/utils/schedule';
import { ItemListRow } from '../inbox/ItemListRow';
import { QuickCaptureModal } from '../inbox/QuickCaptureModal';
import type { LaterBoxItem } from '@/lib/supabase/types';
import { ItemCard } from '../inbox/ItemCard';
import {
  Plus,
  Search,
  Upload,
  UploadCloud,
  FileText,
  Video,
  CheckSquare,
  Link2,
  Clock,
  Menu,
  ArrowRight,
  ArrowLeft,
  LayoutGrid,
  List,
  Sparkles,
  HelpCircle,
  Folder,
  Calendar,
  Layers,
  StickyNote,
  Music2,
  PlayCircle,
  CheckCircle2,
  Pencil,
  Check,
  X,
} from 'lucide-react';

function ScheduledRow({ item }: { item: LaterBoxItem }) {
  const { archiveItem } = useItems();
  return (
    <div className="space-y-1">
      <ItemListRow item={item} />
      <div className="flex items-center justify-between px-2 text-xs text-[#6c6b63]">
        <span>{returnLabel(item.return_at)}</span>
        {item.type === 'task' && (
          <button onClick={() => archiveItem(item.id)} className="font-bold py-1 hover:underline">
            ✓ Done
          </button>
        )}
      </div>
    </div>
  );
}

function ItemCardRow({
  title,
  subtitle,
  time,
  iconType,
  onClick,
}: {
  title: string;
  subtitle: string;
  time: string;
  iconType?: string;
  onClick?: () => void;
}) {
  const renderIcon = () => {
    const t = title.toLowerCase();
    const sub = subtitle.toLowerCase();

    if (iconType === 'ps' || t.endsWith('.psd') || sub.includes('psd')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-[#001e36] text-[#31a8ff] font-bold text-xs flex items-center justify-center shrink-0">
          Ps
        </div>
      );
    }
    if (iconType === 'video' || t.includes('video') || t.includes('youtube') || sub.includes('video')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center shrink-0 border border-purple-100">
          <Video className="w-4 h-4" />
        </div>
      );
    }
    if (iconType === 'task' || sub.includes('task') || t.includes('portfolio')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-neutral-100 text-[#171711] flex items-center justify-center shrink-0 border border-[#e4e0d5]">
          <CheckSquare className="w-4 h-4" />
        </div>
      );
    }
    if (iconType === 'link' || sub.includes('link') || t.includes('article')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0 border border-blue-100">
          <Link2 className="w-4 h-4" />
        </div>
      );
    }
    return (
      <div className="w-8 h-8 rounded-xl bg-white text-[#171711] flex items-center justify-center shrink-0 border border-[#e4e0d5]">
        <FileText className="w-4 h-4" />
      </div>
    );
  };

  return (
    <div
      onClick={onClick}
      className="p-3 sm:p-3.5 rounded-2xl bg-white border border-[#f0ede4] hover:border-[#171711] hover:shadow-2xs transition-all flex items-center justify-between gap-3 cursor-pointer group"
    >
      <div className="flex items-center gap-3 min-w-0">
        {renderIcon()}
        <div className="min-w-0">
          <p className="font-bold text-xs sm:text-sm text-[#171711] truncate group-hover:text-black">
            {title}
          </p>
          <p className="text-[11px] text-[#9e9b92] truncate">{subtitle}</p>
        </div>
      </div>
      <div className="flex items-center gap-1.5 text-[11px] font-semibold text-[#6c6b63] shrink-0">
        <span>{time}</span>
        <Clock className="w-3 h-3 text-[#9e9b92]" />
      </div>
    </div>
  );
}

export function ScheduleDashboard({ view }: { view?: ScheduleView }) {
  const { items, inboxItems, now, loading, syncStatus, hasDemoItems, clearDemoItems } = useItems();
  const { user, userName, setUserName } = useAuth();
  const router = useRouter();
  const [capture, setCapture] = useState(false);
  const [files, setFiles] = useState<File[] | undefined>();
  const [browse, setBrowse] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [isEditingName, setIsEditingName] = useState(false);
  const [nameInput, setNameInput] = useState('');

  // Filtered view state
  const [filterSearch, setFilterSearch] = useState('');
  const [formatFilter, setFormatFilter] = useState<'all' | 'article' | 'video' | 'music' | 'note' | 'file'>('all');
  const [layoutMode, setLayoutMode] = useState<'grid' | 'list'>('grid');

  const upcoming = scheduleItems(items, 'upcoming', now);
  const today = scheduleItems(items, 'today', now);
  const someday = scheduleItems(items, 'someday', now);

  const open = (browseFiles = false, dropped?: File[]) => {
    setFiles(dropped);
    setBrowse(browseFiles);
    setCapture(true);
  };

  const hour = now.getHours();
  const greetingTime = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
  const effectiveUserName = userName || user?.user_metadata?.full_name?.split(' ')[0] || user?.email?.split('@')[0] || '';

  const selected = view ? scheduleItems(items, view, now) : [];

  // Filter items in filtered view
  const filteredSelected = selected.filter((item) => {
    // Search query
    if (filterSearch.trim()) {
      const q = filterSearch.toLowerCase();
      const title = (item.metadata?.title || item.title || '').toLowerCase();
      const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
      const domain = (item.metadata?.domain || item.url || '').toLowerCase();
      if (!title.includes(q) && !desc.includes(q) && !domain.includes(q)) return false;
    }

    // Format filter
    if (formatFilter !== 'all') {
      const cType = item.metadata?.content_type || (item.url ? 'link' : 'note');
      const ext = item.url?.split('.').pop()?.toLowerCase() || '';
      const isFile = item.type === 'file' || ['pdf', 'psd', 'zip', 'docx'].includes(ext);

      if (formatFilter === 'article' && cType !== 'article' && item.type !== 'article') return false;
      if (formatFilter === 'video' && cType !== 'video' && !item.url?.includes('youtube.com')) return false;
      if (formatFilter === 'music' && cType !== 'music' && !item.url?.includes('spotify.com')) return false;
      if (formatFilter === 'note' && item.type !== 'note' && (!item.text_content || item.url)) return false;
      if (formatFilter === 'file' && !isFile) return false;
    }

    return true;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <p className="text-sm font-semibold text-[#8e8d87] animate-pulse">Loading LaterBox...</p>
      </div>
    );
  }

  // Filtered view (Today, Upcoming, Someday)
  if (view) {
    const viewConfig = {
      someday: {
        pill: '✦ Someday Vault • Zero Deadline Pressure',
        headline: 'Some things don’t need a deadline.',
        subhead: 'The Someday Vault keeps your reading list, side project ideas, and reference files safe—without cluttering your daily view.',
        action: 'Save to Someday',
        emptyTitle: 'Someday Vault is clear',
        emptyDesc: 'Items saved without a specific return date will wait here safely until you feel like exploring them.',
      },
      today: {
        pill: '⚡ Returned Today • When Later Becomes Now',
        headline: 'When later becomes now.',
        subhead: 'You don’t have to search, remember, or dig through folders. LaterBox brings your saved items back right on schedule.',
        action: 'Drop Item',
        emptyTitle: 'No items due today',
        emptyDesc: 'Nothing scheduled for today yet. Relax, or pick something from your Inbox or Someday Vault.',
      },
      upcoming: {
        pill: '📅 Scheduled Timeline • Quiet Utility',
        headline: 'Returning on schedule.',
        subhead: 'Everything you’ve postponed, neatly arranged by when it returns. Quiet, predictable, and out of your head.',
        action: 'Schedule Item',
        emptyTitle: 'No upcoming returns scheduled',
        emptyDesc: 'Postponed items with future return times will appear here chronologically.',
      },
    }[view];

    const filterPills = [
      { id: 'all' as const, label: `All (${selected.length})`, icon: <Layers className="w-3.5 h-3.5" /> },
      { id: 'article' as const, label: 'Articles', icon: <FileText className="w-3.5 h-3.5" /> },
      { id: 'video' as const, label: 'Videos', icon: <PlayCircle className="w-3.5 h-3.5" /> },
      { id: 'music' as const, label: 'Music', icon: <Music2 className="w-3.5 h-3.5" /> },
      { id: 'note' as const, label: 'Notes', icon: <StickyNote className="w-3.5 h-3.5" /> },
      { id: 'file' as const, label: 'Files', icon: <Folder className="w-3.5 h-3.5" /> },
    ];

    return (
      <div className="max-w-6xl mx-auto p-6 sm:p-8 space-y-6">
        {/* Top Omnibar with Back, Search, Grid/List Switcher & Local Mode */}
        <div className="flex flex-wrap items-center justify-between gap-3 pb-2 border-b border-[#e4e0d5]/60">
          <div className="flex items-center gap-3">
            <Link
              href="/home"
              className="w-9 h-9 rounded-full bg-white border border-[#e4e0d5] flex items-center justify-center text-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-colors cursor-pointer shrink-0"
              title="Back to Dashboard"
            >
              <ArrowLeft className="w-4 h-4" />
            </Link>

            {/* Omnibar Search */}
            <div className="relative w-64 sm:w-80">
              <Search className="w-3.5 h-3.5 text-[#9e9b92] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={filterSearch}
                onChange={(e) => setFilterSearch(e.target.value)}
                placeholder={`Filter ${view}...`}
                className="w-full rounded-full bg-[#faf8f5] border border-[#e4e0d5] pl-9 pr-14 py-2 text-xs text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:border-[#171711] shadow-2xs transition-colors"
              />
              <kbd className="absolute right-2.5 top-1/2 -translate-y-1/2 px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[9px] font-mono font-bold text-[#171711]">
                ⌘ K
              </kbd>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {/* Grid vs List Toggle */}
            <div className="flex items-center gap-1 bg-[#ebe7dc]/60 p-1 rounded-full text-xs font-bold text-[#6c6b63]">
              <button
                type="button"
                onClick={() => setLayoutMode('grid')}
                className={`p-1.5 rounded-full transition-all cursor-pointer ${
                  layoutMode === 'grid'
                    ? 'bg-white text-[#171711] shadow-2xs'
                    : 'text-[#6c6b63] hover:text-[#171711]'
                }`}
                title="Grid view"
              >
                <LayoutGrid className="w-3.5 h-3.5" />
              </button>
              <button
                type="button"
                onClick={() => setLayoutMode('list')}
                className={`p-1.5 rounded-full transition-all cursor-pointer ${
                  layoutMode === 'list'
                    ? 'bg-white text-[#171711] shadow-2xs'
                    : 'text-[#6c6b63] hover:text-[#171711]'
                }`}
                title="List view"
              >
                <List className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[11px] font-black text-[#171711]">
              <span className="w-1.5 h-1.5 rounded-full bg-[#27c93f]" />
              <span>Local Mode</span>
            </div>

            <Link
              href="/tutorial"
              className="hidden sm:inline-flex items-center gap-1 px-3 py-1 rounded-full bg-white border border-[#e4e0d5] text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] transition-colors"
            >
              <HelpCircle className="w-3.5 h-3.5 text-[#9e9b92]" />
              <span>Tutorial</span>
            </Link>
          </div>
        </div>

        {/* View Header with Signature Style */}
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pt-1">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black">
              <span>{viewConfig.pill}</span>
            </div>
            <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711]">
              {viewConfig.headline}
            </h1>
            <p className="text-xs sm:text-sm text-[#6c6b63] font-medium max-w-2xl leading-relaxed">
              {viewConfig.subhead}
            </p>
          </div>

          <button
            onClick={() => open()}
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#171711] text-white hover:bg-[#282723] text-xs font-black shadow-xs transition-all cursor-pointer self-start sm:self-auto shrink-0"
          >
            <Plus className="w-4 h-4" />
            <span>{viewConfig.action}</span>
          </button>
        </div>

        {/* Format Filter Chips */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none pt-1">
          {filterPills.map((pill) => {
            const active = formatFilter === pill.id;
            return (
              <button
                key={pill.id}
                type="button"
                onClick={() => setFormatFilter(pill.id)}
                className={`inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer ${
                  active
                    ? 'bg-[#e6edb0] border border-[#d0db84] text-[#171711] shadow-2xs'
                    : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f5]'
                }`}
              >
                {pill.icon}
                <span>{pill.label}</span>
              </button>
            );
          })}
        </div>

        {/* Content: Rich Card Grid or Scheduled List */}
        {filteredSelected.length === 0 ? (
          <div className="rounded-3xl border border-dashed border-[#e4e0d5] bg-white p-12 text-center space-y-3">
            <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
              <Clock className="w-6 h-6" />
            </div>
            <h3 className="text-base font-extrabold text-[#171711]">{viewConfig.emptyTitle}</h3>
            <p className="text-xs text-[#6c6b63] max-w-md mx-auto leading-relaxed">
              {filterSearch || formatFilter !== 'all'
                ? `No items in ${view} match your current filter criteria.`
                : viewConfig.emptyDesc}
            </p>
            <div className="pt-2">
              <button
                onClick={() => open()}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#171711] text-white text-xs font-bold shadow-xs hover:bg-[#282723] transition-all cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Add Item to LaterBox</span>
              </button>
            </div>
          </div>
        ) : layoutMode === 'grid' ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredSelected.map((item) => (
              <ItemCard key={item.id} item={item} />
            ))}
          </div>
        ) : (
          <div className="space-y-3">
            {filteredSelected.map((item) => (
              <ScheduledRow key={item.id} item={item} />
            ))}
          </div>
        )}

        <QuickCaptureModal
          isOpen={capture}
          onClose={() => setCapture(false)}
          initialFiles={files}
          browseFiles={browse}
        />
      </div>
    );
  }

  interface DisplayItem {
    id: string;
    title: string;
    subtitle: string;
    time: string;
    iconType?: string;
    item?: LaterBoxItem;
  }

  // Fallback items matching screenshot if empty store
  const defaultWaitingItems: DisplayItem[] = [
    {
      id: 'default-1',
      title: 'ClientFeedback.pdf',
      subtitle: 'PDF Document • Added 2 days ago',
      time: 'Tomorrow, 10:00 AM',
      iconType: 'document',
    },
    {
      id: 'default-2',
      title: 'Design Inspiration.psd',
      subtitle: 'PSD File • Added 3 days ago',
      time: 'Today, 03:00 PM',
      iconType: 'ps',
    },
    {
      id: 'default-3',
      title: 'YouTube Video',
      subtitle: 'Link • Added 1 week ago',
      time: 'Sunday, 09:00 AM',
      iconType: 'video',
    },
  ];

  const defaultComingUpItems: DisplayItem[] = [
    {
      id: 'default-4',
      title: 'Finish Portfolio',
      subtitle: 'Task • Added 3 days ago',
      time: '25 Jul, 10:00 AM',
      iconType: 'task',
    },
    {
      id: 'default-5',
      title: 'Read Article – Design Trends',
      subtitle: 'Link • Added 5 days ago',
      time: '26 Jul, 08:00 AM',
      iconType: 'link',
    },
  ];

  // Map real items dynamically from actual schedule collections
  const activeWaitingList = today.length > 0 ? today : inboxItems;
  const waitingDisplayItems: DisplayItem[] = activeWaitingList.slice(0, 4).map((item) => ({
    id: item.id,
    title: item.title || 'Untitled item',
    subtitle:
      item.metadata?.description ||
      `${item.type.charAt(0).toUpperCase() + item.type.slice(1)} • ${item.return_at ? 'Returned' : 'In inbox'}`,
    time: item.return_at ? returnLabel(item.return_at) : 'Waiting in inbox',
    iconType: item.type,
    item,
  }));

  const comingUpDisplayItems: DisplayItem[] = upcoming.slice(0, 3).map((item) => ({
    id: item.id,
    title: item.title || 'Untitled item',
    subtitle:
      item.metadata?.description ||
      `${item.type.charAt(0).toUpperCase() + item.type.slice(1)} • Scheduled`,
    time: returnLabel(item.return_at),
    iconType: item.type,
    item,
  }));

  const returnedTodayCount = today.length;
  const waitingInboxCount = inboxItems.length;
  const somedayCount = someday.length;
  const nextReturn = upcoming.length > 0 ? upcoming[0] : null;

  return (
    <div className="max-w-6xl mx-auto p-6 sm:p-8 space-y-6">
      {/* Top Search Omnibar */}
      <div className="flex items-center justify-between gap-4 mb-8 sm:mb-12">
        <div className="flex-1 max-w-xl mx-auto">
          <button
            type="button"
            onClick={() => open()}
            className="w-full rounded-full bg-[#faf8f5] border border-[#e4e0d5] px-4 py-2.5 flex items-center justify-between text-xs text-[#9e9b92] shadow-2xs hover:border-[#171711]/40 transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <Search className="w-3.5 h-3.5 text-[#9e9b92]" />
              <span>Search or type a command...</span>
            </div>
            <kbd className="px-2 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono font-bold text-[#171711]">
              Ctrl+K
            </kbd>
          </button>
        </div>
        <Link
          href="/settings"
          className="p-2.5 rounded-xl hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors shrink-0"
          title="Settings"
        >
          <Menu className="w-4 h-4" />
        </Link>
      </div>

      {/* Greeting Header */}
      <div className="pt-2 sm:pt-4">
        {!effectiveUserName ? (
          <div className="space-y-2">
            <h1 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight">
              {greetingTime}! What should we call you?
            </h1>
            <form
              onSubmit={(e) => {
                e.preventDefault();
                if (nameInput.trim()) {
                  setUserName(nameInput.trim());
                  setNameInput('');
                }
              }}
              className="flex items-center gap-2 max-w-sm"
            >
              <input
                type="text"
                value={nameInput}
                onChange={(e) => setNameInput(e.target.value)}
                placeholder="Enter your name..."
                autoFocus
                className="flex-1 px-3.5 py-2 rounded-xl bg-white border border-[#e4e0d5] focus:border-[#171711] text-sm font-bold text-[#171711] placeholder:text-[#9e9b92] shadow-2xs focus:outline-none transition-colors"
              />
              <button
                type="submit"
                className="px-4 py-2 rounded-xl bg-[#171711] text-white text-xs font-black shadow-xs hover:bg-black transition-all cursor-pointer shrink-0"
              >
                Save
              </button>
              <button
                type="button"
                onClick={() => setUserName('Friend')}
                className="px-2.5 py-2 text-xs font-semibold text-[#8e8d87] hover:text-[#171711] transition-colors cursor-pointer shrink-0"
              >
                Skip
              </button>
            </form>
          </div>
        ) : isEditingName ? (
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (nameInput.trim()) {
                setUserName(nameInput.trim());
              }
              setIsEditingName(false);
            }}
            className="flex items-center gap-2 max-w-md flex-wrap sm:flex-nowrap"
          >
            <span className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight shrink-0">
              {greetingTime},
            </span>
            <input
              type="text"
              value={nameInput}
              onChange={(e) => setNameInput(e.target.value)}
              placeholder="Your name"
              autoFocus
              className="flex-1 min-w-[140px] px-3 py-1 rounded-xl bg-white border border-[#171711] text-xl sm:text-2xl font-black text-[#171711] shadow-2xs focus:outline-none"
            />
            <button
              type="submit"
              className="px-3 py-1.5 rounded-xl bg-[#171711] text-white text-xs font-bold shadow-xs hover:bg-black transition-all cursor-pointer shrink-0"
            >
              Save
            </button>
            <button
              type="button"
              onClick={() => setIsEditingName(false)}
              className="px-2.5 py-1.5 rounded-xl bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] text-xs font-semibold transition-colors cursor-pointer shrink-0"
            >
              Cancel
            </button>
          </form>
        ) : (
          <div className="flex items-center gap-2 group">
            <h1 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight">
              {greetingTime}, {effectiveUserName}.
            </h1>
            <button
              type="button"
              onClick={() => {
                setNameInput(effectiveUserName);
                setIsEditingName(true);
              }}
              title="Edit your name"
              className="opacity-0 group-hover:opacity-100 transition-opacity p-1.5 rounded-lg hover:bg-white text-[#9e9b92] hover:text-[#171711] cursor-pointer"
            >
              <Pencil className="w-3.5 h-3.5" />
            </button>
          </div>
        )}
        <div className="flex flex-wrap items-center justify-between gap-2 mt-0.5">
          <p className="text-xs sm:text-sm text-[#8e8d87] font-medium">
            Here is what needs your attention.
          </p>
          {hasDemoItems && (
            <button
              type="button"
              onClick={() => {
                if (window.confirm('Clear all demo cards to start fresh with an empty LaterBox?')) {
                  clearDemoItems();
                }
              }}
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#6c6b63] hover:text-[#171711] shadow-2xs transition-colors cursor-pointer"
              title="Clear pre-seeded demo items"
            >
              <Sparkles className="w-3.5 h-3.5 text-amber-500" />
              <span>Clear Demo Cards (Start Fresh)</span>
            </button>
          )}
        </div>
      </div>

      {/* Top Metric Cards Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {/* Metric 1: RETURNED TODAY */}
        <Link
          href="/today"
          className="p-4 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] hover:border-[#171711]/30 transition-all flex items-center justify-between group"
        >
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-1">
              RETURNED TODAY
            </span>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-[#171711]" />
              <span className="font-black text-lg text-[#171711]">
                {returnedTodayCount} Items
              </span>
            </div>
          </div>
          <div className="flex items-center -space-x-1.5">
            <div className="w-7 h-7 rounded-lg bg-[#001e36] text-[#31a8ff] font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              Ps
            </div>
            <div className="w-7 h-7 rounded-lg bg-[#ef4444] text-white font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              PDF
            </div>
            <div className="w-7 h-7 rounded-lg bg-[#f0ede4] text-[#6c6b63] font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              +1
            </div>
          </div>
        </Link>

        {/* Metric 2: WAITING IN INBOX */}
        <Link
          href="/inbox"
          className="p-4 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] hover:border-[#171711]/30 transition-all flex items-center justify-between group"
        >
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-1">
              WAITING IN INBOX
            </span>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-[#9e9b92]" />
              <span className="font-black text-lg text-[#171711]">
                {waitingInboxCount} Items
              </span>
            </div>
          </div>
          <div className="flex items-center -space-x-1.5">
            <div className="w-7 h-7 rounded-full bg-[#ea4335] text-white font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              G
            </div>
            <div className="w-7 h-7 rounded-lg bg-[#faf8f5] border border-[#e4e0d5] text-[#171711] font-bold text-[10px] flex items-center justify-center shadow-2xs">
              <FileText className="w-3.5 h-3.5 text-[#6c6b63]" />
            </div>
          </div>
        </Link>
      </div>

      {/* Two-Column Work Area */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-2">
        {/* Left Column: WAITING FOR YOU & COMING UP */}
        <div className="lg:col-span-8 space-y-6">
          {/* Section: WAITING FOR YOU */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92]">
                WAITING FOR YOU
              </span>
              <Link
                href="/inbox"
                className="text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] flex items-center gap-1"
              >
                <span>View Inbox</span>
                <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
            <div className="space-y-2">
              {waitingDisplayItems.length > 0 ? (
                waitingDisplayItems.map((item) => (
                  <ItemCardRow
                    key={item.id}
                    title={item.title}
                    subtitle={item.subtitle}
                    time={item.time}
                    iconType={item.iconType}
                    onClick={() => {
                      if ('item' in item && item.item) {
                        router.push(`/item/${item.item.id}`);
                      } else {
                        open();
                      }
                    }}
                  />
                ))
              ) : (
                <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] text-center text-xs text-[#8e8d87]">
                  All caught up! No items waiting for your attention right now.
                </div>
              )}
            </div>
          </div>

          {/* Section: COMING UP */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92]">
                COMING UP
              </span>
              <Link
                href="/upcoming"
                className="text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] flex items-center gap-1"
              >
                <span>View Upcoming</span>
                <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
            <div className="space-y-2">
              {comingUpDisplayItems.length > 0 ? (
                comingUpDisplayItems.map((item) => (
                  <ItemCardRow
                    key={item.id}
                    title={item.title}
                    subtitle={item.subtitle}
                    time={item.time}
                    iconType={item.iconType}
                    onClick={() => {
                      if ('item' in item && item.item) {
                        router.push(`/item/${item.item.id}`);
                      } else {
                        open();
                      }
                    }}
                  />
                ))
              ) : (
                <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] text-center text-xs text-[#8e8d87]">
                  No upcoming returns scheduled yet.
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Column: QUICK DROP & NEXT RETURN */}
        <div className="lg:col-span-4 space-y-5">
          {/* Quick Drop Box */}
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-3">
              QUICK DROP
            </span>
            <div
              onDragOver={(e) => {
                e.preventDefault();
                setDragging(true);
              }}
              onDragLeave={() => setDragging(false)}
              onDrop={(e) => {
                e.preventDefault();
                setDragging(false);
                const dropped = Array.from(e.dataTransfer.files);
                if (dropped.length) open(false, dropped);
              }}
              className={`p-6 rounded-2xl border-2 border-dashed text-center space-y-2.5 transition-all ${
                dragging
                  ? 'border-[#171711] bg-[#e6edb0]/30 scale-[1.02]'
                  : 'border-[#e4e0d5] bg-[#faf8f5] hover:border-[#171711]/40'
              }`}
            >
              <div className="w-9 h-9 mx-auto rounded-xl bg-[#e6edb0] text-[#171711] flex items-center justify-center shadow-2xs">
                <Upload className="w-4 h-4" />
              </div>
              <p className="font-bold text-xs sm:text-sm text-[#171711]">Drop files or links here</p>
              <p className="text-[11px] text-[#9e9b92] leading-tight max-w-[210px] mx-auto">
                LaterBox will safely store them until you&apos;re ready to deal with them.
              </p>
              <button
                type="button"
                onClick={() => open(true)}
                className="px-4 py-1.5 rounded-full bg-white border border-[#e4e0d5] hover:border-[#171711] text-[#171711] font-bold text-xs shadow-2xs transition-all cursor-pointer"
              >
                Browse Files
              </button>
            </div>
          </div>

          {/* Next Return Box */}
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-2">
              NEXT RETURN
            </span>
            {nextReturn ? (
              <Link
                href={`/item/${nextReturn.id}`}
                className="p-3 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] hover:border-[#171711]/30 flex items-center gap-3 transition-all"
              >
                <div className="w-7 h-7 rounded-lg bg-white text-[#171711] border border-[#e4e0d5] flex items-center justify-center shrink-0">
                  <FileText className="w-3.5 h-3.5" />
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-xs text-[#171711] truncate">{nextReturn.title}</p>
                  <p className="text-[10px] text-[#9e9b92]">{returnLabel(nextReturn.return_at)}</p>
                </div>
              </Link>
            ) : (
              <div className="p-3 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] flex items-center gap-3">
                <div className="w-7 h-7 rounded-lg bg-white text-[#9e9b92] border border-[#e4e0d5] flex items-center justify-center shrink-0">
                  <Clock className="w-3.5 h-3.5" />
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-xs text-[#171711] truncate">No scheduled returns</p>
                  <p className="text-[10px] text-[#9e9b92]">Choose a return time when capturing</p>
                </div>
              </div>
            )}
          </div>

          {/* Someday Header Preview */}
          <div>
            <Link
              href="/someday"
              className="flex items-center justify-between text-[10px] font-black tracking-widest uppercase text-[#9e9b92] hover:text-[#171711] transition-colors group"
            >
              <span>SOMEDAY ({somedayCount})</span>
              <ArrowRight className="w-3 h-3 text-[#9e9b92] group-hover:text-[#171711] transition-colors" />
            </Link>
          </div>
        </div>
      </div>

      <QuickCaptureModal
        isOpen={capture}
        onClose={() => setCapture(false)}
        initialFiles={files}
        browseFiles={browse}
      />
    </div>
  );
}

