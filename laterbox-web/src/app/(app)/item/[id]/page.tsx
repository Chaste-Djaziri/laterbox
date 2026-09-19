'use client';

import React, { use, useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { MediaEmbed } from '@/components/item/MediaEmbed';
import { NoteEditor } from '@/components/item/NoteEditor';
import { AddToCollectionModal } from '@/components/collections/AddToCollectionModal';
import { ReturnTimePicker } from '@/components/scheduling/ReturnTimePicker';
import { isDue } from '@/lib/utils/schedule';
import { useItems } from '@/lib/store/ItemContext';
import { extractDomain, formatTimeAgo, buildTextFragmentUrl } from '@/lib/utils/url';
import { fetchAttachmentDownloadUrl } from '@/lib/utils/attachment';
import { Attachment } from '@/lib/supabase/types';
import {
  ArrowLeft,
  Star,
  CheckCircle,
  Archive,
  Inbox,
  FolderPlus,
  Folder,
  ExternalLink,
  Trash2,
  Copy,
  Check,
  Quote,
  Clock,
  Link2,
  Paperclip,
  Download,
  FileText,
  PlayCircle,
  Music2,
  ImageIcon,
  ChevronDown,
  ChevronUp,
  Apple,
  Laptop,
  Terminal,
  Smartphone,
  Puzzle,
  Globe,
  Play,
  StickyNote,
  Tag,
} from 'lucide-react';

function formatBytes(bytes?: number): string {
  if (!bytes) return '0 B';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function AttachmentRow({ attachment }: { attachment: Attachment }) {
  const [downloading, setDownloading] = useState(false);
  const [mediaUrl, setMediaUrl] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(true);

  const ext = attachment.file_extension.toLowerCase();
  const mime = attachment.mime_type.toLowerCase();
  const isImage = mime.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'svg'].includes(ext);
  const isPdf = ext === 'pdf' || mime === 'application/pdf';
  const isVideo = mime.startsWith('video/') || ['mp4', 'mov', 'mkv', 'webm'].includes(ext);
  const isAudio = mime.startsWith('audio/') || ['mp3', 'm4a', 'wav', 'aac', 'ogg'].includes(ext);

  useEffect(() => {
    if (attachment.local_path?.startsWith('data:') || attachment.local_path?.startsWith('http')) {
      setMediaUrl(attachment.local_path);
      return;
    }
    fetchAttachmentDownloadUrl(attachment.id, attachment.user_id ?? null).then((url) => {
      if (url) setMediaUrl(url);
    });
  }, [attachment.id, attachment.local_path, attachment.user_id]);

  const handleDownload = async () => {
    if (downloading) return;
    setDownloading(true);
    try {
      const url = mediaUrl || (await fetchAttachmentDownloadUrl(attachment.id, attachment.user_id ?? null));
      if (url) {
        const a = document.createElement('a');
        a.href = url;
        a.download = attachment.original_file_name || 'download';
        a.target = '_blank';
        a.rel = 'noopener noreferrer';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
      } else {
        alert('Could not generate download URL. Please try again.');
      }
    } finally {
      setDownloading(false);
    }
  };

  return (
    <div className="p-4 rounded-2xl bg-[#faf9f5] border border-[#e4e0d5] flex flex-col gap-3 transition-all">
      {/* Live Preview Media Area */}
      {mediaUrl && (
        <>
          {/* Image Preview */}
          {isImage && (
            <div className="w-full max-h-96 rounded-2xl overflow-hidden bg-white border border-[#e4e0d5] flex items-center justify-center">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={mediaUrl}
                alt={attachment.original_file_name}
                className="w-full h-auto max-h-96 object-contain"
              />
            </div>
          )}

          {/* PDF Viewer */}
          {isPdf && (
            <div className="w-full rounded-2xl overflow-hidden bg-white border border-[#e4e0d5]">
              <div className="p-2.5 bg-[#fef2f2] border-b border-[#fca5a5]/40 flex items-center justify-between">
                <span className="text-xs font-bold text-[#991b1b] flex items-center gap-1.5">
                  <FileText className="w-3.5 h-3.5" /> PDF Preview
                </span>
                <button
                  type="button"
                  onClick={() => setExpanded(!expanded)}
                  className="text-xs font-semibold text-[#991b1b] flex items-center gap-1 hover:underline cursor-pointer"
                >
                  {expanded ? (
                    <>
                      <span>Collapse</span>
                      <ChevronUp className="w-3.5 h-3.5" />
                    </>
                  ) : (
                    <>
                      <span>Expand</span>
                      <ChevronDown className="w-3.5 h-3.5" />
                    </>
                  )}
                </button>
              </div>
              {expanded && (
                <iframe
                  src={`${mediaUrl}#toolbar=1&navpanes=0`}
                  title={attachment.original_file_name}
                  className="w-full h-96 border-0"
                />
              )}
            </div>
          )}

          {/* Video Player */}
          {isVideo && (
            <div className="w-full rounded-2xl overflow-hidden bg-black border border-[#e4e0d5]">
              <video
                src={mediaUrl}
                controls
                playsInline
                className="w-full max-h-96 object-contain"
              />
            </div>
          )}

          {/* Audio Player */}
          {isAudio && (
            <div className="w-full p-3 rounded-2xl bg-white border border-[#e4e0d5]">
              <audio src={mediaUrl} controls className="w-full" />
            </div>
          )}
        </>
      )}

      {/* Attachment Details Footer */}
      <div className="flex items-center justify-between gap-3 pt-1">
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="w-9 h-9 rounded-xl bg-white flex items-center justify-center shrink-0 border border-[#e4e0d5] shadow-2xs">
            {isImage ? (
              <ImageIcon className="w-4 h-4 text-[#0284c7]" />
            ) : isPdf ? (
              <FileText className="w-4 h-4 text-red-600" />
            ) : isVideo ? (
              <PlayCircle className="w-4 h-4 text-rose-600" />
            ) : isAudio ? (
              <Music2 className="w-4 h-4 text-emerald-600" />
            ) : (
              <Paperclip className="w-4 h-4 text-[#6c6b63]" />
            )}
          </div>
          <div className="min-w-0">
            <p className="text-xs font-bold text-[#171711] truncate">
              {attachment.original_file_name}
            </p>
            <p className="text-[10px] text-[#6c6b63]">
              {attachment.file_extension.toUpperCase()} • {formatBytes(attachment.byte_size)}
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={handleDownload}
          disabled={downloading}
          title={`Download ${attachment.original_file_name}`}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] shadow-2xs transition-colors cursor-pointer shrink-0"
        >
          <Download className="w-3.5 h-3.5" />
          <span>{downloading ? 'Downloading…' : 'Download'}</span>
        </button>
      </div>
    </div>
  );
}

