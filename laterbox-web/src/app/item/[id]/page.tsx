'use client';

import React, { use, useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AppShell } from '@/components/layout/AppShell';
import { MediaEmbed } from '@/components/item/MediaEmbed';
import { NoteEditor } from '@/components/item/NoteEditor';
import { useItems } from '@/lib/store/ItemContext';
import { extractDomain, formatTimeAgo, buildTextFragmentUrl } from '@/lib/utils/url';
import { fetchAttachmentDownloadUrl } from '@/lib/utils/attachment';
import { Attachment } from '@/lib/supabase/types';
import {
  ArrowLeft,
  Star,
  CheckCircle,
  Archive,
  ExternalLink,
  Trash2,
  Copy,
  Quote,
  Clock,
  Link2,
  Paperclip,
  Download,
  FileText,
  FileSpreadsheet,
  FileCode,
  File,
  Image as ImageIcon,
  PlayCircle,
  Music2,
  Eye,
  ChevronDown,
  ChevronUp,
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
    fetchAttachmentDownloadUrl(attachment.id).then((url) => {
      if (url) setMediaUrl(url);
    });
  }, [attachment.id, attachment.local_path]);

  const handleDownload = async () => {
    if (downloading) return;
    setDownloading(true);
    try {
      const url = mediaUrl || await fetchAttachmentDownloadUrl(attachment.id);
      if (url) {
        window.open(url, '_blank');
      } else {
        alert('Could not generate download URL. Please try again.');
      }
    } finally {
      setDownloading(false);
    }
  };

  return (
    <div className="p-4 rounded-3xl bg-[#ebe7dc]/50 border border-[#e4e0d5] flex flex-col gap-3 transition-all">
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
              <div className="p-2 bg-[#fef2f2] border-b border-[#fca5a5]/40 flex items-center justify-between">
                <span className="text-xs font-bold text-[#991b1b] flex items-center gap-1.5">
                  <FileText className="w-3.5 h-3.5" /> PDF Preview
                </span>
                <button
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
          onClick={handleDownload}
          disabled={downloading}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] shadow-2xs transition-colors cursor-pointer shrink-0"
        >
          <Download className="w-3.5 h-3.5" />
          <span>{downloading ? 'Loading…' : 'Open / Download'}</span>
        </button>
      </div>
    </div>
  );
}

