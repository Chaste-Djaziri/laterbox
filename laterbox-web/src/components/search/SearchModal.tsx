'use client';

import React, { useState, useEffect, useRef, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { useItems } from '@/lib/store/ItemContext';
import { LaterBoxItem } from '@/lib/supabase/types';
import {
  Search,
  X,
  Layers,
  FileText,
  PlayCircle,
  Music2,
  StickyNote,
  Folder,
  ArrowRight,
  Clock,
  CalendarDays,
  Archive,
  Inbox,
  BookMarked,
  Sparkles,
  ExternalLink,
  CornerDownLeft,
} from 'lucide-react';

interface SearchModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function SearchModal({ isOpen, onClose }: SearchModalProps) {
  const router = useRouter();
  const { items } = useItems();
  const [query, setQuery] = useState('');
  const [formatFilter, setFormatFilter] = useState<'all' | 'article' | 'video' | 'music' | 'note' | 'file'>('all');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  // Focus input when opened and reset selection
  useEffect(() => {
    if (isOpen) {
      setQuery('');
      setSelectedIndex(0);
      const timer = setTimeout(() => {
        inputRef.current?.focus();
      }, 50);
      return () => clearTimeout(timer);
    }
  }, [isOpen]);

  // Quick navigation destinations when query is empty
  const navShortcuts = useMemo(() => [
    { label: 'Inbox', href: '/inbox', icon: <Inbox className="w-4 h-4" />, badge: 'Shortcut' },
    { label: 'Today (Returned)', href: '/today', icon: <Clock className="w-4 h-4" />, badge: 'Focus' },
    { label: 'Upcoming', href: '/upcoming', icon: <CalendarDays className="w-4 h-4" />, badge: 'Schedule' },
    { label: 'Someday Vault', href: '/someday', icon: <Archive className="w-4 h-4" />, badge: 'Deferred' },
    { label: 'All Items Library', href: '/library', icon: <BookMarked className="w-4 h-4" />, badge: 'Archive' },
    { label: 'Full Deep Search Engine', href: '/search', icon: <Search className="w-4 h-4" />, badge: 'Vault' },
  ], []);

  // Filtered items based on query & format
  const matchingItems = useMemo(() => {
    const q = query.trim().toLowerCase();

    return items.filter((item) => {
      // Content format filter
      if (formatFilter !== 'all') {
        const cType = item.metadata?.content_type || (item.url ? 'link' : 'note');
        const ext = item.url?.split('.').pop()?.toLowerCase() || '';
        const isFile = item.type === 'file' || ['pdf', 'psd', 'zip', 'docx'].includes(ext);

        if (formatFilter === 'note' && (item.url || !item.text_content)) return false;
        if (formatFilter === 'video' && cType !== 'video' && !item.url?.includes('youtube.com')) return false;
        if (formatFilter === 'music' && cType !== 'music' && !item.url?.includes('spotify.com')) return false;
        if (formatFilter === 'article' && cType !== 'article' && !item.url) return false;
        if (formatFilter === 'file' && !isFile) return false;
      }

      if (!q) return true;

      const title = (item.metadata?.title || item.title || '').toLowerCase();
      const domain = (item.metadata?.domain || item.url || '').toLowerCase();
      const desc = (item.metadata?.description || item.text_content || '').toLowerCase();
      const note = (item.note?.content || '').toLowerCase();
      const tags = (item.tags || []).join(' ').toLowerCase();

      return title.includes(q) || domain.includes(q) || desc.includes(q) || note.includes(q) || tags.includes(q);
    });
  }, [items, query, formatFilter]);

  // If query is empty, show top 4 recent items + nav shortcuts
  const displayedItems = useMemo(() => {
    if (!query.trim()) {
      return matchingItems.slice(0, 4);
    }
    return matchingItems.slice(0, 8);
  }, [matchingItems, query]);

  const totalNavItems = !query.trim() ? navShortcuts.length : 0;
  const totalItemsCount = totalNavItems + displayedItems.length;

  // Keep selected index within bounds
  useEffect(() => {
    if (selectedIndex >= totalItemsCount && totalItemsCount > 0) {
      setSelectedIndex(0);
    }
  }, [totalItemsCount, selectedIndex]);

  // Handle keyboard navigation inside modal
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.preventDefault();
      onClose();
      return;
    }

    if (totalItemsCount === 0) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % totalItemsCount);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + totalItemsCount) % totalItemsCount);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      activateCurrentItem();
    }
  };

  const activateCurrentItem = () => {
    if (!query.trim() && selectedIndex < navShortcuts.length) {
      const target = navShortcuts[selectedIndex];
      onClose();
      router.push(target.href);
      return;
    }

    const itemIdx = !query.trim() ? selectedIndex - navShortcuts.length : selectedIndex;
    const selectedItem = displayedItems[itemIdx];
    if (selectedItem) {
      onClose();
      router.push(`/item/${selectedItem.id}`);
    }
  };

  if (!isOpen) return null;

  const getItemBadge = (item: LaterBoxItem) => {
    const ext = item.url?.split('.').pop()?.toLowerCase() || '';
    const isPsd = ext === 'psd' || item.title?.toLowerCase().endsWith('.psd');
    const isPdf = ext === 'pdf' || item.title?.toLowerCase().endsWith('.pdf');
    const isYoutube = item.url?.includes('youtube.com') || item.url?.includes('youtu.be');
    const isSpotify = item.url?.includes('spotify.com');
    const isNote = !item.url && (item.type === 'note' || !!item.text_content);

    if (isPsd) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-[#001e36] text-[#31a8ff] text-[10px] font-black tracking-tight shrink-0">
          Ps
        </span>
      );
    }
    if (isPdf) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-red-100 text-red-600 text-[10px] font-black tracking-tight shrink-0">
          PDF
        </span>
      );
    }
    if (isYoutube) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-red-50 text-red-600 text-[10px] font-bold shrink-0">
          <PlayCircle className="w-3 h-3 text-red-600" />
          Video
        </span>
      );
    }
    if (isSpotify) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[10px] font-bold shrink-0">
          <Music2 className="w-3 h-3 text-emerald-600" />
          Music
        </span>
      );
    }
    if (isNote) {
      return (
        <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[#171711] text-[10px] font-bold shrink-0">
          <StickyNote className="w-3 h-3 text-[#6c6b63]" />
          Note
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[#6c6b63] text-[10px] font-bold shrink-0">
        <FileText className="w-3 h-3 text-[#6c6b63]" />
        Link
      </span>
    );
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center p-3 sm:p-6 sm:pt-20 bg-[#171711]/40 backdrop-blur-xs transition-opacity animate-in fade-in duration-150"
      onClick={onClose}
    >
      <div
        className="w-full max-w-2xl bg-[#faf8f5] border border-[#e4e0d5] rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[85vh] transition-all animate-in zoom-in-98 duration-150"
        onClick={(e) => e.stopPropagation()}
        onKeyDown={handleKeyDown}
      >
        {/* Search Header Input */}
        <div className="flex items-center gap-3 px-4 py-3.5 border-b border-[#e4e0d5] bg-white">
          <Search className="w-5 h-5 text-[#9e9b92] shrink-0" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setSelectedIndex(0);
            }}
            placeholder="Search items, notes, links, tags, or domains..."
            className="flex-1 bg-transparent text-sm text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden font-medium"
          />
          {query && (
            <button
              type="button"
              onClick={() => {
                setQuery('');
                inputRef.current?.focus();
              }}
              className="p-1 rounded-full text-[#9e9b92] hover:text-[#171711] transition-colors cursor-pointer"
              title="Clear query"
            >
              <X className="w-4 h-4" />
            </button>
          )}
          <kbd
            onClick={onClose}
            className="hidden sm:inline-flex items-center px-2 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono font-bold text-[#6c6b63] hover:text-[#171711] cursor-pointer"
            title="Press Esc to close"
          >
            ESC
          </kbd>
        </div>

        {/* Content Format Filter Pills */}
        <div className="flex items-center gap-1.5 px-4 py-2 bg-[#f7f5ee] border-b border-[#e4e0d5]/60 overflow-x-auto scrollbar-none">
          {[
            { id: 'all', label: 'All', icon: <Layers className="w-3 h-3" /> },
            { id: 'article', label: 'Articles', icon: <FileText className="w-3 h-3" /> },
            { id: 'video', label: 'Videos', icon: <PlayCircle className="w-3 h-3" /> },
            { id: 'music', label: 'Music', icon: <Music2 className="w-3 h-3" /> },
            { id: 'note', label: 'Notes', icon: <StickyNote className="w-3 h-3" /> },
            { id: 'file', label: 'Files', icon: <Folder className="w-3 h-3" /> },
          ].map((tab) => {
            const active = formatFilter === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => {
                  setFormatFilter(tab.id as any);
                  setSelectedIndex(0);
                }}
                className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold transition-all cursor-pointer shrink-0 ${
                  active
                    ? 'bg-[#171711] text-white shadow-2xs'
                    : 'bg-white/80 border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] hover:bg-white'
                }`}
              >
                {tab.icon}
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Search Results / Navigation List */}
        <div ref={listRef} className="flex-1 overflow-y-auto p-2 space-y-3">
          {/* Quick Navigation Section (when query is empty) */}
          {!query.trim() && (
            <div className="space-y-1">
              <div className="px-3 py-1 text-[11px] font-black uppercase tracking-wider text-[#9e9b92]">
                Quick Navigation
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-1">
                {navShortcuts.map((item, idx) => {
                  const isSelected = selectedIndex === idx;
                  return (
                    <button
                      key={item.href}
                      type="button"
                      onClick={() => {
                        onClose();
                        router.push(item.href);
                      }}
                      className={`flex items-center justify-between px-3 py-2 rounded-xl text-xs font-bold transition-all text-left cursor-pointer ${
                        isSelected
                          ? 'bg-[#e6edb0] text-[#171711] shadow-2xs'
                          : 'hover:bg-white text-[#4a4941]'
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <span className="text-[#171711]">{item.icon}</span>
                        <span>{item.label}</span>
                      </div>
                      <span className="text-[10px] font-mono font-medium opacity-60">
                        {item.badge}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Matching Items Section */}
          <div className="space-y-1">
            <div className="px-3 py-1 flex items-center justify-between text-[11px] font-black uppercase tracking-wider text-[#9e9b92]">
              <span>{!query.trim() ? 'Recent In Vault' : `Results (${matchingItems.length})`}</span>
              {query.trim() && (
                <button
                  type="button"
                  onClick={() => {
                    onClose();
                    router.push(`/search?q=${encodeURIComponent(query)}`);
                  }}
                  className="text-[10px] text-[#171711] hover:underline font-bold normal-case cursor-pointer flex items-center gap-1"
                >
                  Deep Search <ArrowRight className="w-3 h-3" />
                </button>
              )}
            </div>

            {displayedItems.length > 0 ? (
              displayedItems.map((item, idx) => {
                const globalIdx = !query.trim() ? navShortcuts.length + idx : idx;
                const isSelected = selectedIndex === globalIdx;
                const title = item.metadata?.title || item.title || item.url || 'Untitled Item';
                const domain = item.metadata?.domain || (item.url ? new URL(item.url, 'http://localhost').hostname.replace('www.', '') : '');
                const preview = item.metadata?.description || item.text_content || item.note?.content || '';

                return (
                  <div
                    key={item.id}
                    onClick={() => {
                      onClose();
                      router.push(`/item/${item.id}`);
                    }}
                    onMouseEnter={() => setSelectedIndex(globalIdx)}
                    className={`flex items-start gap-3 p-3 rounded-xl transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-white border border-[#171711]/20 shadow-sm'
                        : 'hover:bg-white/60 border border-transparent'
                    }`}
                  >
                    <div className="pt-0.5">{getItemBadge(item)}</div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-2">
                        <h4 className="text-xs font-bold text-[#171711] truncate">{title}</h4>
                        {domain && (
                          <span className="text-[10px] text-[#9e9b92] shrink-0 font-medium truncate max-w-[120px]">
                            {domain}
                          </span>
                        )}
                      </div>
                      {preview && (
                        <p className="text-[11px] text-[#6c6b63] line-clamp-1 mt-0.5">
                          {preview}
                        </p>
                      )}
                    </div>
                    {isSelected && (
                      <div className="shrink-0 self-center text-[#171711] opacity-70">
                        <CornerDownLeft className="w-3.5 h-3.5" />
                      </div>
                    )}
                  </div>
                );
              })
            ) : (
              <div className="py-8 text-center space-y-2">
                <div className="w-10 h-10 rounded-full bg-[#ebe7dc] flex items-center justify-center mx-auto text-[#6c6b63]">
                  <Search className="w-4 h-4" />
                </div>
                <p className="text-xs font-bold text-[#171711]">No matching items in vault</p>
                <p className="text-[11px] text-[#6c6b63]">
                  Try different keywords or launch full Deep Search.
                </p>
                <button
                  type="button"
                  onClick={() => {
                    onClose();
                    router.push(`/search?q=${encodeURIComponent(query)}`);
                  }}
                  className="mt-2 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-xs font-bold text-[#171711] hover:bg-[#d9e29a] transition-colors cursor-pointer"
                >
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>Search in Deep Search Engine</span>
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Footer Shortcut Bar */}
        <div className="px-4 py-2.5 bg-[#f7f5ee] border-t border-[#e4e0d5] flex items-center justify-between text-[11px] text-[#6c6b63]">
          <div className="flex items-center gap-3">
            <span className="inline-flex items-center gap-1">
              <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] font-mono text-[9px] font-bold text-[#171711]">↑</kbd>
              <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] font-mono text-[9px] font-bold text-[#171711]">↓</kbd>
              <span className="hidden sm:inline">to navigate</span>
            </span>
            <span className="inline-flex items-center gap-1">
              <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] font-mono text-[9px] font-bold text-[#171711]">↵</kbd>
              <span className="hidden sm:inline">to open</span>
            </span>
            <span className="inline-flex items-center gap-1">
              <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] font-mono text-[9px] font-bold text-[#171711]">esc</kbd>
              <span className="hidden sm:inline">to close</span>
            </span>
          </div>

          <button
            type="button"
            onClick={() => {
              onClose();
              router.push('/search');
            }}
            className="text-[11px] font-bold text-[#171711] hover:underline cursor-pointer flex items-center gap-1"
          >
            <span>Deep Search</span>
            <ExternalLink className="w-3 h-3" />
          </button>
        </div>
      </div>
    </div>
  );
}
