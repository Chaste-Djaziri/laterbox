// laterbox-web/src/components/admin/AdminSidebar.tsx
'use client';

import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import {
  Activity,
  ArrowUpRight,
  CalendarClock,
  CreditCard,
  LayoutDashboard,
  MessageSquareText,
  Shield,
  SlidersHorizontal,
  Users,
  Wallet,
  X,
  type LucideIcon,
} from 'lucide-react';
import { useAdmin } from './AdminContext';

export interface AdminNavItem {
  href: string;
  title: string;
  icon: LucideIcon;
  badge?: string | number;
}

export const ADMIN_NAV_ITEMS: AdminNavItem[] = [
  { href: '/admin/overview', title: 'Overview', icon: LayoutDashboard },
  { href: '/admin/users', title: 'Users & roles', icon: Users },
  { href: '/admin/plans', title: 'Storage plans', icon: CreditCard },
  { href: '/admin/referrals', title: 'Referrals', icon: Activity },
  { href: '/admin/earnings', title: 'Earnings', icon: Wallet },
  { href: '/admin/feedback', title: 'Feedback & reports', icon: MessageSquareText },
  { href: '/admin/features', title: 'Feature controls', icon: SlidersHorizontal },
  { href: '/admin/maintenance', title: 'Maintenance', icon: CalendarClock },
  { href: '/admin/operations', title: 'Operations', icon: Shield },
];

interface AdminSidebarProps {
  mobileOpen?: boolean;
  onCloseMobile?: () => void;
}

export function AdminSidebar({ mobileOpen = false, onCloseMobile }: AdminSidebarProps) {
  const pathname = usePathname();
  const { data, operations } = useAdmin();

  const isCurrentActive = (href: string) => {
    if (href === '/admin/overview') {
      return pathname === '/admin' || pathname === '/admin/overview';
    }
    if (href === '/admin/plans') {
      return pathname === '/admin/plans' || pathname === '/admin/storage';
    }
    if (href === '/admin/operations') {
      return pathname === '/admin/operations' || pathname === '/admin/settings';
    }
    return pathname === href || pathname.startsWith(href + '/');
  };

  const pendingFeedbackCount = operations?.tickets?.filter(t => t.status === 'open').length ?? 0;

  const content = (
    <div className="flex h-full w-full flex-col justify-between p-5">
      {/* Top Brand & Navigation */}
      <div className="flex flex-col">
        {/* Brand Header */}
        <div className="flex items-center justify-between pb-6">
          <Link href="/admin/overview" className="flex items-center gap-3 group focus:outline-none">
            <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#e6edb0] font-black text-[#171711] shadow-sm transition-transform group-hover:scale-105">
              <span className="text-sm font-black tracking-tight">LB</span>
            </div>
            <div>
              <p className="font-bold text-base text-[#171711] leading-tight">LaterBox</p>
              <p className="text-xs text-[#677362] font-medium">Control center</p>
            </div>
          </Link>
          {onCloseMobile && (
            <button
              type="button"
              onClick={onCloseMobile}
              className="lg:hidden rounded-lg p-1.5 text-[#677362] hover:bg-[#e9ebe0] transition-colors"
              aria-label="Close sidebar"
            >
              <X size={18} />
            </button>
          )}
        </div>

        {/* Section Title */}
        <p className="mb-2 mt-4 text-[11px] font-semibold uppercase tracking-widest text-[#677362]">
          Workspace
        </p>

        {/* Navigation list */}
        <nav aria-label="Admin Navigation" className="space-y-1 overflow-y-auto max-h-[calc(100vh-280px)] pr-1">
          {ADMIN_NAV_ITEMS.map(item => {
            const Icon = item.icon;
            const active = isCurrentActive(item.href);
            const badgeCount = item.href === '/admin/feedback' && pendingFeedbackCount > 0 ? pendingFeedbackCount : undefined;

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onCloseMobile}
                aria-current={active ? 'page' : undefined}
                className={`flex items-center justify-between rounded-xl px-4 py-3 text-sm font-semibold transition-all ${
                  active
                    ? 'bg-[#e6edb0] text-[#171711] shadow-[0_1px_4px_rgba(23,23,17,0.05)] font-bold'
                    : 'text-[#677362] hover:bg-[#edf0e4] hover:text-[#171711]'
                }`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  <Icon size={18} strokeWidth={active ? 2.4 : 1.9} className={active ? 'text-[#171711]' : 'text-[#677362]'} />
                  <span className="truncate">{item.title}</span>
                </div>
                {badgeCount !== undefined && (
                  <span className="ml-2 inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-[#171711] px-1.5 text-[10px] font-bold text-white">
                    {badgeCount}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Access footer card */}
      <div className="mt-6 rounded-2xl border border-[#e4e5d9] bg-white/80 p-4 shadow-sm backdrop-blur-sm">
        <p className="text-[10px] font-bold uppercase tracking-widest text-[#677362]">Access</p>
        <p className="mt-1 text-sm font-bold capitalize text-[#171711]">
          {data?.role ?? 'Restricted'}
        </p>
        <Link
          href="/inbox"
          className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-[#435b34] hover:text-[#23351a] hover:underline"
        >
          <span>Open LaterBox</span>
          <ArrowUpRight size={13} />
        </Link>
      </div>
    </div>
  );

  return (
    <>
      {/* Desktop sidebar: ALWAYS attached flush to left screen edge */}
      <aside
        aria-label="Platform administration"
        className="hidden lg:flex lg:sticky lg:top-0 lg:h-screen lg:w-64 lg:shrink-0 lg:flex-col lg:border-r lg:border-[#e4e5d9] lg:bg-[#f7f5ee] z-20"
      >
        {content}
      </aside>

      {/* Mobile drawer with backdrop */}
      {mobileOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex lg:hidden"
        >
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-[#171711]/40 backdrop-blur-sm transition-opacity"
            onClick={onCloseMobile}
            aria-hidden="true"
          />
          {/* Sidebar Drawer */}
          <aside className="relative z-10 flex h-full w-72 max-w-[85vw] flex-col border-r border-[#e4e5d9] bg-[#f7f5ee] shadow-2xl">
            {content}
          </aside>
        </div>
      )}
    </>
  );
}

