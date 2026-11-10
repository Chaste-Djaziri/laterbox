// laterbox-web/src/app/admin/operations/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminOperationsView } from '@/components/admin/AdminOperationsView';

export default function AdminOperationsPage() {
  return (
    <>
      <AdminHeader
        title="Operations"
        subtitle="Safeguards, access permissions, and production security rules"
      />
      <AdminOperationsView />
    </>
  );
}

