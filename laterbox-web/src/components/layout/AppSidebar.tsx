'use client';

import React, { useState } from 'react';
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
  ChevronsLeft,
  ChevronsRight,
} from 'lucide-react';

interface AppSidebarProps {
  onOpenCapture: () => void;
}

export function AppSidebar({ onOpenCapture }: AppSidebarProps) {
  const pathname = usePathname();
  const { inboxItems } = useItems();
  const { user, isGuest, signOut } = useAuth();
  const [collapsed, setCollapsed] = useState(false);

  const navLinks = [
    {
      href: '/inbox',
      label: 'Inbox',
      icon: <Inbox className="w-4 h-4" />,
      badge: inboxItems.length > 0 ? inboxItems.length : undefined,
    },
    {
      href: '/search',
      label: 'Search',
      icon: <Search className="w-4 h-4" />,
    },
    {
      href: '/library',
      label: 'Library',
      icon: <BookMarked className="w-4 h-4" />,
    },
    {
      href: '/tutorial',
      label: 'Guide',
      icon: <Compass className="w-4 h-4" />,
    },
    {
      href: '/download',
      label: 'Apps',
      icon: <Download className="w-4 h-4" />,
    },
    {
      href: '/settings',
      label: 'Settings',
      icon: <Settings className="w-4 h-4" />,
    },
  ];

  return (
    <aside
      className={`h-screen bg-[#f7f5ee] border-r border-[#e4e0d5] flex flex-col justify-between p-3.5 shrink-0 transition-all duration-200 ${
        collapsed ? 'w-[76px]' : 'w-60'
      }`}
    >
      {/* Top Section */}
      <div className="space-y-4">
        {/* Brand Header */}
        <div className="flex items-center justify-between px-1.5 pt-1">
          <Link href="/" className="flex items-center gap-2.5 group">
            <div className="w-[34px] h-[34px] relative rounded-[9px] overflow-hidden shadow-sm transition-transform group-hover:scale-105 bg-[#e6edb0] p-1 shrink-0">
              <Image
                src="/branding/laterbox-icon.png"
                alt="laterbox"
                fill
                className="object-contain p-0.5"
                priority
              />
            </div>
            {!collapsed && (
              <span className="text-[17px] font-extrabold tracking-tight text-[#171711]">
                laterbox
              </span>
            )}
          </Link>

          <button
            onClick={() => setCollapsed(!collapsed)}
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            className="p-1 rounded-lg text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors"
          >
            {collapsed ? (
              <ChevronsRight className="w-4 h-4" />
            ) : (
              <ChevronsLeft className="w-4 h-4" />
            )}
          </button>
        </div>

        {/* Quick Capture Button */}
        <button
          onClick={onOpenCapture}
          className={`w-full flex items-center ${
            collapsed ? 'justify-center px-0' : 'justify-start px-3.5'
          } gap-2 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-bold text-xs shadow-sm transition-all duration-150 group cursor-pointer`}
          title="Save Item"
        >
          <Plus className="w-4 h-4 transition-transform group-hover:rotate-90 shrink-0" />
          {!collapsed && <span>Save Item</span>}
        </button>

        {/* Divider */}
        <div className="border-b border-[#e4e0d5]/80" />

        {/* Navigation Items */}
        <nav className="space-y-1">
          {navLinks.map(({ href, label, icon, badge }) => {
            const isActive = pathname === href || pathname.startsWith(`${href}/`);
            return (
              <Link
                key={href}
                href={href}
                title={collapsed ? label : undefined}
                className={`flex items-center ${
                  collapsed ? 'justify-center px-0' : 'justify-between px-3'
                } py-2.5 rounded-xl text-xs font-semibold transition-all duration-150 ${
                  isActive
                    ? 'bg-[#e6edb0] text-[#171711] font-bold shadow-none'
                    : 'text-[#6c6b63] hover:bg-[#ebe7dc]/70 hover:text-[#171711]'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  {icon}
                  {!collapsed && <span>{label}</span>}
                </div>
                {!collapsed && badge !== undefined && (
                  <span
                    className={`px-1.5 py-0.2 rounded-md text-[10px] font-mono font-bold ${
                      isActive
                        ? 'bg-[#d8e09e] text-[#171711]'
                        : 'bg-[#ebe7dc] text-[#6c6b63]'
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

      {/* Bottom Profile / Cloud Sync Section */}
      <div className="pt-3 border-t border-[#e4e0d5] space-y-2">
        <div className="flex items-center justify-center">
          <CloudSyncIndicator compact={collapsed} />
        </div>

        {user ? (
          <div className="flex items-center justify-between p-2 rounded-xl bg-[#ebe7dc]/50 border border-[#e4e0d5]/70">
            <div className="flex items-center gap-2 min-w-0">
              <div className="w-7 h-7 rounded-lg bg-[#e6edb0] flex items-center justify-center text-[#171711] shrink-0 font-bold text-xs">
                {user.email?.[0].toUpperCase() || <User className="w-3.5 h-3.5" />}
              </div>
              {!collapsed && (
                <div className="min-w-0">
                  <p className="text-xs font-bold text-[#171711] truncate">
                    {user.email}
                  </p>
                  <p className="text-[10px] text-[#6c6b63] font-medium truncate">Account</p>
                </div>
              )}
            </div>
            {!collapsed && (
              <button
                onClick={() => signOut()}
                title="Sign Out"
                className="p-1 rounded-lg text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc] transition-colors"
              >
                <LogOut className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        ) : (
          <div className="p-2.5 rounded-xl bg-[#ebe7dc]/50 border border-[#e4e0d5]/70 space-y-2">
            <div className="flex items-center gap-2 min-w-0">
              <div className="w-7 h-7 rounded-lg bg-[#e6edb0] flex items-center justify-center text-[#171711] shrink-0 font-bold text-xs">
                G
              </div>
              {!collapsed && (
                <div className="min-w-0">
                  <p className="text-xs font-bold text-[#171711] truncate">
                    Guest Mode
                  </p>
                  <p className="text-[10px] text-[#6c6b63] font-medium truncate">Local storage</p>
                </div>
              )}
            </div>
            {!collapsed && (
              <Link
                href="/login"
                className="w-full inline-flex items-center justify-center gap-1.5 py-1.5 px-2.5 rounded-lg bg-[#171711] hover:bg-[#282723] text-white font-bold text-[11px] shadow-sm transition-all"
              >
                <LogIn className="w-3 h-3" />
                <span>Sign In / Sync</span>
              </Link>
            )}
          </div>
        )}
      </div>
    </aside>
  );
}
