// laterbox-web/src/components/admin/AdminOperationsPanel.tsx
'use client';

import { AdminFeedbackView } from './AdminFeedbackView';
import { AdminFeaturesView } from './AdminFeaturesView';
import { AdminMaintenanceView } from './AdminMaintenanceView';

export function AdminOperationsPanel({ view }: { view: 'feedback' | 'features' | 'maintenance' }) {
  if (view === 'feedback') return <AdminFeedbackView />;
  if (view === 'features') return <AdminFeaturesView />;
  if (view === 'maintenance') return <AdminMaintenanceView />;
  return null;
}
