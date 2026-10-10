'use client';

import React, { useState, useMemo, useRef, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { InboxExtensionGate } from '@/components/inbox/InboxExtensionGate';
import { EmailInboxTable } from '@/components/inbox/EmailInboxTable';
import { useItems } from '@/lib/store/ItemContext';
import { Collection } from '@/lib/supabase/types';
import { useAuth } from '@/lib/store/AuthContext';
import { QuickCaptureModal } from '@/components/inbox/QuickCaptureModal';
import {
  Search,
  Sparkles,
  Plus,
  Pencil,
  RefreshCw,
  Settings,
  LogOut,
  X,
} from 'lucide-react';
import { AiOrganizeModal } from '@/components/inbox/AiOrganizeModal';
import { OrganizeSuggestion, OrganizeResponse } from '@/app/api/ai/organize/route';
import { resolveReturnPreset } from '@/lib/utils/schedule';
import { SearchLivePreviewDropdown } from '@/components/inbox/SearchLivePreviewDropdown';
import {
  InboxSearchFilters,
  DEFAULT_SEARCH_FILTERS,
} from '@/lib/utils/emailFormatters';

export default function InboxPage() {
  const router = useRouter();
  const {
    items,
    inboxItems,
    now,
    loading,
    saveNote,
    createCollection,
    addItemToCollection,
    reschedule,
    collections,
  } = useItems();
  const { user, userName, setUserName, signOut, isGuest } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearchSubmitted, setIsSearchSubmitted] = useState(false);
  const [isSearchDropdownOpen, setIsSearchDropdownOpen] = useState(false);
  const [searchFilters, setSearchFilters] = useState<InboxSearchFilters>(DEFAULT_SEARCH_FILTERS);
  const searchContainerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  const [captureOpen, setCaptureOpen] = useState(false);
  const [profileMenuOpen, setProfileMenuOpen] = useState(false);
  const [isEditingProfileName, setIsEditingProfileName] = useState(false);
  const [nameInput, setNameInput] = useState('');
  const profileDropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdowns on outside click
  useEffect(() => {
    const handleOutsideClick = (e: MouseEvent) => {
      if (profileDropdownRef.current && !profileDropdownRef.current.contains(e.target as Node)) {
        setProfileMenuOpen(false);
        setIsEditingProfileName(false);
      }
      if (searchContainerRef.current && !searchContainerRef.current.contains(e.target as Node)) {
        setIsSearchDropdownOpen(false);
      }
    };
    window.addEventListener('mousedown', handleOutsideClick);
    return () => window.removeEventListener('mousedown', handleOutsideClick);
  }, []);

  // Global shortcut: Cmd+K / Ctrl+K focuses the search input
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        searchInputRef.current?.focus();
        if (searchQuery.trim().length > 0) {
          setIsSearchDropdownOpen(true);
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [searchQuery]);

  const handleClearSearch = () => {
    setSearchQuery('');
    setIsSearchSubmitted(false);
    setIsSearchDropdownOpen(false);
    setSearchFilters(DEFAULT_SEARCH_FILTERS);
    searchInputRef.current?.focus();
  };

  const effectiveName = userName || user?.user_metadata?.full_name || user?.user_metadata?.display_name || user?.user_metadata?.name || '';
  const userEmail = user?.email || (isGuest ? 'Guest user' : '');

  const userInitials = useMemo(() => {
    if (effectiveName.trim()) {
      const parts = effectiveName.trim().split(/\s+/);
      if (parts.length >= 2) {
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      }
      return parts[0].slice(0, 2).toUpperCase();
    }
    if (userEmail.trim()) {
      return userEmail.slice(0, 2).toUpperCase();
    }
    return 'U';
  }, [effectiveName, userEmail]);

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

  const resolvedCollectionsMap = useRef<Map<string, Collection>>(new Map());

  const handleApplyCollection = async (itemId: string, collectionName: string) => {
    const trimmed = collectionName.trim();
    if (!trimmed) return;
    const lowerKey = trimmed.toLowerCase();

    let targetCol = resolvedCollectionsMap.current.get(lowerKey);
    if (!targetCol) {
      targetCol = collections.find((c) => c.name.trim().toLowerCase() === lowerKey && !c.deleted_at);
    }
    if (!targetCol) {
      targetCol = await createCollection(trimmed);
    }

    if (targetCol) {
      resolvedCollectionsMap.current.set(lowerKey, targetCol);
      await addItemToCollection(targetCol.id, itemId, targetCol);
      setAppliedCollections((prev) => ({ ...prev, [itemId]: targetCol?.name || trimmed }));
    }
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

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-4">
      <InboxExtensionGate userId={user?.id} />

      {/* Top Header: Title, Centered Search, AI Organize, Save Item, Settings & Profile */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        {/* Left: Clean Inbox Title (No unread count) */}
        <div className="shrink-0">
          <h1 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight">
            Inbox
          </h1>
        </div>

        {/* Center: Bigger, Centered Search Input with Live Preview Dropdown */}
        <div
          ref={searchContainerRef}
          className="order-last md:order-none w-full md:flex-1 md:max-w-xl lg:max-w-2xl md:mx-4 relative"
        >
          <div className="relative w-full">
            <Search className="w-4 h-4 text-[#9e9b92] absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              ref={searchInputRef}
              type="text"
              data-search-input="true"
              value={searchQuery}
              onChange={(e) => {
                const val = e.target.value;
                setSearchQuery(val);
                setIsSearchSubmitted(false);
                setIsSearchDropdownOpen(val.trim().length > 0);
              }}
              onFocus={() => {
                if (searchQuery.trim().length > 0 && !isSearchSubmitted) {
                  setIsSearchDropdownOpen(true);
                }
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  setIsSearchSubmitted(true);
                  setIsSearchDropdownOpen(false);
                } else if (e.key === 'Escape') {
                  setIsSearchDropdownOpen(false);
                }
              }}
              placeholder="Search in inbox..."
              className="w-full pl-11 pr-16 py-2.5 text-sm bg-white border border-[#e4e0d5] rounded-full text-[#171711] placeholder:text-[#9e9b92] shadow-2xs focus:outline-none focus:border-[#171711] hover:border-[#171711]/40 transition-colors"
            />
            {searchQuery.length > 0 ? (
              <button
                type="button"
                onClick={handleClearSearch}
                title="Clear search"
                className="absolute right-3.5 top-1/2 -translate-y-1/2 p-1 text-[#9e9b92] hover:text-[#171711] rounded-full hover:bg-[#faf8f5] transition-colors cursor-pointer"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            ) : (
              <kbd className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[10px] font-mono font-bold text-[#8e8d87] bg-[#ebe7dc] px-2 py-0.5 rounded-md pointer-events-none">
                ⌘ K
              </kbd>
            )}
          </div>

          {/* Live Preview Dropdown when typing */}
          {isSearchDropdownOpen && searchQuery.trim().length > 0 && (
            <SearchLivePreviewDropdown
              searchQuery={searchQuery}
              items={inboxItems}
              filters={searchFilters}
              onUpdateFilters={setSearchFilters}
              onSelectAllResults={() => {
                setIsSearchSubmitted(true);
                setIsSearchDropdownOpen(false);
                searchInputRef.current?.focus();
              }}
              onSelectItem={(item) => {
                setIsSearchDropdownOpen(false);
                router.push(`/item/${item.id}`);
              }}
            />
          )}
        </div>

        {/* Right: Actions, Settings Icon & User Profile Dropdown */}
        <div className="flex items-center gap-2 sm:gap-2.5 shrink-0 ml-auto md:ml-0">
          {/* AI Organize Button */}
          <button
            type="button"
            onClick={handleGetAiSuggestions}
            disabled={aiLoading}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full bg-[#e6edb0] hover:bg-[#d8e09e] text-[#171711] text-xs font-bold shadow-2xs transition-all cursor-pointer active:scale-98 disabled:opacity-75"
            title="AI organize inbox items"
          >
            {aiLoading ? (
              <>
                <RefreshCw className="w-3.5 h-3.5 text-[#171711] animate-spin" />
                <span className="hidden sm:inline">Thinking...</span>
              </>
            ) : aiSuggestions.length > 0 ? (
              <>
                <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
                <span>Review AI ({aiSuggestions.length})</span>
              </>
            ) : (
              <>
                <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
                <span className="hidden sm:inline">AI organize</span>
              </>
            )}
          </button>

          {/* Save Item / Compose Button */}
          <button
            type="button"
            onClick={() => setCaptureOpen(true)}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full bg-[#171711] text-white hover:bg-black text-xs font-bold shadow-xs transition-all cursor-pointer"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Save Item</span>
          </button>

          {/* Settings Icon Link */}
          <Link
            href="/settings"
            title="Settings"
            className="w-9 h-9 rounded-full bg-white border border-[#e4e0d5] hover:border-[#171711] hover:bg-[#faf8f5] flex items-center justify-center text-[#6c6b63] hover:text-[#171711] shadow-2xs transition-colors cursor-pointer shrink-0"
          >
            <Settings className="w-4 h-4" />
          </Link>

          {/* User Profile Avatar / Initials Dropdown */}
          <div className="relative shrink-0" ref={profileDropdownRef}>
            <button
              type="button"
              onClick={() => setProfileMenuOpen((prev) => !prev)}
              title={effectiveName || userEmail || 'Account menu'}
              className="w-9 h-9 rounded-full bg-[#171711] text-[#e6edb0] font-black text-xs flex items-center justify-center shadow-2xs border-2 border-white hover:scale-105 transition-transform cursor-pointer"
            >
              {userInitials}
            </button>

            {profileMenuOpen && (
              <div className="absolute right-0 top-full mt-2 w-72 bg-white border border-[#e4e0d5] rounded-2xl shadow-xl p-3.5 z-50 text-[#171711] animate-in fade-in zoom-in-95">
                {/* Profile Header Card */}
                <div className="flex items-center gap-3 pb-3 border-b border-[#f0ede4]">
                  <div className="w-10 h-10 rounded-full bg-[#171711] text-[#e6edb0] font-black text-sm flex items-center justify-center shrink-0 shadow-2xs">
                    {userInitials}
                  </div>
                  <div className="min-w-0 flex-1">
                    {effectiveName ? (
                      <div className="flex items-center gap-1.5 group">
                        <p className="text-xs sm:text-sm font-black text-[#171711] truncate">
                          {effectiveName}
                        </p>
                        <button
                          type="button"
                          onClick={() => {
                            setNameInput(effectiveName);
                            setIsEditingProfileName(true);
                          }}
                          title="Edit name"
                          className="p-1 text-[#9e9b92] hover:text-[#171711] rounded hover:bg-[#faf8f5] transition-colors"
                        >
                          <Pencil className="w-2.5 h-2.5" />
                        </button>
                      </div>
                    ) : (
                      <p className="text-xs font-semibold text-[#8e8d87]">No name set</p>
                    )}
                    <p className="text-[11px] text-[#9e9b92] truncate">
                      {userEmail || 'Guest user'}
                    </p>
                  </div>
                </div>

                {/* Add/Edit Name Form */}
                {(!effectiveName || isEditingProfileName) && (
                  <form
                    onSubmit={(e) => {
                      e.preventDefault();
                      if (nameInput.trim()) {
                        setUserName(nameInput.trim());
                        setNameInput('');
                        setIsEditingProfileName(false);
                      }
                    }}
                    className="pt-2.5 pb-2 border-b border-[#f0ede4] space-y-1.5"
                  >
                    <label className="text-[10px] font-bold text-[#9e9b92] uppercase tracking-wider block">
                      {effectiveName ? 'Edit your name' : 'Add your name'}
                    </label>
                    <div className="flex items-center gap-1.5">
                      <input
                        type="text"
                        value={nameInput}
                        onChange={(e) => setNameInput(e.target.value)}
                        placeholder="Enter name..."
                        autoFocus
                        className="flex-1 px-2.5 py-1.5 text-xs bg-[#faf8f5] border border-[#e4e0d5] focus:border-[#171711] rounded-xl text-[#171711] focus:outline-none"
                      />
                      <button
                        type="submit"
                        className="px-3 py-1.5 rounded-xl bg-[#171711] text-white text-xs font-bold hover:bg-black transition-colors cursor-pointer shrink-0"
                      >
                        Save
                      </button>
                      {isEditingProfileName && (
                        <button
                          type="button"
                          onClick={() => setIsEditingProfileName(false)}
                          className="px-2 py-1.5 text-xs text-[#8e8d87] hover:text-[#171711] cursor-pointer shrink-0"
                        >
                          ✕
                        </button>
                      )}
                    </div>
                  </form>
                )}

                {/* Menu Options */}
                <div className="pt-2 space-y-1">
                  <Link
                    href="/settings"
                    onClick={() => setProfileMenuOpen(false)}
                    className="flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-bold text-[#171711] hover:bg-[#faf8f5] transition-colors"
                  >
                    <Settings className="w-4 h-4 text-[#6c6b63]" />
                    <span>Settings</span>
                  </Link>

                  <button
                    type="button"
                    onClick={async () => {
                      setProfileMenuOpen(false);
                      await signOut();
                      router.push('/login');
                    }}
                    className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-bold text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer text-left"
                  >
                    <LogOut className="w-4 h-4" />
                    <span>Log out</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Main Content: Email Client Inbox View */}
      {loading ? (
        <div className="bg-white border border-[#e4e0d5] rounded-2xl p-12 text-center animate-pulse">
          <p className="text-xs font-semibold text-[#8e8d87]">Loading inbox messages...</p>
        </div>
      ) : (
        <EmailInboxTable
          items={inboxItems}
          onOpenCapture={() => setCaptureOpen(true)}
          searchQuery={searchQuery}
          isSearchSubmitted={isSearchSubmitted}
          searchFilters={searchFilters}
          onUpdateFilters={setSearchFilters}
          onClearSearch={handleClearSearch}
        />
      )}

      <QuickCaptureModal isOpen={captureOpen} onClose={() => setCaptureOpen(false)} />

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
