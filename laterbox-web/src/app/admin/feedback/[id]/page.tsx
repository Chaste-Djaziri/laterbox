// laterbox-web/src/app/admin/feedback/[id]/page.tsx
'use client';

import { use } from 'react';
import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminFeedbackDetailView } from '@/components/admin/AdminFeedbackDetailView';

export default function AdminFeedbackDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  return (
    <>
      <AdminHeader
        title="Feedback details"
        subtitle="Full submission review, sender contact metadata, and status triage"
      />
      <AdminFeedbackDetailView ticketId={id} />
    </>
  );
}
