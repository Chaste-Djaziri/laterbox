// laterbox-web/src/components/marketing/ReferralWelcomePage.tsx
'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import {
  ArrowRight,
  Check,
  CheckCircle2,
  Clock,
  Cloud,
  Copy,
  Download,
  FolderOpen,
  Gift,
  Inbox,
  Laptop,
  Lock,
  Plus,
  ShieldCheck,
  Smartphone,
  Sparkles,
  Star,
  Zap,
} from 'lucide-react';

interface ReferralWelcomePageProps {
  referralCode: string;
}

export function ReferralWelcomePage({ referralCode }: ReferralWelcomePageProps) {
  const [copied, setCopied] = useState(false);
  const cleanCode = (referralCode || '').trim().toLowerCase();

  // Persist attribution cookie & storage on visitor landing
  useEffect(() => {
    if (!cleanCode) return;

    try {
      // 30 days cookie
      const maxAge = 30 * 24 * 60 * 60;
      const isProd = typeof window !== 'undefined' && window.location.hostname.endsWith('laterbox.dev');
      const domainAttr = isProd ? '; domain=.laterbox.dev' : '';
      document.cookie = `laterbox_ref=${encodeURIComponent(cleanCode)}; path=/; max-age=${maxAge}; SameSite=Lax${domainAttr}${
        isProd ? '; Secure' : ''
      }`;

      // Local storage backup
      localStorage.setItem('laterbox_ref', cleanCode);
      sessionStorage.setItem('laterbox_ref', cleanCode);
    } catch {
      // Ignore client storage restrictions
    }
  }, [cleanCode]);

  const copyCode = () => {
    if (typeof navigator !== 'undefined') {
      navigator.clipboard.writeText(cleanCode);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const signupHref = cleanCode ? `/signup?ref=${encodeURIComponent(cleanCode)}` : '/signup';
  const loginHref = cleanCode ? `/login?ref=${encodeURIComponent(cleanCode)}` : '/login';

  return (
    <div className="relative min-h-screen bg-[#f8f9f4] text-[#192018] overflow-hidden">
      {/* Decorative ambient background accents */}
      <div
        className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 h-[500px] w-[800px] rounded-full bg-gradient-to-b from-[#e6edb0]/50 to-transparent blur-3xl"
        aria-hidden="true"
      />

      <div className="relative mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 pt-12 sm:pt-20 pb-28">
        {/* =================================================================== */}
        {/* HERO SECTION                                                       */}
        {/* =================================================================== */}
        <div className="text-center space-y-5">
          {/* Active Referral Pill */}
          <div className="inline-flex items-center gap-2 rounded-full border border-[#d3df9e] bg-[#e6edb0]/70 px-4 py-1.5 shadow-xs backdrop-blur-sm">
            <Gift className="h-4 w-4 text-[#3e5229]" />
            <span className="text-xs sm:text-sm font-bold text-[#233318]">
              Personal Invite Activated:
            </span>
            <code className="rounded-md bg-[#233318] px-2 py-0.5 text-xs font-mono font-black text-[#e6edb0]">
              {cleanCode.toUpperCase()}
            </code>
            <button
              type="button"
              onClick={copyCode}
              title="Copy invite code"
              className="ml-1 rounded p-0.5 text-[#3e5229] hover:text-[#192018] transition-colors"
            >
              {copied ? <Check className="h-3.5 w-3.5 text-emerald-700" /> : <Copy className="h-3.5 w-3.5" />}
            </button>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight text-[#171711] max-w-3xl mx-auto leading-[1.08]">
            You&apos;ve been invited to LaterBox.
          </h1>

          <p className="mx-auto max-w-2xl text-base sm:text-lg text-[#555f4f] leading-relaxed">
            Your friend invited you to join LaterBox — the calm, local-first inbox for your links, articles, videos, and notes. Save anything in one click, and triage it whenever you&apos;re ready.
          </p>

          {/* Primary Action Buttons */}
          <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3.5">
            <Link
              href={signupHref}
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 rounded-2xl bg-[#171711] px-7 py-4 text-sm font-bold text-[#e6edb0] shadow-lg shadow-[#171711]/10 transition-all hover:bg-[#2b3323] hover:scale-[1.02] focus-visible:outline-2 focus-visible:outline-[#758a50]"
            >
              <span>Claim Invite &amp; Start Free</span>
              <ArrowRight className="h-4 w-4" />
            </Link>

            <Link
              href={loginHref}
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-2xl border border-[#d9dece] bg-white px-6 py-4 text-sm font-bold text-[#171711] shadow-xs transition-colors hover:bg-[#edf0e4]"
            >
              <span>Already have an account? Sign in</span>
            </Link>
          </div>

          <p className="text-xs text-[#788470]">
            Free forever tier · No credit card required to start · Instant onboarding
          </p>
        </div>

        {/* =================================================================== */}
        {/* EXCLUSIVE PERKS CARD                                               */}
        {/* =================================================================== */}
        <div className="mt-14 rounded-3xl border border-[#e4e5d9] bg-white p-7 sm:p-9 shadow-sm">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-[#f0ede5] pb-6">
            <div>
              <span className="text-[11px] font-bold uppercase tracking-widest text-[#74806e]">
                Exclusive Referral Benefits
              </span>
              <h2 className="mt-1 text-xl sm:text-2xl font-bold text-[#171711]">
                What you unlock with code &ldquo;{cleanCode}&rdquo;
              </h2>
            </div>
            <div className="flex items-center gap-2 rounded-2xl bg-[#edf0e2] px-4 py-2 border border-[#d3df9e]">
              <Sparkles className="h-5 w-5 text-[#435b34]" />
              <span className="text-xs font-bold text-[#233318]">Invite Perks Active</span>
            </div>
          </div>

          <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            <div className="rounded-2xl border border-[#e4e0d5] bg-[#faf8f5] p-5 space-y-2">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e6edb0] text-[#171711]">
                <Cloud className="h-5 w-5" />
              </div>
              <h3 className="font-bold text-sm text-[#171711]">500 MB Free Cloud Vault</h3>
              <p className="text-xs text-[#677362] leading-relaxed">
                Seamless multi-device cloud backup and synchronization for your links, reading list, and files.
              </p>
            </div>

            <div className="rounded-2xl border border-[#e4e0d5] bg-[#faf8f5] p-5 space-y-2">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e6edb0] text-[#171711]">
                <Zap className="h-5 w-5" />
              </div>
              <h3 className="font-bold text-sm text-[#171711]">Universal 1-Click Capture</h3>
              <p className="text-xs text-[#677362] leading-relaxed">
                Quick capture shortcut (<code className="font-mono text-[11px] bg-white px-1 py-0.5 rounded border">Ctrl+Alt+L</code>), iOS Share Sheet, and Chrome extension.
              </p>
            </div>

            <div className="rounded-2xl border border-[#e4e0d5] bg-[#faf8f5] p-5 space-y-2">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e6edb0] text-[#171711]">
                <Clock className="h-5 w-5" />
              </div>
              <h3 className="font-bold text-sm text-[#171711]">30-Day Storage Trial Perks</h3>
              <p className="text-xs text-[#677362] leading-relaxed">
                Eligible for high-capacity storage trials and priority referral perks when you upgrade to Plus or Vault.
              </p>
            </div>

            <div className="rounded-2xl border border-[#e4e0d5] bg-[#faf8f5] p-5 space-y-2">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e6edb0] text-[#171711]">
                <Lock className="h-5 w-5" />
              </div>
              <h3 className="font-bold text-sm text-[#171711]">100% Local-First &amp; Private</h3>
              <p className="text-xs text-[#677362] leading-relaxed">
                Your data stays cached on your device. Fast offline access with zero telemetry or algorithmic feed distractions.
              </p>
            </div>
          </div>
        </div>

        {/* =================================================================== */}
        {/* PRODUCT SHOWCASE: HOW LATERBOX WORKS                               */}
        {/* =================================================================== */}
        <div className="mt-16 space-y-8">
          <div className="text-center max-w-xl mx-auto space-y-2">
            <span className="text-[11px] font-bold uppercase tracking-widest text-[#74806e]">
              Calm Product Workflow
            </span>
            <h2 className="text-2xl sm:text-3xl font-black text-[#171711]">
              How LaterBox organizes your digital life
            </h2>
            <p className="text-sm text-[#677362]">
              Stop hoarding 80 open browser tabs. Capture everything in seconds, triage with email-style simplicity.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Step 1 */}
            <div className="rounded-2xl border border-[#e4e5d9] bg-white p-6 space-y-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#171711] text-xs font-bold text-[#e6edb0]">
                1
              </div>
              <h3 className="text-base font-bold text-[#171711]">Capture from anywhere</h3>
              <p className="text-xs text-[#677362] leading-relaxed">
                Reading an article, finding a video, or saving a reference document? Hit your shortcut or share sheet and it lands right in your inbox instantly.
              </p>
            </div>

            {/* Step 2 */}
            <div className="rounded-2xl border border-[#e4e5d9] bg-white p-6 space-y-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#171711] text-xs font-bold text-[#e6edb0]">
                2
              </div>
              <h3 className="text-base font-bold text-[#171711]">Calm email-style triage</h3>
              <p className="text-xs text-[#677362] leading-relaxed">
                Review your saved items when you have focus time. Keep favorites, archive finished reads, or schedule them to return Today or Upcoming.
              </p>
            </div>

            {/* Step 3 */}
            <div className="rounded-2xl border border-[#e4e5d9] bg-white p-6 space-y-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#171711] text-xs font-bold text-[#e6edb0]">
                3
              </div>
              <h3 className="text-base font-bold text-[#171711]">Organize in Collections</h3>
              <p className="text-xs text-[#677362] leading-relaxed">
                Group research into projects, recipes, design inspirations, or travel plans. Everything stays searchable, offline-ready, and organized.
              </p>
            </div>
          </div>
        </div>

        {/* =================================================================== */}
        {/* PLATFORMS AVAILABILITY ROW                                          */}
        {/* =================================================================== */}
        <div className="mt-16 rounded-3xl border border-[#d3df9e] bg-[#e6edb0]/40 p-8 text-center space-y-6">
          <div className="max-w-lg mx-auto space-y-2">
            <h3 className="text-xl sm:text-2xl font-bold text-[#171711]">
              Available on all your devices
            </h3>
            <p className="text-xs sm:text-sm text-[#4d5c3d]">
              Sync your library everywhere without friction. Sign in with the same account to access your items offline and online.
            </p>
          </div>

          <div className="flex flex-wrap items-center justify-center gap-3 sm:gap-4">
            <div className="flex items-center gap-2 rounded-xl bg-white/80 border border-[#cddca8] px-4 py-2.5 text-xs font-bold text-[#171711] shadow-2xs">
              <Smartphone className="h-4 w-4 text-[#435b34]" />
              <span>iOS App Store</span>
            </div>

            <div className="flex items-center gap-2 rounded-xl bg-white/80 border border-[#cddca8] px-4 py-2.5 text-xs font-bold text-[#171711] shadow-2xs">
              <Laptop className="h-4 w-4 text-[#435b34]" />
              <span>Chrome Web Store</span>
            </div>

            <div className="flex items-center gap-2 rounded-xl bg-white/80 border border-[#cddca8] px-4 py-2.5 text-xs font-bold text-[#171711] shadow-2xs">
              <Smartphone className="h-4 w-4 text-[#435b34]" />
              <span>Android APK</span>
            </div>

            <div className="flex items-center gap-2 rounded-xl bg-white/80 border border-[#cddca8] px-4 py-2.5 text-xs font-bold text-[#171711] shadow-2xs">
              <Cloud className="h-4 w-4 text-[#435b34]" />
              <span>Web Application (PWA)</span>
            </div>
          </div>
        </div>

        {/* =================================================================== */}
        {/* FINAL ONBOARDING CTA CARD                                          */}
        {/* =================================================================== */}
        <div className="mt-16 text-center space-y-4">
          <h2 className="text-2xl sm:text-3xl font-black text-[#171711]">
            Ready to reclaim your focus?
          </h2>
          <p className="text-sm text-[#677362] max-w-md mx-auto">
            Join LaterBox with invite code <strong className="text-[#171711] font-mono">{cleanCode}</strong> and start saving for later in under 30 seconds.
          </p>
          <div className="pt-2">
            <Link
              href={signupHref}
              className="inline-flex items-center justify-center gap-2 rounded-2xl bg-[#171711] px-8 py-4 text-sm font-bold text-[#e6edb0] shadow-md hover:bg-[#2b3323] transition-all hover:scale-105"
            >
              <span>Get Started with Code {cleanCode.toUpperCase()}</span>
              <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
        </div>
      </div>

      {/* ===================================================================== */}
      {/* FLOATING INVITATION TOAST REMINDER                                  */}
      {/* ===================================================================== */}
      <div className="fixed bottom-5 left-1/2 -translate-x-1/2 z-40 w-full max-w-md px-4 pointer-events-none">
        <div className="pointer-events-auto flex items-center justify-between gap-3 rounded-2xl border border-[#d3df9e] bg-[#e6edb0]/95 backdrop-blur-md p-3.5 shadow-xl shadow-[#171711]/10">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-[#233318] text-[#e6edb0]">
              <Gift className="h-4 w-4" />
            </div>
            <div className="min-w-0">
              <p className="text-xs font-bold text-[#171711] truncate">
                Invite: <span className="font-mono">{cleanCode.toUpperCase()}</span>
              </p>
              <p className="text-[11px] text-[#4d5c3d] truncate">500 MB Free Cloud Vault active</p>
            </div>
          </div>
          <Link
            href={signupHref}
            className="shrink-0 inline-flex items-center gap-1 rounded-xl bg-[#171711] px-3 py-1.5 text-xs font-bold text-[#e6edb0] shadow-xs hover:bg-[#2b3323] transition-colors"
          >
            <span>Claim</span>
            <ArrowRight className="h-3 w-3" />
          </Link>
        </div>
      </div>
    </div>
  );
}
