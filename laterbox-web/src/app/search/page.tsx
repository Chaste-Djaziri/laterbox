'use client';

import React, { useState } from 'react';
import { AppShell } from '@/components/layout/AppShell';
import { ItemCard } from '@/components/inbox/ItemCard';
import { useItems } from '@/lib/store/ItemContext';
import { Search as SearchIcon, X, FileText, PlayCircle, Music2, StickyNote, Layers } from 'lucide-react';

export default function SearchPage() {
  const { items } = useItems();
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');

  const filtered = items.filter((item) => {
    // Type filter
    if (typeFilter !== 'all') {
      const cType = item.metadata?.content_type || (item.url ? 'link' : 'note');
      if (typeFilter === 'note' && (item.url || !item.text_content)) return false;
      if (typeFilter === 'video' && cType !== 'video' && !item.url?.includes('youtube.com')) return false;
      if (typeFilter === 'music' && cType !== 'music' && !item.url?.includes('spotify.com')) return false;
      if (typeFilter === 'article' && cType !== 'article' && !item.url) return false;
    }

    if (!query.trim()) return true;
    const q = query.toLowerCase();
    const title = (item.metadata?.title || item.title || '').toLowerCase();
    const domain = (item.metadata?.domain || item.url || '').toLowerCase();
    const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
    const note = (item.note?.content || '').toLowerCase();
    return title.includes(q) || domain.includes(q) || desc.includes(q) || note.includes(q);
  });

  const filterChips = [
    { id: 'all', label: 'All Types', icon: <Layers className="w-3.5 h-3.5" /> },
    { id: 'article', label: 'Articles', icon: <FileText className="w-3.5 h-3.5" /> },
    { id: 'video', label: 'Videos', icon: <PlayCircle className="w-3.5 h-3.5" /> },
    { id: 'music', label: 'Music', icon: <Music2 className="w-3.5 h-3.5" /> },
    { id: 'note', label: 'Notes', icon: <StickyNote className="w-3.5 h-3.5" /> },
  ];

  return (
    <AppShell>
      <div className="max-w-7xl mx-auto px-6 sm:px-8 py-7 sm:py-9 space-y-6">
        <div>
          <h1 className="text-3xl font-black text-[#171711] tracking-tight">
            Deep Search
          </h1>
          <p className="text-sm text-[#6c6b63] font-medium mt-0.5">
            Search across your entire saved library, notes, quotes, and web links
          </p>
        </div>

        {/* Large Search Input */}
        <div className="relative max-w-2xl">
          <SearchIcon className="w-5 h-5 text-[#9e9b92] absolute left-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search keywords, domains, titles, personal notes..."
            autoFocus
            className="w-full pl-12 pr-10 py-3.5 text-sm bg-white border border-[#e4e0d5] rounded-2xl text-[#171711] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-400 shadow-xs"
          />
          {query && (
            <button
              onClick={() => setQuery('')}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 p-1 text-[#9e9b92] hover:text-[#171711] rounded-full cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>

        {/* Content Type Filter Chips */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
          {filterChips.map((chip) => {
            const active = typeFilter === chip.id;
            return (
              <button
                key={chip.id}
                onClick={() => setTypeFilter(chip.id)}
                className={`inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all cursor-pointer ${
                  active
                    ? 'bg-[#e6edb0] border border-[#d0db84] text-[#171711] font-bold shadow-none'
                    : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:bg-[#ebe7dc]/60 hover:text-[#171711]'
                }`}
              >
                {chip.icon}
                <span>{chip.label}</span>
              </button>
            );
          })}
        </div>

        {/* Results Header */}
        <div className="flex items-center justify-between text-xs font-bold text-[#9e9b92] uppercase tracking-wider pt-2">
          <span>
            {filtered.length} {filtered.length === 1 ? 'Result' : 'Results'} Found
          </span>
        </div>

        {/* Results Grid */}
        {filtered.length === 0 ? (
          <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
            <SearchIcon className="w-8 h-8 text-[#9e9b92] mx-auto" />
            <h3 className="text-base font-bold text-[#171711]">
              No results found
            </h3>
            <p className="text-xs text-[#6c6b63] max-w-sm mx-auto">
              We couldn't find any saved items matching "{query}". Try checking for spelling or searching with fewer keywords.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {filtered.map((item) => (
              <ItemCard key={item.id} item={item} />
            ))}
          </div>
        )}
      </div>
    </AppShell>
  );
}
