'use client';

import React, { Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { CheckCircle2, ArrowRight } from 'lucide-react';

function ExtensionConnectedContent() {
  const searchParams = useSearchParams();
  const status = searchParams.get('status') || 'approved';

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-zinc-50 text-zinc-900">
      <div className="w-full max-w-md bg-white rounded-3xl p-8 border border-zinc-200/80 shadow-2xl text-center space-y-6 animate-in fade-in">
        <div className="w-16 h-16 mx-auto rounded-3xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-200/60">
          <CheckCircle2 className="w-8 h-8" />
        </div>

        <div className="space-y-2">
          <h1 className="text-2xl font-black tracking-tight text-zinc-900">
            Extension Connected!
          </h1>
          <p className="text-xs sm:text-sm text-zinc-500 leading-relaxed">
            Your laterbox browser extension is now securely paired with your account. You can close this tab and start saving links!
          </p>
        </div>

        <div className="pt-2">
          <Link
            href="/inbox"
            className="inline-flex items-center justify-center gap-2 w-full py-3 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-sm shadow-md transition-all"
          >
            <span>Go to My Inbox</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function ExtensionConnectedPage() {
  return (
    <Suspense fallback={null}>
      <ExtensionConnectedContent />
    </Suspense>
  );
}
