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

// ── Lyrica API response types ─────────────────────────────────────────────────
interface LyricaLine {
  text: string;
  time?: number;
  endTime?: number;
}

interface LyricaSection {
  label: string;
  lines: LyricaLine[];
}

interface LyricaApiResponse {
  song?: {
    title?: string;
    artist?: { name?: string };
  };
  lyrics?: {
    plainText?: string;
    sections?: LyricaSection[];
    isSynced?: boolean;
    isVerified?: boolean;
  };
}

// ── Lyrics panel ──────────────────────────────────────────────────────────────
function LyricaLyricsPanel({ slug }: { slug: string }) {
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [sections, setSections] = useState<LyricaSection[]>([]);
  const [plainText, setPlainText] = useState('');
  const [songInfo, setSongInfo] = useState<{ title?: string; artist?: string } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const load = async () => {
    if (loaded || loading) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`https://lyricarw.com/api/public/songs/${slug}/lyrics`);
      if (!res.ok) throw new Error(`Could not load lyrics (${res.status})`);
      const data = await res.json() as LyricaApiResponse;

      setSongInfo({
        title: data.song?.title,
        artist: data.song?.artist?.name,
      });

      const apiSections = data.lyrics?.sections;
      if (Array.isArray(apiSections) && apiSections.length > 0) {
        setSections(apiSections);
      } else if (data.lyrics?.plainText) {
        // Fallback: wrap plain text as a single section
        const lines = data.lyrics.plainText
          .split(/\r?\n/)
          .map((text) => ({ text }));
        setSections([{ label: '', lines }]);
      }

      setPlainText(data.lyrics?.plainText ?? '');
      setLoaded(true);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load lyrics');
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(plainText || sections.flatMap((s) => s.lines.map((l) => l.text)).join('\n'));
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  const totalLines = sections.reduce((n, s) => n + s.lines.length, 0);

  return (
    <div className="mt-3 rounded-2xl border border-purple-200 bg-purple-50/60 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 bg-purple-100/60 border-b border-purple-200">
        <span className="text-xs font-bold text-purple-800 flex items-center gap-1.5">
          <Music2 className="w-3.5 h-3.5" />
          {songInfo?.title ? (
            <span>
              {songInfo.title}
              {songInfo.artist && (
                <span className="font-normal text-purple-600"> — {songInfo.artist}</span>
              )}
            </span>
          ) : (
            'Lyrics'
          )}
        </span>
        <div className="flex items-center gap-2">
          {loaded && totalLines > 0 && (
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

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center gap-2 py-8 text-purple-600">
          <Loader2 className="w-4 h-4 animate-spin" />
          <span className="text-xs font-medium">Loading lyrics…</span>
        </div>
      )}

      {/* Error */}
      {error && (
        <p className="px-4 py-3 text-xs text-red-600 font-medium">{error}</p>
      )}

      {/* Empty */}
      {loaded && totalLines === 0 && (
        <p className="px-4 py-3 text-xs text-purple-600 font-medium">No lyrics available.</p>
      )}

      {/* Lyrics */}
      {loaded && totalLines > 0 && (
        <div className="px-4 py-4 space-y-5 max-h-96 overflow-y-auto scroll-smooth">
          {sections.map((section, si) => (
            <div key={si} className="space-y-1">
              {section.label && (
                <p className="text-[10px] font-black uppercase tracking-widest text-purple-400 pb-1">
                  {section.label}
                </p>
              )}
              {section.lines.map((line, li) =>
                line.text.trim() === '' ? (
                  <div key={li} className="h-2" />
                ) : (
                  <p
                    key={li}
                    className="text-sm leading-relaxed font-medium text-purple-950"
                  >
                    {line.text}
                  </p>
                )
              )}
            </div>
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
