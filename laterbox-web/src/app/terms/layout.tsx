import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Terms of Service | LaterBox',
  description:
    'Terms of service, user content ownership, and platform synchronization agreement for LaterBox.',
  alternates: {
    canonical: 'https://laterbox.dev/terms',
  },
  openGraph: {
    title: 'Terms of Service | LaterBox',
    description:
      'Review LaterBox terms of service and content ownership policies.',
    url: 'https://laterbox.dev/terms',
  },
};

export default function TermsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
