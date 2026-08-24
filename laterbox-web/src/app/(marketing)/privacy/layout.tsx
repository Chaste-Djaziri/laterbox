import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Privacy Policy | LaterBox',
  description:
    'Our commitment to user privacy, zero ad tracking, local-first offline storage, and Supabase RLS data isolation.',
  alternates: {
    canonical: 'https://laterbox.dev/privacy',
  },
  openGraph: {
    title: 'Privacy Policy | LaterBox',
    description:
      'Learn about LaterBox privacy practices, local-first offline architecture, and zero ad tracking guarantee.',
    url: 'https://laterbox.dev/privacy',
  },
};

export default function PrivacyLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
