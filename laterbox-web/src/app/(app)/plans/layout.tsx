import type { Metadata } from 'next';
export const metadata: Metadata = { title: 'Storage Plans | LaterBox', description: 'Manage Free, Plus, and Vault cloud storage plans.' };
export default function PlansLayout({ children }: { children: React.ReactNode }) { return <>{children}</>; }
