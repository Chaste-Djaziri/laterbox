// laterbox-web/src/components/admin/AdminHeader.tsx
'use client';

import { Menu, RefreshCcw, Loader2 } from 'lucide-react';
import { useAdmin } from './AdminContext';

interface AdminHeaderProps {
  title: string;
  subtitle?: string;
  onOpenMobile?: () => void;
  actions?: React.ReactNode;
}

export function AdminHeader({
  title,
  subtitle = 'Live, role-restricted LaterBox operations',
  onOpenMobile,
  actions,
}: AdminHeaderProps) {
  const { loading, operationsLoading, refreshAll, notice, error, signedIn } = useAdmin();
  const isRefreshing = loading || operationsLoading;

  return (
    <div className="flex flex-col">
      {/* Top Header Row */}
      <header className="flex flex-wrap items-start justify-between gap-4 border-b border-[#e4e5d9] pb-6 pt-1">
        <div className="flex items-center gap-3">
          {onOpenMobile && (
            <button
              type="button"
              onClick={onOpenMobile}
              className="lg:hidden rounded-xl border border-[#d9dece] p-2 text-[#171711] hover:bg-[#edf0e4] transition-colors focus:outline-none"
              aria-label="Open navigation menu"
            >
              <Menu size={20} />
            </button>
          )}
          <div>
            <p className="text-[11px] font-bold uppercase tracking-widest text-[#677362]">
              Platform administration
            </p>
            <h1 className="mt-1.5 text-3xl font-bold tracking-tight text-[#171711] sm:text-4xl">
              {title}
            </h1>
            <p className="mt-1.5 text-sm text-[#677362] font-medium">{subtitle}</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {actions}
          <button
            type="button"
            onClick={() => void refreshAll()}
            disabled={isRefreshing}
            className="inline-flex items-center gap-2 rounded-xl border border-[#d9dece] bg-white px-4 py-2 text-sm font-semibold text-[#171711] hover:bg-[#f1f3e9] transition-colors shadow-sm disabled:opacity-50"
          >
            <RefreshCcw size={15} className={isRefreshing ? 'animate-spin text-[#677362]' : 'text-[#171711]'} />
            <span>{isRefreshing ? 'Refreshing…' : 'Refresh'}</span>
          </button>
        </div>
      </header>

      {/* Notice Banner (Green) */}
      {notice && (
        <div
          role="status"
          className="mt-5 rounded-2xl border border-[#8fb37d] bg-[#eff5e3] px-5 py-3.5 text-sm font-medium text-[#2d4a1f] shadow-sm flex items-center justify-between"
        >
          <span>{notice}</span>
        </div>
      )}

      {/* Error Alert Banner */}
      {error && (
        <div
          role="alert"
          className="mt-5 rounded-2xl border border-amber-800/40 bg-[#fff2e8] p-5 shadow-sm"
        >
          <p className="font-bold text-[#171711]">Access or operation unavailable</p>
          <p className="mt-1.5 text-sm text-[#945632] leading-relaxed">{error}</p>
          {signedIn === false && (
            <a
              href="/login?next=%2Fadmin"
              className="mt-4 inline-block rounded-xl bg-[#e6edb0] px-5 py-2.5 text-sm font-bold text-[#161d13] shadow-sm hover:bg-[#d8e39d] transition-colors"
            >
              Sign in to Control Center
            </a>
          )}
        </div>
      )}

      {/* Loading state when first opening */}
      {loading && !notice && !error && (
        <div className="mt-8 flex items-center gap-3 text-sm text-[#677362]">
          <Loader2 className="animate-spin text-[#435b34]" size={18} />
          <span>Loading secure platform data…</span>
        </div>
      )}
    </div>
  );
}
