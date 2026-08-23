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
  Paperclip,
  FileSpreadsheet,
  FileCode,
  File,
  Image as ImageIcon,
} from 'lucide-react';

interface ItemCardProps {
  item: LaterBoxItem;
}

function formatBytes(bytes?: number): string {
  if (!bytes) return '0 B';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function getFileIcon(filename: string, mime?: string) {
  const ext = filename.split('.').lastItem || filename.split('.').pop()?.toLowerCase() || '';
  if (mime?.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'svg'].includes(ext)) {
    return <ImageIcon className="w-3.5 h-3.5 text-blue-600" />;
  }
  if (mime?.startsWith('video/') || ['mp4', 'mov', 'mkv', 'webm'].includes(ext)) {
    return <PlayCircle className="w-3.5 h-3.5 text-rose-600" />;
  }
  if (mime?.startsWith('audio/') || ['mp3', 'm4a', 'wav', 'aac'].includes(ext)) {
    return <Music2 className="w-3.5 h-3.5 text-emerald-600" />;
  }
  if (['xls', 'xlsx', 'csv'].includes(ext)) {
    return <FileSpreadsheet className="w-3.5 h-3.5 text-green-600" />;
  }
  if (['js', 'ts', 'jsx', 'tsx', 'html', 'css', 'json', 'py', 'dart'].includes(ext)) {
    return <FileCode className="w-3.5 h-3.5 text-purple-600" />;
  }
  if (ext === 'pdf') {
    return <FileText className="w-3.5 h-3.5 text-red-600" />;
  }
  return <File className="w-3.5 h-3.5 text-[#6c6b63]" />;
}

