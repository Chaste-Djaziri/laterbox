'use client';

import React, { useMemo } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useItems } from '@/lib/store/ItemContext';
import { DashboardView } from '@/components/inbox/DashboardView';
import { Folder, ArrowLeft } from 'lucide-react';

export default function CollectionDetailPage() {
  const params = useParams();
  const collectionId = params?.collectionId as string;

  const { collections, items, loading } = useItems();

  const collection = useMemo(
    () => collections.find((c) => c.id === collectionId),
    [collections, collectionId]
  );

  const collectionItems = useMemo(
    () =>
      items.filter(
        (item) =>
          !item.deleted_at &&
          item.collections?.some((c) => c.id === collectionId)
      ),
    [items, collectionId]
  );

  if (!loading && !collection) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-8 text-center space-y-4">
        <div className="w-12 h-12 mx-auto rounded-2xl bg-white border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92] shadow-2xs">
          <Folder className="w-6 h-6" />
        </div>
        <div>
          <h2 className="text-base font-extrabold text-[#171711]">Collection not found</h2>
          <p className="text-xs text-[#8e8d87] mt-1">This collection may have been removed or does not exist.</p>
        </div>
        <Link
          href="/inbox"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#171711] text-white text-xs font-bold hover:bg-black transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Inbox
        </Link>
      </div>
    );
  }

  return (
    <DashboardView
      title={collection?.name || 'Collection'}
      items={collectionItems}
      loading={loading}
    />
  );
}
