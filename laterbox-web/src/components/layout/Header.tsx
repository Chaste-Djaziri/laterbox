'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/store/AuthContext';
import { Bolt, LogIn, Menu, X } from 'lucide-react';

export function Header() {
  const pathname = usePathname();
  const { user, continueAsGuest } = useAuth();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Close mobile menu on route change
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [pathname]);

  const navLinks = [
    { href: '/plans', label: 'Plans' },
    { href: '/download', label: 'Downloads' },
    { href: '/docs', label: 'Docs' },
    { href: '/guide', label: 'Guide' },
  ];

  return (
    <header className="sticky top-0 z-50 w-full bg-[#f7f5ee]/90 backdrop-blur-md border-b border-[#e4e0d5]/60">
      <div className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="w-full flex items-center justify-between md:grid md:grid-cols-[1fr_auto_1fr] py-3.5 sm:py-4">
          {/* Brand Logo */}
          <Link href="/" className="flex items-center gap-2 sm:gap-3 shrink-0 md:justify-self-start">
            <div className="w-[34px] h-[34px] sm:w-[42px] sm:h-[42px] relative rounded-xl overflow-hidden shadow-xs bg-[#e6edb0] p-1 sm:p-1.5 shrink-0">
              <Image
                src="/branding/laterbox-icon.png"
                alt="laterbox"
                fill
                sizes="(max-width: 640px) 34px, 42px"
                className="object-contain p-0.5"
                priority
              />
            </div>
            <span className="text-lg sm:text-2xl font-black tracking-tight text-[#171711]">
              laterbox
            </span>
          </Link>

          {/* Nav Links (Pages Only) */}
          <nav className="hidden md:flex items-center gap-7 text-[14px] font-semibold text-[#6c6b63] justify-self-center">
            {navLinks.map((link) => {
              const isActive = pathname === link.href;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`relative py-1 ${
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
          <div className="flex items-center gap-1.5 sm:gap-3 shrink-0 md:justify-self-end">
            {user ? (
              <Link
                href="/inbox"
                className="inline-flex items-center gap-1.5 sm:gap-2 px-3.5 sm:px-5 py-2 sm:py-2.5 rounded-full text-xs sm:text-sm font-extrabold text-white bg-[#171711] hover:bg-black active:bg-[#0f0f0e] shadow-xs whitespace-nowrap shrink-0"
              >
                <Bolt className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                <span>Open Inbox</span>
              </Link>
            ) : (
              <>
                <Link
                  href="/login"
                  className="hidden sm:inline-flex items-center gap-1.5 px-3.5 py-2 text-xs sm:text-sm font-bold text-[#171711] hover:bg-[#ebe7dc]/60 rounded-xl shrink-0"
                >
                  <LogIn className="w-3.5 h-3.5 sm:w-4 sm:h-4" />
                  <span>Sign In</span>
                </Link>
                <Link
                  href="/inbox"
                  onClick={() => continueAsGuest()}
                  className="inline-flex items-center gap-1.5 sm:gap-2 px-3.5 sm:px-5 py-2 sm:py-2.5 rounded-full text-xs sm:text-sm font-extrabold text-white bg-[#171711] hover:bg-black active:bg-[#0f0f0e] shadow-xs cursor-pointer whitespace-nowrap shrink-0"
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
              className="md:hidden p-1.5 sm:p-2 rounded-xl text-[#171711] hover:bg-[#ebe7dc]/70 active:bg-[#ebe7dc] shrink-0"
              aria-label="Toggle navigation menu"
            >
              {isMobileMenuOpen ? (
                <X className="w-5 h-5" />
              ) : (
                <Menu className="w-5 h-5" />
              )}
            </button>
          </div>
        </div>

        {/* Mobile Navigation Drawer */}
        {isMobileMenuOpen && (
          <div className="md:hidden pb-4 pt-1">
            <div className="p-3.5 sm:p-4 rounded-2xl bg-white border border-[#e4e0d5] shadow-xl shadow-black/[0.04]">
              <div className="space-y-1">
                {navLinks.map((link) => {
                  const isActive = pathname === link.href;
                  return (
                    <Link
                      key={link.href}
                      href={link.href}
                      className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-semibold ${
                        isActive
                          ? 'bg-[#e6edb0]/60 text-[#171711] font-bold'
                          : 'text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f2]'
                      }`}
                    >
                      <span>{link.label}</span>
                      {isActive && (
                        <span className="w-1.5 h-1.5 rounded-full bg-[#171711]" />
                      )}
                    </Link>
                  );
                })}

                {!user && (
                  <div className="pt-2.5 border-t border-[#f0ede4] mt-2 space-y-1">
                    <Link
                      href="/login"
                      className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-sm font-bold text-[#171711] hover:bg-[#faf8f2]"
                    >
                      <LogIn className="w-4 h-4 text-[#6c6b63]" />
                      <span>Sign In</span>
                    </Link>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
