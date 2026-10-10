'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { DashboardView } from '@/components/inbox/DashboardView';

export default function StarredPage() {
  const { starredItems, loading } = useItems();
  return <DashboardView title="Starred" items={starredItems} loading={loading} />;
}
