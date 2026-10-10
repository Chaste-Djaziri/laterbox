'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { DashboardView } from '@/components/inbox/DashboardView';

export default function InboxPage() {
  const { inboxItems, loading } = useItems();
  return <DashboardView title="Inbox" items={inboxItems} loading={loading} />;
}
