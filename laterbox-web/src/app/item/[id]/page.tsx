'use client';

import React, { use } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AppShell } from '@/components/layout/AppShell';
import { MediaEmbed } from '@/components/item/MediaEmbed';
import { NoteEditor } from '@/components/item/NoteEditor';
import { useItems } from '@/lib/store/ItemContext';
import { extractDomain, formatTimeAgo, buildTextFragmentUrl } from '@/lib/utils/url';
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
} from 'lucide-react';

export default function ItemDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const { getItemById, setFavorite, keepItem, archiveItem, markUnseen, deleteItem } = useItems();

  const item = getItemById(id);

  if (!item) {
    return (
      <AppShell>
        <div className="max-w-4xl mx-auto px-4 py-16 text-center space-y-4">
          <h2 className="text-xl font-bold text-zinc-900">Item Not Found</h2>
          <p className="text-sm text-zinc-500">The item you are looking for does not exist or was deleted.</p>
          <Link
            href="/inbox"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-emerald-600 text-white text-xs font-bold"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Return to Inbox</span>
          </Link>
        </div>
      </AppShell>
    );
  }

  const domain = extractDomain(item.url) || item.metadata?.domain;
  const title = item.metadata?.title || item.title || domain || 'Saved Item';
  const description = item.metadata?.description || item.text_content;
  const previewImage = item.metadata?.preview_image_url;
  const timeAgo = formatTimeAgo(item.created_at);

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
            className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-bold text-zinc-600 hover:bg-zinc-100 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back</span>
          </Link>

          <div className="flex items-center gap-1">
            {/* Star button */}
            <button
              onClick={() => setFavorite(item.id, !item.favorite)}
              title={item.favorite ? 'Unstar' : 'Star'}
              className={`p-2 rounded-xl transition-colors ${
                item.favorite
                  ? 'text-amber-500 hover:bg-amber-50'
                  : 'text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100'
              }`}
            >
              <Star className={`w-5 h-5 ${item.favorite ? 'fill-amber-500' : ''}`} />
            </button>

            {/* Status change */}
            {item.status === 'inbox' ? (
              <button
                onClick={() => keepItem(item.id)}
                title="Mark as Kept"
                className="p-2 rounded-xl text-zinc-400 hover:text-emerald-600 hover:bg-emerald-50 transition-colors"
              >
                <CheckCircle className="w-5 h-5" />
              </button>
            ) : item.status === 'saved' ? (
              <button
                onClick={() => archiveItem(item.id)}
                title="Archive"
                className="p-2 rounded-xl text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 transition-colors"
              >
                <Archive className="w-5 h-5" />
              </button>
            ) : (
              <button
                onClick={() => markUnseen(item.id)}
                title="Move back to Inbox"
                className="p-2 rounded-xl text-zinc-400 hover:text-emerald-600 hover:bg-emerald-50 transition-colors"
              >
                <CheckCircle className="w-5 h-5 text-emerald-500" />
              </button>
            )}

            {/* Copy button */}
            {item.url && (
              <button
                onClick={handleCopyLink}
                title="Copy Link"
                className="p-2 rounded-xl text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 transition-colors"
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
                className="p-2 rounded-xl text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 transition-colors"
              >
                <ExternalLink className="w-5 h-5" />
              </a>
            )}

            {/* Delete */}
            <button
              onClick={handleDelete}
              title="Delete Item"
              className="p-2 rounded-xl text-zinc-400 hover:text-red-600 hover:bg-red-50 transition-colors"
            >
              <Trash2 className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Main Item Card */}
        <article className="p-6 sm:p-8 rounded-3xl bg-white border border-zinc-200/80 shadow-sm space-y-6">
          {/* Metadata Top Bar */}
          <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-zinc-400">
            <div className="flex items-center gap-2">
              {item.metadata?.favicon_url ? (
                /* eslint-disable-next-line @next/next/no-img-element */
                <img
                  src={item.metadata.favicon_url}
                  alt=""
                  className="w-4 h-4 rounded object-contain"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              ) : (
                <Link2 className="w-4 h-4 text-zinc-400" />
              )}
              {domain && <span className="font-bold text-zinc-700">{domain}</span>}
              {domain && <span>•</span>}
              <div className="flex items-center gap-1">
                <Clock className="w-3.5 h-3.5" />
                <span>{timeAgo}</span>
              </div>
            </div>

            {item.metadata?.content_type && (
              <span className="px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-zinc-100 text-zinc-700">
                {item.metadata.content_type}
              </span>
            )}
          </div>

          {/* Title */}
          <h1 className="text-2xl sm:text-3xl font-black text-zinc-900 tracking-tight leading-snug">
            {title}
          </h1>

          {/* Media Embed if YouTube/Spotify/Vimeo */}
          {item.url && <MediaEmbed url={item.url} title={title} />}

          {/* Preview Image if not embedded media */}
          {previewImage && !item.url?.includes('youtube.com') && !item.url?.includes('spotify.com') && (
            <div className="w-full aspect-video rounded-2xl overflow-hidden bg-zinc-100 border border-zinc-200">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={previewImage} alt={title} className="w-full h-full object-cover" />
            </div>
          )}

          {/* Highlighted Quote Fragment */}
          {item.url && item.text_content && (
            <div className="p-4 rounded-2xl bg-amber-50 border border-amber-200/80 text-amber-900 space-y-2">
              <div className="flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-amber-700">
                <Quote className="w-4 h-4" />
                <span>Captured Highlight</span>
              </div>
              <p className="text-sm font-medium italic leading-relaxed">
                "{item.text_content}"
              </p>
              {destinationUrl && (
                <div className="pt-1">
                  <a
                    href={destinationUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1.5 text-xs font-bold text-amber-800 hover:underline"
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
            <div className="text-sm sm:text-base text-zinc-600 leading-relaxed space-y-3 font-normal">
              <p>{description}</p>
            </div>
          )}

          {/* Source Link Bar */}
          {item.url && (
            <div className="pt-4 border-t border-zinc-100 flex items-center justify-between">
              <span className="text-xs text-zinc-400 truncate max-w-sm sm:max-w-md">{item.url}</span>
              <a
                href={destinationUrl || item.url}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-zinc-100 hover:bg-zinc-200 text-xs font-bold text-zinc-800 transition-colors"
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
