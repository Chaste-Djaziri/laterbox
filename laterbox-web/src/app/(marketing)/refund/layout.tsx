import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Refund Policy | LaterBox',
  description:
    'LaterBox subscription refund and cancellation policy. Learn about our strict no-refund policy, 14-day free trial, and self-serve cancellation.',
  alternates: {
    canonical: 'https://laterbox.dev/refund',
  },
  openGraph: {
    title: 'Refund Policy | LaterBox',
    description:
      'Review the LaterBox refund and cancellation policy for LaterBox Pro subscriptions.',
    url: 'https://laterbox.dev/refund',
  },
};

export default function RefundLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
