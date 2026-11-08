// laterbox-web/src/components/layout/Header.tsx
'use client';

import { useEffect, useRef, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ArrowRight, ChevronDown, Menu, X } from 'lucide-react';
import { APP_ORIGIN } from '@/lib/auth/config';
import { useAuth } from '@/lib/store/AuthContext';

const primaryLinks = [
  { href: '/features', label: 'Features' },
  { href: '/#how-it-works', label: 'How it works' },
  { href: '/browser-extension', label: 'Browser extension' },
  { href: '/pricing', label: 'Pricing' },
] as const;

const resourceLinks = [
  { href: '/about', label: 'About LaterBox', detail: 'The thinking behind the product' },
  { href: '/download', label: 'Apps & downloads', detail: 'Bring LaterBox to your devices' },
  { href: '/guide', label: 'Getting started', detail: 'Your first save, step by step' },
] as const;

export function Header() {
  const pathname = usePathname();
  const { isAuthenticated, user, loading } = useAuth();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [resourcesOpen, setResourcesOpen] = useState(false);
  const [hasScrolled, setHasScrolled] = useState(false);
  const resourcesRef = useRef<HTMLDivElement>(null);
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
    if (!mobileOpen && !resourcesOpen) return;
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setMobileOpen(false);
        setResourcesOpen(false);
      }
    };
    const closeResourcesOutside = (event: PointerEvent) => {
      if (resourcesRef.current && !resourcesRef.current.contains(event.target as Node)) {
        setResourcesOpen(false);
      }
    };
    document.addEventListener('keydown', closeOnEscape);
    document.addEventListener('pointerdown', closeResourcesOutside);
    return () => {
      document.removeEventListener('keydown', closeOnEscape);
      document.removeEventListener('pointerdown', closeResourcesOutside);
    };
  }, [mobileOpen, resourcesOpen]);

  const activeLink = (href: string) => href !== '/#how-it-works' && pathname === href;
  const closeMobile = () => setMobileOpen(false);

  return (
    <>
      <div className="bg-[#181b14] text-white">
        <div className="mx-auto flex min-h-9 max-w-[1240px] items-center justify-center gap-2 px-4 py-2 text-center text-[11px] font-medium tracking-[0.01em] sm:text-xs">
          <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-[#e6edb0]" aria-hidden="true" />
          <span>Less tab clutter. More room to think.</span>
          <Link href="/#how-it-works" className="inline-flex items-center gap-1 font-bold text-[#e6edb0] underline-offset-4 hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#e6edb0]">
            See how it works <ArrowRight className="h-3 w-3" aria-hidden="true" />
          </Link>
        </div>
      </div>

      <header className={`sticky top-0 z-50 w-full border-b bg-[#f8f8f3]/95 backdrop-blur-xl transition-[border-color,box-shadow] duration-200 ${hasScrolled ? 'border-[#e6e7de] shadow-[0_5px_24px_rgba(24,27,20,0.045)]' : 'border-transparent shadow-none'}`}>
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

          <nav aria-label="Main navigation" className="hidden items-center gap-0.5 lg:flex xl:gap-1">
            {primaryLinks.map(link => (
              <Link
                key={link.href}
                href={link.href}
                aria-current={activeLink(link.href) ? 'page' : undefined}
                className={`rounded-full px-3 py-3 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#678144] xl:px-4 xl:text-sm ${
                  activeLink(link.href) ? 'bg-[#e6edb0] text-[#181b14]' : 'text-[#606458] hover:bg-white hover:text-[#181b14]'
                }`}
              >{link.label}</Link>
            ))}
            <div className="relative" ref={resourcesRef}>
              <button
                type="button"
                aria-expanded={resourcesOpen}
                aria-controls="laterbox-resources-menu"
                aria-haspopup="true"
                onClick={() => setResourcesOpen(value => !value)}
                className={`inline-flex items-center gap-1.5 rounded-full px-3 py-3 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#678144] xl:px-4 xl:text-sm ${
                  resourcesOpen ? 'bg-white text-[#181b14]' : 'text-[#606458] hover:bg-white hover:text-[#181b14]'
                }`}
              >
                More <ChevronDown className={`h-3.5 w-3.5 transition-transform ${resourcesOpen ? 'rotate-180' : ''}`} aria-hidden="true" />
              </button>
              {resourcesOpen && (
                <div id="laterbox-resources-menu" className="absolute left-1/2 top-[calc(100%+14px)] z-50 w-[290px] -translate-x-1/2 rounded-[20px] border border-[#e5e8db] bg-white p-2.5 shadow-[0_25px_80px_rgba(24,27,20,0.14)]">
                  <p className="px-3 pb-1.5 pt-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#939a87]">Explore LaterBox</p>
                  {resourceLinks.map(link => (
                    <Link key={link.href} href={link.href} onClick={() => setResourcesOpen(false)}
                      className="block rounded-xl px-3 py-3 transition-colors hover:bg-[#f4f7eb] focus-visible:outline-2 focus-visible:outline-[#678144]">
                      <span className="block text-sm font-bold text-[#1b2018]">{link.label}</span>
                      <span className="mt-0.5 block text-xs text-[#7d8375]">{link.detail}</span>
                    </Link>
                  ))}
                </div>
              )}
            </div>
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
            <button
              type="button"
              aria-label={mobileOpen ? 'Close navigation' : 'Open navigation'}
              aria-expanded={mobileOpen}
              aria-controls="laterbox-mobile-navigation"
              onClick={() => setMobileOpen(value => !value)}
              className="inline-flex h-11 w-11 items-center justify-center rounded-xl border border-[#e0e4d8] bg-white text-[#181b14] transition-colors hover:bg-[#e6edb0] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#678144] lg:hidden"
            >
              {mobileOpen ? <X className="h-5 w-5" aria-hidden="true" /> : <Menu className="h-5 w-5" aria-hidden="true" />}
            </button>
          </div>
        </div>

        {mobileOpen && (
          <nav id="laterbox-mobile-navigation" aria-label="Mobile navigation" className="border-t border-[#e6e8df] bg-[#f8f8f3] px-4 pb-5 pt-3 shadow-[0_16px_25px_rgba(24,27,20,0.06)] sm:px-6 lg:hidden">
            <div className="mx-auto max-w-[1240px]">
              <p className="px-3 pb-2 pt-2 text-[10px] font-black uppercase tracking-[0.18em] text-[#92998a]">Discover</p>
              {[...primaryLinks, ...resourceLinks].map(link => (
                <Link
                  key={link.href}
                  href={link.href}
                  onClick={closeMobile}
                  aria-current={activeLink(link.href) ? 'page' : undefined}
                  className={`flex min-h-12 items-center justify-between rounded-xl px-3.5 text-[15px] font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-[#678144] ${
                    activeLink(link.href) ? 'bg-[#e6edb0] text-[#1b2018]' : 'text-[#485044] hover:bg-white'
                  }`}
                >
                  {link.label}<ArrowRight className="h-4 w-4 text-[#959d8b]" aria-hidden="true" />
                </Link>
              ))}
              {!isSignedIn && !loading && (
                <Link href={`${APP_ORIGIN}/login`} onClick={closeMobile} className="mt-3 flex min-h-12 items-center justify-center rounded-xl border border-[#dfe5d5] bg-white px-4 text-sm font-bold text-[#1b2018] sm:hidden">Log in to your account</Link>
              )}
            </div>
          </nav>
        )}
      </header>
    </>
  );
}
