'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { FilterBar } from '@/components/inbox/FilterBar';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
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
  Pencil,
  RefreshCw,
} from 'lucide-react';
import { AiOrganizeModal } from '@/components/inbox/AiOrganizeModal';
import { OrganizeSuggestion, OrganizeResponse } from '@/app/api/ai/organize/route';
import { resolveReturnPreset } from '@/lib/utils/schedule';

export default function InboxPage() {
  const router = useRouter();
  const {
    filteredInboxItems,
    items,
    inboxItems,
    starredItems,
    archivedItems,
    now,
    loading,
    hasDemoItems,
    clearDemoItems,
    restoreDemoItems,
    saveNote,
    createCollection,
    addItemToCollection,
    reschedule,
    collections,
  } = useItems();
  const { user, userName, setUserName } = useAuth();
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortOrder, setSortOrder] = useState<'latest' | 'oldest'>('latest');
  const [captureOpen, setCaptureOpen] = useState(false);
  const [isEditingName, setIsEditingName] = useState(false);
  const [nameInput, setNameInput] = useState('');

  // AI Organize Gemini State
  const [aiModalOpen, setAiModalOpen] = useState(false);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiSummary, setAiSummary] = useState('');
  const [aiModel, setAiModel] = useState('');
  const [aiSuggestions, setAiSuggestions] = useState<OrganizeSuggestion[]>([]);
  const [appliedItems, setAppliedItems] = useState<Set<string>>(new Set());
  const [appliedCollections, setAppliedCollections] = useState<Record<string, string>>({});
  const [appliedNotes, setAppliedNotes] = useState<Set<string>>(new Set());
  const [appliedSchedules, setAppliedSchedules] = useState<Record<string, string>>({});

  const handleGetAiSuggestions = async () => {
    if (aiSuggestions.length > 0 && !aiLoading) {
      setAiModalOpen(true);
      return;
    }

    try {
      setAiLoading(true);
      const res = await fetch('/api/ai/organize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          items: inboxItems,
          existingCollections: collections.map((c) => c.name),
        }),
      });

      const data = (await res.json()) as OrganizeResponse;
      if (data.success && Array.isArray(data.suggestions)) {
        setAiSuggestions(data.suggestions);
        setAiSummary(data.summary || '');
        setAiModel(data.model || 'Gemini 3.5 Flash Lite');
        setAiModalOpen(true);
      }
    } catch (err) {
      console.error('Failed to get AI suggestions:', err);
    } finally {
      setAiLoading(false);
    }
  };

  const handleApplyCollection = async (itemId: string, collectionName: string) => {
    let targetCol = collections.find((c) => c.name.toLowerCase() === collectionName.toLowerCase());
    if (!targetCol) {
      targetCol = await createCollection(collectionName);
    }
    if (targetCol) {
      await addItemToCollection(targetCol.id, itemId);
    }
    setAppliedCollections((prev) => ({ ...prev, [itemId]: collectionName }));
  };

  const handleApplyNextStep = async (itemId: string, nextStep: string) => {
    const item = items.find((i) => i.id === itemId);
    const existing = item?.note?.content ? `${item.note.content}\n\n` : '';
    const newContent = `${existing}• Next step: ${nextStep}`;
    await saveNote(itemId, newContent);
    setAppliedNotes((prev) => new Set(prev).add(itemId));
  };

  const handleApplySchedule = async (
    itemId: string,
    schedule: 'today' | 'tomorrow' | 'weekend' | 'someday'
  ) => {
    const preset =
      schedule === 'today'
        ? 'laterToday'
        : schedule === 'tomorrow'
        ? 'tomorrow'
        : schedule === 'weekend'
        ? 'weekend'
        : 'someday';
    const returnAt = resolveReturnPreset(preset, now);
    await reschedule(itemId, returnAt);
    setAppliedSchedules((prev) => ({ ...prev, [itemId]: schedule }));
  };

  const handleApplyTags = async (itemId: string, tags: string[]) => {
    const item = items.find((i) => i.id === itemId);
    const existing = item?.note?.content ? `${item.note.content}\n` : '';
    const tagsText = tags.join(' ');
    if (!item?.note?.content?.includes(tagsText)) {
      await saveNote(itemId, `${existing}${tagsText}`);
    }
  };

  const handleApplyItem = async (suggestion: OrganizeSuggestion) => {
    await handleApplyCollection(suggestion.itemId, suggestion.collection);
    await handleApplyNextStep(suggestion.itemId, suggestion.nextStep);
    await handleApplySchedule(suggestion.itemId, suggestion.recommendedSchedule);
    await handleApplyTags(suggestion.itemId, suggestion.tags);
    setAppliedItems((prev) => new Set(prev).add(suggestion.itemId));
  };

  const handleApplyAll = async () => {
    for (const suggestion of aiSuggestions) {
      await handleApplyItem(suggestion);
    }
  };

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
            <div className="flex items-center gap-2.5">
              <h1 className="text-3xl font-black text-[#171711] tracking-tight">Inbox</h1>
              {userName ? (
                isEditingName ? (
                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      if (nameInput.trim()) setUserName(nameInput.trim());
                      setIsEditingName(false);
                    }}
                    className="flex items-center gap-1.5"
                  >
                    <input
                      type="text"
                      value={nameInput}
                      onChange={(e) => setNameInput(e.target.value)}
                      autoFocus
                      placeholder="Name"
                      className="px-2.5 py-0.5 text-xs font-bold bg-white border border-[#171711] rounded-full text-[#171711] shadow-2xs focus:outline-none w-28"
                    />
                    <button
                      type="submit"
                      className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-bold shadow-xs hover:bg-black transition-all cursor-pointer"
                    >
                      Save
                    </button>
                    <button
                      type="button"
                      onClick={() => setIsEditingName(false)}
                      className="text-[10px] text-[#8e8d87] hover:text-[#171711] transition-colors cursor-pointer px-1"
                    >
                      ✕
                    </button>
                  </form>
                ) : (
                  <button
                    type="button"
                    onClick={() => {
                      setNameInput(userName);
                      setIsEditingName(true);
                    }}
                    title="Click to edit what LaterBox calls you"
                    className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[#faf8f5] hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] shadow-2xs transition-colors cursor-pointer group"
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                    <span>{userName}</span>
                    <Pencil className="w-2.5 h-2.5 text-[#9e9b92] group-hover:text-[#171711]" />
                  </button>
                )
              ) : (
                isEditingName ? (
                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      if (nameInput.trim()) {
                        setUserName(nameInput.trim());
                        setNameInput('');
                      }
                      setIsEditingName(false);
                    }}
                    className="flex items-center gap-1.5"
                  >
                    <input
                      type="text"
                      value={nameInput}
                      onChange={(e) => setNameInput(e.target.value)}
                      autoFocus
                      placeholder="Your name..."
                      className="px-2.5 py-0.5 text-xs font-bold bg-white border border-[#171711] rounded-full text-[#171711] shadow-2xs focus:outline-none w-32"
                    />
                    <button
                      type="submit"
                      className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-bold shadow-xs hover:bg-black transition-all cursor-pointer"
                    >
                      Save
                    </button>
                    <button
                      type="button"
                      onClick={() => setIsEditingName(false)}
                      className="text-[10px] text-[#8e8d87] hover:text-[#171711] transition-colors cursor-pointer px-1"
                    >
                      ✕
                    </button>
                  </form>
                ) : (
                  <button
                    type="button"
                    onClick={() => {
                      setNameInput('');
                      setIsEditingName(true);
                    }}
                    className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-[#e6edb0]/70 hover:bg-[#e6edb0] border border-[#d0db84] text-[11px] font-bold text-[#171711] shadow-2xs transition-colors cursor-pointer"
                  >
                    <span>+ What&apos;s your name?</span>
                  </button>
                )
              )}
            </div>
            <p className="text-xs sm:text-sm text-[#8e8d87] font-medium mt-0.5">
              {userName
                ? `Welcome back, ${userName}. Capture everything. Review when it matters.`
                : 'Capture everything. Review when it matters.'}
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
              data-search-input="true"
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

          {/* Clear Demo Cards Button (Guest/Local Mode) */}
          {hasDemoItems && (
            <button
              type="button"
              onClick={() => {
                if (window.confirm('Clear all demo cards to start fresh in Guest Mode?')) {
                  clearDemoItems();
                }
              }}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#fbfaf6] hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#6c6b63] hover:text-[#171711] shadow-2xs transition-colors cursor-pointer"
              title="Clear demo items to start fresh"
            >
              <Sparkles className="w-3.5 h-3.5 text-amber-500" />
              <span>Clear Demo Cards</span>
            </button>
          )}

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
            onClick={handleGetAiSuggestions}
            disabled={aiLoading}
            className="w-full bg-[#e6edb0] hover:bg-[#d8e09e] text-[#171711] font-bold text-xs py-2 px-3 rounded-xl flex items-center justify-center gap-1.5 transition-all shadow-2xs cursor-pointer active:scale-98 disabled:opacity-75"
          >
            {aiLoading ? (
              <>
                <RefreshCw className="w-3 h-3 text-[#171711] animate-spin" />
                <span>Thinking with Gemini...</span>
              </>
            ) : aiSuggestions.length > 0 ? (
              <>
                <Sparkles className="w-3 h-3 text-[#171711]" />
                <span>Review Suggestions ({aiSuggestions.length})</span>
              </>
            ) : (
              <>
                <Sparkles className="w-3 h-3 text-[#171711]" />
                <span>Get suggestions</span>
              </>
            )}
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
          <div className="flex items-center gap-3 pt-1">
            <button
              type="button"
              onClick={() => setCaptureOpen(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#171711] hover:bg-black text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Save Item</span>
            </button>
            {!hasDemoItems && (
              <button
                type="button"
                onClick={() => restoreDemoItems()}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-white hover:bg-[#faf8f5] border border-[#e4e0d5] text-xs font-bold text-[#6c6b63] hover:text-[#171711] shadow-2xs transition-all cursor-pointer"
              >
                <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                <span>Restore Demo Cards</span>
              </button>
            )}
          </div>
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

      {/* AI Organize Suggestions Modal */}
      <AiOrganizeModal
        isOpen={aiModalOpen}
        onClose={() => setAiModalOpen(false)}
        suggestions={aiSuggestions}
        summary={aiSummary}
        model={aiModel || 'Gemini 3.5 Flash Lite'}
        onApplyAll={handleApplyAll}
        onApplyItem={handleApplyItem}
        onApplyTags={handleApplyTags}
        onApplyCollection={handleApplyCollection}
        onApplyNextStep={handleApplyNextStep}
        onApplySchedule={handleApplySchedule}
        appliedItems={appliedItems}
        appliedCollections={appliedCollections}
        appliedNotes={appliedNotes}
        appliedSchedules={appliedSchedules}
        onRefresh={handleGetAiSuggestions}
        isRefreshing={aiLoading}
      />
    </div>
  );
}
