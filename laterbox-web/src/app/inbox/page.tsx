'use client';

import React, { useState } from 'react';
import { AppShell } from '@/components/layout/AppShell';
import { FilterBar } from '@/components/inbox/FilterBar';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { useItems } from '@/lib/store/ItemContext';
import { LayoutGrid, List, Search, Plus, Inbox as InboxIcon } from 'lucide-react';
import { QuickCaptureModal } from '@/components/inbox/QuickCaptureModal';

export default function InboxPage() {
  const { filteredInboxItems, loading, activeFilter } = useItems();
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [searchQuery, setSearchQuery] = useState('');
  const [captureOpen, setCaptureOpen] = useState(false);

  const displayedItems = filteredInboxItems.filter((item) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    const title = (item.metadata?.title || item.title || '').toLowerCase();
    const domain = (item.metadata?.domain || item.url || '').toLowerCase();
    const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
    const note = (item.note?.content || '').toLowerCase();
    return title.includes(q) || domain.includes(q) || desc.includes(q) || note.includes(q);
  });

  return (
    <AppShell>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6">
        {/* Header & Controls */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-black text-zinc-900 tracking-tight">
              Inbox
            </h1>
            <p className="text-xs sm:text-sm text-zinc-500 font-medium mt-0.5">
              {filteredInboxItems.length} {filteredInboxItems.length === 1 ? 'item' : 'items'} ready to review
            </p>
          </div>

          {/* Search + View Toggles + Save Button */}
          <div className="flex items-center gap-2.5">
            {/* Quick in-page search */}
            <div className="relative flex-1 sm:w-64">
              <Search className="w-4 h-4 text-zinc-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Filter inbox..."
                className="w-full pl-9 pr-4 py-2 text-xs bg-white border border-zinc-200/80 rounded-xl text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/80"
              />
            </div>

            {/* View Mode Toggle */}
            <div className="flex items-center p-1 bg-zinc-200/70 rounded-xl">
              <button
                onClick={() => setViewMode('grid')}
                title="Grid View"
                className={`p-1.5 rounded-lg transition-colors ${
                  viewMode === 'grid'
                    ? 'bg-white text-zinc-900 shadow-sm'
                    : 'text-zinc-500 hover:text-zinc-900'
                }`}
              >
                <LayoutGrid className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                title="List View"
                className={`p-1.5 rounded-lg transition-colors ${
                  viewMode === 'list'
                    ? 'bg-white text-zinc-900 shadow-sm'
                    : 'text-zinc-500 hover:text-zinc-900'
                }`}
              >
                <List className="w-4 h-4" />
              </button>
            </div>

            {/* Save Item Action */}
            <button
              onClick={() => setCaptureOpen(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white text-xs font-bold shadow-sm transition-all"
            >
              <Plus className="w-4 h-4" />
              <span className="hidden sm:inline">Save</span>
            </button>
          </div>
        </div>

        {/* Filter Bar Chips */}
        <FilterBar />

        {/* Loading State */}
        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 animate-pulse">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div
                key={i}
                className="h-64 rounded-3xl bg-zinc-200/60 border border-zinc-200"
              />
            ))}
          </div>
        ) : displayedItems.length === 0 ? (
          /* Empty State */
          <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-zinc-300 space-y-4">
            <div className="w-14 h-14 mx-auto rounded-3xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-200/50 shadow-sm">
              <InboxIcon className="w-7 h-7" />
            </div>
            <div>
              <h3 className="text-lg font-bold text-zinc-900">
                {searchQuery
                  ? 'No items match your search'
                  : activeFilter !== 'all'
                  ? `No ${activeFilter} in your inbox`
                  : 'Your inbox is empty'}
              </h3>
              <p className="text-xs sm:text-sm text-zinc-500 max-w-sm mx-auto mt-1">
                {searchQuery
                  ? 'Try a different search query or clear the filter.'
                  : 'Save links, YouTube videos, articles, and quick notes from the web or desktop extension.'}
              </p>
            </div>
            <div className="pt-2">
              <button
                onClick={() => setCaptureOpen(true)}
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-sm transition-all"
              >
                <Plus className="w-4 h-4" />
                <span>Save your first item</span>
              </button>
            </div>
          </div>
        ) : viewMode === 'grid' ? (
          /* Grid View */
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {displayedItems.map((item) => (
              <ItemCard key={item.id} item={item} />
            ))}
          </div>
        ) : (
          /* List View */
          <div className="space-y-2.5">
            {displayedItems.map((item) => (
              <ItemListRow key={item.id} item={item} />
            ))}
          </div>
        )}
      </div>

      <QuickCaptureModal isOpen={captureOpen} onClose={() => setCaptureOpen(false)} />
    </AppShell>
  );
}
