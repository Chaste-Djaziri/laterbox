// laterbox-web/src/app/admin/plans/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminPlansView } from '@/components/admin/AdminPlansView';

export default function AdminPlansPage() {
  return (
    <>
      <AdminHeader
        title="Storage plans"
        subtitle="Whop product catalog, SKU mappings, and assigned byte quotas"
      />
      <AdminPlansView />
    </>
  );
}
