// laterbox-web/src/app/admin/referrals/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminReferralsView } from '@/components/admin/AdminReferralsView';

export default function AdminReferralsPage() {
  return (
    <>
      <AdminHeader
        title="Referrals"
        subtitle="Advocate enrollment, attribution status, and compensation parameters"
      />
      <AdminReferralsView />
    </>
  );
}

