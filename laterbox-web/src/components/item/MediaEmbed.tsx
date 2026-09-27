'use client';

import React, { useState } from 'react';
import { Music2, Loader2, Copy, Check } from 'lucide-react';

interface MediaEmbedProps {
  url: string;
  title?: string | null;
  /** Pre-resolved embed info from structured_data (skips client-side URL parsing) */
  embedProvider?: string | null;
  embedUrl?: string | null;
  embedHeight?: number | null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Lyrica lyrics panel
// ─────────────────────────────────────────────────────────────────────────────
function LyricaLyricsPanel({ slug }: { slug: string }) {
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [lines, setLines] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const load = async () => {
    if (loaded || loading) return;
    setLoading(true);
    try {
      const res = await fetch(`https://lyricarw.com/api/public/songs/${slug}/lyrics`);
      if (!res.ok) throw new Error(`${res.status}`);
      const data = await res.json() as { synced?: Array<{ text: string }>; plain?: string; lyrics?: string };
      const synced = data?.synced ?? [];
      if (synced.length > 0) {
        setLines(synced.map((l) => l.text));
      } else {
        const plain: string = data?.plain ?? data?.lyrics ?? '';
        setLines(plain ? plain.split('\n') : []);
      }
      setLoaded(true);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load lyrics');
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(lines.join('\n'));
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <div className="mt-3 rounded-2xl border border-purple-200 bg-purple-50/60 overflow-hidden">
      <div className="flex items-center justify-between px-4 py-3 bg-purple-100/60 border-b border-purple-200">
        <span className="text-xs font-bold text-purple-800 flex items-center gap-1.5">
          <Music2 className="w-3.5 h-3.5" />
          Lyrics
        </span>
        <div className="flex items-center gap-2">
          {loaded && lines.length > 0 && (
            <button
              type="button"
              onClick={handleCopy}
              className="flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-purple-200 hover:bg-purple-300 text-purple-900 transition-colors cursor-pointer"
            >
              {copied ? <Check className="w-3 h-3" /> : <Copy className="w-3 h-3" />}
              {copied ? 'Copied!' : 'Copy'}
            </button>
          )}
          {!loaded && !loading && (
            <button
              type="button"
              onClick={load}
              className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-purple-700 hover:bg-purple-800 text-white transition-colors cursor-pointer"
            >
              Load Lyrics
            </button>
          )}
        </div>
      </div>

      {loading && (
        <div className="flex items-center justify-center py-8 text-purple-600">
          <Loader2 className="w-5 h-5 animate-spin" />
        </div>
      )}

      {error && (
        <p className="px-4 py-3 text-xs text-red-600 font-medium">{error}</p>
      )}

      {loaded && lines.length === 0 && (
        <p className="px-4 py-3 text-xs text-purple-600 font-medium">No lyrics available.</p>
      )}

      {loaded && lines.length > 0 && (
        <div className="px-4 py-4 space-y-1 max-h-80 overflow-y-auto">
          {lines.map((line, i) => (
            <p
              key={i}
              className={`text-sm leading-relaxed font-medium ${
                line.trim() === '' ? 'h-3' : 'text-purple-950'
              }`}
            >
              {line || '\u00A0'}
            </p>
          ))}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main MediaEmbed component
// ─────────────────────────────────────────────────────────────────────────────
export function MediaEmbed({ url, title, embedProvider, embedUrl, embedHeight }: MediaEmbedProps) {
  if (!url) return null;

  // ── 1. Use pre-resolved embed info from structured_data if available ──────
  if (embedProvider && embedUrl) {
    if (embedProvider === 'Lyrica') {
      const slug = url.match(/lyricarw\.com\/(?:embed\/song|songs)\/([a-zA-Z0-9_-]+)/)?.[1] ?? '';
      return (
        <div className="my-4 space-y-0">
          <div className="w-full rounded-2xl overflow-hidden shadow-md border border-purple-300">
            <iframe
              src={embedUrl}
              width="100%"
              height={embedHeight ?? 152}
              style={{ border: 0, borderRadius: '16px', maxWidth: '720px' }}
              loading="lazy"
              allow="autoplay; clipboard-write; encrypted-media"
              title={title || 'Lyrica Player'}
            />
          </div>
          {slug && <LyricaLyricsPanel slug={slug} />}
        </div>
      );
    }

    // All other embed providers: YouTube, Spotify, Vimeo, SoundCloud
    const isAspectVideo = embedProvider === 'YouTube' || embedProvider === 'Vimeo';
    return (
      <div
        className={`w-full rounded-2xl overflow-hidden shadow-lg border border-zinc-200 my-4 ${
          embedProvider === 'Spotify' ? 'bg-zinc-900' : 'bg-black'
        } ${isAspectVideo ? 'aspect-video' : ''}`}
        style={!isAspectVideo ? { height: `${embedHeight ?? 166}px` } : undefined}
      >
        <iframe
          src={embedUrl}
          width="100%"
          height={isAspectVideo ? '100%' : (embedHeight ?? 166)}
          title={title || `${embedProvider} Player`}
          allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture; accelerometer; gyroscope"
          allowFullScreen
          loading="lazy"
          className="border-0 w-full h-full"
        />
      </div>
    );
  }

  // ── 2. Fallback: client-side URL parsing ──────────────────────────────────

  // YouTube
  const youtubeMatch = url.match(
    /(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\\w-]{11})/
  );
  if (youtubeMatch?.[1]) {
    const videoId = youtubeMatch[1];
    return (
      <div className="w-full aspect-video rounded-2xl overflow-hidden shadow-lg border border-zinc-200 bg-black my-4">
        <iframe
          src={`https://www.youtube-nocookie.com/embed/${videoId}?autoplay=0&rel=0`}
          title={title || 'YouTube Video'}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
          className="w-full h-full border-0"
        />
      </div>
    );
  }

  // Spotify
  const spotifyMatch = url.match(/open\.spotify\.com\/(track|album|playlist|episode|show)\/([a-zA-Z0-9]+)/);
  if (spotifyMatch) {
    const type = spotifyMatch[1];
    const id = spotifyMatch[2];
    return (
      <div className="w-full rounded-2xl overflow-hidden shadow-md border border-zinc-200 my-4 bg-zinc-900">
        <iframe
          src={`https://open.spotify.com/embed/${type}/${id}?utm_source=generator`}
          width="100%"
          height={type === 'track' ? '152' : '352'}
          allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"
          loading="lazy"
          className="border-0 rounded-2xl"
        />
      </div>
    );
  }

  // Vimeo
  const vimeoMatch = url.match(/vimeo\.com\/(\d+)/);
  if (vimeoMatch?.[1]) {
    const videoId = vimeoMatch[1];
    return (
      <div className="w-full aspect-video rounded-2xl overflow-hidden shadow-lg border border-zinc-200 bg-black my-4">
        <iframe
          src={`https://player.vimeo.com/video/${videoId}`}
          title={title || 'Vimeo Video'}
          allow="autoplay; fullscreen; picture-in-picture"
          allowFullScreen
          className="w-full h-full border-0"
        />
      </div>
    );
  }

  // SoundCloud
  if (url.includes('soundcloud.com')) {
    const encoded = encodeURIComponent(url);
    return (
      <div className="w-full rounded-2xl overflow-hidden shadow-md border border-zinc-200 my-4" style={{ height: '166px' }}>
        <iframe
          src={`https://w.soundcloud.com/player/?url=${encoded}&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true`}
          width="100%"
          height="166"
          allow="autoplay"
          loading="lazy"
          className="border-0 w-full h-full"
          title={title || 'SoundCloud Player'}
        />
      </div>
    );
  }

  // Lyrica (client-side fallback)
  const lyricaMatch = url.match(/lyricarw\.com\/(?:embed\/song|songs)\/([a-zA-Z0-9_-]+)/);
  if (lyricaMatch?.[1]) {
    const slug = lyricaMatch[1];
    return (
      <div className="my-4 space-y-0">
        <div className="w-full rounded-2xl overflow-hidden shadow-md border border-purple-300">
          <iframe
            src={`https://lyricarw.com/embed/song/${slug}`}
            width="100%"
            height="152"
            style={{ border: 0, borderRadius: '16px', maxWidth: '720px' }}
            loading="lazy"
            allow="autoplay; clipboard-write; encrypted-media"
            title={title || 'Lyrica Player'}
          />
        </div>
        <LyricaLyricsPanel slug={slug} />
      </div>
    );
  }

  return null;
}
