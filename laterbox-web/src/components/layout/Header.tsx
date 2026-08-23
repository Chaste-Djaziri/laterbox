'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/lib/store/AuthContext';
import { Bolt, LogIn } from 'lucide-react';

export function Header() {
  const { user, continueAsGuest } = useAuth();

  return (
    <header className="sticky top-0 z-40 w-full border-b border-[#e4e0d5] bg-[#f7f5ee]/90 backdrop-blur-md transition-all">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand Logo */}
        <Link href="/" className="flex items-center gap-2.5 group">
          <div className="w-[34px] h-[34px] relative rounded-[9px] overflow-hidden shadow-sm transition-transform group-hover:scale-105 bg-[#e6edb0] p-1">
            <Image
              src="/branding/laterbox-icon.png"
              alt="laterbox"
              fill
              className="object-contain p-0.5"
              priority
            />
          </div>
          <span className="text-xl font-black tracking-tight text-[#171711]">
            laterbox
          </span>
        </Link>

        {/* Nav Links */}
        <nav className="hidden md:flex items-center gap-6 text-sm font-semibold text-[#6c6b63]">
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
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] shadow-sm transition-all"
            >
              <Bolt className="w-4 h-4" />
              <span>Open Inbox</span>
            </Link>
          ) : (
            <>
              <Link
                href="/login"
                className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-[#171711] hover:text-black transition-colors"
              >
                <LogIn className="w-4 h-4" />
                <span>Sign In</span>
              </Link>
              <Link
                href="/inbox"
                onClick={() => continueAsGuest()}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] shadow-sm transition-all"
              >
                <Bolt className="w-4 h-4" />
                <span>Launch App</span>
              </Link>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
