'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { useItems } from '@/lib/store/ItemContext';
import {
  Search as SearchIcon,
  X,
  FileText,
  PlayCircle,
  Music2,
  StickyNote,
  Layers,
  ArrowLeft,
  LayoutGrid,
  List,
  HelpCircle,
  Sparkles,
  Folder,
  Tag,
} from 'lucide-react';

export default function SearchPage() {
  const { items } = useItems();
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [layoutMode, setLayoutMode] = useState<'grid' | 'list'>('grid');

  const filtered = items.filter((item) => {
    // Type filter
    if (typeFilter !== 'all') {
      const cType = item.metadata?.content_type || (item.url ? 'link' : 'note');
      const ext = item.url?.split('.').pop()?.toLowerCase() || '';
      const isFile = item.type === 'file' || ['pdf', 'psd', 'zip', 'docx'].includes(ext);

      if (typeFilter === 'note' && (item.url || !item.text_content)) return false;
      if (typeFilter === 'video' && cType !== 'video' && !item.url?.includes('youtube.com')) return false;
      if (typeFilter === 'music' && cType !== 'music' && !item.url?.includes('spotify.com')) return false;
      if (typeFilter === 'article' && cType !== 'article' && !item.url) return false;
      if (typeFilter === 'file' && !isFile) return false;
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
    { id: 'all', label: `All (${items.length})`, icon: <Layers className="w-3.5 h-3.5" /> },
    { id: 'article', label: 'Articles', icon: <FileText className="w-3.5 h-3.5" /> },
    { id: 'video', label: 'Videos', icon: <PlayCircle className="w-3.5 h-3.5" /> },
    { id: 'music', label: 'Music', icon: <Music2 className="w-3.5 h-3.5" /> },
    { id: 'note', label: 'Notes', icon: <StickyNote className="w-3.5 h-3.5" /> },
    { id: 'file', label: 'Files', icon: <Folder className="w-3.5 h-3.5" /> },
  ];

  const suggestedKeywords = ['PDF', 'Design', 'Video', 'Project', 'Article', 'Feedback', 'Music'];

  return (
    <div className="max-w-6xl mx-auto p-6 sm:p-8 space-y-6">
      {/* Top Omnibar */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-2 border-b border-[#e4e0d5]/60">
        <div className="flex items-center gap-3">
          <Link
            href="/home"
            className="w-9 h-9 rounded-full bg-white border border-[#e4e0d5] flex items-center justify-center text-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-colors cursor-pointer shrink-0"
            title="Back to Dashboard"
          >
            <ArrowLeft className="w-4 h-4" />
          </Link>
          <span className="text-xs font-bold text-[#6c6b63]">Search Engine</span>
        </div>

        <div className="flex items-center gap-2">
          {/* Grid vs List Toggle */}
          <div className="flex items-center gap-1 bg-[#ebe7dc]/60 p-1 rounded-full text-xs font-bold text-[#6c6b63]">
            <button
              type="button"
              onClick={() => setLayoutMode('grid')}
              className={`p-1.5 rounded-full transition-all cursor-pointer ${
                layoutMode === 'grid'
                  ? 'bg-white text-[#171711] shadow-2xs'
                  : 'text-[#6c6b63] hover:text-[#171711]'
              }`}
              title="Grid view"
            >
              <LayoutGrid className="w-3.5 h-3.5" />
            </button>
            <button
              type="button"
              onClick={() => setLayoutMode('list')}
              className={`p-1.5 rounded-full transition-all cursor-pointer ${
                layoutMode === 'list'
                  ? 'bg-white text-[#171711] shadow-2xs'
                  : 'text-[#6c6b63] hover:text-[#171711]'
              }`}
              title="List view"
            >
              <List className="w-3.5 h-3.5" />
            </button>
          </div>

          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[11px] font-black text-[#171711]">
            <span className="w-1.5 h-1.5 rounded-full bg-[#27c93f]" />
            <span>Local Mode</span>
          </div>

          <Link
            href="/tutorial"
            className="hidden sm:inline-flex items-center gap-1 px-3 py-1 rounded-full bg-white border border-[#e4e0d5] text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] transition-colors"
          >
            <HelpCircle className="w-3.5 h-3.5 text-[#9e9b92]" />
            <span>Tutorial</span>
          </Link>
        </div>
      </div>

      {/* View Header with Signature Style */}
      <div className="space-y-2 pt-1">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black">
          <span>🔍 Instant Offline Search • 100% Local SQLite Core</span>
        </div>
        <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711]">
          Deep Search
        </h1>
        <p className="text-xs sm:text-sm text-[#6c6b63] font-medium max-w-2xl leading-relaxed">
          Search keywords, metadata, domains, and handwritten notes across your entire private vault without sending queries to the cloud.
        </p>
      </div>

      {/* Prominent Search Omnibar */}
      <div className="relative max-w-2xl">
        <SearchIcon className="w-5 h-5 text-[#9e9b92] absolute left-4 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Type to search titles, keywords, domains, personal notes..."
          autoFocus
          className="w-full pl-12 pr-12 py-3.5 text-sm bg-white border border-[#e4e0d5] rounded-2xl text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:border-[#171711] shadow-2xs transition-colors"
        />
        {query && (
          <button
            onClick={() => setQuery('')}
            className="absolute right-4 top-1/2 -translate-y-1/2 p-1 text-[#9e9b92] hover:text-[#171711] rounded-full cursor-pointer transition-colors"
            title="Clear search"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Suggested Search Query Pills */}
      <div className="flex items-center gap-2 flex-wrap">
        <span className="text-[11px] font-bold text-[#9e9b92] uppercase tracking-wider">
          Suggested:
        </span>
        {suggestedKeywords.map((keyword) => (
          <button
            key={keyword}
            type="button"
            onClick={() => setQuery(keyword)}
            className="px-2.5 py-1 rounded-lg bg-white border border-[#e4e0d5] text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] hover:border-[#171711] transition-all cursor-pointer shadow-2xs"
          >
            {keyword}
          </button>
        ))}
      </div>

      {/* Content Type Filter Chips */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none pt-1">
        {filterChips.map((chip) => {
          const active = typeFilter === chip.id;
          return (
            <button
              key={chip.id}
              onClick={() => setTypeFilter(chip.id)}
              className={`inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer ${
                active
                  ? 'bg-[#e6edb0] border border-[#d0db84] text-[#171711] shadow-2xs'
                  : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:bg-[#faf8f5] hover:text-[#171711]'
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
          {query ? ` for “${query}”` : ''}
        </span>
      </div>

      {/* Results Grid / List */}
      {filtered.length === 0 ? (
        <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
          <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
            <SearchIcon className="w-6 h-6" />
          </div>
          <h3 className="text-base font-extrabold text-[#171711]">
            No results found
          </h3>
          <p className="text-xs text-[#6c6b63] max-w-sm mx-auto leading-relaxed">
            We couldn’t find any saved items matching &ldquo;{query}&rdquo;. Try checking spelling or searching by domain or keyword.
          </p>
          {query && (
            <div className="pt-2">
              <button
                type="button"
                onClick={() => {
                  setQuery('');
                  setTypeFilter('all');
                }}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#171711] text-white text-xs font-bold shadow-xs hover:bg-[#282723] transition-all cursor-pointer"
              >
                <span>Reset Search</span>
              </button>
            </div>
          )}
        </div>
      ) : layoutMode === 'grid' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {filtered.map((item) => (
            <ItemCard key={item.id} item={item} />
          ))}
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((item) => (
            <ItemListRow key={item.id} item={item} />
          ))}
        </div>
      )}
    </div>
  );
}
