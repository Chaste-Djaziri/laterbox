'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { InboxFilterType } from '@/lib/supabase/types';
import { Inbox, FileText, PlayCircle, Music2, StickyNote, Star } from 'lucide-react';

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

export function FilterBar() {
  const { activeFilter, setActiveFilter, inboxItems, starredItems } = useItems();

  const getCount = (type: InboxFilterType): number => {
    switch (type) {
      case 'all':
        return inboxItems.length;
      case 'starred':
        return starredItems.length;
      case 'notes':
        return inboxItems.filter((i) => !i.url || (i.text_content && i.text_content.length > 0)).length;
      case 'articles':
        return inboxItems.filter((i) => i.metadata?.content_type === 'article' || (!i.metadata?.content_type && i.url)).length;
      case 'videos':
        return inboxItems.filter((i) => i.metadata?.content_type === 'video' || (i.url && i.url.includes('youtube.com'))).length;
      case 'music':
        return inboxItems.filter(
          (i) => i.metadata?.content_type === 'music' || (i.url && (i.url.includes('spotify.com') || i.url.includes('soundcloud.com')))
        ).length;
    }
  };

  return (
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
                ? 'bg-[#e6edb0] border border-[#cfdb84] text-[#171711] font-bold shadow-none'
                : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:bg-[#ebe7dc]/60 hover:text-[#171711] font-medium'
            }`}
          >
            {icon}
            <span>{label}</span>
            {count > 0 && (
              <span
                className={`px-1.5 py-0.2 rounded-full text-[10px] font-mono font-bold ${
                  isActive
                    ? 'bg-[#171711]/15 text-[#171711]'
                    : 'bg-[#ebe7dc] text-[#6c6b63]'
                }`}
              >
                {count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
