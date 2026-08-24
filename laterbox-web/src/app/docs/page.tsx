import React from 'react';
import { Metadata } from 'next';
import { DocsReader } from '@/components/docs/DocsReader';

export const metadata: Metadata = {
  title: 'Documentation & Architecture | LaterBox',
  description:
    'Comprehensive developer guides, system architecture, local SQLite sync, and API reference for LaterBox.',
};

export default function DocsPage() {
  return <DocsReader currentSlug="introduction" />;
}
