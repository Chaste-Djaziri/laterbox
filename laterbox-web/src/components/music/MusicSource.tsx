import { Apple, Music2 } from 'lucide-react';

export type MusicSource = 'spotify' | 'appleMusic' | 'soundcloud' | 'lyrica' | 'music';

export function getMusicSource(url?: string | null): MusicSource {
  const host = url?.toLowerCase() ?? '';
  if (host.includes('spotify.com')) return 'spotify';
  if (host.includes('music.apple.com') || host.includes('itunes.apple.com')) return 'appleMusic';
  if (host.includes('soundcloud.com')) return 'soundcloud';
  if (host.includes('lyricarw.com')) return 'lyrica';
  return 'music';
}

export function musicSourceLabel(source: MusicSource): string {
  switch (source) {
    case 'spotify': return 'Spotify';
    case 'appleMusic': return 'Apple Music';
    case 'soundcloud': return 'SoundCloud';
    case 'lyrica': return 'Lyrica';
    case 'music': return 'Music';
  }
}

export function MusicSourceIcon({ source, className = 'w-4 h-4' }: { source: MusicSource; className?: string }) {
  if (source === 'spotify') {
    return <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-label="Spotify"><path d="M12 0a12 12 0 1 0 0 24 12 12 0 0 0 0-24Zm5.5 17.3a.75.75 0 0 1-1.03.26c-2.83-1.73-6.39-2.12-10.59-1.16a.75.75 0 1 1-.34-1.46c4.6-1.05 8.55-.61 11.71 1.35.36.22.47.68.25 1.03Zm1.47-3.27a.94.94 0 0 1-1.3.31c-3.24-1.99-8.18-2.57-12.01-1.4a.94.94 0 1 1-.54-1.8c4.39-1.33 9.83-.69 13.54 1.6.44.27.58.86.31 1.3Zm.13-3.41C15.22 8.32 8.81 8.11 5.1 9.24a1.13 1.13 0 1 1-.66-2.16c4.27-1.3 11.33-1.05 15.79 1.6a1.13 1.13 0 0 1-1.13 1.95Z" /></svg>;
  }
  if (source === 'appleMusic') return <Apple className={className} aria-label="Apple Music" />;
  return <Music2 className={className} aria-label={musicSourceLabel(source)} />;
}
