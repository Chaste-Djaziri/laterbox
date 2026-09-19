'use client';

import React, { useState } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { OrganizeSuggestion } from '@/app/api/ai/organize/route';
import {
  Sparkles,
  X,
  Check,
  CheckCircle2,
  FolderPlus,
  Tag,
  Clock,
  ArrowRight,
  RefreshCw,
  Folder,
  FileText,
  PlayCircle,
  Music2,
  StickyNote,
  Layers,
  ChevronRight,
  ExternalLink,
} from 'lucide-react';

interface AiOrganizeModalProps {
  isOpen: boolean;
  onClose: () => void;
  suggestions: OrganizeSuggestion[];
  summary: string;
  model: string;
  onApplyAll: () => Promise<void>;
  onApplyItem: (suggestion: OrganizeSuggestion) => Promise<void>;
  onApplyTags: (itemId: string, tags: string[]) => Promise<void>;
  onApplyCollection: (itemId: string, collectionName: string) => Promise<void>;
  onApplyNextStep: (itemId: string, nextStep: string) => Promise<void>;
  onApplySchedule: (itemId: string, schedule: 'today' | 'tomorrow' | 'weekend' | 'someday') => Promise<void>;
  appliedItems: Set<string>;
  appliedCollections: Record<string, string>;
  appliedNotes: Set<string>;
  appliedSchedules: Record<string, string>;
  onRefresh?: () => void;
  isRefreshing?: boolean;
}

