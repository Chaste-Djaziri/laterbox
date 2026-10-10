'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { DashboardView } from '@/components/inbox/DashboardView';

export default function ArchivedPage() {
  const { archivedItems, loading } = useItems();
  return <DashboardView title="Archived" items={archivedItems} loading={loading} />;
}
