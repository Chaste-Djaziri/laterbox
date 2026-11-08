// laterbox-web/src/app/(app)/settings/layout.tsx
import type { ReactNode } from 'react';
import { SettingsSidebar } from '@/components/settings/SettingsSidebar';

export default function SettingsLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex h-full min-h-0 w-full flex-col overflow-hidden bg-[#f9f8f3] md:flex-row">
      <SettingsSidebar />
      <div id="settings-content" className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain">
        {children}
      </div>
    </div>
  );
}
