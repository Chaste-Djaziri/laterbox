'use client';

import React, { useMemo } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { scheduleItems } from '@/lib/utils/schedule';
import { DashboardView } from '@/components/inbox/DashboardView';

export default function UpcomingPage() {
  const { items, now, loading } = useItems();
  const upcomingItems = useMemo(() => scheduleItems(items, 'upcoming', now), [items, now]);
  return <DashboardView title="Upcoming" items={upcomingItems} loading={loading} />;
}
