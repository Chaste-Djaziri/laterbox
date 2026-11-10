// laterbox-web/src/app/admin/earnings/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminEarningsView } from '@/components/admin/AdminEarningsView';

export default function AdminEarningsPage() {
  return (
    <>
      <AdminHeader
        title="Earnings"
        subtitle="Commission ledger totals, pending qualification, and payout lifecycle"
      />
      <AdminEarningsView />
    </>
  );
}
