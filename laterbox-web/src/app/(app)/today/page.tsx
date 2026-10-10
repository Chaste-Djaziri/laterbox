'use client';

import React, { useMemo } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { scheduleItems } from '@/lib/utils/schedule';
import { DashboardView } from '@/components/inbox/DashboardView';

export default function TodayPage() {
  const { items, now, loading } = useItems();
  const todayItems = useMemo(() => scheduleItems(items, 'today', now), [items, now]);
  return <DashboardView title="Today" items={todayItems} loading={loading} />;
}
