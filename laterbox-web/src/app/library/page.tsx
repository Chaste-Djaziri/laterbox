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
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-black text-zinc-900 tracking-tight">
              Library
            </h1>
            <p className="text-xs sm:text-sm text-zinc-500 font-medium mt-0.5">
              Organize your permanent knowledge base, favorite items, and archived reads
            </p>
          </div>

          {activeTab === 'collections' && (
            <button
              onClick={() => setShowColModal(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-sm transition-all"
            >
              <FolderPlus className="w-4 h-4" />
              <span>New Collection</span>
            </button>
          )}
        </div>

        {/* Tab Navigation */}
        <div className="flex items-center gap-2 border-b border-zinc-200 pb-3 overflow-x-auto scrollbar-none">
          {tabs.map((tab) => {
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                  active
                    ? 'bg-zinc-900 text-white shadow-sm'
                    : 'bg-zinc-100 text-zinc-600 hover:bg-zinc-200'
                }`}
              >
                {tab.icon}
                <span>{tab.label}</span>
                <span
                  className={`px-1.5 py-0.2 rounded-md text-[10px] font-mono ${
                    active
                      ? 'bg-zinc-700 text-zinc-200'
                      : 'bg-zinc-200 text-zinc-600'
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
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-zinc-300 space-y-3">
                <Folder className="w-10 h-10 text-emerald-500 mx-auto" />
                <h3 className="text-base font-bold text-zinc-700">
                  No Collections Created Yet
                </h3>
                <p className="text-xs text-zinc-500 max-w-sm mx-auto">
                  Group your saved links into topics, projects, or reading lists.
                </p>
                <div className="pt-2">
                  <button
                    onClick={() => setShowColModal(true)}
                    className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-emerald-600 text-white text-xs font-bold shadow-sm"
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
                    className="p-6 rounded-3xl bg-white border border-zinc-200/80 hover:border-emerald-500/50 hover:shadow-lg transition-all flex flex-col justify-between"
                  >
                    <div className="flex items-center justify-between mb-4">
                      <div className="w-10 h-10 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-600">
                        <Folder className="w-5 h-5" />
                      </div>
                      <button
                        onClick={() => deleteCollection(col.id)}
                        className="p-1.5 text-zinc-400 hover:text-red-600 rounded-lg hover:bg-zinc-100 transition-colors"
                        title="Delete Collection"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>

                    <div>
                      <h3 className="text-base font-bold text-zinc-900">{col.name}</h3>
                      <p className="text-xs text-zinc-400 mt-1">Collection</p>
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
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-zinc-300 space-y-3">
                <Star className="w-10 h-10 text-amber-400 mx-auto" />
                <h3 className="text-base font-bold text-zinc-700">
                  No Favorites Starred Yet
                </h3>
                <p className="text-xs text-zinc-500 max-w-sm mx-auto">
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
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-zinc-300 space-y-3">
                <CheckCircle className="w-10 h-10 text-emerald-500 mx-auto" />
                <h3 className="text-base font-bold text-zinc-700">
                  No Kept Items Yet
                </h3>
                <p className="text-xs text-zinc-500 max-w-sm mx-auto">
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
              <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-zinc-300 space-y-3">
                <Archive className="w-10 h-10 text-zinc-400 mx-auto" />
                <h3 className="text-base font-bold text-zinc-700">
                  Archive is Empty
                </h3>
                <p className="text-xs text-zinc-500 max-w-sm mx-auto">
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
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-zinc-200">
            <h3 className="text-lg font-bold text-zinc-900 mb-2">Create New Collection</h3>
            <p className="text-xs text-zinc-500 mb-4">
              Enter a name for your new collection.
            </p>
            <form onSubmit={handleCreateCol} className="space-y-4">
              <input
                type="text"
                value={newColName}
                onChange={(e) => setNewColName(e.target.value)}
                placeholder="e.g. Flutter Guides, AI Research, Recipes..."
                autoFocus
                className="w-full px-4 py-2.5 text-sm bg-zinc-50 border border-zinc-200 rounded-xl text-zinc-900 focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
              <div className="flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowColModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-zinc-600 hover:bg-zinc-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!newColName.trim()}
                  className="px-5 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 rounded-xl"
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
