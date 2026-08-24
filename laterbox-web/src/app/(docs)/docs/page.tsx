import React from 'react';
import { Metadata } from 'next';
import { DocsReader } from '@/components/docs/DocsReader';

export const metadata: Metadata = {
  title: 'LaterBox Documentation | Local-First Architecture & Developer Guides',
  description:
    'Comprehensive developer guides, local SQLite Drift sync engine, Supabase Edge Functions, REST APIs, desktop quick capture, and self-hosting documentation for LaterBox.',
  alternates: {
    canonical: 'https://docs.laterbox.dev',
  },
  openGraph: {
    title: 'LaterBox Documentation | Local-First Knowledge Vault',
    description:
      'Comprehensive developer guides, system architecture, local SQLite sync, and API reference for LaterBox.',
    url: 'https://docs.laterbox.dev',
    siteName: 'LaterBox Documentation',
    images: [
      {
        url: 'https://laterbox.dev/branding/og-preview.png',
        width: 1200,
        height: 630,
        alt: 'LaterBox Documentation',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'LaterBox Documentation | Local-First Knowledge Vault',
    description:
      'Developer guides, architecture specifications, offline sync engine, and API reference for LaterBox.',
    images: ['https://laterbox.dev/branding/og-preview.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
};

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
