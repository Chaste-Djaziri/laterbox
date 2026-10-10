'use client';

import React, { createContext, useContext, useState, useEffect, useMemo } from 'react';
import { usePathname } from 'next/navigation';
import {
  InboxSearchFilters,
  DEFAULT_SEARCH_FILTERS,
} from '@/lib/utils/emailFormatters';

export function getRouteTitle(pathname: string): string {
  if (!pathname || pathname === '/' || pathname === '/inbox') return 'Inbox';
  if (pathname === '/starred') return 'Starred';
  if (pathname === '/kept') return 'Kept';
  if (pathname === '/archived') return 'Archived';
  if (pathname === '/trash' || pathname === '/deleted') return 'Recently Deleted';
  if (pathname === '/today') return 'Today';
  if (pathname === '/upcoming') return 'Upcoming';
  if (pathname === '/someday') return 'Someday';
  if (pathname === '/library') return 'Library';
  if (pathname === '/settings') return 'Settings';
  if (pathname === '/plans') return 'Plans';
  if (pathname === '/downloads') return 'Downloads';
  if (pathname === '/tutorial') return 'Tutorial';
  if (pathname.startsWith('/item/')) return 'Item Details';
  if (pathname.startsWith('/library/')) return 'Collection';
  const clean = pathname.replace(/^\//, '').split('/')[0];
  return clean ? clean.charAt(0).toUpperCase() + clean.slice(1) : 'Inbox';
}

interface DashboardContextType {
  title: string;
  setTitle: (title: string) => void;
  searchQuery: string;
  setSearchQuery: (q: string) => void;
  isSearchSubmitted: boolean;
  setIsSearchSubmitted: (s: boolean) => void;
  searchFilters: InboxSearchFilters;
  setSearchFilters: React.Dispatch<React.SetStateAction<InboxSearchFilters>>;
  handleClearSearch: () => void;
  captureOpen: boolean;
  setCaptureOpen: (open: boolean) => void;
}

const DashboardContext = createContext<DashboardContextType | null>(null);

export function DashboardProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const defaultTitle = useMemo(() => getRouteTitle(pathname), [pathname]);
  const [customTitle, setCustomTitle] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearchSubmitted, setIsSearchSubmitted] = useState(false);
  const [searchFilters, setSearchFilters] = useState<InboxSearchFilters>(DEFAULT_SEARCH_FILTERS);
  const [captureOpen, setCaptureOpen] = useState(false);

  // Reset custom title and search on route change
  useEffect(() => {
    setCustomTitle(null);
    setSearchQuery('');
    setIsSearchSubmitted(false);
    setSearchFilters(DEFAULT_SEARCH_FILTERS);
  }, [pathname]);

  const handleClearSearch = () => {
    setSearchQuery('');
    setIsSearchSubmitted(false);
    setSearchFilters(DEFAULT_SEARCH_FILTERS);
  };

  const title = customTitle || defaultTitle;

  return (
    <DashboardContext.Provider
      value={{
        title,
        setTitle: setCustomTitle,
        searchQuery,
        setSearchQuery,
        isSearchSubmitted,
        setIsSearchSubmitted,
        searchFilters,
        setSearchFilters,
        handleClearSearch,
        captureOpen,
        setCaptureOpen,
      }}
    >
      {children}
    </DashboardContext.Provider>
  );
}

export function useDashboard() {
  const context = useContext(DashboardContext);
  if (!context) {
    throw new Error('useDashboard must be used within a DashboardProvider');
  }
  return context;
}
