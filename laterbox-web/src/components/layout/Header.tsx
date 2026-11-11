// laterbox-web/src/components/layout/Header.tsx
'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  ArrowRight,
  BookOpen,
  ChevronRight,
  Compass,
  CreditCard,
  Download,
  HelpCircle,
  Menu,
  Sparkles,
  X,
} from 'lucide-react';
import { APP_ORIGIN } from '@/lib/auth/config';
import { useAuth } from '@/lib/store/AuthContext';
import { AppStoreTopBanner } from '@/components/marketing/AppStoreTopBanner';

interface HeaderNavLink {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string;
}

interface SecondaryNavLink {
  href: string;
  label: string;
  detail: string;
  icon: React.ComponentType<{ className?: string }>;
}

const navLinks: readonly HeaderNavLink[] = [
  { href: '/#features', label: 'Features', icon: Sparkles },
  { href: '/#how-it-works', label: 'How it works', icon: Compass },
  { href: '/download', label: 'Downloads', icon: Download },
  { href: '/pricing', label: 'Pricing', icon: CreditCard },
  { href: '/docs', label: 'Docs', icon: BookOpen },
  { href: '/#faq', label: 'FAQ', icon: HelpCircle },
];

const mobileResourceLinks: readonly SecondaryNavLink[] = [
  { href: '/guide', label: 'Getting started guide', detail: 'Step-by-step walkthrough & workflows', icon: HelpCircle },
];

