'use client';

import React from 'react';

interface MediaEmbedProps {
  url: string;
  title?: string | null;
}

export function MediaEmbed({ url, title }: MediaEmbedProps) {
  if (!url) return null;

  // YouTube Embed
  const youtubeMatch = url.match(
    /(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})/
  );
  if (youtubeMatch && youtubeMatch[1]) {
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

  // Spotify Embed
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

  // Vimeo Embed
  const vimeoMatch = url.match(/vimeo\.com\/(\d+)/);
  if (vimeoMatch && vimeoMatch[1]) {
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

  return null;
}
