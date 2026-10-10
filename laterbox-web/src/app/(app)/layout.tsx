'use client';

import { AccountGate } from '@/lib/auth/AccountGate';
import React from 'react';
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
    </DashboardProvider></AccountGate>
  );
}
