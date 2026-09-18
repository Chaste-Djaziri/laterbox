'use client';

import React, { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { presentEntitlement } from '@/lib/billing/types';
import { scheduleItems } from '@/lib/utils/schedule';
import { CloudSyncIndicator } from '../ui/CloudSyncIndicator';
import {
  Home,
  CalendarDays,
  Clock,
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
  Crown,
  Archive,
} from 'lucide-react';

interface AppSidebarProps {
  onOpenCapture: () => void;
}

export function AppSidebar({ onOpenCapture }: AppSidebarProps) {
  const pathname = usePathname();
  const { inboxItems, items } = useItems();
  const { user, isGuest, signOut } = useAuth();
  const { entitlement, isPro, manage } = useBilling();
  const [collapsed, setCollapsed] = useState(false);
  const [now, setNow] = useState(() => new Date());
  const plan = useMemo(() => presentEntitlement(entitlement, now), [entitlement, now]);

  useEffect(() => {
    if (!entitlement.phaseEndsAt) return;
    const timer = window.setInterval(() => setNow(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, [entitlement.phaseEndsAt]);

  const todayCount = useMemo(() => scheduleItems(items, 'today', now).length, [items, now]);
  const upcomingCount = useMemo(() => scheduleItems(items, 'upcoming', now).length, [items, now]);
  const somedayCount = useMemo(() => scheduleItems(items, 'someday', now).length, [items, now]);

  const coreLinks = [
    { href: '/home', label: 'Home', icon: <Home className="w-4 h-4" /> },
    {
      href: '/inbox',
      label: 'Inbox',
      icon: <Inbox className="w-4 h-4" />,
      badge: inboxItems.length > 0 ? inboxItems.length : undefined,
    },
    {
      href: '/today',
      label: 'Today',
      icon: <Clock className="w-4 h-4" />,
      badge: todayCount > 0 ? todayCount : undefined,
    },
    {
      href: '/upcoming',
      label: 'Upcoming',
      icon: <CalendarDays className="w-4 h-4" />,
      badge: upcomingCount > 0 ? upcomingCount : undefined,
    },
    {
      href: '/someday',
      label: 'Someday',
      icon: <Archive className="w-4 h-4" />,
      badge: somedayCount > 0 ? somedayCount : undefined,
    },
  ];

  const libraryLinks = [
    {
      href: '/library',
      label: 'All Items',
      icon: <BookMarked className="w-4 h-4" />,
    },
    {
      href: '/search',
      label: 'Search',
      icon: <Search className="w-4 h-4" />,
    },
  ];

  const systemLinks = [
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
      href: '/plans',
      label: 'Plans',
      icon: <Crown className="w-4 h-4" />,
    },
    {
      href: '/settings',
      label: 'Settings',
      icon: <Settings className="w-4 h-4" />,
    },
  ];

  const isLinkActive = (href: string) => {
    if (href === '/home') return pathname === '/home' || pathname === '/';
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  const renderLinkItem = ({ href, label, icon, badge }: { href: string; label: string; icon: React.ReactNode; badge?: number }) => {
    const isActive = isLinkActive(href);
    return (
      <Link
        key={href}
        href={href}
        title={collapsed ? label : undefined}
        className={`relative flex items-center ${
          collapsed ? 'justify-center px-0' : 'justify-between px-3'
        } py-2.5 rounded-xl text-xs transition-all duration-150 ${
          isActive
            ? 'bg-white border border-[#e4e0d5]/80 text-[#171711] font-bold shadow-2xs'
            : 'text-[#6c6b63] font-medium hover:bg-[#ebe7dc]/50 hover:text-[#171711]'
        }`}
      >
        {isActive && (
          <span className="w-1.5 h-6 bg-[#171711] rounded-r-md absolute left-0 top-1/2 -translate-y-1/2" />
        )}
        <div className="flex items-center gap-2.5 min-w-0">
          <span className={`shrink-0 ${isActive ? 'text-[#171711]' : 'text-[#8e8d87]'}`}>
            {icon}
          </span>
          {!collapsed && <span className="truncate">{label}</span>}
        </div>
        {!collapsed && badge !== undefined && (
          <span className="w-5 h-5 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black flex items-center justify-center shrink-0">
            {badge}
          </span>
        )}
      </Link>
    );
  };

  return (
    <aside
      className={`h-screen overflow-y-auto bg-[#faf8f5] border-r border-[#e4e0d5] flex flex-col justify-between p-3.5 shrink-0 transition-all duration-200 ${
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
                sizes="34px"
                className="object-contain p-0.5"
                priority
              />
            </div>
            {!collapsed && (
              <span className="text-[17px] font-extrabold tracking-tight text-[#171711]">
                LaterBox
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
            collapsed ? 'justify-center px-0' : 'justify-center px-3'
          } py-2.5 rounded-xl bg-[#171711] hover:bg-black active:bg-[#0f0f0e] text-white font-black text-xs tracking-wider shadow-xs transition-all duration-150 group cursor-pointer`}
          title="Add to LaterBox"
        >
          <Plus className="w-3.5 h-3.5 transition-transform group-hover:rotate-90 shrink-0 mr-1" />
          {!collapsed && <span>+ ADD TO LATERBOX</span>}
        </button>

        {/* Main Navigation Items */}
        <nav className="space-y-1">
          {coreLinks.map(renderLinkItem)}
        </nav>

        {/* Library Section */}
        <div className="pt-2">
          {!collapsed && (
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] px-3 block mb-1">
              LIBRARY
            </span>
          )}
          <nav className="space-y-1">
            {libraryLinks.map(renderLinkItem)}
          </nav>
        </div>

        {/* Activity / System Section */}
        <div className="pt-2">
          {!collapsed && (
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] px-3 block mb-1">
              ACTIVITY
            </span>
          )}
          <nav className="space-y-1">
            {systemLinks.map(renderLinkItem)}
          </nav>
        </div>
      </div>

      {/* Bottom Profile / Cloud Sync Section */}
      <div className="pt-3 border-t border-[#e4e0d5] space-y-2">
        <div className="rounded-xl bg-[#171711] p-2.5 text-white" title={collapsed ? plan.label : undefined}>
          <div className={`flex items-center ${collapsed ? 'justify-center' : 'gap-2'}`}>
            <Crown className={`size-4 shrink-0 ${plan.tone === 'warning' ? 'text-amber-300' : 'text-[#d7ff27]'}`} />
            {!collapsed && <span className="min-w-0 flex-1 truncate text-[11px] font-black">{plan.label}</span>}
          </div>
          {!collapsed && plan.progress !== null && <div className="mt-2 h-1 overflow-hidden rounded-full bg-white/15"><div className={`h-full ${plan.tone === 'warning' ? 'bg-amber-300' : 'bg-[#d7ff27]'}`} style={{ width: `${Math.round(plan.progress * 100)}%` }} /></div>}
          {!collapsed && (isPro && entitlement.provider === 'paddle' ? <button type="button" onClick={() => void manage()} className={`mt-2 text-[10px] font-black ${plan.tone === 'warning' ? 'text-amber-300' : 'text-[#d7ff27]'}`}>{plan.actionLabel}</button> : <Link href="/plans" className="mt-2 block text-[10px] font-black text-[#d7ff27]">{plan.actionLabel}</Link>)}
        </div>
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
