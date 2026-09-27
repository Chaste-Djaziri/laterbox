'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { CloudSyncIndicator } from '@/components/ui/CloudSyncIndicator';
import { useItems } from '@/lib/store/ItemContext';
import {
  ArrowLeft,
  Folder,
  LayoutGrid,
  List,
  Search,
  PackageOpen,
} from 'lucide-react';

export default function CollectionDetailPage() {
  const params = useParams();
  const collectionId = params?.collectionId as string;

  const { collections, items } = useItems();
  const [searchQuery, setSearchQuery] = useState('');
  const [layoutMode, setLayoutMode] = useState<'grid' | 'list'>('grid');

  const collection = collections.find((c) => c.id === collectionId);

  // Items that belong to this collection
  const collectionItems = items.filter(
    (item) =>
      !item.deleted_at &&
      item.collections?.some((c) => c.id === collectionId),
  );

  const filteredItems = searchQuery.trim()
    ? collectionItems.filter((item) => {
        const q = searchQuery.toLowerCase();
        const title = (item.metadata?.title || item.title || '').toLowerCase();
        const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
        const domain = (item.metadata?.domain || item.url || '').toLowerCase();
        return title.includes(q) || desc.includes(q) || domain.includes(q);
      })
    : collectionItems;

  if (!collection) {
    return (
      <div className="max-w-6xl mx-auto p-8 text-center space-y-4">
        <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
          <Folder className="w-6 h-6" />
        </div>
        <h2 className="text-lg font-extrabold text-[#171711]">Collection not found</h2>
        <Link
          href="/library"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#171711] text-white text-xs font-bold hover:bg-[#282723] transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Library
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-6 sm:p-8 space-y-6">
      {/* Top bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-2 border-b border-[#e4e0d5]/60">
        <div className="flex items-center gap-3">
          <Link
            href="/library"
            className="w-9 h-9 rounded-full bg-white border border-[#e4e0d5] flex items-center justify-center text-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-colors cursor-pointer shrink-0"
            title="Back to Library"
          >
            <ArrowLeft className="w-4 h-4" />
          </Link>

          {/* Search */}
          <div className="relative w-64 sm:w-80">
            <Search className="w-3.5 h-3.5 text-[#9e9b92] absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={`Search in "${collection.name}"…`}
              className="w-full rounded-full bg-[#faf8f5] border border-[#e4e0d5] pl-9 pr-4 py-2 text-xs text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:border-[#171711] shadow-2xs transition-colors"
            />
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Grid / List toggle */}
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

          <CloudSyncIndicator />
        </div>
      </div>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pt-1">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center text-[#171711] shrink-0">
            <Folder className="w-7 h-7" />
          </div>
          <div>
            <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711]">
              {collection.name}
            </h1>
            <p className="text-xs text-[#6c6b63] font-medium mt-1">
              {collectionItems.length === 0
                ? 'No items yet'
                : `${collectionItems.length} item${collectionItems.length === 1 ? '' : 's'} in this collection`}
            </p>
          </div>
        </div>

        {/* Item count badge */}
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black self-start sm:self-auto">
          <span>{filteredItems.length} shown</span>
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="text-[#6c6b63] hover:text-[#171711] font-bold"
            >
              ✕
            </button>
          )}
        </div>
      </div>

      {/* Content */}
      {filteredItems.length === 0 ? (
        <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
          <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
            <PackageOpen className="w-6 h-6" />
          </div>
          <h3 className="text-base font-extrabold text-[#171711]">
            {searchQuery ? 'No results found' : 'No items in this collection'}
          </h3>
          <p className="text-xs text-[#6c6b63] max-w-sm mx-auto leading-relaxed">
            {searchQuery
              ? 'Try a different search term.'
              : 'Add items from your Inbox or Library by tapping the collection button on any item.'}
          </p>
        </div>
      ) : layoutMode === 'grid' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredItems.map((item) => (
            <ItemCard key={item.id} item={item} />
          ))}
        </div>
      ) : (
        <div className="space-y-3">
          {filteredItems.map((item) => (
            <ItemListRow key={item.id} item={item} />
          ))}
        </div>
      )}
    </div>
  );
}
