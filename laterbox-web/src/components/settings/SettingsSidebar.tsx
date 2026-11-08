// laterbox-web/src/components/settings/SettingsSidebar.tsx
'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Bell, CalendarClock, Cloud, Crown, DatabaseBackup,
  Puzzle, RefreshCw, ShieldCheck, UserRound, type LucideIcon,
} from 'lucide-react';
import { useDashboard } from '@/lib/store/DashboardContext';
import { SETTINGS_SECTIONS } from '@/lib/utils/settingsNavigation';

const sectionIcons: Record<string, LucideIcon> = {
  account: UserRound,
  preferences: CalendarClock,
  notifications: Bell,
  sync: Cloud,
  backup: DatabaseBackup,
  apps: Puzzle,
  billing: Crown,
  updates: RefreshCw,
  legal: ShieldCheck,
};

export function SettingsSidebar() {
  const pathname = usePathname();
  const { setTitle } = useDashboard();

  useEffect(() => {
    setTitle('Settings');
  }, [setTitle]);

  const nav = SETTINGS_SECTIONS.map(section => {
    const href = `/settings/${section.id}`;
    const active = pathname === href || pathname.startsWith(href + '/');
    const Icon = sectionIcons[section.id];
    return (
      <Link
        key={section.id}
        href={href}
        aria-current={active ? 'page' : undefined}
        className={`group flex min-h-10 shrink-0 items-center gap-3 rounded-xl border px-3 py-2.5 text-[12px] font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7d9454] ${
          active
            ? 'border-[#d8e3ad] bg-[#e6edb0] text-[#26331e]'
            : 'border-transparent text-[#787d72] hover:bg-white hover:text-[#171711]'
        }`}
      >
        <Icon className={`h-[18px] w-[18px] shrink-0 ${active ? 'text-[#415932]' : 'text-[#8c9486] group-hover:text-[#53684b]'}`} strokeWidth={active ? 2.3 : 1.9} aria-hidden="true" />
        <span className="whitespace-nowrap">{section.label}</span>
      </Link>
    );
  });

  return (
    <>
      <aside aria-label="Settings sections" className="hidden h-full w-[248px] shrink-0 flex-col border-r border-[#e5e2d7] bg-[#f7f5ee] md:flex">
        <nav aria-label="Settings navigation" className="min-h-0 flex-1 space-y-1 overflow-y-auto px-3 py-5 [scrollbar-width:thin]">
          <p className="px-3 pb-1 pt-1 text-[10px] font-black uppercase tracking-[0.13em] text-[#a2a59a]">Personal</p>
          {nav.slice(0, 3)}
          <p className="px-3 pb-1 pt-5 text-[10px] font-black uppercase tracking-[0.13em] text-[#a2a59a]">Data & devices</p>
          {nav.slice(3, 6)}
          <p className="px-3 pb-1 pt-5 text-[10px] font-black uppercase tracking-[0.13em] text-[#a2a59a]">More</p>
          {nav.slice(6)}
        </nav>
        <p className="shrink-0 border-t border-[#e7e4d9] px-6 py-4 text-[11px] leading-relaxed text-[#a3a89c]">
          Changes to local preferences apply to this browser.
        </p>
      </aside>
      <nav aria-label="Settings sections" className="flex shrink-0 gap-2 overflow-x-auto border-b border-[#e7e4d9] bg-[#f7f5ee] px-3 py-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden md:hidden">
        {nav}
      </nav>
    </>
  );
}
