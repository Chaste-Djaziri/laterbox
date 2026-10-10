'use client';

import React from 'react';
import '@videojs/react/audio/skin.css';
import { AudioPlayer, AudioSkin, Audio } from '@videojs/react/audio';

interface AudioPlayerComponentProps {
  src: string;
  title?: string;
  className?: string;
}

export function AudioPlayerComponent({
  src,
  title,
  className = '',
}: AudioPlayerComponentProps) {
  return (
    <div
      className={`w-full p-2.5 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] shadow-2xs ${className}`}
    >
      <AudioPlayer>
        <AudioSkin style={{ width: '100%' }}>
          <Audio src={src} title={title} crossOrigin="anonymous" />
        </AudioSkin>
      </AudioPlayer>
    </div>
  );
}
