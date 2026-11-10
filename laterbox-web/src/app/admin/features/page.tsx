// laterbox-web/src/app/admin/features/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminFeaturesView } from '@/components/admin/AdminFeaturesView';

export default function AdminFeaturesPage() {
  return (
    <>
      <AdminHeader
        title="Feature controls"
        subtitle="Global switches for referrals, subscription checkout, support, and AI"
      />
      <AdminFeaturesView />
    </>
  );
}
