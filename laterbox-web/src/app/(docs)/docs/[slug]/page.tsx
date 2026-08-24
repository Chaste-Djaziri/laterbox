import React from 'react';
import { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { DocsReader } from '@/components/docs/DocsReader';
import { ALL_DOCS, getDocBySlug } from '@/lib/docs-data';

interface DocsSlugPageProps {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  return ALL_DOCS.map((doc) => ({
    slug: doc.slug,
  }));
}

export async function generateMetadata({ params }: DocsSlugPageProps): Promise<Metadata> {
  const { slug } = await params;
  const doc = getDocBySlug(slug);

  if (!doc) {
    return {
      title: 'Documentation | LaterBox Docs',
    };
  }

  const canonicalUrl = `https://docs.laterbox.dev/${slug}`;

  return {
    title: `${doc.title} | LaterBox Documentation`,
    description: doc.description,
    alternates: {
      canonical: canonicalUrl,
    },
    openGraph: {
      title: `${doc.title} | LaterBox Documentation`,
      description: doc.description,
      url: canonicalUrl,
      siteName: 'LaterBox Documentation',
      images: [
        {
          url: 'https://laterbox.dev/branding/og-preview.png',
          width: 1200,
          height: 630,
          alt: doc.title,
        },
      ],
      locale: 'en_US',
      type: 'article',
    },
    twitter: {
      card: 'summary_large_image',
      title: `${doc.title} | LaterBox Documentation`,
      description: doc.description,
      images: ['https://laterbox.dev/branding/og-preview.png'],
    },
    robots: {
      index: true,
      follow: true,
    },
  };
}

export default async function DocsSlugPage({ params }: DocsSlugPageProps) {
  const { slug } = await params;
  const doc = getDocBySlug(slug);

  if (!doc) {
    notFound();
  }

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'TechArticle',
    headline: doc.title,
    description: doc.description,
    url: `https://docs.laterbox.dev/${slug}`,
    articleSection: doc.category,
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
      <DocsReader currentSlug={slug} />
    </>
  );
}
