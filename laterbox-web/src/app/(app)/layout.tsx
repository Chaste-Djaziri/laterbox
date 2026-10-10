'use client';

import React from 'react';
import { AppShell } from '@/components/layout/AppShell';
import { DashboardProvider } from '@/lib/store/DashboardContext';

export default function AuthenticatedAppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <DashboardProvider>
      <AppShell>{children}</AppShell>
    </DashboardProvider>
  );
}
