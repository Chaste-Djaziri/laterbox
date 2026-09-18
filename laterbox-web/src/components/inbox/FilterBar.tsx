'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { InboxFilterType } from '@/lib/supabase/types';
import {
  Inbox,
  FileText,
  PlayCircle,
  Music2,
  StickyNote,
  Star,
  ChevronDown,
  ListFilter,
} from 'lucide-react';

interface FilterOption {
  type: InboxFilterType;
  label: string;
  icon: React.ReactNode;
}

const FILTER_OPTIONS: FilterOption[] = [
  { type: 'all', label: 'All', icon: <Inbox className="w-3.5 h-3.5" /> },
  { type: 'articles', label: 'Articles', icon: <FileText className="w-3.5 h-3.5" /> },
  { type: 'videos', label: 'Videos', icon: <PlayCircle className="w-3.5 h-3.5" /> },
  { type: 'music', label: 'Music', icon: <Music2 className="w-3.5 h-3.5" /> },
  { type: 'notes', label: 'Notes', icon: <StickyNote className="w-3.5 h-3.5" /> },
  { type: 'starred', label: 'Starred', icon: <Star className="w-3.5 h-3.5" /> },
];

export function FilterBar({
  sortOrder = 'latest',
  onSortChange,
}: {
  sortOrder?: 'latest' | 'oldest';
  onSortChange?: (sort: 'latest' | 'oldest') => void;
}) {
  const { activeFilter, setActiveFilter, inboxItems, starredItems } = useItems();

  const getCount = (type: InboxFilterType): number => {
    switch (type) {
      case 'all':
        return inboxItems.length;
      case 'starred':
        return starredItems.length;
      case 'notes':
        return inboxItems.filter((i) => i.type === 'note' || i.metadata?.content_type === 'note' || (!i.url && i.text_content)).length;
      case 'articles':
        return inboxItems.filter((i) => i.type === 'article' || i.metadata?.content_type === 'article' || (i.url && !i.url.includes('youtube') && !i.url.includes('spotify'))).length;
      case 'videos':
        return inboxItems.filter((i) => i.type === 'video' || i.metadata?.content_type === 'video' || (i.url && i.url.includes('youtube.com'))).length;
      case 'music':
        return inboxItems.filter(
          (i) => i.type === 'music' || i.metadata?.content_type === 'music' || (i.url && i.url.includes('spotify.com'))
        ).length;
    }
  };

  return (
    <div className="flex items-center justify-between gap-3 flex-wrap">
      {/* Filter Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none touch-pan-x">
        {FILTER_OPTIONS.map(({ type, label, icon }) => {
          const isActive = activeFilter === type;
          const count = getCount(type);

          return (
            <button
              key={type}
              onClick={() => setActiveFilter(type)}
              className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs transition-all duration-150 shrink-0 select-none cursor-pointer ${
                isActive
                  ? 'bg-[#e6edb0] border border-[#cfdb84] text-[#171711] font-bold shadow-2xs'
                  : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] font-medium'
              }`}
            >
              <span className={isActive ? 'text-[#171711]' : 'text-[#8e8d87]'}>{icon}</span>
              <span>{label}</span>
              {count > 0 && (
                <span
                  className={`text-[11px] font-bold ml-0.5 ${
                    isActive ? 'text-[#171711]' : 'text-[#8e8d87]'
                  }`}
                >
                  {count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* Sorting Dropdown Button on the far right */}
      <div className="flex items-center gap-2 ml-auto shrink-0">
        <button
          type="button"
          onClick={() => onSortChange?.(sortOrder === 'latest' ? 'oldest' : 'latest')}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-[#171711] hover:text-black bg-white border border-transparent hover:border-[#e4e0d5] rounded-xl transition-all cursor-pointer"
        >
          <ListFilter className="w-3.5 h-3.5 text-[#6c6b63]" />
          <span>{sortOrder === 'latest' ? 'Latest first' : 'Oldest first'}</span>
          <ChevronDown className="w-3 h-3 text-[#9e9b92]" />
        </button>
      </div>
    </div>
  );
}
