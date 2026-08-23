'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/lib/store/AuthContext';
import { Bolt, LogIn } from 'lucide-react';

export function Header() {
  const { user, continueAsGuest } = useAuth();

  return (
    <header className="sticky top-0 z-40 w-full border-b border-zinc-200/80 bg-white/80 backdrop-blur-md transition-all">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand Logo */}
        <Link href="/" className="flex items-center gap-2.5 group">
          <div className="w-8 h-8 relative rounded-xl overflow-hidden shadow-sm transition-transform group-hover:scale-105">
            <Image
              src="/branding/laterbox-icon.png"
              alt="laterbox"
              fill
              className="object-contain"
              priority
            />
          </div>
          <span className="text-xl font-black tracking-tight text-zinc-900">
            laterbox
          </span>
        </Link>

        {/* Nav Links */}
        <nav className="hidden md:flex items-center gap-6 text-sm font-semibold text-zinc-600">
          <Link href="/#features" className="hover:text-emerald-600 transition-colors">
            Features
          </Link>
          <Link href="/#how-it-works" className="hover:text-emerald-600 transition-colors">
            How It Works
          </Link>
          <Link href="/tutorial" className="hover:text-emerald-600 transition-colors">
            Guide
          </Link>
          <Link href="/download" className="hover:text-emerald-600 transition-colors">
            Download
          </Link>
        </nav>

        {/* Auth / Launch Actions */}
        <div className="flex items-center gap-3">
          {user ? (
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 shadow-sm transition-all"
            >
              <Bolt className="w-4 h-4" />
              <span>Open Inbox</span>
            </Link>
          ) : (
            <>
              <Link
                href="/login"
                className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-zinc-700 hover:text-emerald-600 transition-colors"
              >
                <LogIn className="w-4 h-4" />
                <span>Sign In</span>
              </Link>
              <Link
                href="/inbox"
                onClick={() => continueAsGuest()}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 shadow-sm transition-all"
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
