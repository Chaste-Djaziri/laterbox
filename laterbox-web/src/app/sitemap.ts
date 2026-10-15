import type { MetadataRoute } from 'next';
import { headers } from 'next/headers';
import { ALL_DOCS } from '@/lib/docs-data';
import { SITE_URL, DOCS_URL } from '@/lib/seo';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const host = (await headers()).get('host') || '';
  if (host.startsWith('app.')) return [];
  if (host.startsWith('docs.')) {
    return [{ url: DOCS_URL }, ...ALL_DOCS.map(doc => ({ url: DOCS_URL + '/' + doc.slug }))];
  }
  return ['/', '/features', '/about', '/browser-extension', '/download', '/guide', '/pricing', '/privacy', '/terms', '/refund']
    .map(path => ({ url: new URL(path, SITE_URL).href }));
}
