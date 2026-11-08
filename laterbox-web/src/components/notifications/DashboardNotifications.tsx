// laterbox-web/src/components/notifications/DashboardNotifications.tsx
'use client';

import { CloudOff, Puzzle, ShieldAlert } from 'lucide-react';
import { InboxExtensionGate } from '@/components/inbox/InboxExtensionGate';
import { useAuth } from '@/lib/store/AuthContext';
import { useItems } from '@/lib/store/ItemContext';
import { DashboardNoticeBar, type DashboardNotice } from './DashboardNoticeBar';

/**
 * Dashboard notice sources are intentionally separate from rendering.
 * Add future notices to the array below; DashboardNoticeBar handles switching,
 * action buttons and independent dismissal for every source.
 */
export function DashboardNotifications() {
  const { user, loading } = useAuth();
  const { syncStatus, syncNow } = useItems();

  return (
    <InboxExtensionGate userId={user?.id}>
      {({ disconnected, openSetup }) => {
        const notices: DashboardNotice[] = [];

        if (!loading && !user) {
          notices.push({
            id: 'guest-local-saves',
            icon: ShieldAlert,
            tone: 'warning',
            title: "You're browsing without an account.",
            description: 'Saved items stay on this browser. Log in to enable cloud sync and help protect them if browser data is cleared.',
            actions: [
              { id: 'login', label: 'Log in', href: '/login' },
              { id: 'signup', label: 'Create account', href: '/signup', variant: 'secondary' },
            ],
          });
        }

        if (disconnected) {
          notices.push({
            id: 'browser-extension-disconnected',
            icon: Puzzle,
            tone: 'warning',
            title: 'LaterBox extension is not connected.',
            description: '1-click browser capture is disabled — connect the extension to save articles, videos, and links.',
            actions: [
              { id: 'setup', label: 'Set up extension', onClick: openSetup },
              { id: 'downloads', label: 'Downloads', href: '/downloads', variant: 'secondary' },
            ],
          });
        }

        if (!loading && user && (syncStatus === 'error' || syncStatus === 'offline')) {
          notices.push({
            id: syncStatus === 'error' ? 'cloud-sync-error' : 'working-offline',
            icon: CloudOff,
            tone: syncStatus === 'error' ? 'error' : 'info',
            title: syncStatus === 'error' ? 'Cloud sync needs attention.' : "You're working offline.",
            description: syncStatus === 'error'
              ? 'Some changes may still be waiting on this device. Retry when your connection is available.'
              : 'Your changes remain saved locally and can sync when your connection returns.',
            actions: [
              {
                id: 'retry',
                label: 'Retry sync',
                onClick: () => { void syncNow().catch(() => {}); },
              },
              { id: 'settings', label: 'Settings', href: '/settings', variant: 'secondary' },
            ],
          });
        }

        return <DashboardNoticeBar notices={notices} />;
      }}
    </InboxExtensionGate>
  );
}
