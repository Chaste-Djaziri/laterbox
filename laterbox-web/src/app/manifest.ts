import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'LaterBox - Save for Later',
    short_name: 'LaterBox',
    description: 'Save anything now. Read, watch & organize later.',
    start_url: '/inbox',
    display: 'standalone',
    background_color: '#f7f5ee',
    theme_color: '#171711',
    icons: [
      {
        src: '/branding/laterbox-icon.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/branding/laterbox-icon.png',
        sizes: '512x512',
        type: 'image/png',
      },
    ],
  };
}
