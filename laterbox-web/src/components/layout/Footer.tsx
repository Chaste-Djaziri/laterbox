'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';

export function Footer() {
  return (
    <footer className="border-t border-[#e4e0d5] py-12 text-xs text-[#6c6b63] bg-[#f7f5ee] mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-6">
        {/* Brand & Copyright */}
        <div className="flex items-center gap-2.5">
          <div className="w-6 h-6 relative rounded-lg overflow-hidden bg-[#e6edb0] p-1 shrink-0">
            <Image
              src="/branding/laterbox-icon.png"
              alt="laterbox"
              fill
              className="object-contain p-0.5"
            />
          </div>
          <span className="font-extrabold text-[#171711] text-sm">laterbox</span>
          <span className="text-[#9e9b92]">•</span>
          <span>© {new Date().getFullYear()} laterbox. All rights reserved.</span>
        </div>

        {/* Links */}
        <div className="flex flex-wrap items-center justify-center gap-6 font-semibold">
          <Link href="/#features" className="hover:text-[#171711] transition-colors">
            Features
          </Link>
          <Link href="/#how-it-works" className="hover:text-[#171711] transition-colors">
            How It Works
          </Link>
          <Link href="/guide" className="hover:text-[#171711] transition-colors">
            Guide
          </Link>
          <Link href="/download" className="hover:text-[#171711] transition-colors">
            Downloads
          </Link>
          <Link href="/privacy" className="hover:text-[#171711] transition-colors">
            Privacy Policy
          </Link>
          <Link href="/terms" className="hover:text-[#171711] transition-colors">
            Terms of Service
          </Link>
          <Link href="/inbox" className="hover:text-[#171711] transition-colors">
            Web App
          </Link>
        </div>
      </div>
    </footer>
  );
}
