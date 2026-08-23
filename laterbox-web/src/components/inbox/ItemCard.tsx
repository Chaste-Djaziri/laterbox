'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LaterBoxItem, Attachment } from '@/lib/supabase/types';
import { useItems } from '@/lib/store/ItemContext';
import { formatTimeAgo, extractDomain, buildTextFragmentUrl } from '@/lib/utils/url';
import { fetchAttachmentDownloadUrl } from '@/lib/utils/attachment';
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

function getFileCategory(filename: string, mime?: string): 'image' | 'pdf' | 'video' | 'audio' | 'spreadsheet' | 'code' | 'file' {
  const ext = filename.split('.').pop()?.toLowerCase() || '';
  if (mime?.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'svg'].includes(ext)) {
    return 'image';
  }
  if (ext === 'pdf' || mime === 'application/pdf') {
    return 'pdf';
  }
  if (mime?.startsWith('video/') || ['mp4', 'mov', 'mkv', 'webm'].includes(ext)) {
    return 'video';
  }
  if (mime?.startsWith('audio/') || ['mp3', 'm4a', 'wav', 'aac', 'ogg'].includes(ext)) {
    return 'audio';
  }
  if (['xls', 'xlsx', 'csv'].includes(ext)) {
    return 'spreadsheet';
  }
  if (['js', 'ts', 'jsx', 'tsx', 'html', 'css', 'json', 'py', 'dart', 'rs', 'go', 'cpp', 'c', 'sh', 'md', 'txt'].includes(ext)) {
    return 'code';
  }
  return 'file';
}

