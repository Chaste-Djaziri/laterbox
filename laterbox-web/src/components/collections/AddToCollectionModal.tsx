'use client';

import React, { useState } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { Folder, FolderPlus, Check, X, Plus, Loader2 } from 'lucide-react';
import { LaterBoxItem } from '@/lib/supabase/types';

interface AddToCollectionModalProps {
  item: LaterBoxItem;
  isOpen: boolean;
  onClose: () => void;
}

export function AddToCollectionModal({ item, isOpen, onClose }: AddToCollectionModalProps) {
  const { collections, createCollection, addItemToCollection, removeItemFromCollection } = useItems();
  const [newColName, setNewColName] = useState('');
  const [creating, setCreating] = useState(false);
  const [addedCols, setAddedCols] = useState<Set<string>>(new Set());
  const [busyColId, setBusyColId] = useState<string | null>(null);

  if (!isOpen) return null;

  const itemTitle = item.metadata?.title || item.title || 'Selected item';

  const handleToggleCollection = async (collectionId: string) => {
    setBusyColId(collectionId);
    try {
      if (addedCols.has(collectionId)) {
        await removeItemFromCollection(collectionId, item.id);
        setAddedCols((prev) => {
          const next = new Set(prev);
          next.delete(collectionId);
          return next;
        });
      } else {
        await addItemToCollection(collectionId, item.id);
        setAddedCols((prev) => new Set(prev).add(collectionId));
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
      await addItemToCollection(newCol.id, item.id);
      setAddedCols((prev) => new Set(prev).add(newCol.id));
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
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <FolderPlus className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-black text-[#171711] tracking-tight">Add to Collection</h3>
              <p className="text-xs text-[#6c6b63] truncate max-w-[260px] font-medium">
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

        {/* Existing Collections List */}
        <div className="space-y-1.5 max-h-56 overflow-y-auto pr-1">
          {collections.length === 0 ? (
            <div className="text-center py-6 px-3 rounded-2xl bg-white border border-[#e4e0d5] space-y-1">
              <Folder className="w-8 h-8 text-[#9e9b92] mx-auto mb-1" />
              <p className="text-xs font-bold text-[#171711]">No collections yet</p>
              <p className="text-[11px] text-[#6c6b63]">
                Create a collection below to organize your items.
              </p>
            </div>
          ) : (
            collections.map((col) => {
              const isAdded = addedCols.has(col.id);
              const isBusy = busyColId === col.id;

              return (
                <button
                  key={col.id}
                  type="button"
                  onClick={() => handleToggleCollection(col.id)}
                  disabled={isBusy}
                  className={`w-full flex items-center justify-between p-3 rounded-2xl border transition-all text-left cursor-pointer ${
                    isAdded
                      ? 'bg-[#e6edb0]/60 border-[#d0db84] text-[#171711]'
                      : 'bg-white hover:bg-[#ebe7dc]/50 border-[#e4e0d5] text-[#171711]'
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 ${
                        isAdded ? 'bg-[#171711] text-white' : 'bg-[#f7f5ee] text-[#6c6b63]'
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
                      <span className="inline-flex items-center gap-1 text-[11px] font-extrabold text-[#171711]">
                        <Check className="w-4 h-4 text-[#171711]" />
                        <span>Added</span>
                      </span>
                    ) : (
                      <span className="text-xs font-bold text-[#9e9b92] hover:text-[#171711]">
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
              placeholder="New collection name…"
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
            className="w-full py-2.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] transition-colors cursor-pointer"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
}