export function AiOrganizeModal({
  isOpen,
  onClose,
  suggestions,
  summary,
  model,
  onApplyAll,
  onApplyItem,
  onApplyTags,
  onApplyCollection,
  onApplyNextStep,
  onApplySchedule,
  appliedItems,
  appliedCollections,
  appliedNotes,
  appliedSchedules,
  onRefresh,
  isRefreshing,
}: AiOrganizeModalProps) {
  const { items } = useItems();
  const [applyingAll, setApplyingAll] = useState(false);
  const [activeItemApplying, setActiveItemApplying] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleApplyAllClick = async () => {
    try {
      setApplyingAll(true);
      await onApplyAll();
    } finally {
      setApplyingAll(false);
    }
  };

  const handleApplyItemClick = async (suggestion: OrganizeSuggestion) => {
    try {
      setActiveItemApplying(suggestion.itemId);
      await onApplyItem(suggestion);
    } finally {
      setActiveItemApplying(null);
    }
  };

  const getItemBadge = (item?: any) => {
    if (!item) return null;
    const ext = item.url?.split('.').pop()?.toLowerCase() || '';
    const isPsd = ext === 'psd' || item.title?.toLowerCase().endsWith('.psd');
    const isPdf = ext === 'pdf' || item.title?.toLowerCase().endsWith('.pdf');
    const isYoutube = item.url?.includes('youtube.com') || item.url?.includes('youtu.be');
    const isSpotify = item.url?.includes('spotify.com');
    const isNote = !item.url && (item.type === 'note' || !!item.text_content);

    if (isPsd) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-[#001e36] text-[#31a8ff] text-[10px] font-black shrink-0">
          Ps
        </span>
      );
    }
    if (isPdf) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-red-100 text-red-600 text-[10px] font-black shrink-0">
          PDF
        </span>
      );
    }
    if (isYoutube) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-red-50 text-red-600 text-[10px] font-bold shrink-0">
          <PlayCircle className="w-3 h-3 text-red-600" />
          Video
        </span>
      );
    }
    if (isSpotify) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[10px] font-bold shrink-0">
          <Music2 className="w-3 h-3 text-emerald-600" />
          Music
        </span>
      );
    }
    if (isNote) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[#171711] text-[10px] font-bold shrink-0">
          <StickyNote className="w-3 h-3 text-[#6c6b63]" />
          Note
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[#6c6b63] text-[10px] font-bold shrink-0">
        <FileText className="w-3 h-3 text-[#6c6b63]" />
        Link
      </span>
    );
  };

  const getScheduleLabel = (sched: string) => {
    switch (sched) {
      case 'today':
        return '☀️ Later Today';
      case 'tomorrow':
        return '🌅 Tomorrow 09:00 AM';
      case 'weekend':
        return '📅 This Weekend';
      case 'someday':
        return '📦 Someday Vault';
      default:
        return 'Schedule Return';
    }
  };

  const allApplied = suggestions.length > 0 && suggestions.every((s) => appliedItems.has(s.itemId));

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-[#171711]/50 backdrop-blur-xs transition-opacity animate-in fade-in duration-150"
      onClick={onClose}
    >
      <div
        className="w-full max-w-3xl bg-[#faf8f5] border border-[#e4e0d5] rounded-3xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh] transition-all animate-in zoom-in-98 duration-150"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#e4e0d5] bg-white">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center text-[#171711] shrink-0">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-black text-[#171711] tracking-tight">
                  AI Inbox Organizer
                </h3>
                <span className="px-2 py-0.5 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black uppercase">
                  Beta
                </span>
              </div>
              <p className="text-[11px] text-[#6c6b63]">
                Smart suggestions for tags, collections, schedules, and next steps.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {onRefresh && (
              <button
                type="button"
                onClick={onRefresh}
                disabled={isRefreshing}
                className="p-2 rounded-xl text-[#6c6b63] hover:text-[#171711] hover:bg-[#f7f5ee] transition-colors cursor-pointer disabled:opacity-50"
                title="Regenerate suggestions"
              >
                <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              className="p-2 rounded-xl text-[#6c6b63] hover:text-[#171711] hover:bg-[#f7f5ee] transition-colors cursor-pointer"
              title="Close modal"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Summary Banner & Bulk Action */}
        <div className="px-6 py-3.5 bg-gradient-to-r from-[#f7f5ee] to-[#ebe7dc]/50 border-b border-[#e4e0d5] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="space-y-0.5">
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-[#171711]">AI Analysis</span>
              <span className="text-[10px] font-mono font-medium px-2 py-0.5 rounded-full bg-white border border-[#e4e0d5] text-[#6c6b63]">
                {model}
              </span>
            </div>
            <p className="text-xs text-[#6c6b63] leading-snug">
              {summary || `Generated recommendations for ${suggestions.length} items.`}
            </p>
          </div>

          <button
            type="button"
            onClick={handleApplyAllClick}
            disabled={applyingAll || allApplied || suggestions.length === 0}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all shadow-xs flex items-center justify-center gap-1.5 shrink-0 cursor-pointer ${
              allApplied
                ? 'bg-[#e6edb0] text-[#171711] cursor-default'
                : 'bg-[#171711] hover:bg-black active:scale-98 text-white'
            }`}
          >
            {allApplied ? (
              <>
                <Check className="w-3.5 h-3.5" />
                <span>All Applied ✓</span>
              </>
            ) : applyingAll ? (
              <>
                <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                <span>Applying All...</span>
              </>
            ) : (
              <>
                <Sparkles className="w-3.5 h-3.5 text-[#e6edb0]" />
                <span>Apply All Suggestions</span>
              </>
            )}
          </button>
        </div>

        {/* Suggestions List Container */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {suggestions.length === 0 ? (
            <div className="py-12 text-center space-y-2">
              <div className="w-12 h-12 rounded-2xl bg-[#ebe7dc] flex items-center justify-center mx-auto text-[#6c6b63]">
                <Sparkles className="w-6 h-6" />
              </div>
              <h4 className="text-sm font-bold text-[#171711]">No suggestions available</h4>
              <p className="text-xs text-[#6c6b63]">Your inbox may be empty or already organized.</p>
            </div>
          ) : (
            suggestions.map((suggestion) => {
              const item = items.find((i) => i.id === suggestion.itemId);
              const isItemApplied = appliedItems.has(suggestion.itemId);
              const isCollectionApplied = appliedCollections[suggestion.itemId] === suggestion.collection;
              const isNoteApplied = appliedNotes.has(suggestion.itemId);
              const isScheduleApplied = !!appliedSchedules[suggestion.itemId];
              const isApplying = activeItemApplying === suggestion.itemId;

              return (
                <div
                  key={suggestion.itemId}
                  className={`p-5 rounded-2xl border transition-all ${
                    isItemApplied
                      ? 'bg-white/80 border-[#d0db84] shadow-2xs'
                      : 'bg-white border-[#e4e0d5] hover:border-[#171711]/30 shadow-xs'
                  }`}
                >
                  {/* Top Item Row */}
                  <div className="flex items-start justify-between gap-3 pb-3 border-b border-[#f0ece1]">
                    <div className="flex items-start gap-2.5 min-w-0">
                      <div className="pt-0.5">{getItemBadge(item)}</div>
                      <div className="min-w-0">
                        <h4 className="text-xs sm:text-sm font-bold text-[#171711] truncate">
                          {item?.title || item?.metadata?.title || 'Saved Item'}
                        </h4>
                        {item?.url && (
                          <p className="text-[10px] text-[#9e9b92] truncate mt-0.5">{item.url}</p>
                        )}
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => handleApplyItemClick(suggestion)}
                      disabled={isItemApplied || isApplying}
                      className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all shrink-0 cursor-pointer ${
                        isItemApplied
                          ? 'bg-[#e6edb0] text-[#171711] cursor-default'
                          : 'bg-[#f7f5ee] hover:bg-[#171711] hover:text-white border border-[#e4e0d5] text-[#171711]'
                      }`}
                    >
                      {isItemApplied ? (
                        <span className="flex items-center gap-1">
                          <Check className="w-3 h-3" />
                          Applied
                        </span>
                      ) : isApplying ? (
                        <span className="flex items-center gap-1">
                          <RefreshCw className="w-3 h-3 animate-spin" />
                          Applying...
                        </span>
                      ) : (
                        <span>Apply Item</span>
                      )}
                    </button>
                  </div>

                  {/* Recommendation Grid */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-3">
                    {/* Tags Section */}
                    <div className="space-y-1.5 bg-[#faf8f5] p-3 rounded-xl border border-[#e4e0d5]/60">
                      <div className="flex items-center gap-1.5 text-[10px] font-black uppercase text-[#9e9b92]">
                        <Tag className="w-3 h-3" />
                        <span>Suggested Tags</span>
                      </div>
                      <div className="flex items-center gap-1.5 flex-wrap">
                        {suggestion.tags.map((tag) => (
                          <button
                            key={tag}
                            type="button"
                            onClick={() => onApplyTags(suggestion.itemId, [tag])}
                            className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-mono font-medium bg-white border border-[#e4e0d5] text-[#171711] hover:bg-[#e6edb0] transition-colors cursor-pointer"
                            title={`Add ${tag}`}
                          >
                            <span>{tag}</span>
                            <span className="text-[#9e9b92] text-[10px]">+</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Collection Section */}
                    <div className="space-y-1.5 bg-[#faf8f5] p-3 rounded-xl border border-[#e4e0d5]/60">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5 text-[10px] font-black uppercase text-[#9e9b92]">
                          <Folder className="w-3 h-3" />
                          <span>Suggested Collection</span>
                        </div>
                        <button
                          type="button"
                          onClick={() => onApplyCollection(suggestion.itemId, suggestion.collection)}
                          disabled={isCollectionApplied}
                          className={`text-[10px] font-bold cursor-pointer transition-colors ${
                            isCollectionApplied
                              ? 'text-[#27c93f]'
                              : 'text-[#171711] hover:underline'
                          }`}
                        >
                          {isCollectionApplied ? '✓ Added' : '+ Add'}
                        </button>
                      </div>
                      <div className="flex items-center gap-2 text-xs font-bold text-[#171711]">
                        <span className="w-5 h-5 rounded-md bg-[#e6edb0] flex items-center justify-center text-[10px]">
                          📁
                        </span>
                        <span className="truncate">{suggestion.collection}</span>
                      </div>
                    </div>

                    {/* Next Step Section */}
                    <div className="space-y-1.5 bg-[#faf8f5] p-3 rounded-xl border border-[#e4e0d5]/60">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5 text-[10px] font-black uppercase text-[#9e9b92]">
                          <Sparkles className="w-3 h-3 text-[#ca8a04]" />
                          <span>Actionable Next Step</span>
                        </div>
                        <button
                          type="button"
                          onClick={() => onApplyNextStep(suggestion.itemId, suggestion.nextStep)}
                          disabled={isNoteApplied}
                          className={`text-[10px] font-bold cursor-pointer transition-colors ${
                            isNoteApplied
                              ? 'text-[#27c93f]'
                              : 'text-[#171711] hover:underline'
                          }`}
                        >
                          {isNoteApplied ? '✓ Saved' : '+ Save Note'}
                        </button>
                      </div>
                      <p className="text-xs text-[#171711] font-medium leading-snug">
                        {suggestion.nextStep}
                      </p>
                    </div>

                    {/* Schedule Section */}
                    <div className="space-y-1.5 bg-[#faf8f5] p-3 rounded-xl border border-[#e4e0d5]/60">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5 text-[10px] font-black uppercase text-[#9e9b92]">
                          <Clock className="w-3 h-3" />
                          <span>Recommended Return</span>
                        </div>
                        <button
                          type="button"
                          onClick={() => onApplySchedule(suggestion.itemId, suggestion.recommendedSchedule)}
                          disabled={isScheduleApplied}
                          className={`text-[10px] font-bold cursor-pointer transition-colors ${
                            isScheduleApplied
                              ? 'text-[#27c93f]'
                              : 'text-[#171711] hover:underline'
                          }`}
                        >
                          {isScheduleApplied ? '✓ Scheduled' : 'Schedule'}
                        </button>
                      </div>
                      <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white border border-[#e4e0d5] text-xs font-bold text-[#171711]">
                        <span>{getScheduleLabel(suggestion.recommendedSchedule)}</span>
                      </div>
                    </div>
                  </div>

                  {/* Reasoning Footer */}
                  {suggestion.reasoning && (
                    <div className="mt-3 pt-2 text-[11px] text-[#8e8d87] italic">
                      💡 {suggestion.reasoning}
                    </div>
                  )}
                </div>
              );
            })
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-3 bg-[#f7f5ee] border-t border-[#e4e0d5] flex items-center justify-between text-xs text-[#6c6b63]">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-[#27c93f]" />
            <span>Google Gemini Intelligence • Private Local Execution</span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-1.5 rounded-xl bg-white border border-[#e4e0d5] hover:bg-[#faf8f5] text-[#171711] font-bold transition-colors cursor-pointer"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
}
