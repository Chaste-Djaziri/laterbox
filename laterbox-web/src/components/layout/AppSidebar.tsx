'use client';

import React, { useEffect, useMemo, useState, useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { presentEntitlement } from '@/lib/billing/types';
import { scheduleItems } from '@/lib/utils/schedule';
import { CloudSyncIndicator } from '../ui/CloudSyncIndicator';
import {
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
  ChevronRight,
  Crown,
  Archive,
  Check,
  X,
  Star,
  CheckCircle,
} from 'lucide-react';

interface AppSidebarProps {
  onOpenCapture: () => void;
}

export function AppSidebar({ onOpenCapture }: AppSidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { inboxItems, starredItems, savedItems, items, collections, createCollection } = useItems();
  const { user, userName, isGuest, signOut } = useAuth();
  const { entitlement, isPro, manage } = useBilling();
  const [collapsed, setCollapsed] = useState(false);
  const [now, setNow] = useState(() => new Date());
  const plan = useMemo(() => presentEntitlement(entitlement, now), [entitlement, now]);

  const [isCreatingCollection, setIsCreatingCollection] = useState(false);
  const [newCollectionName, setNewCollectionName] = useState('');
  const [isSubmittingCollection, setIsSubmittingCollection] = useState(false);
  const newCollectionInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isCreatingCollection) {
      newCollectionInputRef.current?.focus();
    }
  }, [isCreatingCollection]);

  const handleCreateCollection = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = newCollectionName.trim();
    if (!trimmed || isSubmittingCollection) return;
    try {
      setIsSubmittingCollection(true);
      const newCol = await createCollection(trimmed);
      setNewCollectionName('');
      setIsCreatingCollection(false);
      if (newCol?.id) {
        router.push(`/library/${newCol.id}`);
      }
    } catch (err) {
      console.error('Failed to create collection:', err);
    } finally {
      setIsSubmittingCollection(false);
    }
  };

  useEffect(() => {
    if (!entitlement.phaseEndsAt) return;
    const timer = window.setInterval(() => setNow(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, [entitlement.phaseEndsAt]);

  const todayCount = useMemo(() => scheduleItems(items, 'today', now).length, [items, now]);
  const upcomingCount = useMemo(() => scheduleItems(items, 'upcoming', now).length, [items, now]);
  const somedayCount = useMemo(() => scheduleItems(items, 'someday', now).length, [items, now]);

  const coreLinks = [
    {
      href: '/inbox',
      label: 'Inbox',
      icon: <Inbox className="w-4 h-4" />,
      badge: inboxItems.length > 0 ? inboxItems.length : undefined,
    },
    {
      href: '/starred',
      label: 'Starred',
      icon: <Star className="w-4 h-4" />,
      badge: starredItems.length > 0 ? starredItems.length : undefined,
    },
    {
      href: '/kept',
      label: 'Kept',
      icon: <CheckCircle className="w-4 h-4" />,
      badge: savedItems.length > 0 ? savedItems.length : undefined,
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
      href: '/downloads',
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
    if (href === '/inbox') return pathname === '/inbox' || pathname === '/';
    if (href === '/downloads') return pathname === '/downloads' || pathname === '/download';
    if (href === '/library') return pathname === '/library';
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  const renderLinkItem = ({ href, label, icon, badge }: { href: string; label: string; icon: React.ReactNode; badge?: number }) => {
    const isActive = isLinkActive(href);
    const isInboxActive = isActive && href === '/inbox';

    return (
      <Link
        key={href}
        href={href}
        title={collapsed ? label : undefined}
        className={`relative flex items-center ${
          collapsed ? 'justify-center px-0' : 'justify-between px-3'
        } py-2.5 rounded-xl text-xs transition-all duration-150 ${
          isInboxActive
            ? 'bg-[#e6edb0] text-[#171711] font-bold shadow-2xs'
            : isActive
            ? 'bg-white border border-[#e4e0d5]/80 text-[#171711] font-bold shadow-2xs'
            : 'text-[#6c6b63] font-medium hover:bg-[#ebe7dc]/50 hover:text-[#171711]'
        }`}
      >
        {isActive && !isInboxActive && (
          <span className="w-1.5 h-6 bg-[#171711] rounded-r-md absolute left-0 top-1/2 -translate-y-1/2" />
        )}
        <div className="flex items-center gap-2.5 min-w-0">
          <span className={`shrink-0 ${isActive ? 'text-[#171711]' : 'text-[#8e8d87]'}`}>
            {icon}
          </span>
          {!collapsed && <span className="truncate">{label}</span>}
        </div>
        {!collapsed && badge !== undefined && (
          <span
            className={`w-5 h-5 rounded-full text-[10px] font-black flex items-center justify-center shrink-0 ${
              isInboxActive
                ? 'bg-[#d8e09e] text-[#171711]'
                : 'bg-[#e6edb0] text-[#171711]'
            }`}
          >
            {badge}
          </span>
        )}
      </Link>
    );
  };

  return (
    <aside
      className={`h-screen overflow-y-auto bg-transparent flex flex-col justify-between p-3.5 shrink-0 transition-all duration-200 ${
        collapsed ? 'w-[76px]' : 'w-64'
      }`}
    >
      {/* Top Section */}
      <div>
        {/* Brand Header */}
        <div className={`flex items-center ${collapsed ? 'justify-center px-0' : 'justify-start px-1.5'} pt-1.5 pb-7`}>
          <Link href="/" className={`flex items-center ${collapsed ? 'justify-center' : 'gap-3'} group`}>
            <div className="w-[42px] h-[42px] relative shrink-0 transition-transform group-hover:scale-105">
              <Image
                src="/branding/laterbox-icon.png"
                alt="laterbox"
                fill
                sizes="42px"
                className="object-contain"
                priority
              />
            </div>
            {!collapsed && (
              <span className="text-[22px] font-black tracking-tight text-[#171711] leading-none select-none">
                laterbox
              </span>
            )}
          </Link>
        </div>

        <div className="space-y-4">
          {/* Quick Capture Button */}
          <button
            onClick={onOpenCapture}
          className={`w-full flex items-center justify-center ${
            collapsed ? 'px-0 min-h-14' : 'px-4 min-h-16'
          } py-4 rounded-2xl bg-[#171711] hover:bg-black active:bg-[#0f0f0e] text-white font-black text-lg tracking-tight shadow-md hover:shadow-lg hover:-translate-y-0.5 active:translate-y-0 transition-all duration-150 group cursor-pointer`}
          title="Save Item (⌃⌥L / Control+Option+L)"
        >
          <div className="flex items-center">
            <Plus className={`w-6 h-6 transition-transform group-hover:rotate-90 shrink-0 ${collapsed ? '' : 'mr-2'}`} strokeWidth={2.75} />
            {!collapsed && <span>Save Item</span>}
          </div>
        </button>

        {/* Main Navigation Items */}
        <nav className="space-y-1">
          {coreLinks.map(renderLinkItem)}
        </nav>

        {/* Collections (Labels) Section */}
        <div className="pt-2">
          {!collapsed ? (
            <div className="flex items-center justify-between px-3 mb-1">
              <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92]">
                COLLECTIONS
              </span>
              <button
                type="button"
                onClick={() => setIsCreatingCollection(true)}
                className="p-1 -mr-1 rounded-lg text-[#8e8d87] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
                title="Create new collection"
                aria-label="Create new collection"
              >
                <Plus className="w-3.5 h-3.5" strokeWidth={2.5} />
              </button>
            </div>
          ) : (
            <div className="flex justify-center mb-1">
              <button
                type="button"
                onClick={() => {
                  setCollapsed(false);
                  setIsCreatingCollection(true);
                }}
                className="p-1.5 rounded-lg text-[#8e8d87] hover:text-[#171711] hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
                title="Create new collection"
              >
                <Plus className="w-3.5 h-3.5" strokeWidth={2.5} />
              </button>
            </div>
          )}

          {/* Inline creation input */}
          {isCreatingCollection && !collapsed && (
            <form onSubmit={handleCreateCollection} className="px-1.5 py-1 mb-1">
              <div className="flex items-center gap-1.5 bg-white border border-[#171711] rounded-xl px-2.5 py-1.5 shadow-2xs">
                <input
                  ref={newCollectionInputRef}
                  type="text"
                  value={newCollectionName}
                  onChange={(e) => setNewCollectionName(e.target.value)}
                  placeholder="Collection name..."
                  className="w-full text-xs bg-transparent focus:outline-none text-[#171711] placeholder:text-[#9e9b92]"
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === 'Escape') {
                      setIsCreatingCollection(false);
                      setNewCollectionName('');
                    }
                  }}
                />
                <button
                  type="submit"
                  disabled={!newCollectionName.trim() || isSubmittingCollection}
                  className="p-1 rounded-lg bg-[#171711] text-white hover:bg-black disabled:opacity-40 transition-colors cursor-pointer shrink-0"
                  title="Save"
                >
                  <Check className="w-3 h-3" />
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setIsCreatingCollection(false);
                    setNewCollectionName('');
                  }}
                  className="p-1 rounded-lg text-[#8e8d87] hover:text-[#171711] transition-colors cursor-pointer shrink-0"
                  title="Cancel"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            </form>
          )}

          {/* Collections List */}
          <nav className="space-y-1">
            {collections.map((col) => {
              const count = items.filter(
                (item) => !item.deleted_at && item.collections?.some((c) => c.id === col.id)
              ).length;
              const href = `/library/${col.id}`;
              const isActive = pathname === href;

              return (
                <Link
                  key={col.id}
                  href={href}
                  title={collapsed ? col.name : undefined}
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
                    <svg
                      className={`w-3.5 h-3.5 shrink-0 transition-colors ${
                        isActive ? 'text-[#171711]' : 'text-[#8e8d87]'
                      }`}
                      viewBox="0 0 24 24"
                      fill={isActive ? 'currentColor' : 'none'}
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M2.5 7A2.5 2.5 0 0 1 5 4.5h10.8a2.5 2.5 0 0 1 1.95.94l4.25 5.31a1.5 1.5 0 0 1 0 1.88l-4.25 5.31a2.5 2.5 0 0 1-1.95.94H5A2.5 2.5 0 0 1 2.5 16.5V7z" />
                    </svg>
                    {!collapsed && <span className="truncate">{col.name}</span>}
                  </div>
                  {!collapsed && count > 0 && (
                    <span className="text-[10px] font-bold text-[#8e8d87] px-1.5 py-0.5 rounded-md bg-[#ebe7dc]/60 shrink-0">
                      {count}
                    </span>
                  )}
                </Link>
              );
            })}

            {collections.length === 0 && !isCreatingCollection && !collapsed && (
              <button
                type="button"
                onClick={() => setIsCreatingCollection(true)}
                className="w-full text-left px-3 py-2 text-[11px] text-[#9e9b92] hover:text-[#171711] transition-colors flex items-center gap-2 rounded-xl hover:bg-[#ebe7dc]/40 cursor-pointer"
              >
                <Plus className="w-3 h-3 text-[#9e9b92]" />
                <span>New collection...</span>
              </button>
            )}
          </nav>
        </div>

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
      </div>

      {/* Bottom Profile / Cloud Sync Section */}
      <div className="pt-3 border-t border-[#e4e0d5] space-y-2.5">
        {/* Free Plan Card */}
        <Link
          href="/plans"
          className="block p-3 rounded-2xl bg-white border border-[#e4e0d5] hover:border-[#171711]/40 transition-all shadow-2xs group"
          title={collapsed ? plan.label : undefined}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Crown className="w-4 h-4 text-amber-500 shrink-0" />
              {!collapsed && (
                <span className="text-xs font-bold text-[#171711]">{plan.label || 'Free Plan'}</span>
              )}
            </div>
            {!collapsed && (
              <ChevronRight className="w-3.5 h-3.5 text-[#9e9b92] group-hover:text-[#171711] transition-colors" />
            )}
          </div>
          {!collapsed && (
            <p className="text-[10px] text-[#8e8d87] mt-1 pl-6 font-medium">
              {plan.actionLabel || 'Upgrade for more space'}
            </p>
          )}
        </Link>

        {/* Sync Indicator (Pro Mode) */}
        {isPro && (
          <div className={collapsed ? "flex items-center justify-center" : "w-full"}>
            <CloudSyncIndicator compact={collapsed} fullWidth={!collapsed} />
          </div>
        )}

        {/* User / Guest Account Row */}
        {user ? (
          <div className="flex items-center justify-between p-2 rounded-xl bg-white border border-[#e4e0d5] shadow-2xs">
            <div className="flex items-center gap-2 min-w-0">
              <div className="w-7 h-7 rounded-full bg-[#171711] flex items-center justify-center text-white shrink-0 font-bold text-xs">
                {userName ? userName[0].toUpperCase() : user.email?.[0].toUpperCase() || <User className="w-3.5 h-3.5" />}
              </div>
              {!collapsed && (
                <div className="min-w-0">
                  <p className="text-xs font-bold text-[#171711] truncate">
                    {userName || user.email}
                  </p>
                  <p className="text-[10px] text-[#8e8d87] font-medium truncate">
                    {userName ? user.email : 'Account'}
                  </p>
                </div>
              )}
            </div>
            {!collapsed && (
              <button
                type="button"
                onClick={() => signOut()}
                title="Sign Out"
                className="p-1 rounded-lg text-[#9e9b92] hover:text-[#171711] transition-colors cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        ) : (
          <div className="flex items-center justify-between p-2 rounded-xl bg-white border border-[#e4e0d5] shadow-2xs">
            <div className="flex items-center gap-2 min-w-0">
              <div className="w-7 h-7 rounded-full bg-[#171711] flex items-center justify-center text-white shrink-0 font-bold text-xs">
                {userName ? userName[0].toUpperCase() : 'G'}
              </div>
              {!collapsed && (
                <div className="min-w-0">
                  <p className="text-xs font-bold text-[#171711] truncate">
                    {userName || 'Guest Mode'}
                  </p>
                  <p className="text-[10px] text-[#8e8d87] font-medium truncate">
                    {userName ? 'Guest • Local storage' : 'Local storage only'}
                  </p>
                </div>
              )}
            </div>
            {!collapsed && (
              <Link
                href="/settings"
                className="p-1 rounded-lg text-[#9e9b92] hover:text-[#171711] transition-colors"
                title="Settings"
              >
                <Settings className="w-3.5 h-3.5" />
              </Link>
            )}
          </div>
        )}
      </div>
    </aside>
  );
}
