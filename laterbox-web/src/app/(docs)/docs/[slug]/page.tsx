import React from 'react';
import { Metadata } from 'next';
import { publicMetadata, DOCS_URL } from '@/lib/seo';
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

  if (!doc) notFound();
  const metadata = publicMetadata(doc.title + ' | LaterBox Documentation', doc.description, '/' + slug, DOCS_URL);
  return { ...metadata, openGraph: { ...metadata.openGraph, type: 'article' } };
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
