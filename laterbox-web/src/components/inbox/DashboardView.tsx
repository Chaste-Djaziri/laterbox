'use client';

import React from 'react';
import { useDashboard } from '@/lib/store/DashboardContext';
import { EmailInboxTable } from '@/components/inbox/EmailInboxTable';
import { LaterBoxItem } from '@/lib/supabase/types';

interface DashboardViewProps {
  items: LaterBoxItem[];
  loading?: boolean;
  title?: string;
  topBanner?: React.ReactNode;
}

export function DashboardView({ items, loading, title: propTitle, topBanner }: DashboardViewProps) {
  const {
    title: contextTitle,
    setTitle,
    searchQuery,
    isSearchSubmitted,
    searchFilters,
    setSearchFilters,
    handleClearSearch,
    setCaptureOpen,
  } = useDashboard();

  React.useEffect(() => {
    if (propTitle) {
      setTitle(propTitle);
    }
  }, [propTitle, setTitle]);

  const activeTitle = propTitle || contextTitle;

  return (
    <div className="w-full px-3 sm:px-4 lg:px-5 pb-2 sm:pb-3 flex flex-col flex-1 min-h-0 h-full overflow-hidden">
      {topBanner}
      <div className="flex-1 min-h-0 overflow-hidden flex flex-col">
        {loading ? (
          <div className="bg-white border border-[#e4e0d5] rounded-2xl p-12 text-center animate-pulse flex-1 flex items-center justify-center">
            <p className="text-xs font-semibold text-[#8e8d87]">
              Loading {activeTitle.toLowerCase()} messages...
            </p>
          </div>
        ) : (
          <EmailInboxTable
            items={items}
            onOpenCapture={() => setCaptureOpen(true)}
            searchQuery={searchQuery}
            isSearchSubmitted={isSearchSubmitted}
            searchFilters={searchFilters}
            onUpdateFilters={setSearchFilters}
            onClearSearch={handleClearSearch}
          />
        )}
      </div>
    </div>
  );
}