export default function ItemDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const { getItemById, setFavorite, keepItem, archiveItem, markUnseen, deleteItem } = useItems();

  const item = getItemById(id);

  if (!item) {
    return (
      <AppShell>
        <div className="max-w-4xl mx-auto px-4 py-16 text-center space-y-4">
          <h2 className="text-xl font-bold text-[#171711]">Item Not Found</h2>
          <p className="text-sm text-[#6c6b63]">The item you are looking for does not exist or was deleted.</p>
          <Link
            href="/inbox"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#171711] text-white text-xs font-bold"
          >
            <span>Back to Inbox</span>
          </Link>
        </div>
      </AppShell>
    );
  }

  const domain = extractDomain(item.url) || item.metadata?.domain;
  const title = item.metadata?.title || item.title || (item.attachments && item.attachments.length > 0 ? item.attachments[0].original_file_name : null) || domain || 'Saved Item';
  const description = item.metadata?.description || item.text_content;
  const timeAgo = formatTimeAgo(item.created_at);
  const previewImage = item.metadata?.preview_image_url;

  const destinationUrl = item.url
    ? buildTextFragmentUrl(item.url, item.text_content, item.text_selector ? JSON.parse(item.text_selector).before : null)
    : null;

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this item?')) {
      await deleteItem(item.id);
      router.push('/inbox');
    }
  };

  const handleCopyLink = () => {
    if (item.url) {
      navigator.clipboard.writeText(destinationUrl || item.url);
      alert('Link copied to clipboard!');
    }
  };

  return (
    <AppShell>
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-6 sm:py-8 space-y-6">
        {/* Top Back & Actions Navigation */}
        <div className="flex items-center justify-between gap-4">
          <Link
            href="/inbox"
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-bold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back</span>
          </Link>

          <div className="flex items-center gap-1">
            {/* Star button */}
            <button
              onClick={() => setFavorite(item.id, !item.favorite)}
              title={item.favorite ? 'Unstar' : 'Star'}
              className={`p-2 rounded-xl transition-colors cursor-pointer ${
                item.favorite
                  ? 'text-amber-500 hover:bg-amber-50'
                  : 'text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60'
              }`}
            >
              <Star className={`w-5 h-5 ${item.favorite ? 'fill-amber-500' : ''}`} />
            </button>

            {/* Status change */}
            {item.status === 'inbox' ? (
              <button
                onClick={() => keepItem(item.id)}
                title="Mark as Kept"
                className="p-2 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#e6edb0] transition-colors cursor-pointer"
              >
                <CheckCircle className="w-5 h-5" />
              </button>
            ) : item.status === 'saved' ? (
              <button
                onClick={() => archiveItem(item.id)}
                title="Archive"
                className="p-2 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <Archive className="w-5 h-5" />
              </button>
            ) : (
              <button
                onClick={() => markUnseen(item.id)}
                title="Move back to Inbox"
                className="p-2 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#e6edb0] transition-colors cursor-pointer"
              >
                <CheckCircle className="w-5 h-5 text-[#171711]" />
              </button>
            )}

            {/* Copy button */}
            {item.url && (
              <button
                onClick={handleCopyLink}
                title="Copy Link"
                className="p-2 rounded-xl text-[#9e9b92] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
              >
                <Copy className="w-5 h-5" />
              </button>
            )}

            {/* External source */}
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

            {/* Delete */}
            <button
              onClick={handleDelete}
              title="Delete Item"
              className="p-2 rounded-xl text-[#9e9b92] hover:text-red-600 hover:bg-red-50 transition-colors cursor-pointer"
            >
              <Trash2 className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Main Item Card */}
        <article className="p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5] shadow-xs space-y-6">
          {/* Metadata Top Bar */}
          <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-[#9e9b92]">
            <div className="flex items-center gap-2">
              {item.metadata?.favicon_url ? (
                /* eslint-disable-next-line @next/next/no-img-element */
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

            {item.metadata?.content_type && (
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-[#ebe7dc] text-[#171711]">
                {item.metadata.content_type}
              </span>
            )}
          </div>

          {/* Title */}
          <h1 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight leading-snug">
            {title}
          </h1>

          {/* Media Embed if YouTube/Spotify/Vimeo */}
          {item.url && <MediaEmbed url={item.url} title={title} />}

          {/* Preview Image if not embedded media */}
          {previewImage && !item.url?.includes('youtube.com') && !item.url?.includes('spotify.com') && (
            <div className="w-full aspect-video rounded-2xl overflow-hidden bg-[#ebe7dc]/50 border border-[#e4e0d5]">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={previewImage} alt={title} className="w-full h-full object-cover" />
            </div>
          )}

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

          {/* Description or Text Content */}
          {description && (!item.url || description !== item.text_content) && (
            <div className="text-sm sm:text-base text-[#6c6b63] leading-relaxed space-y-3 font-normal">
              <p>{description}</p>
            </div>
          )}

          {/* Attached Files & Assets */}
          {item.attachments && item.attachments.length > 0 && (
            <div className="pt-4 border-t border-[#e4e0d5]/70 space-y-4">
              <div className="flex items-center gap-2 text-xs font-bold text-[#171711] uppercase tracking-wider">
                <Paperclip className="w-3.5 h-3.5 text-[#0284c7]" />
                <span>Attachments ({item.attachments.length})</span>
              </div>
              <div className="space-y-4">
                {item.attachments.map((att) => (
                  <AttachmentRow key={att.id} attachment={att} />
                ))}
              </div>
            </div>
          )}

          {/* Source Link Bar */}
          {item.url && (
            <div className="pt-4 border-t border-[#e4e0d5]/70 flex items-center justify-between">
              <span className="text-xs text-[#9e9b92] truncate max-w-sm sm:max-w-md">{item.url}</span>
              <a
                href={destinationUrl || item.url}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-xs font-bold text-[#171711] transition-colors"
              >
                <span>Open Source</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          )}
        </article>

        {/* Personal Note Editor */}
        <NoteEditor itemId={item.id} initialContent={item.note?.content} />
      </div>
    </AppShell>
  );
}
