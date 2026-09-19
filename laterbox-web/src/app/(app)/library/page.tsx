'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { QuickCaptureModal } from '@/components/inbox/QuickCaptureModal';
import { useItems } from '@/lib/store/ItemContext';
import {
  Star,
  CheckCircle,
  Archive,
  FolderPlus,
  Plus,
  Folder,
  Trash2,
  Search,
  ArrowLeft,
  LayoutGrid,
  List,
  HelpCircle,
  Sparkles,
  Layers,
  BookOpen,
} from 'lucide-react';

type LibraryTab = 'collections' | 'starred' | 'saved' | 'archived';

export default function LibraryPage() {
  const { starredItems, savedItems, archivedItems, collections, createCollection, deleteCollection } = useItems();
  const [activeTab, setActiveTab] = useState<LibraryTab>('collections');
  const [newColName, setNewColName] = useState('');
  const [showColModal, setShowColModal] = useState(false);
  const [showCaptureModal, setShowCaptureModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [layoutMode, setLayoutMode] = useState<'grid' | 'list'>('grid');

  const handleCreateCol = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newColName.trim()) return;
    await createCollection(newColName.trim());
    setNewColName('');
    setShowColModal(false);
  };

  const tabs = [
    { id: 'collections' as LibraryTab, label: 'Collections', icon: <Folder className="w-4 h-4" />, count: collections.length },
    { id: 'starred' as LibraryTab, label: 'Favorites', icon: <Star className="w-4 h-4" />, count: starredItems.length },
    { id: 'saved' as LibraryTab, label: 'Kept', icon: <CheckCircle className="w-4 h-4" />, count: savedItems.length },
    { id: 'archived' as LibraryTab, label: 'Archive', icon: <Archive className="w-4 h-4" />, count: archivedItems.length },
  ];

  const filterItems = (itemsList: typeof starredItems) => {
    if (!searchQuery.trim()) return itemsList;
    const q = searchQuery.toLowerCase();
    return itemsList.filter((item) => {
      const title = (item.metadata?.title || item.title || '').toLowerCase();
      const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
      const domain = (item.metadata?.domain || item.url || '').toLowerCase();
      return title.includes(q) || desc.includes(q) || domain.includes(q);
    });
  };

  const displayedStarred = filterItems(starredItems);
  const displayedSaved = filterItems(savedItems);
  const displayedArchived = filterItems(archivedItems);

  return (
    <>
      <div className="max-w-6xl mx-auto p-6 sm:p-8 space-y-6">
        {/* Top Omnibar with Back, Search, Grid/List Switcher & Local Mode */}
        <div className="flex flex-wrap items-center justify-between gap-3 pb-2 border-b border-[#e4e0d5]/60">
          <div className="flex items-center gap-3">
            <Link
              href="/home"
              className="w-9 h-9 rounded-full bg-white border border-[#e4e0d5] flex items-center justify-center text-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-colors cursor-pointer shrink-0"
              title="Back to Dashboard"
            >
              <ArrowLeft className="w-4 h-4" />
            </Link>

            {/* Omnibar Search */}
            <div className="relative w-64 sm:w-80">
              <Search className="w-3.5 h-3.5 text-[#9e9b92] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                data-search-input="true"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search your library..."
                className="w-full rounded-full bg-[#faf8f5] border border-[#e4e0d5] pl-9 pr-14 py-2 text-xs text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:border-[#171711] shadow-2xs transition-colors"
              />
              <kbd className="absolute right-2.5 top-1/2 -translate-y-1/2 px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[9px] font-mono font-bold text-[#171711]">
                ⌘ K
              </kbd>
            </div>
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
        <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pt-1">
          <div className="space-y-2">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-black">
              <span>📚 Permanent Knowledge Base • Local-First Storage</span>
            </div>
            <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711]">
              Library
            </h1>
            <p className="text-xs sm:text-sm text-[#6c6b63] font-medium max-w-2xl leading-relaxed">
              Organize your saved articles, client PDFs, design files, notes, and references into custom collections and permanent vaults.
            </p>
          </div>

          <div className="flex items-center gap-2">
            {activeTab === 'collections' && (
              <button
                onClick={() => setShowColModal(true)}
                className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
              >
                <FolderPlus className="w-4 h-4" />
                <span>New Collection</span>
              </button>
            )}
            <button
              onClick={() => setShowCaptureModal(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-full bg-white border border-[#e4e0d5] hover:border-[#171711] text-[#171711] text-xs font-bold shadow-2xs transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Save Item</span>
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="flex items-center gap-2 border-b border-[#e4e0d5] pb-3 overflow-x-auto scrollbar-none pt-1">
          {tabs.map((tab) => {
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  active
                    ? 'bg-[#e6edb0] border border-[#d0db84] text-[#171711] shadow-2xs'
                    : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:bg-[#faf8f5] hover:text-[#171711]'
                }`}
              >
                {tab.icon}
                <span>{tab.label}</span>
                <span
                  className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold ${
                    active
                      ? 'bg-[#171711] text-white'
                      : 'bg-[#ebe7dc] text-[#6c6b63]'
                  }`}
                >
                  {tab.count}
                </span>
              </button>
            );
          })}
        </div>

        {/* Tab Content: Collections */}
        {activeTab === 'collections' && (
          <div>
            {collections.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
                  <Folder className="w-6 h-6" />
                </div>
                <h3 className="text-base font-extrabold text-[#171711]">
                  No Collections Created Yet
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto leading-relaxed">
                  Group your saved links, PDFs, designs, and reading lists into project topics.
                </p>
                <div className="pt-2">
                  <button
                    onClick={() => setShowColModal(true)}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs cursor-pointer"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Create Collection</span>
                  </button>
                </div>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {collections.map((col) => (
                  <div
                    key={col.id}
                    className="p-6 rounded-3xl bg-white border border-[#e4e0d5] hover:border-[#171711] hover:shadow-xs transition-all flex flex-col justify-between group"
                  >
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center text-[#171711]">
                        <Folder className="w-5 h-5" />
                      </div>
                      <button
                        onClick={() => deleteCollection(col.id)}
                        className="p-2 text-[#9e9b92] hover:text-red-600 rounded-xl hover:bg-red-50 transition-colors cursor-pointer opacity-80 group-hover:opacity-100"
                        title="Delete Collection"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>

                    <div>
                      <h3 className="text-base font-black text-[#171711]">{col.name}</h3>
                      <p className="text-xs text-[#9e9b92] mt-1 font-semibold">Saved Collection</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Tab Content: Favorites (Starred) */}
        {activeTab === 'starred' && (
          <div>
            {displayedStarred.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-amber-500">
                  <Star className="w-6 h-6 fill-amber-400" />
                </div>
                <h3 className="text-base font-extrabold text-[#171711]">
                  No Favorites Starred Yet
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto leading-relaxed">
                  Click the star icon on any card in your inbox or vault to pin your essential links and notes.
                </p>
              </div>
            ) : layoutMode === 'grid' ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {displayedStarred.map((item) => (
                  <ItemCard key={item.id} item={item} />
                ))}
              </div>
            ) : (
              <div className="space-y-3">
                {displayedStarred.map((item) => (
                  <ItemListRow key={item.id} item={item} />
                ))}
              </div>
            )}
          </div>
        )}

        {/* Tab Content: Saved (Kept) */}
        {activeTab === 'saved' && (
          <div>
            {displayedSaved.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#171711]">
                  <CheckCircle className="w-6 h-6" />
                </div>
                <h3 className="text-base font-extrabold text-[#171711]">
                  No Kept Items Yet
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto leading-relaxed">
                  Items you keep from your inbox will appear here as your permanent local reference library.
                </p>
              </div>
            ) : layoutMode === 'grid' ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {displayedSaved.map((item) => (
                  <ItemCard key={item.id} item={item} />
                ))}
              </div>
            ) : (
              <div className="space-y-3">
                {displayedSaved.map((item) => (
                  <ItemListRow key={item.id} item={item} />
                ))}
              </div>
            )}
          </div>
        )}

        {/* Tab Content: Archived */}
        {activeTab === 'archived' && (
          <div>
            {displayedArchived.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
                  <Archive className="w-6 h-6" />
                </div>
                <h3 className="text-base font-extrabold text-[#171711]">
                  Archive is Empty
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto leading-relaxed">
                  Finished reading or processed items are safely stored here if you ever need to retrieve them.
                </p>
              </div>
            ) : layoutMode === 'grid' ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {displayedArchived.map((item) => (
                  <ItemCard key={item.id} item={item} />
                ))}
              </div>
            ) : (
              <div className="space-y-3">
                {displayedArchived.map((item) => (
                  <ItemListRow key={item.id} item={item} />
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* New Collection Modal */}
      {showColModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="w-full max-w-md bg-[#f7f5ee] rounded-3xl p-6 sm:p-7 shadow-2xl border border-[#e4e0d5] space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center text-[#171711]">
                <FolderPlus className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-lg font-black text-[#171711]">Create New Collection</h3>
                <p className="text-xs text-[#6c6b63]">
                  Group your items by project, topic, or reading queue.
                </p>
              </div>
            </div>

            <form onSubmit={handleCreateCol} className="space-y-4 pt-1">
              <input
                type="text"
                value={newColName}
                onChange={(e) => setNewColName(e.target.value)}
                placeholder="e.g. Flutter Guides, AI Research, Recipes..."
                autoFocus
                className="w-full px-4 py-2.5 text-xs bg-white border border-[#e4e0d5] rounded-xl text-[#171711] focus:outline-hidden focus:border-[#171711]"
              />
              <div className="flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowColModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-[#6c6b63] hover:bg-[#ebe7dc]/60 rounded-xl cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!newColName.trim()}
                  className="px-5 py-2 text-xs font-bold text-white bg-[#171711] hover:bg-[#282723] disabled:opacity-50 rounded-xl cursor-pointer shadow-xs"
                >
                  Create Collection
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <QuickCaptureModal
        isOpen={showCaptureModal}
        onClose={() => setShowCaptureModal(false)}
      />
    </>
  );
}
