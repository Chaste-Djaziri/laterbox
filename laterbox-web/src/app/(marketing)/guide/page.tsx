// laterbox-web/src/app/(marketing)/guide/page.tsx
'use client';

import React from 'react';
import Link from 'next/link';
import { ArrowRight, BookOpen, Clock, Download, Sparkles } from 'lucide-react';

export default function GuidePage() {
  return (
    <div className="w-full flex-1 bg-[#fbfaf6]">
      <main className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-20 sm:py-32 text-center space-y-8">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#f4f7eb] border border-[#cbd79c] text-xs font-bold text-[#2c3324]">
          <Clock className="w-3.5 h-3.5 text-[#5e773c]" />
          <span>Coming Soon</span>
        </div>

        <div className="space-y-3">
          <h1 className="text-3xl sm:text-5xl font-black text-[#181b14] tracking-[-0.04em]">
            Guide coming soon.
          </h1>
          <p className="text-sm sm:text-base text-[#606458] font-medium max-w-lg mx-auto leading-relaxed">
            We are working on it. A full interactive getting started walkthrough and onboarding tutorials are on the way.
          </p>
        </div>

        <div className="pt-4 flex flex-wrap items-center justify-center gap-3">
          <Link
            href="/docs"
            className="inline-flex items-center gap-2 px-5 py-3 rounded-2xl bg-[#181b14] hover:bg-[#30392a] text-white text-xs font-bold transition-all shadow-2xs"
          >
            <BookOpen className="w-4 h-4 text-[#e6edb0]" />
            <span>Read Documentation</span>
          </Link>
          <Link
            href="/download"
            className="inline-flex items-center gap-2 px-5 py-3 rounded-2xl bg-white border border-[#e4e0d5] hover:bg-[#f4f7eb] text-[#181b14] text-xs font-bold transition-all shadow-2xs"
          >
            <Download className="w-4 h-4" />
            <span>Download Apps</span>
          </Link>
          <Link
            href="/inbox"
            className="inline-flex items-center gap-1.5 px-5 py-3 rounded-2xl text-xs font-bold text-[#606458] hover:text-[#181b14] transition-colors"
          >
            <span>Launch Web App</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>
      </main>
    </div>
  );
}
