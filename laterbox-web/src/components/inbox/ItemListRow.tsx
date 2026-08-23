'use client';

import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
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
  Paperclip,
} from 'lucide-react';

export function ItemListRow({ item }: { item: LaterBoxItem }) {
  const router = useRouter();
  const { setFavorite, keepItem, deleteItem } = useItems();

  const attachments = item.attachments || [];
  const hasAttachments = attachments.length > 0;

  const domain = extractDomain(item.url) || item.metadata?.domain;
  const title = item.metadata?.title || item.title || (hasAttachments ? attachments[0].original_file_name : null) || domain || 'Saved Item';
  const timeAgo = formatTimeAgo(item.created_at);
  const contentType = item.metadata?.content_type || (hasAttachments ? 'file' : item.url ? 'link' : 'note');

  const destinationUrl = item.url
    ? buildTextFragmentUrl(item.url, item.text_content, item.text_selector ? JSON.parse(item.text_selector).before : null)
    : `/item/${item.id}`;

  const renderIcon = () => {
    if (hasAttachments) {
      return <Paperclip className="w-5 h-5 text-[#0284c7] shrink-0" />;
    }
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

  const handleRowClick = () => {
    router.push(`/item/${item.id}`);
  };

  return (
    <div
      onClick={handleRowClick}
      className="group flex items-center justify-between gap-4 p-3.5 sm:p-4 rounded-2xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-xs transition-all cursor-pointer"
    >
      <div className="flex items-center gap-3.5 min-w-0 flex-1">
        {item.metadata?.favicon_url ? (
          /* eslint-disable-next-line @next/next/no-img-element */
          <img
            src={item.metadata.favicon_url}
            alt=""
            className="w-5 h-5 rounded-xs object-contain shrink-0"
            onError={(e) => {
              (e.target as HTMLElement).style.display = 'none';
            }}
          />
        ) : (
          renderIcon()
        )}

        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <h4 className="text-sm font-bold text-[#171711] group-hover:text-black truncate tracking-tight">
              {title}
            </h4>
            {hasAttachments && (
              <span className="inline-flex items-center gap-1 px-2 py-0.2 rounded-full text-[10px] font-bold bg-[#e0f2fe] text-[#0369a1] shrink-0">
                <Paperclip className="w-2.5 h-2.5" />
                <span>{attachments.length}</span>
              </span>
            )}
          </div>
          <div className="flex items-center gap-2 mt-0.5 text-xs text-[#9e9b92]">
            {domain && <span className="font-semibold text-[#6c6b63]">{domain}</span>}
            {domain && <span>•</span>}
            <span>{timeAgo}</span>
          </div>
        </div>
      </div>

      <div
        className="flex items-center gap-1 shrink-0"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={(e) => {
            e.stopPropagation();
            setFavorite(item.id, !item.favorite);
          }}
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
          onClick={(e) => {
            e.stopPropagation();
            keepItem(item.id);
          }}
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
            onClick={(e) => e.stopPropagation()}
            title="Open Link"
            className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
          >
            <ExternalLink className="w-4 h-4" />
          </a>
        )}

        <button
          onClick={(e) => {
            e.stopPropagation();
            deleteItem(item.id);
          }}
          title="Delete"
          className="p-1.5 rounded-xl text-[#9e9b92] hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
