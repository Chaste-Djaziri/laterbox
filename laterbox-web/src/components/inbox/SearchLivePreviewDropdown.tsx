'use client';

import React from 'react';
import { LaterBoxItem } from '@/lib/supabase/types';
import {
  InboxSearchFilters,
  formatEmailDate,
  getEmailSender,
  itemMatchesFilters,
  itemMatchesQuery,
} from '@/lib/utils/emailFormatters';
import {
  Search,
  Paperclip,
  Clock,
  Star,
  FileText,
  Video,
  Mail,
  ExternalLink,
} from 'lucide-react';

interface SearchLivePreviewDropdownProps {
  searchQuery: string;
  items: LaterBoxItem[];
  filters: InboxSearchFilters;
  onUpdateFilters: (updater: (prev: InboxSearchFilters) => InboxSearchFilters) => void;
  onSelectAllResults: () => void;
  onSelectItem: (item: LaterBoxItem) => void;
}

export function SearchLivePreviewDropdown({
  searchQuery,
  items,
  filters,
  onUpdateFilters,
  onSelectAllResults,
  onSelectItem,
}: SearchLivePreviewDropdownProps) {
  // Filter matches for the live dropdown preview
  const matchingItems = React.useMemo(() => {
    if (!searchQuery.trim()) return [];
    return items
      .filter((item) => itemMatchesQuery(item, searchQuery) && itemMatchesFilters(item, filters))
      .slice(0, 5);
  }, [items, searchQuery, filters]);

  const toggleAttachment = (e: React.MouseEvent) => {
    e.stopPropagation();
    onUpdateFilters((prev) => ({ ...prev, hasAttachment: !prev.hasAttachment }));
  };

  const toggle7Days = (e: React.MouseEvent) => {
    e.stopPropagation();
    onUpdateFilters((prev) => ({
      ...prev,
      dateRange: prev.dateRange === '7d' ? 'all' : '7d',
    }));
  };

  const toggleStarred = (e: React.MouseEvent) => {
    e.stopPropagation();
    onUpdateFilters((prev) => ({ ...prev, starred: !prev.starred }));
  };

  const toggleArticles = (e: React.MouseEvent) => {
    e.stopPropagation();
    onUpdateFilters((prev) => ({
      ...prev,
      format: prev.format === 'articles' ? 'all' : 'articles',
    }));
  };

  const toggleMedia = (e: React.MouseEvent) => {
    e.stopPropagation();
    onUpdateFilters((prev) => ({
      ...prev,
      format: prev.format === 'media' ? 'all' : 'media',
    }));
  };

  return (
    <div
      data-search-preview-dropdown="true"
      className="absolute left-0 right-0 top-full mt-2 z-50 bg-white border border-[#e4e0d5] rounded-2xl shadow-xl overflow-hidden divide-y divide-[#f0ede4] animate-in fade-in zoom-in-98 duration-100"
      onMouseDown={(e) => {
        // Prevent input blur when clicking inside dropdown
        e.stopPropagation();
      }}
    >
      {/* 1. Quick Filter Pills Bar */}
      <div className="p-3 bg-[#faf8f5]/40 flex items-center gap-1.5 overflow-x-auto scrollbar-none">
        <button
          type="button"
          onClick={toggleAttachment}
          className={`shrink-0 inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold transition-all cursor-pointer ${
            filters.hasAttachment
              ? 'bg-[#171711] text-[#e6edb0] border border-[#171711] shadow-2xs'
              : 'bg-white text-[#171711] border border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
          }`}
        >
          <Paperclip className="w-3 h-3" />
          <span>Has attachment</span>
        </button>

        <button
          type="button"
          onClick={toggle7Days}
          className={`shrink-0 inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold transition-all cursor-pointer ${
            filters.dateRange === '7d'
              ? 'bg-[#171711] text-[#e6edb0] border border-[#171711] shadow-2xs'
              : 'bg-white text-[#171711] border border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
          }`}
        >
          <Clock className="w-3 h-3" />
          <span>Last 7 days</span>
        </button>

        <button
          type="button"
          onClick={toggleStarred}
          className={`shrink-0 inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold transition-all cursor-pointer ${
            filters.starred
              ? 'bg-[#171711] text-[#e6edb0] border border-[#171711] shadow-2xs'
              : 'bg-white text-[#171711] border border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
          }`}
        >
          <Star className="w-3 h-3" />
          <span>Starred</span>
        </button>

        <button
          type="button"
          onClick={toggleArticles}
          className={`shrink-0 inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold transition-all cursor-pointer ${
            filters.format === 'articles'
              ? 'bg-[#171711] text-[#e6edb0] border border-[#171711] shadow-2xs'
              : 'bg-white text-[#171711] border border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
          }`}
        >
          <FileText className="w-3 h-3" />
          <span>Articles</span>
        </button>

        <button
          type="button"
          onClick={toggleMedia}
          className={`shrink-0 inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold transition-all cursor-pointer ${
            filters.format === 'media'
              ? 'bg-[#171711] text-[#e6edb0] border border-[#171711] shadow-2xs'
              : 'bg-white text-[#171711] border border-[#e4e0d5] hover:border-[#171711]/50 hover:bg-[#faf8f5]'
          }`}
        >
          <Video className="w-3 h-3" />
          <span>Media</span>
        </button>
      </div>

      {/* 2. Matching Results List */}
      <div className="divide-y divide-[#f0ede4] max-h-[340px] overflow-y-auto">
        {matchingItems.length === 0 ? (
          <div className="px-4 py-8 text-center">
            <p className="text-xs font-medium text-[#8e8d87]">
              No items in inbox match &ldquo;{searchQuery}&rdquo;
            </p>
          </div>
        ) : (
          matchingItems.map((item) => {
            const sender = getEmailSender(item);
            const title =
              item.metadata?.title ||
              item.title ||
              item.attachments?.[0]?.original_file_name ||
              'Untitled item';
            const hasAttachments = item.attachments && item.attachments.length > 0;
            const isMedia =
              item.metadata?.content_type === 'video' ||
              item.type === 'video' ||
              item.url?.includes('youtube.com');

            return (
              <div
                key={item.id}
                onClick={() => onSelectItem(item)}
                className="px-4 py-2.5 hover:bg-[#faf8f5] transition-colors cursor-pointer flex items-center gap-3 text-left group"
              >
                {/* Left Type Icon */}
                <div className="shrink-0 text-[#8e8d87] group-hover:text-[#171711] transition-colors">
                  {isMedia ? (
                    <Video className="w-4 h-4" />
                  ) : hasAttachments ? (
                    <Paperclip className="w-4 h-4" />
                  ) : item.type === 'note' || item.type === 'task' ? (
                    <FileText className="w-4 h-4" />
                  ) : item.url ? (
                    <ExternalLink className="w-4 h-4" />
                  ) : (
                    <Mail className="w-4 h-4" />
                  )}
                </div>

                {/* Center Title and Sender */}
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-xs sm:text-sm font-bold text-[#171711] truncate group-hover:text-black">
                      {title}
                    </p>
                    <div className="flex items-center gap-1.5 shrink-0">
                      {hasAttachments && (
                        <Paperclip className="w-3 h-3 text-[#9e9b92]" />
                      )}
                      <span className="text-[11px] font-medium text-[#8e8d87]">
                        {formatEmailDate(item.created_at)}
                      </span>
                    </div>
                  </div>
                  <p className="text-[11px] sm:text-xs text-[#6c6b63] truncate mt-0.5">
                    {sender}
                  </p>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* 3. Bottom Execution Row ("All search results for ...") */}
      <div
        onClick={onSelectAllResults}
        className="px-4 py-3 bg-[#faf8f5]/60 hover:bg-[#faf8f5] cursor-pointer flex items-center justify-between transition-colors group"
      >
        <div className="flex items-center gap-2.5 min-w-0">
          <Search className="w-4 h-4 text-[#6c6b63] group-hover:text-[#171711] transition-colors shrink-0" />
          <span className="text-xs sm:text-sm font-bold text-[#171711] truncate">
            All search results for &ldquo;{searchQuery}&rdquo;
          </span>
        </div>
        <kbd className="text-[10px] font-mono font-bold text-[#8e8d87] bg-[#ebe7dc] px-2 py-0.5 rounded-md shrink-0 shadow-2xs group-hover:bg-[#e2ded2] group-hover:text-[#171711] transition-colors">
          Press ENTER
        </kbd>
      </div>
    </div>
  );
}
