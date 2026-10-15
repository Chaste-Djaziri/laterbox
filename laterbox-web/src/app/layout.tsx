import type { Metadata, Viewport } from 'next';
import './globals.css';
import { AuthProvider } from '@/lib/store/AuthContext';
import { ItemProvider } from '@/lib/store/ItemContext';
import { BillingProvider } from '@/lib/store/BillingContext';
import { WebUpdateBanner } from '@/components/ui/WebUpdateBanner';

export const metadata: Metadata = {
  metadataBase: new URL('https://laterbox.dev'),
  title: { default: 'LaterBox', template: '%s | LaterBox' },
  applicationName: 'LaterBox',
  icons: { icon: '/branding/laterbox-icon.png', apple: '/branding/laterbox-icon.png' },
  manifest: '/manifest.webmanifest',
};

export const viewport: Viewport = {
  themeColor: '#171711',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  viewportFit: 'cover',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-[#f7f5ee] text-[#171711] antialiased selection:bg-[#e6edb0] selection:text-[#171711]">
        <AuthProvider>
          <BillingProvider>
            <ItemProvider>
              {children}
              <WebUpdateBanner />
            </ItemProvider>
          </BillingProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
