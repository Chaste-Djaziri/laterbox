'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { CloudSyncIndicator } from '../ui/CloudSyncIndicator';
import {
  Inbox,
  Search,
  BookMarked,
  Settings,
  Plus,
  Compass,
  Download,
  LogIn,
  LogOut,
  User,
} from 'lucide-react';

interface AppSidebarProps {
  onOpenCapture: () => void;
}

export function AppSidebar({ onOpenCapture }: AppSidebarProps) {
  const pathname = usePathname();
  const { inboxItems } = useItems();
  const { user, isGuest, signOut } = useAuth();

  const navLinks = [
    {
      href: '/inbox',
      label: 'Inbox',
      icon: <Inbox className="w-5 h-5" />,
      badge: inboxItems.length > 0 ? inboxItems.length : undefined,
    },
    {
      href: '/search',
      label: 'Search',
      icon: <Search className="w-5 h-5" />,
    },
    {
      href: '/library',
      label: 'Library',
      icon: <BookMarked className="w-5 h-5" />,
    },
    {
      href: '/tutorial',
      label: 'Guide',
      icon: <Compass className="w-5 h-5" />,
    },
    {
      href: '/download',
      label: 'Apps',
      icon: <Download className="w-5 h-5" />,
    },
    {
      href: '/settings',
      label: 'Settings',
      icon: <Settings className="w-5 h-5" />,
    },
  ];

  return (
    <aside className="w-64 h-screen bg-zinc-50/80 border-r border-zinc-200/80 flex flex-col justify-between p-4 shrink-0 transition-all">
      {/* Top Section */}
      <div className="space-y-6">
        {/* Brand */}
        <div className="flex items-center justify-between px-2">
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="w-8 h-8 relative rounded-xl overflow-hidden shadow-sm transition-transform group-hover:scale-105">
              <Image
                src="/branding/laterbox-icon.png"
                alt="laterbox"
                fill
                className="object-contain"
                priority
              />
            </div>
            <span className="text-xl font-black tracking-tight text-zinc-900">
              laterbox
            </span>
          </Link>
          <CloudSyncIndicator compact />
        </div>

        {/* Quick Capture Button */}
        <button
          onClick={onOpenCapture}
          className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-2xl bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-extrabold text-sm shadow-md shadow-emerald-600/15 transition-all duration-150 group"
        >
          <Plus className="w-4 h-4 transition-transform group-hover:rotate-90" />
          <span>Save Item</span>
        </button>

        {/* Navigation Items */}
        <nav className="space-y-1">
          {navLinks.map(({ href, label, icon, badge }) => {
            const isActive = pathname === href || pathname.startsWith(`${href}/`);
            return (
              <Link
                key={href}
                href={href}
                className={`flex items-center justify-between px-3.5 py-2.5 rounded-2xl text-sm font-bold transition-all duration-150 ${
                  isActive
                    ? 'bg-zinc-900 text-white shadow-sm'
                    : 'text-zinc-600 hover:bg-zinc-200/60 hover:text-zinc-900'
                }`}
              >
                <div className="flex items-center gap-3">
                  {icon}
                  <span>{label}</span>
                </div>
                {badge !== undefined && (
                  <span
                    className={`px-2 py-0.5 rounded-full text-[11px] font-mono font-bold ${
                      isActive
                        ? 'bg-zinc-700 text-zinc-200'
                        : 'bg-zinc-200 text-zinc-600'
                    }`}
                  >
                    {badge}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Bottom User Profile Section */}
      <div className="pt-4 border-t border-zinc-200/80 space-y-3">
        {user ? (
          <div className="flex items-center justify-between p-2 rounded-2xl bg-white border border-zinc-200/60">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600 shrink-0 font-bold text-xs">
                {user.email?.[0].toUpperCase() || <User className="w-4 h-4" />}
              </div>
              <div className="min-w-0">
                <p className="text-xs font-bold text-zinc-900 truncate">
                  {user.email}
                </p>
                <p className="text-[10px] text-zinc-400 font-medium truncate">Logged in</p>
              </div>
            </div>
            <button
              onClick={() => signOut()}
              title="Sign Out"
              className="p-1.5 rounded-xl text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        ) : (
          <div className="p-3 rounded-2xl bg-emerald-50 border border-emerald-200/60 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-extrabold text-emerald-800">
                Guest Mode
              </span>
              <CloudSyncIndicator compact />
            </div>
            <p className="text-[11px] text-emerald-700/80 leading-relaxed">
              Items saved locally. Sign in to sync across your Mac, iPhone, and Android.
            </p>
            <Link
              href="/login"
              className="w-full inline-flex items-center justify-center gap-1.5 py-1.5 px-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-bold text-xs shadow-sm transition-all"
            >
              <LogIn className="w-3.5 h-3.5" />
              <span>Sign In / Sync</span>
            </Link>
          </div>
        )}
      </div>
    </aside>
  );
}
