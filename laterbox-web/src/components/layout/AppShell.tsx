'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { AppSidebar } from './AppSidebar';
import { QuickCaptureModal } from '../inbox/QuickCaptureModal';
import { CloudSyncIndicator } from '../ui/CloudSyncIndicator';
import { useItems } from '@/lib/store/ItemContext';
import { Inbox, Search, BookMarked, Settings, Plus } from 'lucide-react';

export function AppShell({ children }: { children: React.ReactNode }) {
  const [captureOpen, setCaptureOpen] = useState(false);
  const pathname = usePathname();
  const { inboxItems } = useItems();

  // Keyboard shortcut: meta+k or 'c' to open quick capture
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (
        (e.metaKey || e.ctrlKey) &&
        e.key.toLowerCase() === 'k' &&
        !(e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement)
      ) {
        e.preventDefault();
        setCaptureOpen(true);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const mobileNavItems = [
    { href: '/inbox', label: 'Inbox', icon: <Inbox className="w-5 h-5" />, badge: inboxItems.length || undefined },
    { href: '/search', label: 'Search', icon: <Search className="w-5 h-5" /> },
    { href: '/library', label: 'Library', icon: <BookMarked className="w-5 h-5" /> },
    { href: '/settings', label: 'Settings', icon: <Settings className="w-5 h-5" /> },
  ];

  return (
    <div className="flex h-screen w-full bg-[#f7f5ee] overflow-hidden text-[#171711]">
      {/* Desktop Sidebar */}
      <div className="hidden md:flex shrink-0">
        <AppSidebar onOpenCapture={() => setCaptureOpen(true)} />
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-[#f7f5ee]">
        {/* Mobile Top Header */}
        <header className="md:hidden flex items-center justify-between px-4 h-14 bg-[#f7f5ee] border-b border-[#e4e0d5] shrink-0 z-20">
          <Link href="/inbox" className="flex items-center gap-2">
            <div className="w-7 h-7 relative rounded-lg overflow-hidden bg-[#e6edb0] p-1">
              <Image src="/branding/laterbox-icon.png" alt="laterbox" fill sizes="28px" className="object-contain p-0.5" />
            </div>
            <span className="text-lg font-black tracking-tight text-[#171711]">laterbox</span>
          </Link>
          <div className="flex items-center gap-2">
            <CloudSyncIndicator compact />
            <button
              onClick={() => setCaptureOpen(true)}
              className="p-2 rounded-xl bg-[#171711] active:bg-black text-white font-bold"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>
        </header>

        {/* Scrollable Page Content */}
        <main className="flex-1 overflow-y-auto pb-20 md:pb-0">{children}</main>

        {/* Mobile Bottom Navigation Bar */}
        <nav className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-[#f7f5ee]/95 backdrop-blur-lg border-t border-[#e4e0d5] flex items-center justify-around px-2 z-30">
          {mobileNavItems.map(({ href, label, icon, badge }) => {
            const isActive = pathname === href || pathname.startsWith(`${href}/`);
            return (
              <Link
                key={href}
                href={href}
                className={`relative flex flex-col items-center justify-center py-1 px-3.5 rounded-xl transition-colors ${
                  isActive
                    ? 'text-[#171711] font-bold bg-[#e6edb0]'
                    : 'text-[#6c6b63] font-medium hover:text-[#171711]'
                }`}
              >
                <div className="relative">
                  {icon}
                  {badge !== undefined && (
                    <span className="absolute -top-1 -right-2 px-1 min-w-4 h-4 rounded-full bg-[#171711] text-white text-[9px] font-mono font-bold flex items-center justify-center">
                      {badge}
                    </span>
                  )}
                </div>
                <span className="text-[10px] tracking-tight mt-0.5">{label}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Quick Capture Floating Modal */}
      <QuickCaptureModal isOpen={captureOpen} onClose={() => setCaptureOpen(false)} />
    </div>
  );
}
