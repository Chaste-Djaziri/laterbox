import { publicMetadata, DOCS_URL } from '@/lib/seo';
import React from 'react';
import { Metadata } from 'next';
import { DocsReader } from '@/components/docs/DocsReader';

export const metadata: Metadata = publicMetadata('LaterBox Documentation', 'Explore LaterBox setup guides, supported clients, capture workflows, and technical documentation.', '/', DOCS_URL);

export default function DocsPage() {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'TechArticle',
    headline: 'LaterBox Documentation & Architecture Guide',
    description:
      'Comprehensive developer guides, local SQLite sync engine, and API reference for LaterBox.',
    url: 'https://docs.laterbox.dev',
    publisher: {
      '@type': 'Organization',
      name: 'LaterBox',
      url: 'https://laterbox.dev',
      logo: 'https://laterbox.dev/branding/laterbox-icon.png',
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <DocsReader currentSlug="introduction" />
    </>
  );
}
