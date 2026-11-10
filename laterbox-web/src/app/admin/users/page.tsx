// laterbox-web/src/app/admin/users/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminUsersView } from '@/components/admin/AdminUsersView';

export default function AdminUsersPage() {
  return (
    <>
      <AdminHeader
        title="Users & roles"
        subtitle="Account permissions, subscription entitlements, and referral statuses"
      />
      <AdminUsersView />
    </>
  );
}

