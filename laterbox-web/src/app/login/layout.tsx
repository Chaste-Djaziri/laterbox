import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Sign In or Create Account | LaterBox',
  description:
    'Sign in to sync your saved articles, videos, and reading queues seamlessly across desktop, mobile, and browser extensions.',
  alternates: {
    canonical: 'https://laterbox.dev/login',
  },
  openGraph: {
    title: 'Sign In to LaterBox',
    description:
      'Access your saved items, reading lists, and notes across all your devices.',
    url: 'https://laterbox.dev/login',
  },
};

export default function LoginLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
