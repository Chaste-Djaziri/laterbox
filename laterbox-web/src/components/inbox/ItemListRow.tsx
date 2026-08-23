'use client';

import React from 'react';
import Link from 'next/link';
import { LaterBoxItem } from '@/lib/supabase/types';
import { useItems } from '@/lib/store/ItemContext';
import { formatTimeAgo, extractDomain, buildTextFragmentUrl } from '@/lib/utils/url';
import {
  Star,
  CheckCircle,
  ExternalLink,
  Trash2,
  FileText,
  PlayCircle,
  Music2,
  StickyNote,
  Link2,
} from 'lucide-react';

export function ItemListRow({ item }: { item: LaterBoxItem }) {
  const { setFavorite, keepItem, deleteItem } = useItems();

  const domain = extractDomain(item.url) || item.metadata?.domain;
  const title = item.metadata?.title || item.title || domain || 'Saved Item';
  const timeAgo = formatTimeAgo(item.created_at);
  const contentType = item.metadata?.content_type || (item.url ? 'link' : 'note');

  const destinationUrl = item.url
    ? buildTextFragmentUrl(item.url, item.text_content, item.text_selector ? JSON.parse(item.text_selector).before : null)
    : `/item/${item.id}`;

  const renderIcon = () => {
    switch (contentType) {
      case 'video':
        return <PlayCircle className="w-5 h-5 text-red-500 shrink-0" />;
      case 'music':
        return <Music2 className="w-5 h-5 text-emerald-600 shrink-0" />;
      case 'article':
        return <FileText className="w-5 h-5 text-[#171711] shrink-0" />;
      case 'note':
        return <StickyNote className="w-5 h-5 text-amber-600 shrink-0" />;
      default:
        return <Link2 className="w-5 h-5 text-[#6c6b63] shrink-0" />;
    }
  };

  return (
    <div className="group flex items-center justify-between gap-4 p-3.5 sm:p-4 rounded-2xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-xs transition-all">
      <div className="flex items-center gap-3.5 min-w-0 flex-1">
        {item.metadata?.favicon_url ? (
          /* eslint-disable-next-line @next/next/no-img-element */
          <img
            src={item.metadata.favicon_url}
            alt=""
            className="w-5 h-5 rounded object-contain shrink-0"
            onError={(e) => {
              (e.target as HTMLElement).style.display = 'none';
            }}
          />
        ) : (
          renderIcon()
        )}

        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <Link
              href={`/item/${item.id}`}
              className="text-sm font-bold text-[#171711] hover:text-[#000000] truncate tracking-tight"
            >
              {title}
            </Link>
          </div>
          <div className="flex items-center gap-2 mt-0.5 text-xs text-[#9e9b92]">
            {domain && <span className="font-semibold text-[#6c6b63]">{domain}</span>}
            {domain && <span>•</span>}
            <span>{timeAgo}</span>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-1 shrink-0">
        <button
          onClick={() => setFavorite(item.id, !item.favorite)}
          title={item.favorite ? 'Unstar' : 'Star'}
          className={`p-1.5 rounded-xl transition-colors cursor-pointer ${
            item.favorite
              ? 'text-amber-500 hover:bg-amber-50'
              : 'text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60'
          }`}
        >
          <Star className={`w-4 h-4 ${item.favorite ? 'fill-amber-500' : ''}`} />
        </button>

        <button
          onClick={() => keepItem(item.id)}
          title="Mark as Kept"
          className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#e6edb0] transition-colors cursor-pointer"
        >
          <CheckCircle className="w-4 h-4" />
        </button>

        {item.url && (
          <a
            href={destinationUrl}
            target="_blank"
            rel="noreferrer"
            title="Open Link"
            className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
          >
            <ExternalLink className="w-4 h-4" />
          </a>
        )}

        <button
          onClick={() => deleteItem(item.id)}
          title="Delete"
          className="p-1.5 rounded-xl text-[#9e9b92] hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
