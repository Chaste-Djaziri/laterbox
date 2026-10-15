import type { Metadata } from 'next';
export const metadata: Metadata = { robots: { index: false, follow: true } };
import { AccountGate } from '@/lib/auth/AccountGate';
import React from 'react';
import { MobileBlockOverlay } from '@/components/ui/MobileBlockOverlay';
import { AppShell } from '@/components/layout/AppShell';
import { DashboardProvider } from '@/lib/store/DashboardContext';

export default function AuthenticatedAppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AccountGate><DashboardProvider>
      <AppShell>{children}</AppShell>
      <MobileBlockOverlay />
    </DashboardProvider></AccountGate>
  );
}
