import type { MetadataRoute } from 'next';
import { ALL_DOCS } from '@/lib/docs-data';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'https://laterbox.dev';
  const docsBaseUrl = 'https://docs.laterbox.dev';
  const lastModified = new Date();

  const docUrls: MetadataRoute.Sitemap = ALL_DOCS.map((doc) => ({
    url: `${docsBaseUrl}/${doc.slug}`,
    lastModified,
    changeFrequency: 'weekly',
    priority: 0.85,
  }));

  return [
    {
      url: baseUrl,
      lastModified,
      changeFrequency: 'daily',
      priority: 1.0,
    },
    {
      url: docsBaseUrl,
      lastModified,
      changeFrequency: 'daily',
      priority: 0.95,
    },
    {
      url: `${baseUrl}/download`,
      lastModified,
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/guide`,
      lastModified,
      changeFrequency: 'weekly',
      priority: 0.8,
    },
    ...docUrls,
    {
      url: `${baseUrl}/login`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.6,
    },
    {
      url: `${baseUrl}/privacy`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.5,
    },
    {
      url: `${baseUrl}/terms`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.5,
    },
  ];
}

