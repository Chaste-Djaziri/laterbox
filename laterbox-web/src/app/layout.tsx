import type { Metadata, Viewport } from 'next';
import './globals.css';
import { AuthProvider } from '@/lib/store/AuthContext';
import { ItemProvider } from '@/lib/store/ItemContext';

export const metadata: Metadata = {
  title: {
    default: 'laterbox - Save anything now. Read, watch & organize later.',
    template: '%s | laterbox',
  },
  description:
    'Universal save-for-later memory app. Save articles, YouTube videos, tweets, notes and PDFs across Web, Desktop, iOS, Android, and Browser Extensions with AI enrichment.',
  keywords: [
    'save for later',
    'bookmark manager',
    'read later',
    'laterbox',
    'pocket alternative',
    'instapaper alternative',
    'web capture',
  ],
  authors: [{ name: 'LaterBox' }],
  icons: {
    icon: '/branding/laterbox-icon.png',
    apple: '/branding/laterbox-icon.png',
  },
  openGraph: {
    title: 'laterbox - Save anything now. Read, watch & organize later.',
    description:
      'Universal save-for-later memory app. Save articles, YouTube videos, tweets, notes and PDFs across Web, Desktop, iOS, Android, and Browser Extensions.',
    url: 'https://laterbox.app',
    siteName: 'laterbox',
    images: [
      {
        url: '/branding/laterbox-logo.png',
        width: 1200,
        height: 630,
        alt: 'laterbox logo',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'laterbox - Save anything now. Read, watch & organize later.',
    description: 'Universal save-for-later memory app with AI enrichment.',
    images: ['/branding/laterbox-logo.png'],
  },
};

export const viewport: Viewport = {
  themeColor: '#059669',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-screen bg-zinc-50 dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100 antialiased selection:bg-emerald-500 selection:text-white">
        <AuthProvider>
          <ItemProvider>{children}</ItemProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
