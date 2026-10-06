'use client';

import React, { useState, useEffect, useMemo, useRef } from 'react';
import Link from 'next/link';
import { ItemCard } from '@/components/inbox/ItemCard';
import { ItemListRow } from '@/components/inbox/ItemListRow';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import {
  parseAmbiguousQuery,
  filterAndRankAmbiguousItems,
  generateSuggestedQueries,
  type ParsedSearchQuery,
  type AmbiguousContentType,
} from '@/lib/search/ambiguousSearch';
import {
  Search as SearchIcon,
  Database,
  X,
  FileText,
  PlayCircle,
  Music2,
  StickyNote,
  Layers,
  ArrowLeft,
  LayoutGrid,
  List,
  HelpCircle,
  Sparkles,
  Folder,
  Loader2,
  Calendar,
  Zap,
  Lock,
} from 'lucide-react';

interface AiSearchResult {
  summary: string;
  model: string;
  rankedItemIds: string[];
  explanations: Record<string, string>;
  parsedFilters?: {
    contentType?: string;
    dateRange?: { start?: string; end?: string; label: string };
    semanticKeywords?: string[];
  };
}

export default function SearchPage() {
  const { items } = useItems();
  const { session } = useAuth();
  const { isPro } = useBilling();

  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [layoutMode, setLayoutMode] = useState<'grid' | 'list'>('grid');
  const [aiEnabled, setAiEnabled] = useState(true);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiResult, setAiResult] = useState<AiSearchResult | null>(null);

  // Parse ambiguous natural language query locally (instant, zero-latency)
  const parsed = useMemo<ParsedSearchQuery>(() => {
    return parseAmbiguousQuery(query);
  }, [query]);

  // Synchronous client-side filter and ranking
  const localRanked = useMemo(() => {
    // If user clicked an explicit format chip, let that override parsed format
    const effectiveParsed: ParsedSearchQuery = {
      ...parsed,
      contentType: typeFilter !== 'all' ? (typeFilter as AmbiguousContentType) : parsed.contentType,
    };
    return filterAndRankAmbiguousItems(items, effectiveParsed);
  }, [items, parsed, typeFilter]);

  // Debounced Gemini AI Semantic Search call when user has Pro plan
  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    const trimmed = query.trim();
    if (!isPro || !aiEnabled || trimmed.length < 3) {
      setAiLoading(false);
      setAiResult(null);
      return;
    }

    setAiLoading(true);

    debounceTimerRef.current = setTimeout(async () => {
      try {
        const candidatePayload = items.slice(0, 40).map((item) => ({
          id: item.id,
          title: item.title || item.metadata?.title || 'Untitled',
          type: item.type || item.metadata?.content_type || 'link',
          url: item.url || undefined,
          domain: item.metadata?.domain || (item.url ? new URL(item.url, 'http://localhost').hostname : undefined),
          description: item.metadata?.description || item.text_content?.slice(0, 150) || undefined,
          created_at: item.created_at,
          note: item.note?.content?.slice(0, 100) || undefined,
          collections: (item.collections || []).map((c) => c.name),
        }));

        const res = await fetch('/api/ai/search', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session?.access_token || ''}`,
          },
          body: JSON.stringify({
            query: trimmed,
            items: candidatePayload,
            referenceDate: new Date().toISOString(),
          }),
        });

        if (res.ok) {
          const data = (await res.json()) as any;
          if (data.success) {
            setAiResult({
              summary: data.summary,
              model: data.model || 'Gemini 3.5 Flash',
              rankedItemIds: data.rankedItemIds || [],
              explanations: data.explanations || {},
              parsedFilters: data.parsedFilters,
            });
          } else {
            setAiResult(null);
          }
        } else {
          setAiResult(null);
        }
      } catch (err) {
        console.warn('[AI Search] Failed to reach Gemini search endpoint:', err);
        setAiResult(null);
      } finally {
        setAiLoading(false);
      }
    }, 450);

    return () => {
      if (debounceTimerRef.current) clearTimeout(debounceTimerRef.current);
    };
  }, [query, isPro, aiEnabled, items, session?.access_token]);

  // Final sorted list combining AI ranking (if available) with local ranking
  const finalFilteredItems = useMemo(() => {
    if (!aiResult || aiResult.rankedItemIds.length === 0) {
      return localRanked.map((r) => r.item);
    }

    // Map items ordered by Gemini's rank
    const idToItemMap = new Map(items.map((it) => [it.id, it]));
    const aiOrdered: typeof items = [];
    const seenIds = new Set<string>();

    for (const id of aiResult.rankedItemIds) {
      const it = idToItemMap.get(id);
      if (it && !seenIds.has(id)) {
        aiOrdered.push(it);
        seenIds.add(id);
      }
    }

    // Append any locally ranked items not in Gemini's subset
    for (const r of localRanked) {
      if (!seenIds.has(r.item.id)) {
        aiOrdered.push(r.item);
        seenIds.add(r.item.id);
      }
    }

    return aiOrdered;
  }, [aiResult, localRanked, items]);

  const filterChips = [
    { id: 'all', label: `All (${items.length})`, icon: <Layers className="w-3.5 h-3.5" /> },
    { id: 'article', label: 'Articles', icon: <FileText className="w-3.5 h-3.5" /> },
    { id: 'video', label: 'Videos', icon: <PlayCircle className="w-3.5 h-3.5" /> },
    { id: 'music', label: 'Music', icon: <Music2 className="w-3.5 h-3.5" /> },
    { id: 'note', label: 'Notes', icon: <StickyNote className="w-3.5 h-3.5" /> },
    { id: 'file', label: 'Files', icon: <Folder className="w-3.5 h-3.5" /> },
  ];

  // Dynamically compute suggestions from user's actual items guaranteed to have results
  const suggestedQueries = useMemo(() => {
    return generateSuggestedQueries(items);
  }, [items]);

  return (
    <div className="max-w-6xl mx-auto p-6 sm:p-8 space-y-6">
      {/* Top Omnibar with Back, Gemini AI Status & Layout Mode */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-2 border-b border-[#e4e0d5]/60">
        <div className="flex items-center gap-3">
          <Link
            href="/home"
            className="w-9 h-9 rounded-full bg-white border border-[#e4e0d5] flex items-center justify-center text-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-colors cursor-pointer shrink-0"
            title="Back to Dashboard"
          >
            <ArrowLeft className="w-4 h-4" />
          </Link>
          <span className="text-xs font-bold text-[#6c6b63]">Search Engine</span>
        </div>

        <div className="flex items-center gap-2">
          {/* Later AI Status Indicator / Pro Upgrade Badge */}
          {isPro ? (
            <button
              type="button"
              onClick={() => setAiEnabled(!aiEnabled)}
              className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold transition-all cursor-pointer border ${
                aiEnabled
                  ? 'bg-[#e6edb0] border-[#d0db84] text-[#171711] shadow-2xs'
                  : 'bg-white border-[#e4e0d5] text-[#8e8d87] hover:text-[#171711]'
              }`}
              title="Toggle Later AI Semantic Search for ambiguous natural language queries"
            >
              <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
              <span>Later AI {aiEnabled ? 'On' : 'Off'}</span>
            </button>
          ) : (
            <Link
              href="/plans"
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white border border-[#e4e0d5] text-xs font-bold text-[#6c6b63] hover:text-[#171711] hover:border-[#171711] transition-all shadow-2xs"
              title="Upgrade to LaterBox Pro to activate Later AI Semantic Search"
            >
              <Sparkles className="w-3.5 h-3.5 text-[#bfa829]" />
              <span>Later AI • Pro</span>
            </Link>
          )}

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
      <div className="space-y-2 pt-1">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-bold shadow-2xs">
          <SearchIcon className="w-3.5 h-3.5 text-[#171711] shrink-0" />
          <span>Instant Offline Search</span>
          <span className="w-1 h-1 rounded-full bg-[#171711]/40" />
          <Database className="w-3.5 h-3.5 text-[#171711] shrink-0" />
          <span>100% Local SQLite Core</span>
        </div>
        <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711]">
          Deep Search
        </h1>
        <p className="text-xs sm:text-sm text-[#6c6b63] font-medium max-w-2xl leading-relaxed">
          Ask naturally (e.g. &ldquo;a cideo i saved in october&rdquo; or &ldquo;between May and August&rdquo;). Searches keywords, metadata, and vault notes with offline typo tolerance and Later AI reasoning.
        </p>
      </div>

      {/* Prominent Search Omnibar */}
      <div className="relative max-w-2xl">
        <SearchIcon className="w-5 h-5 text-[#9e9b92] absolute left-4 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          data-search-input="true"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Type to search... e.g. “a cideo i saved in october”, dates, keywords"
          autoFocus
          className="w-full pl-12 pr-12 py-3.5 text-sm bg-white border border-[#e4e0d5] rounded-2xl text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:border-[#171711] shadow-2xs transition-colors font-medium"
        />
        {query && (
          <button
            onClick={() => {
              setQuery('');
              setAiResult(null);
            }}
            className="absolute right-4 top-1/2 -translate-y-1/2 p-1 text-[#9e9b92] hover:text-[#171711] rounded-full cursor-pointer transition-colors"
            title="Clear search"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Ambiguous Intent & AI Insights Banner */}
      {query.trim().length > 0 && (parsed.hasAmbiguousFilters || aiResult || aiLoading) && (
        <div className="rounded-2xl border border-[#d0db84] bg-[#fbffdc] p-4 text-xs space-y-2 shadow-2xs">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-2 text-[#444a10] font-bold">
              {aiLoading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin text-[#88961c]" />
                  <span>Searching with Later AI...</span>
                </>
              ) : aiResult ? (
                <>
                  <Sparkles className="w-4 h-4 text-[#88961c]" />
                  <span>{aiResult.summary}</span>
                </>
              ) : (
                <>
                  <Sparkles className="w-4 h-4 text-[#88961c]" />
                  <span>{parsed.explanation}</span>
                </>
              )}
            </div>

            {!isPro && (
              <span className="text-[10px] font-bold text-[#737e1b] bg-white/70 px-2 py-0.5 rounded-md border border-[#d0db84]/60">
                Local Ambiguous Engine
              </span>
            )}
          </div>

          {/* Parsed Criteria Breakdown Chips */}
          <div className="flex items-center gap-1.5 flex-wrap pt-1 border-t border-[#d0db84]/40">
            <span className="text-[10px] font-black uppercase tracking-wider text-[#687216]">
              Extracted Filters:
            </span>
            {parsed.contentType && (
              <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-white text-[#171711] text-[11px] font-bold border border-[#d0db84] shadow-2xs">
                Format: {parsed.contentType.toUpperCase()}
              </span>
            )}
            {parsed.dateRange && (
              <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-white text-[#171711] text-[11px] font-bold border border-[#d0db84] shadow-2xs">
                <Calendar className="w-3 h-3 text-[#687216]" />
                {parsed.dateRange.label}
              </span>
            )}
            {parsed.cleanedKeywords && (
              <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-white text-[#171711] text-[11px] font-bold border border-[#d0db84] shadow-2xs">
                Keyword: &ldquo;{parsed.cleanedKeywords}&rdquo;
              </span>
            )}
          </div>
        </div>
      )}

      {/* Suggested Natural Language Search Queries (Guaranteed Results) */}
      {suggestedQueries.length > 0 && (
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-[11px] font-bold text-[#9e9b92] uppercase tracking-wider">
            Suggested:
          </span>
          {suggestedQueries.map((suggested) => (
            <button
              key={suggested}
              type="button"
              onClick={() => setQuery(suggested)}
              className="px-2.5 py-1 rounded-lg bg-white border border-[#e4e0d5] text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] hover:border-[#171711] transition-all cursor-pointer shadow-2xs"
            >
              {suggested}
            </button>
          ))}
        </div>
      )}

      {/* Content Type Filter Chips */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none pt-1">
        {filterChips.map((chip) => {
          const active = typeFilter === chip.id;
          return (
            <button
              key={chip.id}
              onClick={() => setTypeFilter(chip.id)}
              className={`inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer ${
                active
                  ? 'bg-[#e6edb0] border border-[#d0db84] text-[#171711] shadow-2xs'
                  : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:bg-[#faf8f5] hover:text-[#171711]'
              }`}
            >
              {chip.icon}
              <span>{chip.label}</span>
            </button>
          );
        })}
      </div>

      {/* Results Header */}
      <div className="flex items-center justify-between text-xs font-bold text-[#9e9b92] uppercase tracking-wider pt-2">
        <span>
          {finalFilteredItems.length} {finalFilteredItems.length === 1 ? 'Result' : 'Results'} Found
          {query ? ` for “${query}”` : ''}
        </span>
      </div>

      {/* Results Grid / List */}
      {finalFilteredItems.length === 0 ? (
        <div className="text-center py-20 px-4 rounded-3xl bg-white border border-dashed border-[#e4e0d5] space-y-3">
          <div className="w-12 h-12 mx-auto rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
            <SearchIcon className="w-6 h-6" />
          </div>
          <h3 className="text-base font-extrabold text-[#171711]">
            No results found
          </h3>
          <p className="text-xs text-[#6c6b63] max-w-sm mx-auto leading-relaxed">
            We couldn’t find any saved items matching &ldquo;{query}&rdquo;. Try asking with different wording, a broader date range, or resetting filters.
          </p>
          {query && (
            <div className="pt-2">
              <button
                type="button"
                onClick={() => {
                  setQuery('');
                  setTypeFilter('all');
                  setAiResult(null);
                }}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#171711] text-white text-xs font-bold shadow-xs hover:bg-[#282723] transition-all cursor-pointer"
              >
                <span>Reset Search</span>
              </button>
            </div>
          )}
        </div>
      ) : layoutMode === 'grid' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {finalFilteredItems.map((item) => (
            <ItemCard key={item.id} item={item} />
          ))}
        </div>
      ) : (
        <div className="space-y-3">
          {finalFilteredItems.map((item) => (
            <ItemListRow key={item.id} item={item} />
          ))}
        </div>
      )}
    </div>
  );
}
