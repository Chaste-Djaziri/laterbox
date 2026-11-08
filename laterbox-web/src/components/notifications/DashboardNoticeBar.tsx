// laterbox-web/src/components/notifications/DashboardNoticeBar.tsx
'use client';

import { useEffect, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { ArrowRight, ChevronLeft, ChevronRight, X, type LucideIcon } from 'lucide-react';
import { nextNoticeId, visibleNotices } from '@/lib/utils/dashboardNotices';

export interface DashboardNoticeAction {
  id: string;
  label: string;
  href?: string;
  onClick?: () => void;
  variant?: 'primary' | 'secondary';
}

export interface DashboardNotice {
  id: string;
  title: string;
  description: string;
  icon: LucideIcon;
  tone?: 'warning' | 'info' | 'error' | 'success';
  actions?: DashboardNoticeAction[];
}

export interface DashboardNoticeBarProps {
  notices: readonly DashboardNotice[];
  /** Auto-switch interval. Set 0 to disable rotation. */
  rotationMs?: number;
  className?: string;
}

const toneStyles: Record<NonNullable<DashboardNotice['tone']>, string> = {
  warning: 'border-[#f2e7c9] bg-[#fdfaf3]',
  info: 'border-[#dfe9c5] bg-[#f9fbf2]',
  error: 'border-[#efd8ce] bg-[#fff9f5]',
  success: 'border-[#d5e8c5] bg-[#f4faf0]',
};
const iconStyles: Record<NonNullable<DashboardNotice['tone']>, string> = {
  warning: 'bg-[#e6edb0] text-[#28331e]',
  info: 'bg-[#e6edb0] text-[#28331e]',
  error: 'bg-[#f4e0d3] text-[#824432]',
  success: 'bg-[#dcefc9] text-[#395f32]',
};

function Action({
  action,
  noticeId,
}: {
  action: DashboardNoticeAction;
  noticeId: string;
}): ReactNode {
  const isPrimary = (action.variant ?? 'primary') === 'primary';
  const cls = `inline-flex min-h-9 shrink-0 items-center justify-center gap-1.5 rounded-full px-3.5 py-2 text-xs font-bold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#819559] ${
    isPrimary
      ? 'bg-[#171711] text-[#e6edb0] hover:bg-[#33352b]'
      : 'border border-[#dfdfd3] bg-white text-[#35402e] hover:border-[#b4c487] hover:bg-[#f3f7e6]'
  }`;
  const children = (
    <>
      <span>{action.label}</span>
      {isPrimary && <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />}
    </>
  );
  if (action.href) {
    return <Link key={`${noticeId}-${action.id}`} href={action.href} className={cls}>{children}</Link>;
  }
  return (
    <button
      key={`${noticeId}-${action.id}`}
      type="button"
      onClick={action.onClick}
      className={cls}
    >
      {children}
    </button>
  );
}

export function DashboardNoticeBar({
  notices,
  rotationMs = 9000,
  className = '',
}: DashboardNoticeBarProps) {
  const [dismissedIds, setDismissedIds] = useState<Set<string>>(() => new Set());
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const [manualCycle, setManualCycle] = useState(0);

  const visible = visibleNotices(notices, dismissedIds);
  const visibleIds = visible.map(notice => notice.id);
  const activeId = selectedId && visibleIds.includes(selectedId) ? selectedId : visibleIds[0] ?? null;
  const activeIndex = activeId ? visibleIds.indexOf(activeId) : -1;
  const active = activeIndex >= 0 ? visible[activeIndex] : null;
  const visibleKey = visibleIds.join('\u001f');

  useEffect(() => {
    if (!visibleKey || !rotationMs || hovered || focused) return;
    const ids = visibleKey.split('\u001f');
    if (ids.length < 2) return;
    const interval = window.setInterval(() => {
      if (document.visibilityState === 'visible') {
        setSelectedId(previous =>
          nextNoticeId(ids, previous && ids.includes(previous) ? previous : ids[0], 1)
        );
      }
    }, rotationMs);
    return () => window.clearInterval(interval);
  }, [visibleKey, rotationMs, hovered, focused, manualCycle]);

  const go = (direction: 1 | -1) => {
    setSelectedId(nextNoticeId(visibleIds, activeId, direction));
    setManualCycle(value => value + 1);
  };

  const dismissActive = () => {
    if (!active) return;
    const nextId = nextNoticeId(visibleIds, active.id);
    setDismissedIds(previous => {
      const next = new Set(previous);
      next.add(active.id);
      return next;
    });
    setSelectedId(nextId === active.id ? null : nextId);
    setManualCycle(value => value + 1);
  };

  if (!active) return null;

  const Icon = active.icon;
  const tone = active.tone ?? 'warning';

  return (
    <section
      aria-label="Dashboard notifications"
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onFocusCapture={() => setFocused(true)}
      onBlurCapture={event => {
        if (!event.currentTarget.contains(event.relatedTarget as Node | null)) setFocused(false);
      }}
      className={`w-full rounded-2xl border px-3 py-3 text-[#171711] shadow-2xs sm:px-4 ${toneStyles[tone]} ${className}`}
    >
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div key={active.id} className="flex min-w-0 flex-1 items-start gap-3 animate-in fade-in duration-200 motion-reduce:animate-none sm:items-center">
          <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${iconStyles[tone]}`}>
            <Icon className="h-[19px] w-[19px]" strokeWidth={2} aria-hidden="true" />
          </span>
          <p className="min-w-0 text-xs leading-5 sm:text-sm sm:leading-relaxed">
            <span className="font-extrabold text-[#171711]">{active.title}</span>{' '}
            <span className="text-[#6e7169]">{active.description}</span>
          </p>
        </div>
        <div className="flex shrink-0 flex-wrap items-center justify-end gap-2 sm:pl-12 lg:pl-0">
          {active.actions?.map(action => (
            <Action action={action} noticeId={active.id} key={`${active.id}-${action.id}`} />
          ))}
          {visible.length > 1 && (
            <div role="group" aria-label="Notice navigation" className="flex shrink-0 items-center gap-0.5 rounded-full border border-[#e2e3d7] bg-white/75 p-0.5">
              <button
                type="button"
                aria-label="Previous notice"
                onClick={() => go(-1)}
                className="rounded-full p-1.5 text-[#72776b] hover:bg-[#e6edb0] hover:text-[#171711] focus-visible:outline-2 focus-visible:outline-[#819559]"
              >
                <ChevronLeft className="h-4 w-4" aria-hidden="true" />
              </button>
              <span className="min-w-8 text-center text-[10px] font-bold tabular-nums text-[#74786c]" aria-label={`Notice ${activeIndex + 1} of ${visible.length}`}>
                {activeIndex + 1}/{visible.length}
              </span>
              <button
                type="button"
                aria-label="Next notice"
                onClick={() => go(1)}
                className="rounded-full p-1.5 text-[#72776b] hover:bg-[#e6edb0] hover:text-[#171711] focus-visible:outline-2 focus-visible:outline-[#819559]"
              >
                <ChevronRight className="h-4 w-4" aria-hidden="true" />
              </button>
            </div>
          )}
          <button
            type="button"
            onClick={dismissActive}
            aria-label={`Dismiss notification: ${active.title}`}
            title="Dismiss this notification"
            className="shrink-0 rounded-lg p-2 text-[#8e8d87] transition-colors hover:bg-[#171711]/5 hover:text-[#171711] focus-visible:outline-2 focus-visible:outline-[#819559]"
          >
            <X className="h-4 w-4" aria-hidden="true" />
          </button>
        </div>
      </div>
    </section>
  );
}
