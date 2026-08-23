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
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-zinc-900 tracking-tight">
            Deep Search
          </h1>
          <p className="text-xs sm:text-sm text-zinc-500 font-medium mt-0.5">
            Search across your entire saved library, notes, quotes, and web links
          </p>
        </div>

        {/* Large Search Input */}
        <div className="relative max-w-2xl">
          <SearchIcon className="w-5 h-5 text-zinc-400 absolute left-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search keywords, domains, titles, personal notes..."
            autoFocus
            className="w-full pl-12 pr-10 py-3.5 text-sm bg-white border border-zinc-200/80 rounded-2xl text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/80 shadow-sm"
          />
          {query && (
            <button
              onClick={() => setQuery('')}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 p-1 text-zinc-400 hover:text-zinc-600 rounded-full"
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
                className={`inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
                  active
                    ? 'bg-zinc-900 text-white shadow-sm'
                    : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200'
                }`}
              >
                {chip.icon}
                <span>{chip.label}</span>
              </button>
            );
          })}
        </div>

        {/* Results Header */}
        <div className="flex items-center justify-between text-xs font-bold text-zinc-400 uppercase tracking-wider pt-2">
          <span>
            {filtered.length} {filtered.length === 1 ? 'Result' : 'Results'} Found
          </span>
        </div>

        {/* Results Grid */}
        {filtered.length === 0 ? (
          <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-zinc-300 space-y-3">
            <SearchIcon className="w-8 h-8 text-zinc-300 mx-auto" />
            <h3 className="text-base font-bold text-zinc-700">
              No results found
            </h3>
            <p className="text-xs text-zinc-500 max-w-sm mx-auto">
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