export default function ItemDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const {
    getItemById,
    now,
    setFavorite,
    reschedule,
    keepItem,
    archiveItem,
    markUnseen,
    deleteItem,
  } = useItems();

  const [collectionModalOpen, setCollectionModalOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const [imgError, setImgError] = useState(false);

  const item = getItemById(id);

  if (!item) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-16 text-center space-y-4">
        <h2 className="text-xl font-bold text-[#171711]">Item Not Found</h2>
        <p className="text-sm text-[#6c6b63]">The item you are looking for does not exist or was deleted.</p>
        <Link
          href="/inbox"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#171711] text-white text-xs font-bold shadow-xs hover:bg-[#282723] transition-colors"
        >
          <span>Back to Inbox</span>
        </Link>
      </div>
    );
  }

  const attachments = item.attachments || [];
  const primaryAttachment = attachments.length > 0 ? attachments[0] : null;

  const domain = extractDomain(item.url) || item.metadata?.domain || (item.url ? 'link' : null);
  const title = item.metadata?.title || item.title || primaryAttachment?.original_file_name || domain || 'Saved Item';
  const description = item.metadata?.description || item.text_content;
  const timeAgo = formatTimeAgo(item.created_at);
  const previewImage = item.metadata?.preview_image_url;

  // Determine platform card format category
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

  // Structured tags parsing
  let tags: string[] = [];
  if (item.metadata?.structured_data) {
    try {
      const data =
        typeof item.metadata.structured_data === 'string'
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
    : null;

  const itemCollections = item.collections || [];

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this item?')) {
      await deleteItem(item.id);
      router.push('/inbox');
    }
  };

  const handleCopyLink = () => {
    const textToCopy = destinationUrl || item.url || item.text_content || title;
    navigator.clipboard.writeText(textToCopy);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <>
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-6">
        {/* Top Header & Actions Navigation */}
        <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-[#e4e0d5]">
          <Link
            href="/inbox"
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-bold text-[#6c6b63] hover:text-[#171711] bg-white border border-[#e4e0d5] hover:bg-[#faf8f5] transition-colors shadow-2xs"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Inbox</span>
          </Link>

          <div className="flex items-center gap-1.5">
            {/* Star Button */}
            <button
              type="button"
              onClick={() => setFavorite(item.id, !item.favorite)}
              title={item.favorite ? 'Unstar' : 'Star'}
              className={`p-2 rounded-xl transition-colors cursor-pointer ${
                item.favorite
                  ? 'text-amber-500 hover:bg-amber-50 bg-amber-50/50'
                  : 'text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60'
              }`}
            >
              <Star className={`w-5 h-5 ${item.favorite ? 'fill-amber-500' : ''}`} />
            </button>

            {item.type === 'task' && item.status !== 'archived' && (
              <button
                type="button"
                onClick={() => archiveItem(item.id)}
                className="rounded-xl bg-[#e6edb0] px-3.5 py-1.5 text-xs font-bold text-[#171711] hover:bg-[#d8e09f] shadow-2xs transition-colors cursor-pointer"
              >
                Done
              </button>
            )}

            {/* Keep in Library / Archive / Move to Inbox Button */}
            {item.status === 'inbox' || item.status === 'deferred' ? (
              <button
                type="button"
                onClick={() => keepItem(item.id)}
                title="Keep in Library"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold bg-[#e6edb0] hover:bg-[#dbe49e] text-[#171711] transition-colors cursor-pointer shadow-2xs"
              >
                <CheckCircle className="w-4 h-4" />
                <span className="hidden sm:inline">Keep</span>
              </button>
            ) : item.status === 'saved' ? (
              <button
                type="button"
                onClick={() => archiveItem(item.id)}
                title="Archive"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <Archive className="w-4 h-4" />
                <span className="hidden sm:inline">Archive</span>
              </button>
            ) : (
              <button
                type="button"
                onClick={() => markUnseen(item.id)}
                title="Move back to Inbox"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-[#171711] bg-[#e6edb0] hover:bg-[#dbe49e] transition-colors cursor-pointer"
              >
                <Inbox className="w-4 h-4" />
                <span className="hidden sm:inline">Move to Inbox</span>
              </button>
            )}

            {/* Add to Collection Button */}
            <button
              type="button"
              onClick={() => setCollectionModalOpen(true)}
              title="Add to Collection"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold text-[#171711] bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] transition-colors cursor-pointer shadow-2xs"
            >
              <FolderPlus className="w-4 h-4 text-[#0369a1]" />
              <span className="hidden sm:inline">Collections</span>
            </button>

            {/* Copy Button */}
            <button
              type="button"
              onClick={handleCopyLink}
              title={item.url ? 'Copy Link' : 'Copy Text'}
              className="p-2 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
            >
              {copied ? <Check className="w-5 h-5 text-emerald-600" /> : <Copy className="w-5 h-5" />}
            </button>

            {/* External source Link */}
            {item.url && (
              <a
                href={destinationUrl || item.url}
                target="_blank"
                rel="noreferrer"
                title="Open Source in New Tab"
                className="p-2 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
              >
                <ExternalLink className="w-5 h-5" />
              </a>
            )}

            {/* Delete Button */}
            <button
              type="button"
              onClick={handleDelete}
              title="Delete Item"
              className="p-2 rounded-xl text-[#9e9b92] hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer"
            >
              <Trash2 className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Reschedule Picker */}
        <div className="bg-[#faf8f5] p-4 rounded-2xl border border-[#e4e0d5]">
          <ReturnTimePicker
            value={item.return_at ?? null}
            onChange={(value) => {
              void reschedule(item.id, value);
            }}
          />
        </div>

        {/* ========================================================================= */}
        {/* Main Item Card: Multi-Platform Identification & Visual Previews */}
        {/* ========================================================================= */}
        <article className="rounded-[28px] sm:rounded-[34px] bg-white border-2 border-[#171711] shadow-[0_20px_60px_rgba(0,0,0,0.06)] overflow-hidden transition-all duration-200">
          {/* FORMAT 1: PSD / Design File */}
          {isPsd ? (
            <div className="relative w-full h-52 sm:h-64 bg-gradient-to-tr from-[#1e1b4b] via-[#701a75] via-[#ec4899] to-[#84cc16] overflow-hidden flex items-center justify-center border-b border-[#e4e0d5]">
              <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-black/20" />
              <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-xs font-semibold flex items-center gap-1.5 shadow-sm">
                <span className="w-2 h-2 rounded-full bg-white/80" />
                <span>Design File</span>
              </div>
              <div className="absolute bottom-4 left-4 w-11 h-11 rounded-2xl bg-[#001e36] text-[#31a8ff] font-black text-lg flex items-center justify-center shadow-lg border border-white/20">
                Ps
              </div>
            </div>
          ) : isPdf ? (
            /* FORMAT 2: PDF Document Simulated Sheet */
            <div className="relative w-full h-52 sm:h-64 bg-[#f8f7f4] flex items-center justify-center overflow-hidden border-b border-[#e4e0d5]">
              <div className="w-52 sm:w-60 h-36 sm:h-44 bg-white rounded-xl shadow-md border border-[#e4e0d5] p-5 space-y-2.5 flex flex-col justify-center">
                <div className="h-2 bg-[#e4e0d5] rounded-full w-full" />
                <div className="h-2 bg-[#e4e0d5] rounded-full w-5/6" />
                <div className="h-2 bg-[#e4e0d5] rounded-full w-4/6" />
                <div className="h-2 bg-[#e4e0d5] rounded-full w-full" />
                <div className="h-2 bg-[#e4e0d5] rounded-full w-3/4" />
              </div>
              <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-xs font-semibold flex items-center gap-1.5 shadow-sm">
                <span className="w-2 h-2 rounded-full bg-white/80" />
                <span>PDF Document</span>
              </div>
              <div className="absolute bottom-4 left-4 w-11 h-11 rounded-2xl bg-[#ef4444] text-white font-black text-sm flex items-center justify-center shadow-lg border border-white/20">
                PDF
              </div>
            </div>
          ) : isVideo ? (
            /* FORMAT 3: Video with Rich OG Image / Player */
            <div className="relative w-full h-52 sm:h-72 bg-black overflow-hidden border-b border-[#e4e0d5]">
              {previewImage && !imgError ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={previewImage}
                  alt={title}
                  className="w-full h-full object-cover"
                  onError={() => setImgError(true)}
                />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-neutral-800 to-neutral-950 flex items-center justify-center">
                  <Play className="w-12 h-12 text-white/50" />
                </div>
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/30" />
              <div className="absolute top-4 left-4 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-xs font-semibold flex items-center gap-1.5 shadow-sm">
                <span>{domain || 'youtube.com'}</span>
              </div>
              <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-[#ea4335] text-white text-xs font-bold flex items-center gap-1.5 shadow-sm">
                <Play className="w-3 h-3 fill-white" />
                <span>Video</span>
              </div>
            </div>
          ) : isMusic ? (
            /* FORMAT 4: Music / Audio with Artwork & Floating Play Button */
            <div className="relative w-full h-52 sm:h-72 bg-neutral-900 overflow-hidden border-b border-[#e4e0d5]">
              {previewImage && !imgError ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={previewImage}
                  alt={title}
                  className="w-full h-full object-cover"
                  onError={() => setImgError(true)}
                />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-emerald-900 to-teal-950 flex items-center justify-center">
                  <Music2 className="w-12 h-12 text-emerald-400" />
                </div>
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/30" />
              <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-xs font-semibold flex items-center gap-1.5 shadow-sm">
                <span>♪ Music</span>
              </div>
              {/* Floating Circular Play Button */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="w-14 h-14 rounded-full bg-white/95 text-[#171711] flex items-center justify-center shadow-xl hover:scale-105 transition-transform cursor-pointer pl-1">
                  <Play className="w-6 h-6 fill-[#171711]" />
                </div>
              </div>
            </div>
          ) : isNote ? (
            /* FORMAT 5: Note Banner */
            <div className="p-6 bg-[#fbfaf6] border-b border-[#e4e0d5] flex items-center justify-between">
              <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] border border-[#171711]/20 flex items-center justify-center text-[#171711]">
                <StickyNote className="w-5 h-5" />
              </div>
              <div className="px-3 py-1 rounded-full bg-[#ebe7dc] text-[#171711] text-xs font-bold flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-[#171711]" />
                <span>Note</span>
              </div>
            </div>
          ) : isArticle ? (
            /* FORMAT 6: Article Banner */
            <div className="p-6 bg-[#fbfaf6] border-b border-[#e4e0d5] flex items-center justify-between">
              <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-white border border-[#e4e0d5] text-xs font-bold text-[#171711] shadow-2xs">
                <div className="w-4 h-4 rounded-xs bg-black text-white flex items-center justify-center text-[10px] font-black">
                  N
                </div>
                <span>{domain || 'notion.so'}</span>
              </div>
              <div className="px-3 py-1 rounded-full bg-[#ebe7dc] text-[#171711] text-xs font-bold flex items-center gap-1.5">
                <span>Article</span>
              </div>
            </div>
          ) : null}

          {/* Card Body Details */}
          <div className="p-6 sm:p-8 space-y-6">
            {/* Metadata Top Bar */}
            <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-[#9e9b92]">
              <div className="flex flex-wrap items-center gap-2">
                {item.metadata?.favicon_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={item.metadata.favicon_url}
                    alt=""
                    className="w-4 h-4 rounded-xs object-contain"
                    onError={(e) => {
                      (e.target as HTMLElement).style.display = 'none';
                    }}
                  />
                ) : (
                  <Link2 className="w-4 h-4 text-[#9e9b92]" />
                )}
                {domain && <span className="font-bold text-[#171711]">{domain}</span>}
                {domain && <span>•</span>}
                <div className="flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5" />
                  <span>{timeAgo}</span>
                </div>
              </div>

              <div className="flex items-center gap-1.5">
                {/* Platform / OS Badge */}
                {(() => {
                  let osLabel: string | null = null;
                  if (item.metadata?.structured_data) {
                    try {
                      const parsed =
                        typeof item.metadata.structured_data === 'string'
                          ? JSON.parse(item.metadata.structured_data)
                          : item.metadata.structured_data;
                      if (parsed?.os) osLabel = parsed.os;
                      else if (parsed?.source === 'browserExtension') osLabel = 'Extension';
                    } catch (_) {}
                  }
                  if (!osLabel && item.metadata?.classification_source) {
                    const src = item.metadata.classification_source;
                    if (src === 'browserExtension' || src === 'extension') osLabel = 'Extension';
                    else if (src === 'macosShare' || src === 'desktopQuickCapture') osLabel = 'macOS';
                    else if (src === 'iosShare') osLabel = 'iOS';
                    else if (src === 'androidShare') osLabel = 'Android';
                    else if (src === 'web') osLabel = 'Web';
                  }

                  if (!osLabel) return null;

                  return (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#ebe7dc] text-[#6c6b63] border border-[#e4e0d5]/60">
                      {osLabel === 'macOS' || osLabel === 'iOS' ? (
                        <Apple className="w-2.5 h-2.5" />
                      ) : osLabel === 'Windows' ? (
                        <Laptop className="w-2.5 h-2.5" />
                      ) : osLabel === 'Linux' ? (
                        <Terminal className="w-2.5 h-2.5" />
                      ) : osLabel === 'Android' ? (
                        <Smartphone className="w-2.5 h-2.5" />
                      ) : osLabel === 'Extension' ? (
                        <Puzzle className="w-2.5 h-2.5" />
                      ) : (
                        <Globe className="w-2.5 h-2.5" />
                      )}
                      <span>{osLabel}</span>
                    </span>
                  );
                })()}

                {/* Status Badge */}
                <span
                  className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-wider ${
                    item.status === 'inbox' || item.status === 'deferred'
                      ? 'bg-[#e0f2fe] text-[#0369a1]'
                      : item.status === 'saved'
                      ? 'bg-[#e6edb0] text-[#171711]'
                      : 'bg-[#f4f4f5] text-[#71717a]'
                  }`}
                >
                  {isDue(item, now)
                    ? 'Inbox'
                    : item.status === 'deferred'
                    ? item.return_at
                      ? 'Scheduled'
                      : 'Someday'
                    : item.status === 'saved'
                    ? 'Kept'
                    : 'Archived'}
                </span>
              </div>
            </div>

            {/* Collections Pill Bar */}
            {itemCollections.length > 0 && (
              <div className="flex flex-wrap items-center gap-1.5 pt-1">
                <span className="text-xs font-semibold text-[#9e9b92] mr-1 flex items-center gap-1">
                  <Folder className="w-3.5 h-3.5 text-[#0369a1]" />
                  <span>In:</span>
                </span>
                {itemCollections.map((col) => (
                  <Link
                    key={col.id}
                    href={`/library?collection=${col.id}`}
                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-[#e0f2fe] hover:bg-[#bae6fd] text-[#0369a1] transition-colors"
                  >
                    <span>{col.name}</span>
                  </Link>
                ))}
                <button
                  type="button"
                  onClick={() => setCollectionModalOpen(true)}
                  className="text-xs text-[#0369a1] hover:underline font-semibold ml-1 cursor-pointer"
                >
                  + Edit
                </button>
              </div>
            )}

            {/* Title & Subtitle */}
            <div className="space-y-1">
              <h1 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight leading-snug">
                {title}
              </h1>
              {description && (!item.url || description !== item.text_content) && (
                <p className="text-sm sm:text-base text-[#6c6b63] leading-relaxed">
                  {description}
                </p>
              )}
            </div>

            {/* Multi-Platform Tags */}
            {tags.length > 0 && (
              <div className="flex flex-wrap items-center gap-1.5 pt-1">
                <Tag className="w-3 h-3 text-[#9e9b92] mr-1" />
                {tags.map((t) => (
                  <span
                    key={t}
                    className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#f4f3ed] text-[#6c6b63] border border-[#e4e0d5]"
                  >
                    #{t}
                  </span>
                ))}
              </div>
            )}

            {/* Media Embed for Videos or Music */}
            {item.url && <MediaEmbed url={item.url} title={title} />}

            {/* Highlighted Quote Fragment */}
            {item.url && item.text_content && (
              <div className="p-4 rounded-2xl bg-[#fef3c7]/60 border border-[#fde68a] text-[#b45309] space-y-2">
                <div className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-[#b45309]">
                  <Quote className="w-4 h-4" />
                  <span>Captured Highlight</span>
                </div>
                <p className="text-sm font-medium italic leading-relaxed">
                  &ldquo;{item.text_content}&rdquo;
                </p>
                {destinationUrl && (
                  <div className="pt-1">
                    <a
                      href={destinationUrl}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex items-center gap-1.5 text-xs font-bold text-[#b45309] hover:underline"
                    >
                      <span>View in source context</span>
                      <ExternalLink className="w-3.5 h-3.5" />
                    </a>
                  </div>
                )}
              </div>
            )}

            {/* Note text content if pure note */}
            {!item.url && item.text_content && !primaryAttachment && (
              <div className="p-4 rounded-2xl bg-[#faf9f5] border border-[#e4e0d5] text-[#171711] text-sm whitespace-pre-wrap leading-relaxed font-mono">
                {item.text_content}
              </div>
            )}

            {/* Attached Files & Assets */}
            {attachments.length > 0 && (
              <div className="pt-4 border-t border-[#e4e0d5]/70 space-y-4">
                <div className="flex items-center gap-2 text-xs font-bold text-[#171711] uppercase tracking-wider">
                  <Paperclip className="w-3.5 h-3.5 text-[#0284c7]" />
                  <span>Attachments ({attachments.length})</span>
                </div>
                <div className="space-y-4">
                  {attachments.map((att) => (
                    <AttachmentRow key={att.id} attachment={att} />
                  ))}
                </div>
              </div>
            )}

            {/* Platform Branding Footer */}
            <div className="flex items-center justify-between pt-4 border-t border-[#f4f3ed]">
              <div className="flex items-center gap-2 text-xs font-semibold text-[#6c6b63]">
                {isMusic ? (
                  <div className="flex items-center gap-1.5 text-[#1db954]">
                    <Music2 className="w-4 h-4" />
                    <span className="font-bold">Spotify</span>
                  </div>
                ) : isVideo ? (
                  <div className="flex items-center gap-1.5 text-[#ea4335]">
                    <Play className="w-4 h-4 fill-[#ea4335]" />
                    <span className="font-bold">YouTube</span>
                  </div>
                ) : isArticle ? (
                  <div className="flex items-center gap-1.5 text-[#171711]">
                    <div className="w-3.5 h-3.5 rounded-xs bg-black text-white text-[9px] font-black flex items-center justify-center">
                      N
                    </div>
                    <span className="font-bold">Notion</span>
                  </div>
                ) : isPsd ? (
                  <div className="flex items-center gap-1.5 text-[#001e36]">
                    <div className="w-4 h-4 rounded-xs bg-[#001e36] text-[#31a8ff] text-[9px] font-black flex items-center justify-center">
                      Ps
                    </div>
                    <span className="font-bold">Adobe Photoshop</span>
                  </div>
                ) : isPdf ? (
                  <div className="flex items-center gap-1.5 text-red-600">
                    <FileText className="w-4 h-4" />
                    <span className="font-bold">PDF Document</span>
                  </div>
                ) : (
                  <div className="flex items-center gap-1.5">
                    <StickyNote className="w-4 h-4 text-[#8c897f]" />
                    <span>Personal Note</span>
                  </div>
                )}
                <span>•</span>
                <span>{timeAgo}</span>
              </div>

              {item.url && (
                <a
                  href={destinationUrl || item.url}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-[#171711] hover:bg-black text-xs font-bold text-white shadow-xs transition-colors cursor-pointer"
                >
                  <span>
                    {isMusic
                      ? 'Open in Spotify'
                      : isVideo
                      ? 'Watch on YouTube'
                      : isArticle
                      ? 'Open in Notion'
                      : 'Open Link'}
                  </span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </a>
              )}
            </div>
          </div>
        </article>

        {/* Personal Note Editor */}
        <NoteEditor itemId={item.id} initialContent={item.note?.content} />
      </div>

      {/* Add / Manage Collections Modal */}
      <AddToCollectionModal
        item={item}
        isOpen={collectionModalOpen}
        onClose={() => setCollectionModalOpen(false)}
      />
    </>
  );
}
