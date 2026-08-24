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

  return {
    title: `${doc.title} | LaterBox Docs`,
    description: doc.description,
  };
}

export default async function DocsSlugPage({ params }: DocsSlugPageProps) {
  const { slug } = await params;
  const doc = getDocBySlug(slug);

  if (!doc) {
    notFound();
  }

  return <DocsReader currentSlug={slug} />;
}
