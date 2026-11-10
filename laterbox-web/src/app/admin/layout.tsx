// laterbox-web/src/app/admin/layout.tsx
import type { Metadata } from 'next';
import { AdminLayoutClient } from '@/components/admin/AdminLayoutClient';

export const metadata: Metadata = {
  title: 'LaterBox Control Center · Platform Administration',
  description: 'Role-restricted administrative operations and live service monitoring for LaterBox.',
  robots: { index: false, follow: false },
};

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return <AdminLayoutClient>{children}</AdminLayoutClient>;
}

