// laterbox-web/src/app/admin/maintenance/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminMaintenanceView } from '@/components/admin/AdminMaintenanceView';

export default function AdminMaintenancePage() {
  return (
    <>
      <AdminHeader
        title="Maintenance"
        subtitle="Live, role-restricted LaterBox operations"
      />
      <AdminMaintenanceView />
    </>
  );
}

