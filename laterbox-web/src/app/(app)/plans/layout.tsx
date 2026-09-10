import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Plans & Subscriptions | LaterBox',
  description: 'Manage your LaterBox Pro subscription, compare plans, and review billing details.',
};

export default function PlansLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
