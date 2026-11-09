// laterbox-web/src/app/(marketing)/layout.tsx
import type { ReactNode } from 'react';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { SmoothScrollProvider } from '@/components/marketing/SmoothScrollProvider';

export default function MarketingLayout({ children }: { children: ReactNode }) {
  return (
    <SmoothScrollProvider>
      <div className="flex min-h-screen flex-col bg-[#f8f9f4] text-[#192018]">
        <a
          href="#main-content"
          className="sr-only fixed left-4 top-4 z-[100] rounded-full bg-[#e6edb0] px-5 py-3 text-sm font-bold text-[#192018] shadow-xl focus:not-sr-only"
        >
          Skip to main content
        </a>
        <Header />
        <main id="main-content" tabIndex={-1} className="min-w-0 flex-1">
          {children}
        </main>
        <Footer />
      </div>
    </SmoothScrollProvider>
  );
}
