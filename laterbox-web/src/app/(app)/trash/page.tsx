'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { DashboardView } from '@/components/inbox/DashboardView';
import { Trash2 } from 'lucide-react';

export default function TrashPage() {
  const { deletedItems, emptyTrash, loading } = useItems();

  const topBanner = deletedItems.length > 0 ? (
    <div className="mb-2.5 px-4 py-2.5 rounded-2xl bg-amber-50/90 border border-amber-200/80 flex items-center justify-between gap-3 text-xs shrink-0 shadow-2xs">
      <div className="flex items-center gap-2 text-amber-900 min-w-0">
        <Trash2 className="w-4 h-4 text-amber-700 shrink-0" />
        <span className="truncate">
          Items in Recently Deleted can be restored or permanently removed.
        </span>
      </div>
      <button
        type="button"
        onClick={() => {
          if (confirm('Permanently delete all items in Trash? This cannot be undone.')) {
            emptyTrash();
          }
        }}
        className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-xs shadow-2xs transition-colors cursor-pointer shrink-0"
      >
        <Trash2 className="w-3.5 h-3.5" />
        <span>Empty Trash Now</span>
      </button>
    </div>
  ) : null;

  return (
    <DashboardView
      title="Recently Deleted"
      items={deletedItems}
      loading={loading}
      topBanner={topBanner}
    />
  );
}
