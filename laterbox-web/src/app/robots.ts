import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: '*',
        allow: [
          '/',
          '/download',
          '/docs',
          '/guide',
          '/tutorial',
          '/privacy',
          '/terms',
          '/login',
        ],
        disallow: [
          '/api/',
          '/inbox',
          '/item/',
          '/library',
          '/search',
          '/settings',
          '/extension/',
        ],
      },
    ],
    sitemap: 'https://laterbox.dev/sitemap.xml',
    host: 'https://laterbox.dev',
  };
}
