'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/lib/store/AuthContext';
import { Bolt, LogIn } from 'lucide-react';

export function Header() {
  const { user, continueAsGuest } = useAuth();

  return (
    <div className="sticky top-3 sm:top-5 z-40 w-full px-3.5 sm:px-6 lg:px-8 max-w-6xl mx-auto pointer-events-none transition-all duration-300">
      <header className="pointer-events-auto bg-white/90 backdrop-blur-xl border border-[#e4e0d5] shadow-lg shadow-black/[0.03] rounded-2xl sm:rounded-3xl px-4 sm:px-6 py-3 sm:py-3.5 flex items-center justify-between transition-all">
        {/* Brand Logo */}
        <Link href="/" className="flex items-center gap-3 group">
          <div className="w-[40px] h-[40px] relative rounded-xl overflow-hidden shadow-xs transition-transform group-hover:scale-105 bg-[#e6edb0] p-1.5 shrink-0">
            <Image
              src="/branding/laterbox-icon.png"
              alt="laterbox"
              fill
              className="object-contain p-0.5"
              priority
            />
          </div>
          <span className="text-2xl font-black tracking-tight text-[#171711]">
            laterbox
          </span>
        </Link>

        {/* Nav Links */}
        <nav className="hidden md:flex items-center gap-8 text-[15px] font-semibold text-[#6c6b63]">
          <Link href="/#features" className="hover:text-[#171711] transition-colors">
            Features
          </Link>
          <Link href="/#how-it-works" className="hover:text-[#171711] transition-colors">
            How It Works
          </Link>
          <Link href="/tutorial" className="hover:text-[#171711] transition-colors">
            Guide
          </Link>
          <Link href="/download" className="hover:text-[#171711] transition-colors">
            Download
          </Link>
        </nav>

        {/* Auth / Launch Actions */}
        <div className="flex items-center gap-3">
          {user ? (
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-xs sm:text-sm font-extrabold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] shadow-xs transition-all"
            >
              <Bolt className="w-4 h-4" />
              <span>Open Inbox</span>
            </Link>
          ) : (
            <>
              <Link
                href="/login"
                className="hidden sm:inline-flex items-center gap-1.5 px-4 py-2 text-xs sm:text-sm font-bold text-[#171711] hover:bg-[#ebe7dc]/60 rounded-xl transition-colors"
              >
                <LogIn className="w-4 h-4" />
                <span>Sign In</span>
              </Link>
              <Link
                href="/inbox"
                onClick={() => continueAsGuest()}
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-xs sm:text-sm font-extrabold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] shadow-xs transition-all cursor-pointer"
              >
                <Bolt className="w-4 h-4" />
                <span>Launch App</span>
              </Link>
            </>
          )}
        </div>
      </header>
    </div>
  );
}
