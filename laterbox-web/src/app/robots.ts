import type { MetadataRoute } from 'next';
import { headers } from 'next/headers';
import { SITE_URL, DOCS_URL } from '@/lib/seo';

export default async function robots(): Promise<MetadataRoute.Robots> {
  const host = (await headers()).get('host') || '';
  // Allow app pages to be crawled so their noindex headers can be observed.
  if (host.startsWith('app.')) return { rules: { userAgent: '*', disallow: ['/api/'] } };
  const origin = host.startsWith('docs.') ? DOCS_URL : SITE_URL;
  return {
    rules: { userAgent: '*', allow: '/', disallow: ['/api/'] },
    sitemap: origin + '/sitemap.xml',
    host: origin,
  };
}
