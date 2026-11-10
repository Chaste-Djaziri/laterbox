import type { Metadata, Viewport } from 'next';
import './globals.css';
import { AuthProvider } from '@/lib/store/AuthContext';
import { ItemProvider } from '@/lib/store/ItemContext';
import { BillingProvider } from '@/lib/store/BillingContext';
import { WebUpdateBanner } from '@/components/ui/WebUpdateBanner';
import { MaintenanceOverlay } from '@/components/platform/MaintenanceOverlay';

// Preserve the Whop Pixel payload exactly as supplied by the business.
const WHOP_PIXEL = `!function(w,d,s,u,n,a,b){if(w[n])return;a=w[n]={q:[],t:+new Date,s:[],o:u,track:function(){a.q.push([+new Date].concat([].slice.call(arguments)))},setScope:function(){a.s=[].slice.call(arguments).filter(function(x){return typeof x==="string"});a.q.push([+new Date,"setScope"].concat(a.s))},scope:function(){var c=[].slice.call(arguments);return{track:function(){a.q.push([+new Date].concat([].slice.call(arguments)).concat([{__scope:c}]))}}}};b=d.createElement(s);b.async=1;b.src=u+"/s.js";d.getElementsByTagName(s)[0].parentNode.insertBefore(b,d.getElementsByTagName(s)[0])}(window,document,"script","https://t.whop.tw","whop");whop.setScope("biz_VzpmkYvhtl23Ma");whop.track("page");`;

export const metadata: Metadata = {
  metadataBase: new URL('https://laterbox.dev'),
  title: { default: 'LaterBox', template: '%s | LaterBox' },
  applicationName: 'LaterBox',
  icons: { icon: '/branding/laterbox-icon.png', apple: '/branding/laterbox-icon.png' },
  manifest: '/manifest.webmanifest',
  itunes: {
    appId: '6804139119',
    appArgument: 'https://laterbox.dev',
  },
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
      <head>
        <script dangerouslySetInnerHTML={{ __html: WHOP_PIXEL }} />
      </head>
      <body className="min-h-screen bg-[#f7f5ee] text-[#171711] antialiased selection:bg-[#e6edb0] selection:text-[#171711]">
        <AuthProvider>
          <BillingProvider>
            <ItemProvider>
              {children}
              <WebUpdateBanner />
              <MaintenanceOverlay />
            </ItemProvider>
          </BillingProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
