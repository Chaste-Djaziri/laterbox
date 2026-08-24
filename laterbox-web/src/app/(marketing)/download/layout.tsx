import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Download LaterBox Apps & Browser Extensions | macOS, Windows, Linux, Android',
  description:
    'Download LaterBox for macOS (Apple Silicon & Intel), Windows 10/11 x64, Linux, Android APK/Google Play Beta, and 1-click Chrome & Firefox extensions.',
  alternates: {
    canonical: 'https://laterbox.dev/download',
  },
  openGraph: {
    title: 'Download LaterBox Apps & Browser Extensions',
    description:
      'Native desktop apps, mobile companions, and browser extensions for lightning-fast 1-second capture.',
    url: 'https://laterbox.dev/download',
  },
};

export default function DownloadLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
