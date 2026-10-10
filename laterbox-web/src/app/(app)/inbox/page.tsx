'use client';

import React, { useState, useMemo, useRef } from 'react';
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
} from 'lucide-react';
import { AiOrganizeModal } from '@/components/inbox/AiOrganizeModal';
import { OrganizeSuggestion, OrganizeResponse } from '@/app/api/ai/organize/route';
import { resolveReturnPreset } from '@/lib/utils/schedule';

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
  const { user, userName, setUserName } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
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

      {/* Top Header: Title, Search, AI Organize & Compose/Save */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        {/* Left: Title & Name Greeting */}
        <div className="flex items-center gap-3">
          <div className="flex items-baseline gap-2">
            <h1 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight">
              Inbox
            </h1>
            <span className="text-xs font-bold text-[#8e8d87]">
              ({inboxItems.length})
            </span>
          </div>

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
                <span>+ Name</span>
              </button>
            )
          )}
        </div>

        {/* Center / Right: Omnibar Search & Action Buttons */}
        <div className="flex items-center gap-2.5 flex-1 max-w-xl sm:justify-end">
          {/* Search Omnibar */}
          <div className="relative flex-1 max-w-sm">
            <Search className="w-3.5 h-3.5 text-[#9e9b92] absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              data-search-input="true"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search in inbox..."
              className="w-full pl-9 pr-12 py-2 text-xs bg-white border border-[#e4e0d5] rounded-full text-[#171711] placeholder:text-[#9e9b92] shadow-2xs focus:outline-none focus:border-[#171711] transition-colors"
            />
            <kbd className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[9px] font-mono font-bold text-[#8e8d87] bg-[#ebe7dc] px-1.5 py-0.5 rounded">
              ⌘ K
            </kbd>
          </div>

          {/* AI Organize Button */}
          <button
            type="button"
            onClick={handleGetAiSuggestions}
            disabled={aiLoading}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-full bg-[#e6edb0] hover:bg-[#d8e09e] text-[#171711] text-xs font-bold shadow-2xs transition-all cursor-pointer active:scale-98 disabled:opacity-75 shrink-0"
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
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#171711] text-white hover:bg-black text-xs font-bold shadow-xs transition-all cursor-pointer shrink-0"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Save Item</span>
          </button>
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
