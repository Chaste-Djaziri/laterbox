'use client';

import React from 'react';
import '@videojs/react/video/skin.css';
import { VideoPlayer, VideoSkin, Video } from '@videojs/react/video';

interface VideoPlayerComponentProps {
  src: string;
  poster?: string;
  title?: string;
  className?: string;
}

export function VideoPlayerComponent({
  src,
  poster,
  title,
  className = '',
}: VideoPlayerComponentProps) {
  return (
    <div
      className={`w-full rounded-2xl overflow-hidden bg-black border border-[#171711] shadow-2xs ${className}`}
    >
      <VideoPlayer>
        <VideoSkin style={{ width: '100%', aspectRatio: '16 / 9' }}>
          <Video
            src={src}
            poster={poster}
            title={title}
            playsInline
            crossOrigin="anonymous"
          />
        </VideoSkin>
      </VideoPlayer>
    </div>
  );
}
