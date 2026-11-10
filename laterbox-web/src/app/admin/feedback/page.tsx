// laterbox-web/src/app/admin/feedback/page.tsx
'use client';

import { AdminHeader } from '@/components/admin/AdminHeader';
import { AdminFeedbackView } from '@/components/admin/AdminFeedbackView';

export default function AdminFeedbackPage() {
  return (
    <>
      <AdminHeader
        title="Feedback & reports"
        subtitle="Live support submissions, user reports, and triage statuses"
      />
      <AdminFeedbackView />
    </>
  );
}

