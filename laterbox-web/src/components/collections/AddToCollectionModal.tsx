'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { Folder, FolderPlus, Check, X, Plus, Loader2, MinusCircle } from 'lucide-react';
import { LaterBoxItem } from '@/lib/supabase/types';

interface AddToCollectionModalProps {
  item: LaterBoxItem;
  isOpen: boolean;
  onClose: () => void;
}

export function AddToCollectionModal({ item, isOpen, onClose }: AddToCollectionModalProps) {
  const { collections, items, createCollection, addItemToCollection, removeItemFromCollection } = useItems();
  const [newColName, setNewColName] = useState('');
  const [creating, setCreating] = useState(false);
  const [busyColId, setBusyColId] = useState<string | null>(null);

  // Retrieve freshest representation of the item from ItemContext
  const currentItem = useMemo(() => {
    return items.find((i) => i.id === item.id) || item;
  }, [items, item]);

  // Set of collection IDs the item currently belongs to
  const [activeCols, setActiveCols] = useState<Set<string>>(() => {
    return new Set((currentItem.collections || []).map((c) => c.id));
  });

  // Sync state whenever modal opens or currentItem collections change
  useEffect(() => {
    if (isOpen) {
      const colIds = (currentItem.collections || []).map((c) => c.id);
      setActiveCols(new Set(colIds));
    }
  }, [isOpen, currentItem]);

  if (!isOpen) return null;

  const itemTitle = currentItem.metadata?.title || currentItem.title || 'Selected item';

  const handleToggleCollection = async (collectionId: string) => {
    setBusyColId(collectionId);
    try {
      if (activeCols.has(collectionId)) {
        await removeItemFromCollection(collectionId, currentItem.id);
        setActiveCols((prev) => {
          const next = new Set(prev);
          next.delete(collectionId);
          return next;
        });
      } else {
        await addItemToCollection(collectionId, currentItem.id);
        setActiveCols((prev) => new Set(prev).add(collectionId));
      }
    } finally {
      setBusyColId(null);
    }
  };

  const handleCreateCollection = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newColName.trim() || creating) return;

    setCreating(true);
    try {
      const newCol = await createCollection(newColName.trim());
      await addItemToCollection(newCol.id, currentItem.id, newCol);
      setActiveCols((prev) => new Set(prev).add(newCol.id));
      setNewColName('');
    } finally {
      setCreating(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in"
      onClick={(e) => {
        e.stopPropagation();
        onClose();
      }}
    >
      <div
        className="w-full max-w-md bg-[#f7f5ee] rounded-3xl p-6 sm:p-7 shadow-2xl border border-[#e4e0d5] space-y-5"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84] shrink-0">
              <FolderPlus className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-lg font-black text-[#171711] tracking-tight">Manage Collections</h3>
                {activeCols.size > 0 && (
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-[#171711] text-[#e6edb0]">
                    {activeCols.size} in
                  </span>
                )}
              </div>
              <p className="text-xs text-[#6c6b63] truncate max-w-[250px] font-medium" title={itemTitle}>
                {itemTitle}
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 text-[#6c6b63] hover:text-[#171711] rounded-full hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Subtitle / hint */}
        <p className="text-[11px] text-[#6c6b63] -mt-2">
          Choose one or multiple collections to organize this item, or click an active collection to remove it.
        </p>

        {/* Existing Collections List */}
        <div className="space-y-1.5 max-h-60 overflow-y-auto pr-1">
          {collections.length === 0 ? (
            <div className="text-center py-6 px-3 rounded-2xl bg-white border border-[#e4e0d5] space-y-1">
              <Folder className="w-8 h-8 text-[#9e9b92] mx-auto mb-1" />
              <p className="text-xs font-bold text-[#171711]">No collections created yet</p>
              <p className="text-[11px] text-[#6c6b63]">
                Create a collection below to categorize your items.
              </p>
            </div>
          ) : (
            collections.map((col) => {
              const isAdded = activeCols.has(col.id);
              const isBusy = busyColId === col.id;

              return (
                <button
                  key={col.id}
                  type="button"
                  onClick={() => handleToggleCollection(col.id)}
                  disabled={isBusy}
                  className={`w-full flex items-center justify-between p-3 rounded-2xl border transition-all text-left cursor-pointer group ${
                    isAdded
                      ? 'bg-[#e6edb0]/60 border-[#bac77e] text-[#171711] shadow-2xs'
                      : 'bg-white hover:bg-[#ebe7dc]/50 border-[#e4e0d5] text-[#171711]'
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 transition-colors ${
                        isAdded ? 'bg-[#171711] text-white' : 'bg-[#f7f5ee] text-[#6c6b63] group-hover:text-[#171711]'
                      }`}
                    >
                      <Folder className="w-4 h-4" />
                    </div>
                    <span className="text-xs font-bold truncate">{col.name}</span>
                  </div>

                  <div className="shrink-0">
                    {isBusy ? (
                      <Loader2 className="w-4 h-4 animate-spin text-[#171711]" />
                    ) : isAdded ? (
                      <div className="flex items-center gap-1.5">
                        <span className="inline-flex items-center gap-1 text-[11px] font-extrabold text-[#171711] group-hover:hidden">
                          <Check className="w-4 h-4 text-[#171711]" />
                          <span>In collection</span>
                        </span>
                        <span className="hidden group-hover:inline-flex items-center gap-1 text-[11px] font-bold text-rose-600">
                          <MinusCircle className="w-3.5 h-3.5" />
                          <span>Remove</span>
                        </span>
                      </div>
                    ) : (
                      <span className="text-xs font-bold text-[#9e9b92] group-hover:text-[#171711] transition-colors">
                        + Add
                      </span>
                    )}
                  </div>
                </button>
              );
            })
          )}
        </div>

        {/* Create Collection Input */}
        <form onSubmit={handleCreateCollection} className="pt-2 border-t border-[#e4e0d5] space-y-2">
          <div className="flex items-center gap-2">
            <input
              type="text"
              value={newColName}
              onChange={(e) => setNewColName(e.target.value)}
              placeholder="Create new collection…"
              className="flex-1 px-3.5 py-2.5 rounded-xl bg-white border border-[#e4e0d5] text-xs font-medium text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:border-[#171711] transition-colors"
            />
            <button
              type="submit"
              disabled={!newColName.trim() || creating}
              className="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] disabled:opacity-50 text-white text-xs font-bold transition-all cursor-pointer shrink-0 shadow-2xs"
            >
              {creating ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <>
                  <Plus className="w-3.5 h-3.5" />
                  <span>Create</span>
                </>
              )}
            </button>
          </div>
        </form>

        {/* Done Button */}
        <div className="pt-1">
          <button
            type="button"
            onClick={onClose}
            className="w-full py-2.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] transition-colors cursor-pointer shadow-2xs"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
}
