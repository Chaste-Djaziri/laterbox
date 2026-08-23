'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { LaterBoxItem } from '@/lib/supabase/types';
import { useItems } from '@/lib/store/ItemContext';
import { formatTimeAgo, extractDomain, buildTextFragmentUrl } from '@/lib/utils/url';
import {
  Star,
  CheckCircle,
  Archive,
  MoreVertical,
  ExternalLink,
  Trash2,
  FileText,
  PlayCircle,
  Music2,
  StickyNote,
  Link2,
  Quote,
} from 'lucide-react';

interface ItemCardProps {
  item: LaterBoxItem;
}

export function ItemCard({ item }: ItemCardProps) {
  const { setFavorite, keepItem, archiveItem, markUnseen, deleteItem } = useItems();
  const [menuOpen, setMenuOpen] = useState(false);
  const [imgError, setImgError] = useState(false);

  const domain = extractDomain(item.url) || item.metadata?.domain || (item.url ? 'link' : null);
  const title = item.metadata?.title || item.title || domain || 'Saved Item';
  const description = item.metadata?.description || item.text_content;
  const timeAgo = formatTimeAgo(item.created_at);
  const previewImage = item.metadata?.preview_image_url;
  const contentType = item.metadata?.content_type || (item.url ? 'link' : 'note');

  const destinationUrl = item.url
    ? buildTextFragmentUrl(item.url, item.text_content, item.text_selector ? JSON.parse(item.text_selector).before : null)
    : `/item/${item.id}`;

  const renderBadge = () => {
    switch (contentType) {
      case 'video':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-red-50 text-red-600 dark:bg-red-950/60 dark:text-red-400">
            <PlayCircle className="w-3 h-3" /> Video
          </span>
        );
      case 'music':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-emerald-50 text-emerald-600 dark:bg-emerald-950/60 dark:text-emerald-400">
            <Music2 className="w-3 h-3" /> Music
          </span>
        );
      case 'article':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-blue-50 text-blue-600 dark:bg-blue-950/60 dark:text-blue-400">
            <FileText className="w-3 h-3" /> Article
          </span>
        );
      case 'note':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-amber-50 text-amber-600 dark:bg-amber-950/60 dark:text-amber-400">
            <StickyNote className="w-3 h-3" /> Note
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-400">
            <Link2 className="w-3 h-3" /> Link
          </span>
        );
    }
  };

  return (
    <div className="group relative flex flex-col justify-between rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800/80 hover:border-emerald-500/40 dark:hover:border-emerald-500/40 hover:shadow-xl dark:hover:shadow-emerald-950/10 transition-all duration-300 overflow-hidden">
      {/* Top Media Preview */}
      {previewImage && !imgError && (
        <Link href={`/item/${item.id}`} className="relative w-full aspect-video overflow-hidden bg-zinc-100 dark:bg-zinc-950 block">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={previewImage}
            alt={title}
            onError={() => setImgError(true)}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        </Link>
      )}

      {/* Card Body */}
      <div className="p-5 flex-1 flex flex-col justify-between">
        <div>
          {/* Domain & Badge Row */}
          <div className="flex items-center justify-between gap-2 mb-2.5">
            <div className="flex items-center gap-2 min-w-0">
              {item.metadata?.favicon_url ? (
                /* eslint-disable-next-line @next/next/no-img-element */
                <img
                  src={item.metadata.favicon_url}
                  alt=""
                  className="w-4 h-4 rounded-sm shrink-0 object-contain"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              ) : null}
              {domain && (
                <span className="text-xs font-semibold text-zinc-500 dark:text-zinc-400 truncate">
                  {domain}
                </span>
              )}
            </div>
            {renderBadge()}
          </div>

          {/* Title */}
          <Link href={`/item/${item.id}`} className="block group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">
            <h3 className="text-base font-extrabold text-zinc-900 dark:text-zinc-100 line-clamp-2 leading-snug tracking-tight mb-1.5">
              {title}
            </h3>
          </Link>

          {/* Description / Text Content */}
          {description && (
            <p className="text-xs text-zinc-500 dark:text-zinc-400 line-clamp-2 leading-relaxed mb-3">
              {description}
            </p>
          )}

          {/* Highlighted Quote Indicator */}
          {item.url && item.text_content && (
            <div className="flex items-center gap-1.5 p-2 rounded-xl bg-amber-50/70 dark:bg-amber-950/30 text-amber-800 dark:text-amber-300 text-[11px] font-medium mb-3 border border-amber-200/50 dark:border-amber-900/30">
              <Quote className="w-3.5 h-3.5 shrink-0" />
              <span className="truncate italic">"{item.text_content}"</span>
            </div>
          )}
        </div>

        {/* Card Footer Actions */}
        <div className="pt-3 mt-3 border-t border-zinc-100 dark:border-zinc-800/80 flex items-center justify-between">
          <span className="text-[11px] font-medium text-zinc-400 dark:text-zinc-500">
            {timeAgo}
          </span>

          <div className="flex items-center gap-1">
            {/* Star Button */}
            <button
              onClick={() => setFavorite(item.id, !item.favorite)}
              title={item.favorite ? 'Unstar' : 'Star'}
              className={`p-1.5 rounded-xl transition-colors ${
                item.favorite
                  ? 'text-amber-500 hover:bg-amber-50 dark:hover:bg-amber-950/50'
                  : 'text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800'
              }`}
            >
              <Star className={`w-4 h-4 ${item.favorite ? 'fill-amber-500' : ''}`} />
            </button>

            {/* Status Change (Mark Seen / Keep) */}
            {item.status === 'inbox' ? (
              <button
                onClick={() => keepItem(item.id)}
                title="Mark as Kept / Seen"
                className="p-1.5 rounded-xl text-zinc-400 hover:text-emerald-600 dark:hover:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 transition-colors"
              >
                <CheckCircle className="w-4 h-4" />
              </button>
            ) : item.status === 'saved' ? (
              <button
                onClick={() => archiveItem(item.id)}
                title="Archive"
                className="p-1.5 rounded-xl text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
              >
                <Archive className="w-4 h-4" />
              </button>
            ) : (
              <button
                onClick={() => markUnseen(item.id)}
                title="Move back to Inbox"
                className="p-1.5 rounded-xl text-zinc-400 hover:text-emerald-600 dark:hover:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/40 transition-colors"
              >
                <CheckCircle className="w-4 h-4 text-emerald-500" />
              </button>
            )}

            {/* External link */}
            {item.url && (
              <a
                href={destinationUrl}
                target="_blank"
                rel="noreferrer"
                title="Open Source Link"
                className="p-1.5 rounded-xl text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
              >
                <ExternalLink className="w-4 h-4" />
              </a>
            )}

            {/* Context Dropdown */}
            <div className="relative">
              <button
                onClick={() => setMenuOpen(!menuOpen)}
                className="p-1.5 rounded-xl text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors"
              >
                <MoreVertical className="w-4 h-4" />
              </button>

              {menuOpen && (
                <>
                  <div className="fixed inset-0 z-20" onClick={() => setMenuOpen(false)} />
                  <div className="absolute right-0 bottom-full mb-2 w-40 rounded-2xl bg-white dark:bg-zinc-900 shadow-xl border border-zinc-200 dark:border-zinc-800 py-1.5 z-30 animate-in fade-in zoom-in-95 duration-150">
                    <Link
                      href={`/item/${item.id}`}
                      className="w-full text-left px-3.5 py-2 text-xs font-semibold text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 block"
                      onClick={() => setMenuOpen(false)}
                    >
                      View Details & Notes
                    </Link>
                    <button
                      onClick={() => {
                        setMenuOpen(false);
                        deleteItem(item.id);
                      }}
                      className="w-full text-left px-3.5 py-2 text-xs font-semibold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/40 flex items-center gap-2"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      Delete Item
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
