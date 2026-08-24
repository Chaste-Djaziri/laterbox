import React from 'react';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen flex flex-col justify-between bg-[#f7f5ee] text-[#171711]">
      <Header />
      <main className="flex-1">{children}</main>
      <Footer />
    </div>
  );
}
