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
  { type: 'all', label: 'All', icon: <Inbox className="w-4 h-4" /> },
  { type: 'articles', label: 'Articles', icon: <FileText className="w-4 h-4" /> },
  { type: 'videos', label: 'Videos', icon: <PlayCircle className="w-4 h-4" /> },
  { type: 'music', label: 'Music', icon: <Music2 className="w-4 h-4" /> },
  { type: 'notes', label: 'Notes', icon: <StickyNote className="w-4 h-4" /> },
  { type: 'starred', label: 'Starred', icon: <Star className="w-4 h-4" /> },
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
    <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none touch-pan-x">
      {FILTER_OPTIONS.map(({ type, label, icon }) => {
        const isActive = activeFilter === type;
        const count = getCount(type);

        return (
          <button
            key={type}
            onClick={() => setActiveFilter(type)}
            className={`inline-flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all duration-150 shrink-0 select-none ${
              isActive
                ? 'bg-zinc-900 text-white shadow-sm'
                : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200/70 hover:text-zinc-900'
            }`}
          >
            {icon}
            <span>{label}</span>
            <span
              className={`px-1.5 py-0.2 rounded-md text-[10px] font-mono font-medium ${
                isActive
                  ? 'bg-zinc-700 text-zinc-200'
                  : 'bg-zinc-200 text-zinc-600'
              }`}
            >
              {count}
            </span>
          </button>
        );
      })}
    </div>
  );
}