export function Header() {
  const pathname = usePathname();
  const { isAuthenticated, user, loading } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [hasScrolled, setHasScrolled] = useState(false);

  const isSignedIn = Boolean(user || isAuthenticated);
  const dashboardHref = `${APP_ORIGIN}/inbox`;
  const primaryActionHref = isSignedIn ? dashboardHref : `${APP_ORIGIN}/signup`;
  const primaryActionLabel = isSignedIn ? 'Open app' : 'Get started free';

  useEffect(() => {
    const updateScrollState = () => setHasScrolled(window.scrollY > 8);
    const frame = window.requestAnimationFrame(updateScrollState);
    window.addEventListener('scroll', updateScrollState, { passive: true });
    return () => {
      window.cancelAnimationFrame(frame);
      window.removeEventListener('scroll', updateScrollState);
    };
  }, []);

  useEffect(() => {
    if (!mobileOpen) return;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setMobileOpen(false);
      }
    };
    document.addEventListener('keydown', closeOnEscape);
    return () => {
      document.removeEventListener('keydown', closeOnEscape);
    };
  }, [mobileOpen]);

  // Lock body scroll when mobile sidebar is open
  useEffect(() => {
    if (mobileOpen) {
      const originalOverflow = document.body.style.overflow;
      document.body.style.overflow = 'hidden';
      return () => {
        document.body.style.overflow = originalOverflow;
      };
    }
  }, [mobileOpen]);

  const activeLink = (href: string) => !href.startsWith('/#') && pathname === href;
  const closeMobile = () => setMobileOpen(false);

  return (
    <>
      {/* Apple App Store Smart Banner Embed at the very top of the web */}
      <AppStoreTopBanner />

      {/* Secondary Top Promo Bar */}
      <div className="bg-[#181b14] text-white">
        <div className="mx-auto flex min-h-9 max-w-[1240px] items-center justify-center gap-2 px-4 py-2 text-center text-[11px] font-medium tracking-[0.01em] sm:text-xs">
          <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-[#e6edb0]" aria-hidden="true" />
          <span>Less tab clutter. More room to think.</span>
          <Link href="/#how-it-works" className="inline-flex items-center gap-1 font-bold text-[#e6edb0] underline-offset-4 hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#e6edb0]">
            See how it works <ArrowRight className="h-3 w-3" aria-hidden="true" />
          </Link>
        </div>
      </div>

      <header
        data-lenis-prevent
        className={`sticky top-0 z-50 w-full border-b bg-[#f8f8f3]/95 backdrop-blur-xl transition-[border-color,box-shadow] duration-200 ${hasScrolled ? 'border-[#e6e7de] shadow-[0_5px_24px_rgba(24,27,20,0.045)]' : 'border-transparent shadow-none'}`}
      >
        <div className="mx-auto flex h-[80px] max-w-[1320px] items-center justify-between gap-4 px-4 sm:h-[88px] sm:px-6 lg:gap-8 lg:px-8">
          <Link
            href="/"
            onClick={closeMobile}
            className="group inline-flex shrink-0 items-center gap-2.5 rounded-lg focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#678144]"
            aria-label="LaterBox, go to homepage"
          >
            <span className="relative flex h-10 w-10 items-center justify-center overflow-hidden rounded-[12px] border border-[#cbd79c] bg-[#e6edb0] shadow-[0_3px_10px_rgba(23,23,17,0.08)] transition-transform duration-200 group-hover:-rotate-3 sm:h-12 sm:w-12">
              <Image src="/branding/laterbox-icon.png" alt="" fill priority sizes="48px" className="object-contain p-1" />
            </span>
            <span className="text-[25px] font-black tracking-[-0.065em] text-[#181b14] sm:text-[27px]">laterbox<span className="text-[#84934f]">.</span></span>
          </Link>

          <nav aria-label="Main navigation" className="hidden items-center gap-1 lg:flex xl:gap-2">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                aria-current={activeLink(link.href) ? 'page' : undefined}
                className={`rounded-full px-3.5 py-2 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#678144] xl:px-4 ${
                  activeLink(link.href) ? 'bg-[#e6edb0] text-[#181b14]' : 'text-[#606458] hover:bg-white hover:text-[#181b14]'
                }`}
              >
                {link.label}
              </Link>
            ))}
          </nav>

          <div className="flex shrink-0 items-center gap-2 sm:gap-3">
            {!isSignedIn && !loading && (
              <Link href={`${APP_ORIGIN}/login`} className="hidden rounded-full px-3 py-2 text-sm font-semibold text-[#545a4e] transition-colors hover:text-[#181b14] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#678144] sm:inline-flex">
                Log in
              </Link>
            )}
            <Link href={primaryActionHref} className="inline-flex min-h-11 items-center justify-center gap-1.5 rounded-full bg-[#181b14] px-4 text-xs font-bold text-white shadow-[0_4px_12px_rgba(24,27,20,0.11)] transition-all hover:-translate-y-0.5 hover:bg-[#30392a] hover:shadow-[0_8px_22px_rgba(24,27,20,0.17)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#678144] sm:min-h-12 sm:px-6 sm:text-sm">
              <span>{loading ? 'Open LaterBox' : primaryActionLabel}</span>
              <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
            </Link>

            {/* Mobile Sidebar Hamburger Toggle Button */}
            <button
              type="button"
              aria-label={mobileOpen ? 'Close navigation sidebar' : 'Open navigation sidebar'}
              aria-expanded={mobileOpen}
              aria-controls="laterbox-mobile-sidebar"
              onClick={() => setMobileOpen(prev => !prev)}
              className="relative z-30 inline-flex h-11 w-11 items-center justify-center rounded-xl border border-[#e0e4d8] bg-white text-[#181b14] transition-colors hover:bg-[#e6edb0] active:scale-95 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#678144] lg:hidden cursor-pointer touch-manipulation select-none"
            >
              {mobileOpen ? <X className="h-5 w-5" aria-hidden="true" /> : <Menu className="h-5 w-5" aria-hidden="true" />}
            </button>
          </div>
        </div>
      </header>

      {/* Backdrop Overlay - Always in DOM with pointer-events protection */}
      <div
        className={`fixed inset-0 z-[999] bg-black/60 backdrop-blur-xs transition-opacity duration-300 lg:hidden ${
          mobileOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
        }`}
        onClick={closeMobile}
        aria-hidden="true"
      />

      {/* Proper Mobile Slide-over Sidebar Drawer - Always in DOM, zero-delay CSS slide */}
      <aside
        id="laterbox-mobile-sidebar"
        aria-label="Mobile navigation"
        data-lenis-prevent
        className={`fixed inset-y-0 right-0 z-[1000] w-[310px] sm:w-[350px] max-w-[85vw] bg-[#fbfaf6] border-l border-[#e4e0d5] shadow-[-12px_0_36px_rgba(0,0,0,0.25)] flex flex-col justify-between overflow-hidden transition-transform duration-300 ease-out lg:hidden ${
          mobileOpen ? 'translate-x-0 pointer-events-auto' : 'translate-x-full pointer-events-none'
        }`}
      >
        {/* Sidebar Top Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-[#e4e0d5] bg-[#f8f8f3] shrink-0">
          <Link
            href="/"
            onClick={closeMobile}
            className="group inline-flex shrink-0 items-center gap-2.5"
            aria-label="LaterBox, go to homepage"
          >
            <span className="relative flex h-9 w-9 items-center justify-center overflow-hidden rounded-[10px] border border-[#cbd79c] bg-[#e6edb0] shadow-2xs transition-transform duration-200 group-hover:-rotate-3">
              <Image src="/branding/laterbox-icon.png" alt="" fill priority sizes="36px" className="object-contain p-1" />
            </span>
            <span className="text-xl font-black tracking-[-0.06em] text-[#181b14]">
              laterbox<span className="text-[#84934f]">.</span>
            </span>
          </Link>
          <button
            type="button"
            onClick={closeMobile}
            aria-label="Close navigation sidebar"
            className="inline-flex h-9 w-9 items-center justify-center rounded-xl border border-[#e0e4d8] bg-white text-[#181b14] hover:bg-[#e6edb0] active:scale-95 transition-all cursor-pointer touch-manipulation"
          >
            <X className="h-5 w-5" aria-hidden="true" />
          </button>
        </div>

        {/* Scrollable Navigation Body */}
        <div className="flex-1 overflow-y-auto px-4 py-5 space-y-6" data-lenis-prevent>
          {/* Main Navigation Section */}
          <div className="space-y-1.5">
            <p className="px-3 text-[10px] font-black uppercase tracking-[0.18em] text-[#92998a]">
              Navigation
            </p>
            <div className="space-y-0.5">
              {navLinks.map((link) => {
                const Icon = link.icon;
                const isActive = activeLink(link.href);
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    onClick={closeMobile}
                    aria-current={isActive ? 'page' : undefined}
                    className={`flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-bold transition-colors ${
                      isActive
                        ? 'bg-[#e6edb0] text-[#181b14] shadow-2xs'
                        : 'text-[#383d34] hover:bg-white hover:text-[#181b14]'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon className={`w-4 h-4 ${isActive ? 'text-[#181b14]' : 'text-[#7d8375]'}`} />
                      <span>{link.label}</span>
                    </div>
                    {link.badge && (
                      <span className="text-[10px] font-extrabold px-2 py-0.5 rounded-full bg-white border border-[#d8dccf] text-[#606458]">
                        {link.badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </div>
          </div>

          {/* Resources Section */}
          <div className="space-y-1.5">
            <p className="px-3 text-[10px] font-black uppercase tracking-[0.18em] text-[#92998a]">
              Resources
            </p>
            <div className="space-y-1">
              {mobileResourceLinks.map((link) => {
                const Icon = link.icon;
                const isActive = activeLink(link.href);
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    onClick={closeMobile}
                    aria-current={isActive ? 'page' : undefined}
                    className={`group flex items-start justify-between rounded-xl px-3.5 py-2.5 transition-colors ${
                      isActive
                        ? 'bg-[#e6edb0] text-[#181b14] shadow-2xs'
                        : 'text-[#383d34] hover:bg-white hover:text-[#181b14]'
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <Icon className={`w-4 h-4 mt-0.5 shrink-0 ${isActive ? 'text-[#181b14]' : 'text-[#7d8375]'}`} />
                      <div>
                        <span className="block font-bold text-sm leading-tight text-[#1b2018]">{link.label}</span>
                        <span className="block text-[11px] font-normal text-[#7d8375] mt-0.5 leading-snug">{link.detail}</span>
                      </div>
                    </div>
                    <ChevronRight className="w-4 h-4 text-[#a3aba0] shrink-0 mt-1 opacity-0 group-hover:opacity-100 transition-opacity" />
                  </Link>
                );
              })}
            </div>
          </div>
        </div>

        {/* Bottom Account & CTA Footer */}
        <div className="p-4 border-t border-[#e4e0d5] bg-[#f8f8f3] shrink-0 space-y-2.5">
          {isSignedIn ? (
            <div className="space-y-2">
              <div className="flex items-center gap-2.5 px-3 py-2 rounded-xl bg-white border border-[#e0e4d8] text-xs">
                <div className="w-6 h-6 rounded-full bg-[#e6edb0] flex items-center justify-center font-bold text-[#181b14] text-[11px] shrink-0">
                  {user?.email?.slice(0, 2).toUpperCase() || 'LB'}
                </div>
                <span className="truncate text-[#505649] font-medium">{user?.email || 'Logged In'}</span>
              </div>
              <Link
                href={dashboardHref}
                onClick={closeMobile}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-[#181b14] text-white font-extrabold text-sm shadow-sm hover:bg-[#30392a] active:scale-[0.99] transition-all"
              >
                <span>Open LaterBox</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          ) : (
            <div className="space-y-2">
              <Link
                href={primaryActionHref}
                onClick={closeMobile}
                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-[#181b14] text-white font-extrabold text-sm shadow-sm hover:bg-[#30392a] active:scale-[0.99] transition-all"
              >
                <span>{loading ? 'Open LaterBox' : 'Get started free'}</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
              <Link
                href={`${APP_ORIGIN}/login`}
                onClick={closeMobile}
                className="w-full flex items-center justify-center py-2.5 rounded-xl border border-[#dfe5d5] bg-white text-xs font-bold text-[#181b14] hover:bg-[#f4f7eb] active:scale-[0.99] transition-all"
              >
                Log in to your account
              </Link>
            </div>
          )}
          <p className="text-center text-[10px] text-[#939a87] font-medium pt-0.5">
            Offline-first • Encrypted • Multi-platform
          </p>
        </div>
      </aside>
    </>
  );
}
