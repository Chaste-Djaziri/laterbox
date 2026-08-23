'use client';

import React, { useState } from 'react';
import { AppShell } from '@/components/layout/AppShell';
import { ItemCard } from '@/components/inbox/ItemCard';
import { useItems } from '@/lib/store/ItemContext';
import {
  Star,
  CheckCircle,
  Archive,
  FolderPlus,
  Plus,
  Folder,
  Trash2,
} from 'lucide-react';

type LibraryTab = 'collections' | 'starred' | 'saved' | 'archived';

export default function LibraryPage() {
  const { starredItems, savedItems, archivedItems, collections, createCollection, deleteCollection } = useItems();
  const [activeTab, setActiveTab] = useState<LibraryTab>('collections');
  const [newColName, setNewColName] = useState('');
  const [showColModal, setShowColModal] = useState(false);

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

  return (
    <AppShell>
      <div className="max-w-7xl mx-auto px-6 sm:px-8 py-7 sm:py-9 space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-black text-[#171711] tracking-tight">
              Library
            </h1>
            <p className="text-sm text-[#6c6b63] font-medium mt-0.5">
              Organize your permanent knowledge base, favorite items, and archived reads
            </p>
          </div>

          {activeTab === 'collections' && (
            <button
              onClick={() => setShowColModal(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
            >
              <FolderPlus className="w-4 h-4" />
              <span>New Collection</span>
            </button>
          )}
        </div>

        {/* Tab Navigation */}
        <div className="flex items-center gap-2 border-b border-[#e4e0d5] pb-3 overflow-x-auto scrollbar-none">
          {tabs.map((tab) => {
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  active
                    ? 'bg-[#e6edb0] border border-[#d0db84] text-[#171711] shadow-none'
                    : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:bg-[#ebe7dc]/60 hover:text-[#171711]'
                }`}
              >
                {tab.icon}
                <span>{tab.label}</span>
                <span
                  className={`px-1.5 py-0.2 rounded-md text-[10px] font-mono ${
                    active
                      ? 'bg-[#171711]/15 text-[#171711]'
                      : 'bg-[#ebe7dc] text-[#6c6b63]'
                  }`}
                >
                  {tab.count}
                </span>
              </button>
            );
          })}
        </div>

        {/* Tab Content */}
        {activeTab === 'collections' && (
          <div>
            {collections.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <Folder className="w-10 h-10 text-[#6c6b63] mx-auto" />
                <h3 className="text-base font-bold text-[#171711]">
                  No Collections Created Yet
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto">
                  Group your saved links into topics, projects, or reading lists.
                </p>
                <div className="pt-2">
                  <button
                    onClick={() => setShowColModal(true)}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs cursor-pointer"
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
                    className="p-6 rounded-3xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-xs transition-all flex flex-col justify-between"
                  >
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711]">
                        <Folder className="w-5 h-5" />
                      </div>
                      <button
                        onClick={() => deleteCollection(col.id)}
                        className="p-1.5 text-[#9e9b92] hover:text-red-600 rounded-lg hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
                        title="Delete Collection"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>

                    <div>
                      <h3 className="text-base font-bold text-[#171711]">{col.name}</h3>
                      <p className="text-xs text-[#9e9b92] mt-1">Collection</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'starred' && (
          <div>
            {starredItems.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <Star className="w-10 h-10 text-amber-400 mx-auto" />
                <h3 className="text-base font-bold text-[#171711]">
                  No Favorites Starred Yet
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto">
                  Click the star icon on any card in your inbox to save it to your favorites.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {starredItems.map((item) => (
                  <ItemCard key={item.id} item={item} />
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'saved' && (
          <div>
            {savedItems.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <CheckCircle className="w-10 h-10 text-[#171711] mx-auto" />
                <h3 className="text-base font-bold text-[#171711]">
                  No Kept Items Yet
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto">
                  Items you keep from your inbox will appear here for long-term reference.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {savedItems.map((item) => (
                  <ItemCard key={item.id} item={item} />
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'archived' && (
          <div>
            {archivedItems.length === 0 ? (
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
                <Archive className="w-10 h-10 text-[#9e9b92] mx-auto" />
                <h3 className="text-base font-bold text-[#171711]">
                  Archive is Empty
                </h3>
                <p className="text-xs text-[#6c6b63] max-w-sm mx-auto">
                  Archived links and articles are stored here if you ever need them again.
                </p>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {archivedItems.map((item) => (
                  <ItemCard key={item.id} item={item} />
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* New Collection Modal */}
      {showColModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in">
          <div className="w-full max-w-md bg-[#f7f5ee] rounded-3xl p-6 shadow-2xl border border-[#e4e0d5]">
            <h3 className="text-lg font-bold text-[#171711] mb-2">Create New Collection</h3>
            <p className="text-xs text-[#6c6b63] mb-4">
              Enter a name for your new collection.
            </p>
            <form onSubmit={handleCreateCol} className="space-y-4">
              <input
                type="text"
                value={newColName}
                onChange={(e) => setNewColName(e.target.value)}
                placeholder="e.g. Flutter Guides, AI Research, Recipes..."
                autoFocus
                className="w-full px-4 py-2.5 text-sm bg-white border border-[#e4e0d5] rounded-xl text-[#171711] focus:outline-none focus:ring-2 focus:ring-zinc-900/10"
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
                  className="px-5 py-2 text-xs font-bold text-white bg-[#171711] hover:bg-[#282723] disabled:opacity-50 rounded-xl cursor-pointer"
                >
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
