'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { AppShell } from '@/components/layout/AppShell';
import { FilterBar } from '@/components/inbox/FilterBar';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { CloudSyncIndicator } from '@/components/ui/CloudSyncIndicator';
import {
  LayoutGrid,
  List,
  Search,
  Plus,
  HelpCircle,
  LogIn,
  LogOut,
  Package,
} from 'lucide-react';
import { QuickCaptureModal } from '@/components/inbox/QuickCaptureModal';

export default function InboxPage() {
  const { filteredInboxItems, loading, activeFilter } = useItems();
  const { user, signOut } = useAuth();
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
      <div className="max-w-7xl mx-auto px-6 sm:px-8 py-7 sm:py-9 space-y-6">
        {/* Header & Controls Top Bar */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-black text-[#171711] tracking-tight">
              Inbox
            </h1>
            <p className="text-sm text-[#6c6b63] font-medium mt-0.5">
              {filteredInboxItems.length} {filteredInboxItems.length === 1 ? 'item' : 'items'} saved
            </p>
          </div>

          {/* Desktop Right Action Bar */}
          <div className="flex items-center gap-3">
            {/* Quick in-page search */}
            <div className="relative flex-1 sm:w-56">
              <Search className="w-4 h-4 text-[#9e9b92] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search inbox..."
                className="w-full pl-9 pr-3 py-1.5 text-xs bg-white border border-[#e4e0d5] rounded-xl text-[#171711] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-400"
              />
            </div>

            {/* View Mode Toggle */}
            <div className="hidden sm:flex items-center p-0.5 bg-[#ebe7dc]/70 border border-[#e4e0d5] rounded-xl">
              <button
                onClick={() => setViewMode('grid')}
                title="Grid View"
                className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                  viewMode === 'grid'
                    ? 'bg-white text-[#171711] shadow-xs font-bold'
                    : 'text-[#6c6b63] hover:text-[#171711]'
                }`}
              >
                <LayoutGrid className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                title="List View"
                className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                  viewMode === 'list'
                    ? 'bg-white text-[#171711] shadow-xs font-bold'
                    : 'text-[#6c6b63] hover:text-[#171711]'
                }`}
              >
                <List className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Cloud Sync Status */}
            <CloudSyncIndicator />

            {/* Tutorial link */}
            <Link
              href="/tutorial"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
            >
              <HelpCircle className="w-4 h-4" />
              <span className="hidden md:inline">Tutorial</span>
            </Link>

            {/* Sign in / Sign out */}
            {user ? (
              <button
                onClick={() => signOut()}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <LogOut className="w-4 h-4" />
                <span className="hidden md:inline">Sign out</span>
              </button>
            ) : (
              <Link
                href="/login"
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
              >
                <LogIn className="w-4 h-4" />
                <span className="hidden md:inline">Sign in</span>
              </Link>
            )}
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
                className="h-64 rounded-3xl bg-white border border-[#e4e0d5]"
              />
            ))}
          </div>
        ) : displayedItems.length === 0 ? (
          /* Empty State matching Flutter screenshot */
          <div className="flex flex-col items-center justify-center min-h-[48vh] text-center px-4 space-y-3">
            <div className="w-14 h-14 rounded-2xl bg-white border border-[#e4e0d5] flex items-center justify-center text-[#171711] shadow-xs">
              <Package className="w-7 h-7 stroke-[1.75]" />
            </div>
            <div>
              <h3 className="text-base sm:text-lg font-bold text-[#171711]">
                {searchQuery
                  ? 'No items match your search'
                  : activeFilter !== 'all'
                  ? `No ${activeFilter} in your inbox`
                  : 'Nothing saved yet'}
              </h3>
              <p className="text-xs sm:text-sm text-[#6c6b63] max-w-sm mx-auto mt-1">
                {searchQuery
                  ? 'Try a different search query or clear the filter.'
                  : 'Tap + to save a link or note for later.'}
              </p>
            </div>
            <div className="pt-2">
              <button
                onClick={() => setCaptureOpen(true)}
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-sm transition-all cursor-pointer"
              >
                <Plus className="w-4 h-4" />
                <span>Save Item</span>
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
