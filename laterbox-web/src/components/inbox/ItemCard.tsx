'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { LaterBoxItem } from '@/lib/supabase/types';
import { useItems } from '@/lib/store/ItemContext';
import { formatTimeAgo, extractDomain, buildTextFragmentUrl } from '@/lib/utils/url';
import {
  Star,
  Check,
  MoreVertical,
  ExternalLink,
  Trash2,
  FileText,
  Play,
  Music2,
  StickyNote,
  FolderPlus,
  Copy,
  CheckCircle,
  Archive,
  Inbox,
  Laptop,
  Globe,
} from 'lucide-react';
import { RescheduleAction } from '../scheduling/RescheduleAction';
import { AddToCollectionModal } from '../collections/AddToCollectionModal';

interface ItemCardProps {
  item: LaterBoxItem;
}

export function ItemCard({ item }: ItemCardProps) {
  const router = useRouter();
  const { setFavorite, keepItem, archiveItem, markUnseen, deleteItem } = useItems();
  const [menuOpen, setMenuOpen] = useState(false);
  const [imgError, setImgError] = useState(false);
  const [collectionModalOpen, setCollectionModalOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const attachments = item.attachments || [];
  const primaryAttachment = attachments.length > 0 ? attachments[0] : null;

  const domain = extractDomain(item.url) || item.metadata?.domain || (item.url ? 'link' : null);
  const title = item.metadata?.title || item.title || primaryAttachment?.original_file_name || domain || 'Saved Item';
  const description = item.metadata?.description || item.text_content || '';
  const timeAgo = formatTimeAgo(item.created_at);
  const previewImage = item.metadata?.preview_image_url;

  // Determine card format category
  const ext = (primaryAttachment?.file_extension || primaryAttachment?.original_file_name || title || '')
    .split('.')
    .pop()
    ?.toLowerCase() || '';

  const isPsd = ext === 'psd' || item.metadata?.content_type === 'design' || title.toLowerCase().endsWith('.psd');
  const isPdf = ext === 'pdf' || item.metadata?.content_type === 'document' || title.toLowerCase().endsWith('.pdf');
  const isVideo = item.type === 'video' || item.metadata?.content_type === 'video' || (item.url && item.url.includes('youtube.com'));
  const isMusic = item.type === 'music' || item.metadata?.content_type === 'music' || (item.url && item.url.includes('spotify.com'));
  const isNote = item.type === 'note' || item.metadata?.content_type === 'note' || (!item.url && !primaryAttachment && item.text_content);
  const isArticle = item.type === 'article' || item.metadata?.content_type === 'article' || (domain && (domain.includes('notion.so') || domain.includes('medium.com')));

  // Tags parsing
  let tags: string[] = [];
  if (item.metadata?.structured_data) {
    try {
      const data = typeof item.metadata.structured_data === 'string'
        ? JSON.parse(item.metadata.structured_data)
        : item.metadata.structured_data;
      if (Array.isArray(data?.tags)) tags = data.tags;
    } catch (_) {}
  }
  if (tags.length === 0) {
    if (isPsd) tags = ['design', 'inspiration', 'ui'];
    else if (isPdf) tags = ['feedback', 'client', 'product'];
    else if (isVideo) tags = ['cloudflare', 'supabase', 'development'];
    else if (isNote) tags = ['ideas', 'side project', 'notes'];
    else if (isMusic) tags = ['music', 'chill', 'r&b'];
    else if (isArticle) tags = ['productivity', 'focus', 'mindset'];
    else if (domain) tags = [domain.replace(/\.[a-z]+$/, '')];
  }

  const destinationUrl = item.url
    ? buildTextFragmentUrl(item.url, item.text_content, item.text_selector ? JSON.parse(item.text_selector).before : null)
    : `/item/${item.id}`;

  const handleCardClick = () => {
    router.push(`/item/${item.id}`);
  };

  const handleCopy = (e: React.MouseEvent) => {
    e.stopPropagation();
    const textToCopy = item.url || item.text_content || title;
    navigator.clipboard.writeText(textToCopy);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
    setMenuOpen(false);
  };

  return (
    <>
      <div
        onClick={handleCardClick}
        className="group relative flex flex-col justify-between rounded-[22px] bg-white border border-[#e4e0d5] hover:border-[#171711]/40 hover:shadow-md transition-all duration-200 overflow-hidden cursor-pointer"
      >
        {/* ========================================================================= */}
        {/* Visual Media Banner Formats */}
        {/* ========================================================================= */}

        {/* FORMAT 1: PSD / Design File */}
        {isPsd ? (
          <div className="relative w-full h-36 bg-gradient-to-tr from-[#1e1b4b] via-[#701a75] via-[#ec4899] to-[#84cc16] overflow-hidden flex items-center justify-center border-b border-[#f0ede4]">
            <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-black/20" />
            <div className="absolute top-2.5 right-2.5 px-2.5 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-semibold flex items-center gap-1 shadow-sm">
              <span className="w-1.5 h-1.5 rounded-full bg-white/70" />
              <span>Design File</span>
            </div>
            <div className="absolute bottom-2.5 left-2.5 w-7 h-7 rounded-lg bg-[#001e36] text-[#31a8ff] font-black text-xs flex items-center justify-center shadow-md border border-white/20">
              Ps
            </div>
          </div>
        ) : isPdf ? (
          /* FORMAT 2: PDF Document Simulated Sheet */
          <div className="relative w-full h-36 bg-[#f8f7f4] flex items-center justify-center overflow-hidden border-b border-[#f0ede4]">
            <div className="w-36 h-26 bg-white rounded-lg shadow-sm border border-[#e4e0d5] p-3 space-y-1.5 flex flex-col justify-center">
              <div className="h-1.5 bg-[#e4e0d5] rounded-full w-full" />
              <div className="h-1.5 bg-[#e4e0d5] rounded-full w-5/6" />
              <div className="h-1.5 bg-[#e4e0d5] rounded-full w-4/6" />
              <div className="h-1.5 bg-[#e4e0d5] rounded-full w-full" />
              <div className="h-1.5 bg-[#e4e0d5] rounded-full w-3/4" />
            </div>
            <div className="absolute top-2.5 right-2.5 px-2.5 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-semibold flex items-center gap-1 shadow-sm">
              <span className="w-1.5 h-1.5 rounded-full bg-white/70" />
              <span>Document</span>
            </div>
            <div className="absolute bottom-2.5 left-2.5 w-7 h-7 rounded-lg bg-[#ef4444] text-white font-black text-[9px] flex items-center justify-center shadow-md border border-white/20">
              PDF
            </div>
          </div>
        ) : isVideo ? (
          /* FORMAT 3: Video with Rich OG Image */
          <div className="relative w-full h-36 bg-neutral-900 overflow-hidden border-b border-[#f0ede4]">
            {previewImage && !imgError ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={previewImage}
                alt={title}
                className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                onError={() => setImgError(true)}
              />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-neutral-800 to-neutral-950 flex items-center justify-center">
                <Play className="w-8 h-8 text-white/50" />
              </div>
            )}
            <div className="absolute top-2.5 left-2.5 px-2.5 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-medium flex items-center gap-1 shadow-sm">
              <span>{domain || 'youtube.com'}</span>
            </div>
            <div className="absolute top-2.5 right-2.5 px-2.5 py-0.5 rounded-full bg-[#ea4335] text-white text-[10px] font-bold flex items-center gap-1 shadow-sm">
              <Play className="w-2.5 h-2.5 fill-white" />
              <span>Video</span>
            </div>
          </div>
        ) : isMusic ? (
          /* FORMAT 4: Music / Audio with Artwork & Circular Play Button */
          <div className="relative w-full h-36 bg-neutral-900 overflow-hidden border-b border-[#f0ede4]">
            {previewImage && !imgError ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={previewImage}
                alt={title}
                className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                onError={() => setImgError(true)}
              />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-emerald-900 to-teal-950 flex items-center justify-center">
                <Music2 className="w-8 h-8 text-emerald-400" />
              </div>
            )}
            <div className="absolute top-2.5 right-2.5 px-2.5 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-semibold flex items-center gap-1 shadow-sm">
              <Music2 className="w-2.5 h-2.5" />
              <span>Music</span>
            </div>
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                if (item.url) window.open(item.url, '_blank');
              }}
              title="Play"
              className="absolute bottom-2.5 right-2.5 w-9 h-9 rounded-full bg-white text-[#171711] flex items-center justify-center shadow-lg hover:scale-110 transition-transform cursor-pointer"
            >
              <Play className="w-3.5 h-3.5 fill-[#171711] ml-0.5" />
            </button>
          </div>
        ) : previewImage && !imgError ? (
          /* Generic OG Image Preview */
          <div className="relative w-full h-36 bg-neutral-900 overflow-hidden border-b border-[#f0ede4]">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={previewImage}
              alt={title}
              className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
              onError={() => setImgError(true)}
            />
            {domain && (
              <div className="absolute top-2.5 left-2.5 px-2.5 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-medium shadow-sm">
                <span>{domain}</span>
              </div>
            )}
          </div>
        ) : null}

        {/* ========================================================================= */}
        {/* Card Body Content */}
        {/* ========================================================================= */}
        <div className="p-4 sm:p-5 flex-1 flex flex-col justify-between">
          <div>
            {/* FORMAT 5: Note Header */}
            {isNote ? (
              <div className="flex items-center justify-between mb-2.5">
                <div className="w-7 h-7 rounded-lg bg-[#e6edb0] text-[#171711] flex items-center justify-center">
                  <StickyNote className="w-3.5 h-3.5" />
                </div>
                <span className="px-2.5 py-0.5 rounded-full bg-[#f0ede4] text-[#6c6b63] text-[10px] font-semibold flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#6c6b63]/60" />
                  <span>Note</span>
                </span>
              </div>
            ) : null}

            {/* FORMAT 6: Article Header */}
            {isArticle && !previewImage ? (
              <div className="flex items-center justify-between mb-2.5">
                <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-white border border-[#e4e0d5] text-[10px] font-semibold text-[#171711] shadow-2xs">
                  <div className="w-3.5 h-3.5 rounded bg-black text-white font-bold text-[9px] flex items-center justify-center">
                    N
                  </div>
                  <span>{domain || 'notion.so'}</span>
                </div>
                <span className="px-2.5 py-0.5 rounded-full bg-[#f0ede4] text-[#6c6b63] text-[10px] font-semibold flex items-center gap-1">
                  <FileText className="w-2.5 h-2.5" />
                  <span>Article</span>
                </span>
              </div>
            ) : null}

            {/* Title */}
            <h3 className="font-bold text-sm sm:text-[15px] text-[#171711] group-hover:text-black line-clamp-2 leading-snug tracking-tight mb-1 transition-colors">
              {title}
            </h3>

            {/* Subtitle / Description / Note Snippet */}
            {isNote ? (
              <p className="text-xs text-[#6c6b63] whitespace-pre-line leading-relaxed line-clamp-4 mb-3">
                {item.text_content || description}
              </p>
            ) : description ? (
              <p className="text-xs text-[#8e8d87] line-clamp-2 leading-relaxed mb-3">
                {description}
              </p>
            ) : null}

            {/* Tags Row */}
            {tags.length > 0 && (
              <div className="flex items-center gap-1.5 flex-wrap mt-2 mb-3">
                {tags.slice(0, 3).map((tag, idx) => (
                  <span
                    key={idx}
                    className="px-2 py-0.5 rounded-md bg-[#f0ede4] text-[#6c6b63] text-[10px] font-medium"
                  >
                    {tag}
                  </span>
                ))}
                {tags.length > 3 && (
                  <span className="px-2 py-0.5 rounded-md bg-[#ebe7dc] text-[#6c6b63] text-[10px] font-bold">
                    +{tags.length - 3}
                  </span>
                )}
              </div>
            )}
          </div>

          {/* ========================================================================= */}
          {/* Card Footer Actions */}
          {/* ========================================================================= */}
          <div className="pt-3 border-t border-[#f0ede4] flex items-center justify-between">
            {/* Left Source & Time */}
            <div className="flex items-center gap-1.5 text-[11px] text-[#9e9b92]">
              {isPsd || isPdf || primaryAttachment ? (
                <>
                  <Laptop className="w-3.5 h-3.5 text-[#9e9b92]" />
                  <span>Local file • {timeAgo}</span>
                </>
              ) : isVideo ? (
                <>
                  <svg className="w-3.5 h-3.5 text-[#ea4335]" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                  </svg>
                  <span>YouTube • {timeAgo}</span>
                </>
              ) : isMusic ? (
                <>
                  <svg className="w-3.5 h-3.5 text-[#1ed760]" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.498 17.306c-.217.355-.678.47-1.033.253-2.83-1.73-6.393-2.12-10.592-1.16-.407.094-.813-.16-.906-.566-.094-.407.16-.813.566-.906 4.604-1.052 8.547-.611 11.712 1.346.355.217.47.678.253 1.033zm1.467-3.266c-.273.444-.855.586-1.299.313-3.24-1.992-8.18-2.568-12.012-1.405-.497.151-1.025-.136-1.176-.633-.151-.497.136-1.025.633-1.176 4.39-1.332 9.83-.687 13.54 1.597.444.273.587.855.314 1.304zm.126-3.41c-3.885-2.307-10.29-2.52-14.004-1.392-.596.182-1.229-.16-1.411-.756-.182-.596.16-1.229.756-1.411 4.267-1.295 11.334-1.047 15.792 1.6 4.09 2.427 1.488 4.708.867 4.959z"/>
                  </svg>
                  <span>Spotify • {timeAgo}</span>
                </>
              ) : isArticle ? (
                <>
                  <div className="w-3.5 h-3.5 rounded bg-black text-white font-bold text-[8px] flex items-center justify-center">
                    N
                  </div>
                  <span>Notion • {timeAgo}</span>
                </>
              ) : isNote ? (
                <>
                  <StickyNote className="w-3.5 h-3.5 text-[#9e9b92]" />
                  <span>Note • {timeAgo}</span>
                </>
              ) : (
                <>
                  <Globe className="w-3.5 h-3.5 text-[#9e9b92]" />
                  <span>{domain || 'Web'} • {timeAgo}</span>
                </>
              )}
            </div>

            {/* Right Action Icons */}
            <div
              className="flex items-center gap-1"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Star Button */}
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  setFavorite(item.id, !item.favorite);
                }}
                title={item.favorite ? 'Unstar' : 'Star'}
                className={`p-1 rounded-lg transition-colors cursor-pointer ${
                  item.favorite
                    ? 'text-amber-500'
                    : 'text-[#9e9b92] hover:text-[#171711] hover:bg-[#f0ede4]'
                }`}
              >
                <Star className={`w-3.5 h-3.5 ${item.favorite ? 'fill-amber-500' : ''}`} />
              </button>

              {/* Complete / Archive / Checkmark Button */}
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  if (item.status === 'inbox' || item.status === 'deferred') {
                    keepItem(item.id);
                  } else {
                    archiveItem(item.id);
                  }
                }}
                title="Mark done / Keep"
                className="p-1 rounded-lg text-[#9e9b92] hover:text-[#171711] hover:bg-[#e6edb0] transition-colors cursor-pointer"
              >
                <Check className="w-3.5 h-3.5" />
              </button>

              {/* Folder or External Link Button */}
              {item.url ? (
                <a
                  href={destinationUrl}
                  target="_blank"
                  rel="noreferrer"
                  onClick={(e) => e.stopPropagation()}
                  title="Open source"
                  className="p-1 rounded-lg text-[#9e9b92] hover:text-[#171711] hover:bg-[#f0ede4] transition-colors"
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                </a>
              ) : (
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setCollectionModalOpen(true);
                  }}
                  title="Add to Collection"
                  className="p-1 rounded-lg text-[#9e9b92] hover:text-[#171711] hover:bg-[#f0ede4] transition-colors cursor-pointer"
                >
                  <FolderPlus className="w-3.5 h-3.5" />
                </button>
              )}

              {/* More Dropdown Menu */}
              <div className="relative">
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setMenuOpen(!menuOpen);
                  }}
                  title="More actions"
                  className="p-1 rounded-lg text-[#9e9b92] hover:text-[#171711] hover:bg-[#f0ede4] transition-colors cursor-pointer"
                >
                  <MoreVertical className="w-3.5 h-3.5" />
                </button>

                {menuOpen && (
                  <>
                    <div
                      className="fixed inset-0 z-20"
                      onClick={(e) => {
                        e.stopPropagation();
                        setMenuOpen(false);
                      }}
                    />
                    <div
                      className="absolute right-0 bottom-full mb-1 z-30 w-48 rounded-2xl bg-white border border-[#e4e0d5] shadow-xl py-1.5 text-xs font-semibold animate-in fade-in"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <RescheduleAction item={item} />

                      {/* Add to Collection */}
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setMenuOpen(false);
                          setCollectionModalOpen(true);
                        }}
                        className="w-full flex items-center gap-2.5 px-3.5 py-2 text-[#171711] hover:bg-[#f0ede4] transition-colors text-left cursor-pointer"
                      >
                        <FolderPlus className="w-3.5 h-3.5 text-[#0369a1]" />
                        <span>Add to Collection…</span>
                      </button>

                      {/* Copy Link / Content */}
                      <button
                        type="button"
                        onClick={handleCopy}
                        className="w-full flex items-center gap-2.5 px-3.5 py-2 text-[#171711] hover:bg-[#f0ede4] transition-colors text-left cursor-pointer"
                      >
                        {copied ? (
                          <>
                            <Check className="w-3.5 h-3.5 text-emerald-600" />
                            <span className="text-emerald-600">Copied!</span>
                          </>
                        ) : (
                          <>
                            <Copy className="w-3.5 h-3.5 text-[#6c6b63]" />
                            <span>Copy {item.url ? 'Link' : 'Text'}</span>
                          </>
                        )}
                      </button>

                      {/* View Details */}
                      <button
                        type="button"
                        onClick={() => {
                          setMenuOpen(false);
                          router.push(`/item/${item.id}`);
                        }}
                        className="w-full flex items-center gap-2.5 px-3.5 py-2 text-[#171711] hover:bg-[#f0ede4] transition-colors text-left cursor-pointer"
                      >
                        <FileText className="w-3.5 h-3.5 text-[#6c6b63]" />
                        <span>View Details</span>
                      </button>

                      <div className="my-1 border-t border-[#e4e0d5]" />

                      {/* Delete */}
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setMenuOpen(false);
                          if (confirm('Delete this item?')) {
                            deleteItem(item.id);
                          }
                        }}
                        className="w-full flex items-center gap-2.5 px-3.5 py-2 text-red-600 hover:bg-red-50 transition-colors text-left cursor-pointer"
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

      {/* Add To Collection Modal */}
      <AddToCollectionModal
        item={item}
        isOpen={collectionModalOpen}
        onClose={() => setCollectionModalOpen(false)}
      />
    </>
  );
}
