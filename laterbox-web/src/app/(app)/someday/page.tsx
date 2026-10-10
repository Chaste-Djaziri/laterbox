'use client';

import React, { useMemo } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { scheduleItems } from '@/lib/utils/schedule';
import { DashboardView } from '@/components/inbox/DashboardView';

export default function SomedayPage() {
  const { items, now, loading } = useItems();
  const somedayItems = useMemo(() => scheduleItems(items, 'someday', now), [items, now]);
  return <DashboardView title="Someday" items={somedayItems} loading={loading} />;
}
