// laterbox-web/src/app/admin/overview/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminOverviewView } from '@/components/admin/AdminOverviewView';

export default function AdminOverviewPage() {
  return (
    <>
      <AdminHeader
        title="Overview"
        subtitle="Platform metrics, user acquisition, and financial totals"
      />
      <AdminOverviewView />
    </>
  );
}

