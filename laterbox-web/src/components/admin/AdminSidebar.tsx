// laterbox-web/src/components/admin/AdminSidebar.tsx
'use client';

import { useEffect, useState, type FocusEvent, type MouseEvent } from 'react';
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
  const [tooltip, setTooltip] = useState<{ label: string; left: number; top: number } | null>(null);
  const [userAppUrl, setUserAppUrl] = useState('/inbox');
  const [isExternalApp, setIsExternalApp] = useState(false);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
      setUserAppUrl(isLocal ? '/inbox' : 'https://app.laterbox.dev/inbox');
      setIsExternalApp(!isLocal);
    }
  }, []);

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

  const pendingFeedbackCount = operations?.tickets?.filter((t) => t.status === 'open').length ?? 0;

  const showTooltip = (element: HTMLElement, label: string) => {
    const bounds = element.getBoundingClientRect();
    setTooltip({
      label,
      left: bounds.right + 14,
      top: Math.max(24, Math.min(window.innerHeight - 24, bounds.top + bounds.height / 2)),
    });
  };

  const tooltipHandlers = (label: string) => ({
    onMouseEnter: (event: MouseEvent<HTMLElement>) => showTooltip(event.currentTarget, label),
    onMouseLeave: () => setTooltip(null),
    onFocus: (event: FocusEvent<HTMLElement>) => showTooltip(event.currentTarget, label),
    onBlur: () => setTooltip(null),
  });

  useEffect(() => {
    const hideOnScroll = () => setTooltip(null);
    document.addEventListener('scroll', hideOnScroll, true);
    window.addEventListener('resize', hideOnScroll);
    return () => {
      document.removeEventListener('scroll', hideOnScroll, true);
      window.removeEventListener('resize', hideOnScroll);
    };
  }, []);

  const railItemClass = (active: boolean) =>
    `relative group flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl border transition-all duration-150 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#758a50] ${
      active
        ? 'border-[#d3df9e] bg-[#e6edb0] text-[#21291c] shadow-[0_2px_8px_rgba(30,42,20,0.06)]'
        : 'border-transparent text-[#85877c] hover:bg-white hover:text-[#171711]'
    }`;

  const renderRailLink = ({
    href,
    title,
    icon: Icon,
    badge,
  }: {
    href: string;
    title: string;
    icon: LucideIcon;
    badge?: number;
  }) => {
    const active = isCurrentActive(href);
    const tooltipText = badge ? `${title} (${badge})` : title;

    return (
      <Link
        key={href}
        href={href}
        aria-label={title}
        aria-current={active ? 'page' : undefined}
        {...tooltipHandlers(tooltipText)}
        onClick={() => setTooltip(null)}
        className={railItemClass(active)}
      >
        <Icon className="h-[26px] w-[26px]" strokeWidth={active ? 2.3 : 1.85} aria-hidden="true" />
        {Boolean(badge) && (
          <span
            aria-hidden="true"
            className="absolute -right-0.5 -top-0.5 flex h-[17px] min-w-[17px] items-center justify-center rounded-full border-2 border-[#f7f5ee] bg-[#20271c] px-0.5 text-[9px] font-black leading-none text-white"
          >
            {Math.min(badge ?? 0, 99)}
          </span>
        )}
      </Link>
    );
  };

  return (
    <>
      {/* Desktop collapsed icon sidebar rail (identical design to user dashboard AppSidebar) */}
      <aside
        aria-label="Platform administration"
        className="relative z-30 hidden md:flex h-screen w-[84px] shrink-0 flex-col items-center border-r border-[#e5e2d6] bg-[#f7f5ee] px-3 pb-3 pt-4"
      >
        {/* Brand Home Icon */}
        <Link
          href="/admin/overview"
          aria-label="LaterBox Admin Overview"
          {...tooltipHandlers('LaterBox Admin')}
          onClick={() => setTooltip(null)}
          className="relative flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-2xl bg-[#e6edb0] transition-transform hover:-rotate-3 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#758a50]"
        >
          <Image src="/branding/laterbox-icon.png" alt="" fill priority sizes="52px" className="object-contain p-1.5" />
        </Link>

        {/* Divider */}
        <div className="my-4 h-px w-9 shrink-0 bg-[#e5e2d6]" aria-hidden="true" />

        {/* Scrollable navigation rail */}
        <div className="min-h-0 w-full flex-1 overflow-y-auto overflow-x-hidden [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          <nav aria-label="Admin Navigation" className="flex flex-col items-center gap-1.5">
            {ADMIN_NAV_ITEMS.map((item) => {
              const badgeCount =
                item.href === '/admin/feedback' && pendingFeedbackCount > 0
                  ? pendingFeedbackCount
                  : undefined;
              return renderRailLink({
                href: item.href,
                title: item.title,
                icon: item.icon,
                badge: badgeCount,
              });
            })}
          </nav>
        </div>

        {/* Bottom utility links */}
        <div className="mt-3 flex w-full shrink-0 flex-col items-center gap-2 border-t border-[#e5e2d6] pt-3">
          {/* Open User App Dashboard */}
          {isExternalApp ? (
            <a
              href={userAppUrl}
              aria-label="Open LaterBox App"
              {...tooltipHandlers('Open LaterBox App')}
              onClick={() => setTooltip(null)}
              className={railItemClass(false)}
            >
              <ArrowUpRight className="h-[25px] w-[25px]" strokeWidth={2} aria-hidden="true" />
            </a>
          ) : (
            <Link
              href="/inbox"
              aria-label="Open LaterBox App"
              {...tooltipHandlers('Open LaterBox App')}
              onClick={() => setTooltip(null)}
              className={railItemClass(false)}
            >
              <ArrowUpRight className="h-[25px] w-[25px]" strokeWidth={2} aria-hidden="true" />
            </Link>
          )}

          {/* Access status icon badge */}
          <div
            role="status"
            aria-label={`Access: ${data?.role ?? 'Admin'}`}
            {...tooltipHandlers(`Access: ${data?.role ?? 'Admin'}`)}
            className="flex h-[42px] w-[42px] shrink-0 items-center justify-center rounded-2xl bg-white border border-[#e4e5d9] shadow-sm text-[#435b34]"
          >
            <Shield className="h-5 w-5" strokeWidth={2.2} aria-hidden="true" />
          </div>
        </div>
      </aside>

      {/* Floating tooltip */}
      {tooltip && (
        <div
          role="tooltip"
          style={{ left: tooltip.left, top: tooltip.top }}
          className="pointer-events-none fixed z-50 -translate-y-1/2 whitespace-nowrap rounded-xl bg-[#171711] px-3 py-1.5 text-xs font-semibold text-[#f7f5ee] shadow-[0_8px_20px_rgba(23,23,17,0.24)]"
        >
          {tooltip.label}
        </div>
      )}

      {/* Mobile Drawer (accessible with text labels on touch devices) */}
      {mobileOpen && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex md:hidden">
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-[#171711]/40 backdrop-blur-sm transition-opacity"
            onClick={onCloseMobile}
            aria-hidden="true"
          />
          {/* Drawer */}
          <aside className="relative z-10 flex h-full w-72 max-w-[85vw] flex-col border-r border-[#e5e2d6] bg-[#f7f5ee] p-5 shadow-2xl justify-between">
            <div className="flex flex-col">
              {/* Brand Header */}
              <div className="flex items-center justify-between pb-6">
                <Link
                  href="/admin/overview"
                  onClick={onCloseMobile}
                  className="flex items-center gap-3 group focus:outline-none"
                >
                  <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#e6edb0] font-black text-[#171711] shadow-sm transition-transform group-hover:scale-105">
                    <Image
                      src="/branding/laterbox-icon.png"
                      alt=""
                      fill
                      priority
                      sizes="40px"
                      className="object-contain p-1"
                    />
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
                    className="rounded-lg p-1.5 text-[#677362] hover:bg-[#e9ebe0] transition-colors"
                    aria-label="Close sidebar"
                  >
                    <X size={18} />
                  </button>
                )}
              </div>

              {/* Section Title */}
              <p className="mb-2 mt-2 text-[11px] font-semibold uppercase tracking-widest text-[#677362]">
                Workspace
              </p>

              {/* Navigation list */}
              <nav aria-label="Admin Navigation" className="space-y-1 overflow-y-auto max-h-[calc(100vh-280px)] pr-1">
                {ADMIN_NAV_ITEMS.map((item) => {
                  const Icon = item.icon;
                  const active = isCurrentActive(item.href);
                  const badgeCount =
                    item.href === '/admin/feedback' && pendingFeedbackCount > 0
                      ? pendingFeedbackCount
                      : undefined;

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
                        <Icon
                          size={18}
                          strokeWidth={active ? 2.4 : 1.9}
                          className={active ? 'text-[#171711]' : 'text-[#677362]'}
                        />
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
              {isExternalApp ? (
                <a
                  href={userAppUrl}
                  className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-[#435b34] hover:text-[#23351a] hover:underline"
                >
                  <span>Open LaterBox</span>
                  <ArrowUpRight size={13} />
                </a>
              ) : (
                <Link
                  href="/inbox"
                  onClick={onCloseMobile}
                  className="mt-3 inline-flex items-center gap-1.5 text-xs font-semibold text-[#435b34] hover:text-[#23351a] hover:underline"
                >
                  <span>Open LaterBox</span>
                  <ArrowUpRight size={13} />
                </Link>
              )}
            </div>
          </aside>
        </div>
      )}
    </>
  );
}
