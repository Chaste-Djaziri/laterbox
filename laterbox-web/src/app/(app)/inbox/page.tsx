'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { FilterBar } from '@/components/inbox/FilterBar';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { useItems } from '@/lib/store/ItemContext';
import { QuickCaptureModal } from '@/components/inbox/QuickCaptureModal';
import { scheduleItems } from '@/lib/utils/schedule';
import {
  ArrowLeft,
  Search,
  LayoutGrid,
  List,
  HelpCircle,
  Sun,
  FileText,
  Clock,
  Star,
  CheckCircle2,
  ChevronRight,
  Sparkles,
  Play,
  Package,
  Plus,
} from 'lucide-react';

export default function InboxPage() {
  const router = useRouter();
  const { filteredInboxItems, items, inboxItems, starredItems, archivedItems, now, loading } = useItems();
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortOrder, setSortOrder] = useState<'latest' | 'oldest'>('latest');
  const [captureOpen, setCaptureOpen] = useState(false);
  const [aiSuggestionsActive, setAiSuggestionsActive] = useState(false);

  const todayCount = useMemo(() => scheduleItems(items, 'today', now).length, [items, now]);

  const displayedItems = useMemo(() => {
    let list = filteredInboxItems.filter((item) => {
      if (!searchQuery.trim()) return true;
      const q = searchQuery.toLowerCase();
      const title = (item.metadata?.title || item.title || '').toLowerCase();
      const domain = (item.metadata?.domain || item.url || '').toLowerCase();
      const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
      return title.includes(q) || domain.includes(q) || desc.includes(q);
    });

    list.sort((a, b) => {
      const timeA = new Date(a.created_at).getTime();
      const timeB = new Date(b.created_at).getTime();
      return sortOrder === 'latest' ? timeB - timeA : timeA - timeB;
    });

    return list;
  }, [filteredInboxItems, searchQuery, sortOrder]);

  const continueReviewItem = useMemo(() => {
    return (
      inboxItems.find((i) => i.type === 'video' || i.url?.includes('youtube.com')) ||
      inboxItems[0] ||
      null
    );
  }, [inboxItems]);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6">
      {/* ========================================================================= */}
      {/* Top Header & Omnibar Controls */}
      {/* ========================================================================= */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        {/* Left Title & Back button */}
        <div className="flex items-center gap-3.5">
          <button
            type="button"
            onClick={() => router.back()}
            className="w-8 h-8 rounded-xl bg-white border border-[#e4e0d5] hover:border-[#171711]/40 flex items-center justify-center text-[#171711] shadow-2xs transition-all cursor-pointer shrink-0"
            title="Go back"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <div>
            <h1 className="text-3xl font-black text-[#171711] tracking-tight">Inbox</h1>
            <p className="text-xs sm:text-sm text-[#8e8d87] font-medium mt-0.5">
              Capture everything. Review when it matters.
            </p>
          </div>
        </div>

        {/* Right Controls */}
        <div className="flex items-center gap-2.5 flex-wrap">
          {/* Search Pill Input */}
          <div className="relative flex-1 sm:w-60">
            <Search className="w-3.5 h-3.5 text-[#9e9b92] absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search your inbox..."
              className="w-full pl-9 pr-12 py-1.5 text-xs bg-white border border-[#e4e0d5] rounded-full text-[#171711] placeholder:text-[#9e9b92] shadow-2xs focus:outline-none focus:border-[#171711] transition-colors"
            />
            <kbd className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[9px] font-mono font-bold text-[#8e8d87] bg-[#ebe7dc] px-1.5 py-0.5 rounded">
              ⌘ K
            </kbd>
          </div>

          {/* View Mode Switcher */}
          <div className="flex items-center p-0.5 bg-white border border-[#e4e0d5] rounded-xl shadow-2xs">
            <button
              type="button"
              onClick={() => setViewMode('grid')}
              title="Grid View"
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === 'grid'
                  ? 'bg-[#171711] text-white shadow-2xs'
                  : 'text-[#6c6b63] hover:text-[#171711]'
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
            </button>
            <button
              type="button"
              onClick={() => setViewMode('list')}
              title="List View"
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === 'list'
                  ? 'bg-[#171711] text-white shadow-2xs'
                  : 'text-[#6c6b63] hover:text-[#171711]'
              }`}
            >
              <List className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Local Mode Badge */}
          <div className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white border border-[#e4e0d5] text-xs font-semibold text-[#171711] shadow-2xs">
            <span className="w-2 h-2 rounded-full bg-emerald-500" />
            <span>Local Mode</span>
          </div>

          {/* Tutorial Link */}
          <Link
            href="/tutorial"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white border border-[#e4e0d5] text-xs font-semibold text-[#6c6b63] hover:text-[#171711] shadow-2xs transition-colors"
          >
            <HelpCircle className="w-3.5 h-3.5 text-[#9e9b92]" />
            <span className="hidden md:inline">Tutorial</span>
          </Link>

          {/* Theme / Mode Toggle Icon */}
          <button
            type="button"
            className="p-2 rounded-full bg-white border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] shadow-2xs transition-colors cursor-pointer"
            title="Theme Mode"
          >
            <Sun className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* Top 3 Summary/Widget Cards Row */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
        {/* Card 1: 4 Metrics Columns */}
        <div className="md:col-span-12 lg:col-span-5 bg-white border border-[#e4e0d5] rounded-2xl p-4 shadow-2xs flex items-center justify-between">
          {/* Col 1: Items saved */}
          <div className="flex-1 text-center sm:text-left px-2">
            <div className="w-7 h-7 rounded-lg bg-[#e6edb0] text-[#171711] flex items-center justify-center">
              <FileText className="w-3.5 h-3.5" />
            </div>
            <p className="text-xl font-black text-[#171711] mt-2 leading-none">
              {inboxItems.length > 0 ? inboxItems.length : 5}
            </p>
            <p className="text-[11px] text-[#9e9b92] font-medium mt-1">Items saved</p>
          </div>

          <div className="w-px h-10 bg-[#e4e0d5]/60" />

          {/* Col 2: To review */}
          <div className="flex-1 text-center sm:text-left px-2 pl-3">
            <div className="w-7 h-7 rounded-lg bg-[#fef3c7] text-[#d97706] flex items-center justify-center">
              <Clock className="w-3.5 h-3.5" />
            </div>
            <p className="text-xl font-black text-[#171711] mt-2 leading-none">
              {todayCount > 0 ? todayCount : 3}
            </p>
            <p className="text-[11px] text-[#9e9b92] font-medium mt-1">To review</p>
          </div>

          <div className="w-px h-10 bg-[#e4e0d5]/60" />

          {/* Col 3: Starred */}
          <div className="flex-1 text-center sm:text-left px-2 pl-3">
            <div className="w-7 h-7 rounded-lg bg-[#fef9c3] text-[#ca8a04] flex items-center justify-center">
              <Star className="w-3.5 h-3.5 fill-[#ca8a04]" />
            </div>
            <p className="text-xl font-black text-[#171711] mt-2 leading-none">
              {starredItems.length > 0 ? starredItems.length : 1}
            </p>
            <p className="text-[11px] text-[#9e9b92] font-medium mt-1">Starred</p>
          </div>

          <div className="w-px h-10 bg-[#e4e0d5]/60" />

          {/* Col 4: Processed */}
          <div className="flex-1 text-center sm:text-left px-2 pl-3">
            <div className="w-7 h-7 rounded-lg bg-[#dcfce7] text-[#16a34a] flex items-center justify-center">
              <CheckCircle2 className="w-3.5 h-3.5" />
            </div>
            <p className="text-xl font-black text-[#171711] mt-2 leading-none">
              {archivedItems.length}
            </p>
            <p className="text-[11px] text-[#9e9b92] font-medium mt-1">Processed</p>
          </div>
        </div>

        {/* Card 2: Continue Reviewing */}
        <div
          onClick={() => {
            if (continueReviewItem) router.push(`/item/${continueReviewItem.id}`);
          }}
          className="md:col-span-6 lg:col-span-4 bg-white border border-[#e4e0d5] hover:border-[#171711]/30 rounded-2xl p-4 shadow-2xs flex flex-col justify-between transition-all cursor-pointer group"
        >
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-bold text-[#171711]">Continue reviewing</span>
            <ChevronRight className="w-3.5 h-3.5 text-[#9e9b92] group-hover:text-[#171711] transition-colors" />
          </div>

          <div className="flex items-center gap-3">
            <div className="relative w-16 h-12 rounded-xl overflow-hidden bg-neutral-900 shrink-0 border border-[#e4e0d5]">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={continueReviewItem?.metadata?.preview_image_url || 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80'}
                alt=""
                className="w-full h-full object-cover"
              />
              <div className="absolute bottom-1 right-1 w-4 h-4 rounded-full bg-white text-[#ea4335] shadow-xs flex items-center justify-center">
                <Play className="w-2 h-2 fill-[#ea4335]" />
              </div>
            </div>

            <div className="min-w-0">
              <p className="text-xs font-bold text-[#171711] truncate group-hover:text-black">
                {continueReviewItem?.title || 'Building Distributed Edge Apps...'}
              </p>
              <p className="text-[11px] text-[#9e9b92] mt-0.5">
                {continueReviewItem?.metadata?.site_name || 'YouTube'} • 1 day ago
              </p>
            </div>
          </div>
        </div>

        {/* Card 3: AI Organize Beta */}
        <div className="md:col-span-6 lg:col-span-3 bg-white border border-[#e4e0d5] rounded-2xl p-4 shadow-2xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-[#ca8a04]" />
              <span className="text-xs font-bold text-[#171711]">AI organize</span>
              <span className="px-1.5 py-0.2 rounded-full bg-[#e6edb0] text-[#171711] text-[9px] font-black uppercase">
                Beta
              </span>
            </div>
            <ChevronRight className="w-3.5 h-3.5 text-[#9e9b92]" />
          </div>

          <p className="text-[11px] text-[#8e8d87] leading-tight my-2">
            Let AI suggest tags, collections, and next steps for your inbox items.
          </p>

          <button
            type="button"
            onClick={() => setAiSuggestionsActive(!aiSuggestionsActive)}
            className="w-full bg-[#e6edb0] hover:bg-[#d8e09e] text-[#171711] font-bold text-xs py-2 px-3 rounded-xl flex items-center justify-center gap-1.5 transition-all shadow-2xs cursor-pointer active:scale-98"
          >
            <Sparkles className="w-3 h-3 text-[#171711]" />
            <span>{aiSuggestionsActive ? 'Tags Analyzed ✓' : 'Get suggestions'}</span>
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* Filter Bar Chips & Sort Selector */}
      {/* ========================================================================= */}
      <FilterBar sortOrder={sortOrder} onSortChange={setSortOrder} />

      {/* ========================================================================= */}
      {/* Main Items Work Area */}
      {/* ========================================================================= */}
      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 animate-pulse">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <div key={i} className="h-64 rounded-2xl bg-white border border-[#e4e0d5]" />
          ))}
        </div>
      ) : displayedItems.length === 0 ? (
        <div className="flex flex-col items-center justify-center min-h-[40vh] text-center px-4 space-y-3 bg-white rounded-3xl border border-[#e4e0d5] p-10">
          <div className="w-12 h-12 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] flex items-center justify-center text-[#171711] shadow-2xs">
            <Package className="w-6 h-6 stroke-[1.75]" />
          </div>
          <div>
            <h3 className="text-base font-bold text-[#171711]">
              {searchQuery ? 'No items match your search' : 'Your inbox is clear'}
            </h3>
            <p className="text-xs text-[#8e8d87] max-w-sm mx-auto mt-1">
              {searchQuery
                ? 'Try a different search query or clear the filter.'
                : 'Items appear here when their return time arrives.'}
            </p>
          </div>
          <button
            type="button"
            onClick={() => setCaptureOpen(true)}
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#171711] hover:bg-black text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Save Item</span>
          </button>
        </div>
      ) : viewMode === 'grid' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 sm:gap-6">
          {displayedItems.map((item) => (
            <ItemCard key={item.id} item={item} />
          ))}
        </div>
      ) : (
        <div className="space-y-2.5">
          {displayedItems.map((item) => (
            <ItemListRow key={item.id} item={item} />
          ))}
        </div>
      )}

      <QuickCaptureModal isOpen={captureOpen} onClose={() => setCaptureOpen(false)} />
    </div>
  );
}
