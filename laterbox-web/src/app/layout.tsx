import type { Metadata, Viewport } from 'next';
import './globals.css';
import { AuthProvider } from '@/lib/store/AuthContext';
import { ItemProvider } from '@/lib/store/ItemContext';
import { WebUpdateBanner } from '@/components/ui/WebUpdateBanner';

export const metadata: Metadata = {
  metadataBase: new URL('https://laterbox.dev'),
  title: {
    default: 'LaterBox - Save anything now. Read, watch & organize later.',
    template: '%s | LaterBox',
  },
  description:
    'Universal save-for-later productivity and knowledge memory app. Save articles, YouTube videos, tweets, notes, and PDF attachments across Web, macOS, Windows, Linux, Android, iOS, and Browser Extensions with auto AI enrichment.',
  keywords: [
    'save for later',
    'bookmark manager',
    'read later app',
    'laterbox',
    'pocket alternative',
    'instapaper alternative',
    'web clipper',
    'browser extension',
    'offline reader',
    'cross platform bookmark sync',
  ],
  authors: [{ name: 'LaterBox', url: 'https://laterbox.dev' }],
  creator: 'LaterBox',
  publisher: 'LaterBox',
  applicationName: 'LaterBox',
  alternates: {
    canonical: 'https://laterbox.dev',
  },
  icons: {
    icon: [
      { url: '/branding/laterbox-icon.png', sizes: '32x32', type: 'image/png' },
      { url: '/branding/laterbox-icon.png', sizes: '192x192', type: 'image/png' },
    ],
    apple: [
      { url: '/branding/laterbox-icon.png', sizes: '180x180', type: 'image/png' },
    ],
  },
  manifest: '/manifest.webmanifest',
  openGraph: {
    title: 'LaterBox - Save anything now. Read, watch & organize later.',
    description:
      'Universal save-for-later memory app. Save articles, YouTube videos, tweets, notes, and file attachments across Web, Desktop, Mobile, and Browser Extensions.',
    url: 'https://laterbox.dev',
    siteName: 'LaterBox',
    images: [
      {
        url: '/branding/laterbox-logo.png',
        width: 1200,
        height: 630,
        alt: 'LaterBox - Save for later memory app',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'LaterBox - Save anything now. Read, watch & organize later.',
    description: 'Universal save-for-later memory app with AI enrichment.',
    images: ['/branding/laterbox-logo.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
};

export const viewport: Viewport = {
  themeColor: '#171711',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
};

const jsonLdSchema = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'SoftwareApplication',
      '@id': 'https://laterbox.dev/#software',
      name: 'LaterBox',
      applicationCategory: 'ProductivityApplication',
      operatingSystem: 'Web, macOS, Windows, Linux, Android, iOS, Chrome, Firefox',
      offers: {
        '@type': 'Offer',
        price: '0',
        priceCurrency: 'USD',
      },
      description:
        'Universal save-for-later memory app. Save articles, YouTube videos, tweets, notes, and attachments across Web, Desktop, Mobile, and Browser Extensions.',
      url: 'https://laterbox.dev',
      screenshot: 'https://laterbox.dev/branding/laterbox-logo.png',
      author: {
        '@type': 'Organization',
        name: 'LaterBox',
        url: 'https://laterbox.dev',
      },
    },
    {
      '@type': 'WebSite',
      '@id': 'https://laterbox.dev/#website',
      url: 'https://laterbox.dev',
      name: 'LaterBox',
      description: 'Save anything now. Read, watch & organize later.',
      publisher: {
        '@type': 'Organization',
        name: 'LaterBox',
        url: 'https://laterbox.dev',
        logo: {
          '@type': 'ImageObject',
          url: 'https://laterbox.dev/branding/laterbox-logo.png',
        },
      },
    },
    {
      '@type': 'Organization',
      '@id': 'https://laterbox.dev/#organization',
      name: 'LaterBox',
      url: 'https://laterbox.dev',
      logo: 'https://laterbox.dev/branding/laterbox-logo.png',
      sameAs: ['https://github.com/Chaste-Djaziri/laterbox'],
    },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdSchema) }}
        />
      </head>
      <body className="min-h-screen bg-[#f7f5ee] text-[#171711] antialiased selection:bg-[#e6edb0] selection:text-[#171711]">
        <AuthProvider>
          <ItemProvider>
            {children}
            <WebUpdateBanner />
          </ItemProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