function AttachmentMediaPreview({
  attachment,
  title,
  extraCount,
}: {
  attachment: Attachment;
  title: string;
  extraCount: number;
}) {
  const [downloadUrl, setDownloadUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState(false);

  const category = getFileCategory(attachment.original_file_name, attachment.mime_type);
  const formattedSize = formatBytes(attachment.byte_size);

  useEffect(() => {
    let active = true;

    if (attachment.local_path?.startsWith('data:') || attachment.local_path?.startsWith('http')) {
      setDownloadUrl(attachment.local_path);
      setLoading(false);
      return;
    }

    fetchAttachmentDownloadUrl(attachment.id).then((url) => {
      if (active) {
        setDownloadUrl(url);
        setLoading(false);
      }
    });

    return () => {
      active = false;
    };
  }, [attachment.id, attachment.local_path]);

  // Render Image Preview
  if (category === 'image') {
    if (downloadUrl && !loadError) {
      return (
        <div className="relative w-full aspect-video overflow-hidden bg-[#ebe7dc]/50 block group">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={downloadUrl}
            alt={title}
            onError={() => setLoadError(true)}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
          {extraCount > 0 && (
            <div className="absolute bottom-2.5 right-2.5 px-2 py-0.5 rounded-full bg-[#171711]/80 backdrop-blur-xs text-white text-[10px] font-extrabold shadow-xs">
              +{extraCount} more
            </div>
          )}
        </div>
      );
    }

    return (
      <div className="relative w-full aspect-video bg-gradient-to-br from-[#f0f9ff] via-[#e0f2fe] to-[#bae6fd] border-b border-[#7dd3fc]/30 flex flex-col items-center justify-center p-4 text-center overflow-hidden group">
        <div className="relative w-24 h-16 bg-white rounded-xl shadow-md border border-[#7dd3fc]/40 flex flex-col items-center justify-center p-2 transition-transform duration-300 group-hover:scale-105">
          <ImageIcon className="w-6 h-6 text-[#0284c7] mb-1" />
          <span className="text-[9px] font-bold text-[#171711] truncate max-w-[70px]">
            {attachment.original_file_name}
          </span>
        </div>
        <div className="mt-2 flex items-center gap-1.5">
          <span className="px-2.5 py-0.5 rounded-full bg-white/80 backdrop-blur-xs text-[10px] font-extrabold text-[#0369a1] border border-[#7dd3fc]/50">
            {loading ? 'Loading image…' : `Image • ${formattedSize}`}
          </span>
          {extraCount > 0 && (
            <span className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-extrabold">
              +{extraCount} more
            </span>
          )}
        </div>
      </div>
    );
  }

  // Render PDF Preview
  if (category === 'pdf') {
    if (downloadUrl && !loadError) {
      return (
        <div className="relative w-full aspect-video overflow-hidden bg-[#fef2f2] border-b border-[#fca5a5]/30 group">
          <object
            data={`${downloadUrl}#toolbar=0&navpanes=0&scrollbar=0&view=FitH`}
            type="application/pdf"
            className="w-full h-full pointer-events-none border-0 overflow-hidden"
          >
            <div className="w-full h-full flex flex-col items-center justify-center p-4">
              <FileText className="w-8 h-8 text-[#ef4444] mb-1" />
              <span className="text-xs font-bold text-[#991b1b]">{attachment.original_file_name}</span>
            </div>
          </object>
          {/* Overlay to ensure card is cleanly clickable */}
          <div className="absolute inset-0 bg-transparent" />
          <div className="absolute top-2.5 left-2.5 px-2 py-0.5 rounded-md bg-[#ef4444] text-white text-[9px] font-black tracking-wider shadow-xs">
            PDF
          </div>
          {extraCount > 0 && (
            <div className="absolute bottom-2.5 right-2.5 px-2 py-0.5 rounded-full bg-[#171711]/80 backdrop-blur-xs text-white text-[10px] font-extrabold shadow-xs">
              +{extraCount} more
            </div>
          )}
        </div>
      );
    }

    return (
      <div className="relative w-full aspect-video bg-gradient-to-br from-[#fef2f2] via-[#fee2e2] to-[#fecaca] border-b border-[#fca5a5]/30 flex flex-col items-center justify-center p-4 text-center overflow-hidden group">
        <div className="relative w-28 h-20 bg-white rounded-xl shadow-md border border-[#fca5a5]/40 flex flex-col items-center justify-center p-2 transition-transform duration-300 group-hover:scale-105">
          <div className="absolute top-1.5 right-1.5 px-1.5 py-0.5 rounded-md bg-[#ef4444] text-white text-[9px] font-black tracking-wider">
            PDF
          </div>
          <FileText className="w-7 h-7 text-[#ef4444] mb-1" />
          <span className="text-[10px] font-bold text-[#171711] truncate max-w-[80px]">
            {attachment.original_file_name}
          </span>
        </div>
        <div className="mt-2.5 flex items-center gap-1.5">
          <span className="px-2.5 py-0.5 rounded-full bg-white/80 backdrop-blur-xs text-[11px] font-extrabold text-[#991b1b] border border-[#fca5a5]/50">
            {loading ? 'Loading PDF…' : `PDF • ${formattedSize}`}
          </span>
          {extraCount > 0 && (
            <span className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-extrabold">
              +{extraCount} more
            </span>
          )}
        </div>
      </div>
    );
  }

  // Render Video Preview
  if (category === 'video') {
    if (downloadUrl && !loadError) {
      return (
        <div className="relative w-full aspect-video overflow-hidden bg-black block group">
          <video
            src={downloadUrl}
            preload="metadata"
            muted
            playsInline
            className="w-full h-full object-cover pointer-events-none"
          />
          <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
            <div className="w-11 h-11 rounded-full bg-white/90 backdrop-blur-xs flex items-center justify-center shadow-lg transition-transform duration-300 group-hover:scale-110">
              <PlayCircle className="w-7 h-7 text-[#e11d48]" />
            </div>
          </div>
          {extraCount > 0 && (
            <div className="absolute bottom-2.5 right-2.5 px-2 py-0.5 rounded-full bg-[#171711]/80 backdrop-blur-xs text-white text-[10px] font-extrabold shadow-xs">
              +{extraCount} more
            </div>
          )}
        </div>
      );
    }

    return (
      <div className="relative w-full aspect-video bg-gradient-to-br from-[#fff1f2] via-[#ffe4e6] to-[#fecdd3] border-b border-[#fda4af]/30 flex flex-col items-center justify-center p-4 text-center overflow-hidden group">
        <div className="w-12 h-12 rounded-2xl bg-white shadow-md border border-[#fda4af]/40 flex items-center justify-center transition-transform duration-300 group-hover:scale-110">
          <PlayCircle className="w-7 h-7 text-[#e11d48]" />
        </div>
        <div className="mt-2.5 flex items-center gap-1.5">
          <span className="px-2.5 py-0.5 rounded-full bg-white/80 backdrop-blur-xs text-[11px] font-extrabold text-[#be123c] border border-[#fda4af]/50">
            Video • {formattedSize}
          </span>
          {extraCount > 0 && (
            <span className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-extrabold">
              +{extraCount} more
            </span>
          )}
        </div>
      </div>
    );
  }

  // Render Audio Preview
  if (category === 'audio') {
    return (
      <div className="relative w-full aspect-video bg-gradient-to-br from-[#ecfdf5] via-[#d1fae5] to-[#a7f3d0] border-b border-[#6ee7b7]/30 flex flex-col items-center justify-center p-4 text-center overflow-hidden group">
        <div className="w-12 h-12 rounded-2xl bg-white shadow-md border border-[#6ee7b7]/40 flex items-center justify-center transition-transform duration-300 group-hover:scale-110">
          <Music2 className="w-7 h-7 text-[#059669]" />
        </div>
        <div className="mt-2.5 flex items-center gap-1.5">
          <span className="px-2.5 py-0.5 rounded-full bg-white/80 backdrop-blur-xs text-[11px] font-extrabold text-[#047857] border border-[#6ee7b7]/50">
            Audio • {formattedSize}
          </span>
          {extraCount > 0 && (
            <span className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-extrabold">
              +{extraCount} more
            </span>
          )}
        </div>
      </div>
    );
  }

  // Render Spreadsheet Preview
  if (category === 'spreadsheet') {
    return (
      <div className="relative w-full aspect-video bg-gradient-to-br from-[#f0fdf4] via-[#dcfce7] to-[#bbf7d0] border-b border-[#86efac]/30 flex flex-col items-center justify-center p-4 text-center overflow-hidden group">
        <div className="relative w-28 h-20 bg-white rounded-xl shadow-md border border-[#86efac]/40 flex flex-col items-center justify-center p-2 transition-transform duration-300 group-hover:scale-105">
          <FileSpreadsheet className="w-8 h-8 text-[#16a34a] mb-1" />
          <span className="text-[10px] font-bold text-[#171711] truncate max-w-[80px]">
            {attachment.original_file_name}
          </span>
        </div>
        <div className="mt-2.5 flex items-center gap-1.5">
          <span className="px-2.5 py-0.5 rounded-full bg-white/80 backdrop-blur-xs text-[11px] font-extrabold text-[#15803d] border border-[#86efac]/50">
            Spreadsheet • {formattedSize}
          </span>
          {extraCount > 0 && (
            <span className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-extrabold">
              +{extraCount} more
            </span>
          )}
        </div>
      </div>
    );
  }

  // Render Code / Document
  if (category === 'code') {
    return (
      <div className="relative w-full aspect-video bg-gradient-to-br from-[#faf5ff] via-[#f3e8ff] to-[#e9d5ff] border-b border-[#d8b4fe]/30 flex flex-col items-center justify-center p-4 text-center overflow-hidden group">
        <div className="relative w-28 h-20 bg-[#1e1e1e] text-white rounded-xl shadow-md border border-[#d8b4fe]/40 flex flex-col items-center justify-center p-2 transition-transform duration-300 group-hover:scale-105">
          <FileCode className="w-8 h-8 text-[#c084fc] mb-1" />
          <span className="text-[10px] font-mono text-white/90 truncate max-w-[80px]">
            {attachment.original_file_name}
          </span>
        </div>
        <div className="mt-2.5 flex items-center gap-1.5">
          <span className="px-2.5 py-0.5 rounded-full bg-white/80 backdrop-blur-xs text-[11px] font-extrabold text-[#7e22ce] border border-[#d8b4fe]/50">
            {attachment.file_extension.toUpperCase()} Document • {formattedSize}
          </span>
          {extraCount > 0 && (
            <span className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-extrabold">
              +{extraCount} more
            </span>
          )}
        </div>
      </div>
    );
  }

  // Fallback General File
  return (
    <div className="relative w-full aspect-video bg-gradient-to-br from-[#f5f5f4] via-[#e7e5e4] to-[#d6d3d1] border-b border-[#e4e0d5] flex flex-col items-center justify-center p-4 text-center overflow-hidden group">
      <div className="w-12 h-12 rounded-2xl bg-white shadow-md border border-[#e4e0d5] flex items-center justify-center transition-transform duration-300 group-hover:scale-110">
        <File className="w-7 h-7 text-[#57534e]" />
      </div>
      <div className="mt-2.5 flex items-center gap-1.5">
        <span className="px-2.5 py-0.5 rounded-full bg-white/80 backdrop-blur-xs text-[11px] font-extrabold text-[#44403c] border border-[#e4e0d5]">
          {attachment.file_extension.toUpperCase()} • {formattedSize}
        </span>
        {extraCount > 0 && (
          <span className="px-2 py-0.5 rounded-full bg-[#171711] text-white text-[10px] font-extrabold">
            +{extraCount} more
          </span>
        )}
      </div>
    </div>
  );
}

export function ItemCard({ item }: ItemCardProps) {
  const router = useRouter();
  const { setFavorite, keepItem, archiveItem, markUnseen, deleteItem } = useItems();
  const [menuOpen, setMenuOpen] = useState(false);
  const [imgError, setImgError] = useState(false);

  const attachments = item.attachments || [];
  const hasAttachments = attachments.length > 0;
  const primaryAttachment = hasAttachments ? attachments[0] : null;

  const domain = extractDomain(item.url) || item.metadata?.domain || (item.url ? 'link' : null);
  const title = item.metadata?.title || item.title || (primaryAttachment ? primaryAttachment.original_file_name : null) || domain || 'Saved Item';
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

  const handleCardClick = () => {
    router.push(`/item/${item.id}`);
  };

  return (
    <div
      onClick={handleCardClick}
      className="group relative flex flex-col justify-between rounded-3xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-md transition-all duration-200 overflow-hidden cursor-pointer"
    >
      {/* Top Media Preview: OG Preview Image OR Live Attachment Media Preview */}
      {previewImage && !imgError ? (
        <div className="relative w-full aspect-video overflow-hidden bg-[#ebe7dc]/50 block">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={previewImage}
            alt={title}
            onError={() => setImgError(true)}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        </div>
      ) : primaryAttachment ? (
        <AttachmentMediaPreview
          attachment={primaryAttachment}
          title={title}
          extraCount={attachments.length - 1}
        />
      ) : null}

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
                  className="w-4 h-4 rounded-xs shrink-0 object-contain"
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
          <h3 className="text-base font-extrabold text-[#171711] group-hover:text-black line-clamp-2 leading-snug tracking-tight mb-1.5 transition-colors">
            {title}
          </h3>

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
        </div>

        {/* Card Footer Actions */}
        <div className="pt-3 mt-3 border-t border-[#e4e0d5]/70 flex items-center justify-between">
          <span className="text-[11px] font-medium text-[#9e9b92]">
            {timeAgo}
          </span>

          <div
            className="flex items-center gap-1"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Star Button */}
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

            {/* Status Change Buttons */}
            {item.status === 'inbox' ? (
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
            ) : item.status === 'saved' ? (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  archiveItem(item.id);
                }}
                title="Archive"
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <Archive className="w-4 h-4" />
              </button>
            ) : (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  markUnseen(item.id);
                }}
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
                onClick={(e) => e.stopPropagation()}
                title="Open Source Link"
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
              >
                <ExternalLink className="w-4 h-4" />
              </a>
            )}

            {/* Dropdown Menu */}
            <div className="relative">
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setMenuOpen(!menuOpen);
                }}
                className="p-1.5 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <MoreVertical className="w-4 h-4" />
              </button>

              {menuOpen && (
                <>
                  <div
                    className="fixed inset-0 z-10"
                    onClick={(e) => {
                      e.stopPropagation();
                      setMenuOpen(false);
                    }}
                  />
                  <div
                    className="absolute right-0 bottom-full mb-1 z-20 w-44 rounded-2xl bg-white border border-[#e4e0d5] shadow-lg py-1.5 text-xs font-semibold"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <button
                      onClick={() => {
                        setMenuOpen(false);
                        router.push(`/item/${item.id}`);
                      }}
                      className="w-full flex items-center gap-2 px-3.5 py-2 text-[#171711] hover:bg-[#ebe7dc]/50 transition-colors text-left cursor-pointer"
                    >
                      <FileText className="w-3.5 h-3.5" />
                      <span>View details</span>
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
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
