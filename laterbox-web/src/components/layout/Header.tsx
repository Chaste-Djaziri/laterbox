'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/store/AuthContext';
import { Bolt, LogIn, Menu, X, BookOpen, Download, ShieldCheck, FileText, Sparkles } from 'lucide-react';

export function Header() {
  const pathname = usePathname();
  const { user, continueAsGuest } = useAuth();
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 20) {
        setIsScrolled(true);
      } else {
        setIsScrolled(false);
      }
    };

    handleScroll();
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Close mobile menu on route change
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);

  const navLinks = [
    { href: '/download', label: 'Downloads' },
    { href: '/docs', label: 'Docs' },
    { href: '/guide', label: 'Guide' },
    { href: '/tutorial', label: 'Tutorial' },
    { href: '/privacy', label: 'Privacy' },
    { href: '/terms', label: 'Terms' },
  ];

  return (
    <div
      className={`sticky z-40 w-full transition-all duration-300 ${
        isScrolled
          ? 'top-3 sm:top-4 px-3.5 sm:px-6 lg:px-8 max-w-6xl mx-auto pointer-events-none'
          : 'top-0 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto pointer-events-auto bg-transparent'
      }`}
    >
      <header
        className={`w-full flex items-center justify-between transition-all duration-300 ${
          isScrolled
            ? 'pointer-events-auto bg-white/90 backdrop-blur-xl border border-[#e4e0d5] shadow-lg shadow-black/[0.03] rounded-2xl sm:rounded-3xl px-4 sm:px-6 py-2.5 sm:py-3'
            : 'bg-transparent border-b border-transparent py-5 sm:py-6'
        }`}
      >
        {/* Brand Logo */}
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-[38px] h-[38px] sm:w-[42px] sm:h-[42px] relative rounded-xl overflow-hidden shadow-xs transition-transform group-hover:scale-105 bg-[#e6edb0] p-1.5 shrink-0">
            <Image
              src="/branding/laterbox-icon.png"
              alt="laterbox"
              fill
              sizes="42px"
              className="object-contain p-0.5"
              priority
            />
          </div>
          <span className="text-xl sm:text-2xl font-black tracking-tight text-[#171711]">
            laterbox
          </span>
        </Link>

        {/* Nav Links (Pages Only) */}
        <nav className="hidden md:flex items-center gap-7 text-[14px] font-semibold text-[#6c6b63]">
          {navLinks.map((link) => {
            const isActive = pathname === link.href;
            return (
              <Link
                key={link.href}
                href={link.href}
                className={`transition-colors relative py-1 ${
                  isActive
                    ? 'text-[#171711] font-bold'
                    : 'hover:text-[#171711]'
                }`}
              >
                <span>{link.label}</span>
                {isActive && (
                  <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#171711] rounded-full" />
                )}
              </Link>
            );
          })}
        </nav>

        {/* Auth / Launch Actions & Mobile Toggle */}
        <div className="flex items-center gap-2.5 sm:gap-3">
          {user ? (
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-4 sm:px-5 py-2 sm:py-2.5 rounded-full text-xs sm:text-sm font-extrabold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] shadow-xs transition-all"
            >
              <Bolt className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
              <span>Open Inbox</span>
            </Link>
          ) : (
            <>
              <Link
                href="/login"
                className="hidden sm:inline-flex items-center gap-1.5 px-3.5 py-2 text-xs sm:text-sm font-bold text-[#171711] hover:bg-[#ebe7dc]/60 rounded-xl transition-colors"
              >
                <LogIn className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                <span>Sign In</span>
              </Link>
              <Link
                href="/inbox"
                onClick={() => continueAsGuest()}
                className="inline-flex items-center gap-1.5 sm:gap-2 px-4 sm:px-5 py-2 sm:py-2.5 rounded-full text-xs sm:text-sm font-extrabold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] shadow-xs transition-all cursor-pointer"
              >
                <Bolt className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                <span>Launch App</span>
              </Link>
            </>
          )}

          {/* Mobile Menu Toggle Button */}
          <button
            type="button"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="md:hidden p-2 rounded-xl text-[#171711] hover:bg-[#ebe7dc]/70 transition-colors"
            aria-label="Toggle navigation menu"
          >
            {isMobileMenuOpen ? (
              <X className="w-5 h-5" />
            ) : (
              <Menu className="w-5 h-5" />
            )}
          </button>
        </div>
      </header>

      {/* Mobile Navigation Drawer */}
      {isMobileMenuOpen && (
        <div className="md:hidden mt-2 p-4 rounded-2xl bg-white border border-[#e4e0d5] shadow-xl pointer-events-auto animate-in fade-in slide-in-from-top-2 duration-150">
          <div className="space-y-1">
            {navLinks.map((link) => {
              const isActive = pathname === link.href;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`block px-4 py-2.5 rounded-xl text-sm font-semibold transition-colors ${
                    isActive
                      ? 'bg-[#f7f5ee] text-[#171711] font-bold'
                      : 'text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f2]'
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}

            {!user && (
              <div className="pt-3 border-t border-[#f0ede4] mt-2">
                <Link
                  href="/login"
                  className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-bold text-[#171711] hover:bg-[#faf8f2] transition-colors"
                >
                  <LogIn className="w-4 h-4" />
                  <span>Sign In</span>
                </Link>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
