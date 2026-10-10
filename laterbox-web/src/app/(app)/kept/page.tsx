'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { DashboardView } from '@/components/inbox/DashboardView';

export default function KeptPage() {
  const { savedItems, loading } = useItems();
  return <DashboardView title="Kept" items={savedItems} loading={loading} />;
}