export function ItemCard({ item }: ItemCardProps) {
  const { setFavorite, keepItem, archiveItem, markUnseen, deleteItem } = useItems();
  const [menuOpen, setMenuOpen] = useState(false);
  const [imgError, setImgError] = useState(false);

  const attachments = item.attachments || [];
  const hasAttachments = attachments.length > 0;

  const domain = extractDomain(item.url) || item.metadata?.domain || (item.url ? 'link' : null);
  const title = item.metadata?.title || item.title || (hasAttachments ? attachments[0].original_file_name : null) || domain || 'Saved Item';
  const description = item.metadata?.description || item.text_content;
  const timeAgo = formatTimeAgo(item.created_at);
  const previewImage = item.metadata?.preview_image_url;
  const contentType = item.metadata?.content_type || (hasAttachments ? 'file' : item.url ? 'link' : 'note');

  const destinationUrl = item.url
    ? buildTextFragmentUrl(item.url, item.text_content, item.text_selector ? JSON.parse(item.text_selector).before : null)
    : `/item/${item.id}`;

  const renderBadge = () => {
    if (hasAttachments) {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#e0f2fe] text-[#0369a1]">
          <Paperclip className="w-3 h-3" /> {attachments.length === 1 ? '1 File' : `${attachments.length} Files`}
        </span>
      );
    }

    switch (contentType) {
      case 'video':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#fee2e2] text-[#b91c1c]">
            <PlayCircle className="w-3 h-3" /> Video
          </span>
        );
      case 'music':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#ecfdf5] text-[#047857]">
            <Music2 className="w-3 h-3" /> Music
          </span>
        );
      case 'article':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#e6edb0] text-[#171711]">
            <FileText className="w-3 h-3" /> Article
          </span>
        );
      case 'note':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#fef3c7] text-[#b45309]">
            <StickyNote className="w-3 h-3" /> Note
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#ebe7dc] text-[#6c6b63]">
            <Link2 className="w-3 h-3" /> Link
          </span>
        );
    }
  };

  return (
    <div className="group relative flex flex-col justify-between rounded-3xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-md transition-all duration-200 overflow-hidden">
      {/* Top Media Preview */}
      {previewImage && !imgError && (
        <Link href={`/item/${item.id}`} className="relative w-full aspect-video overflow-hidden bg-[#ebe7dc]/50 block">
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
                <span className="text-xs font-semibold text-[#6c6b63] truncate">
                  {domain}
                </span>
              )}
            </div>
            {renderBadge()}
          </div>

          {/* Title */}
          <Link href={`/item/${item.id}`} className="block group-hover:text-[#171711] transition-colors">
            <h3 className="text-base font-extrabold text-[#171711] line-clamp-2 leading-snug tracking-tight mb-1.5">
              {title}
            </h3>
          </Link>

          {/* Description / Text Content */}
          {description && (
            <p className="text-xs text-[#6c6b63] line-clamp-2 leading-relaxed mb-3">
              {description}
            </p>
          )}

          {/* Highlighted Quote Indicator */}
          {item.url && item.text_content && (
            <div className="flex items-center gap-1.5 p-2 rounded-xl bg-[#fef3c7]/60 text-[#b45309] text-[11px] font-medium mb-3 border border-[#fde68a]">
              <Quote className="w-3.5 h-3.5 shrink-0" />
              <span className="truncate italic">&ldquo;{item.text_content}&rdquo;</span>
            </div>
          )}

          {/* Attached Files Chips */}
          {hasAttachments && (
            <div className="flex flex-wrap gap-1.5 mb-3">
              {attachments.map((att) => (
                <Link
                  key={att.id}
                  href={`/item/${item.id}`}
                  className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl bg-[#ebe7dc]/60 hover:bg-[#e0dbc9] border border-[#e4e0d5] text-[11px] font-semibold text-[#171711] max-w-full transition-colors"
                >
                  {getFileIcon(att.original_file_name, att.mime_type)}
                  <span className="truncate max-w-[140px]">{att.original_file_name}</span>
                  <span className="text-[10px] text-[#6c6b63] shrink-0">
                    ({formatBytes(att.byte_size)})
                  </span>
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Card Footer Actions */}
        <div className="pt-3 mt-3 border-t border-[#e4e0d5]/70 flex items-center justify-between">
          <span className="text-[11px] font-medium text-[#9e9b92]">
            {timeAgo}
          </span>

          <div className="flex items-center gap-1">
            {/* Star Button */}
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

            {/* Status Change Buttons */}
            {item.status === 'inbox' ? (
              <button
                onClick={() => keepItem(item.id)}
                title="Mark as Kept"
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#e6edb0] transition-colors cursor-pointer"
              >
                <CheckCircle className="w-4 h-4" />
              </button>
            ) : item.status === 'saved' ? (
              <button
                onClick={() => archiveItem(item.id)}
                title="Archive"
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <Archive className="w-4 h-4" />
              </button>
            ) : (
              <button
                onClick={() => markUnseen(item.id)}
                title="Move back to Inbox"
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#e6edb0] transition-colors cursor-pointer"
              >
                <CheckCircle className="w-4 h-4 text-[#171711]" />
              </button>
            )}

            {/* External URL Link */}
            {item.url && (
              <a
                href={destinationUrl}
                target="_blank"
                rel="noreferrer"
                title="Open Source Link"
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
              >
                <ExternalLink className="w-4 h-4" />
              </a>
            )}

            {/* Dropdown Menu */}
            <div className="relative">
              <button
                onClick={() => setMenuOpen(!menuOpen)}
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <MoreVertical className="w-4 h-4" />
              </button>

              {menuOpen && (
                <>
                  <div
                    className="fixed inset-0 z-10"
                    onClick={() => setMenuOpen(false)}
                  />
                  <div className="absolute right-0 bottom-full mb-1 z-20 w-44 rounded-2xl bg-white border border-[#e4e0d5] shadow-lg py-1.5 text-xs font-semibold">
                    <Link
                      href={`/item/${item.id}`}
                      className="flex items-center gap-2 px-3.5 py-2 text-[#171711] hover:bg-[#ebe7dc]/50 transition-colors"
                    >
                      <FileText className="w-3.5 h-3.5" />
                      <span>View details</span>
                    </Link>
                    <button
                      onClick={() => {
                        setMenuOpen(false);
                        if (confirm('Delete this item?')) {
                          deleteItem(item.id);
                        }
                      }}
                      className="w-full flex items-center gap-2 px-3.5 py-2 text-red-600 hover:bg-red-50 transition-colors text-left cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>Delete</span>
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
