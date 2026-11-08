// laterbox-web/src/components/marketing/MarketingHero.tsx
'use client';

import Link from 'next/link';
import { ArrowRight, ArrowUpRight, Bookmark, Check, CheckCheck, Puzzle, Clock3, FileText, FolderOpen, Globe2, Link2, Search, Smartphone, Sparkles, Video } from 'lucide-react';
import { APP_ORIGIN } from '@/lib/auth/config';
import { useAuth } from '@/lib/store/AuthContext';

const itemCards = [
  { icon: FileText, title: 'A really good article about design', source: 'Read later', note: 'Tomorrow', tone: 'bg-[#f2f2e8]' },
  { icon: Video, title: 'The video everyone is talking about', source: 'Watch later', note: 'Weekend', tone: 'bg-[#e6edb0]/60' },
  { icon: Link2, title: 'Inspiration for the next big idea', source: 'Ideas', note: 'Someday', tone: 'bg-[#f1ece7]' },
] as const;

function LibraryIllustration() {
  return (
    <div className="relative mx-auto w-full max-w-[620px] select-none lg:translate-x-3" role="img" aria-label="Illustration of a LaterBox library with saved articles, videos, and ideas">
      <div className="pointer-events-none absolute -inset-7 rounded-[48px] bg-[#dbe69c]/45 blur-3xl sm:-inset-12" aria-hidden="true" />
      <div className="relative overflow-hidden rounded-[24px] border-[7px] border-[#20271d] bg-white shadow-[0_36px_90px_rgba(29,36,23,0.18),0_8px_24px_rgba(29,36,23,0.08)] sm:rounded-[29px] sm:border-[9px]">
        <div className="flex h-10 items-center gap-2 border-b border-[#e9ebdf] bg-[#f8f9f4] px-4">
          <span className="h-2.5 w-2.5 rounded-full bg-[#e3ad9c]" />
          <span className="h-2.5 w-2.5 rounded-full bg-[#eddfac]" />
          <span className="h-2.5 w-2.5 rounded-full bg-[#b8d0a0]" />
          <div className="mx-auto hidden w-[52%] max-w-56 rounded-md border border-[#e8ebe0] bg-white px-3 py-1 text-center text-[10px] font-semibold text-[#899080] sm:block">laterbox / your space</div>
        </div>
        <div className="flex min-h-[340px] sm:min-h-[412px]">
          <aside className="hidden w-[145px] shrink-0 flex-col border-r border-[#e7e9dd] bg-[#f5f7ef] px-3 pb-5 pt-6 sm:flex">
            <div className="mb-7 flex items-center gap-2 px-1">
              <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-[#e6edb0] text-[#1b2417]"><Bookmark className="h-4 w-4" /></span>
              <span className="text-sm font-black tracking-tight text-[#23281f]">laterbox<span className="text-[#7e9356]">.</span></span>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-2 rounded-lg bg-[#e6edb0] px-2.5 py-2.5 text-[11px] font-bold text-[#1d2819]"><Bookmark className="h-3.5 w-3.5" /> Inbox <span className="ml-auto">3</span></div>
              <div className="flex items-center gap-2 rounded-lg px-2.5 py-2.5 text-[11px] font-medium text-[#778071]"><Clock3 className="h-3.5 w-3.5" /> Coming up</div>
              <div className="flex items-center gap-2 rounded-lg px-2.5 py-2.5 text-[11px] font-medium text-[#778071]"><FolderOpen className="h-3.5 w-3.5" /> Collections</div>
            </div>
            <div className="mt-auto border-t border-[#e0e4d5] px-2 pt-4 text-[10px] font-medium leading-relaxed text-[#858e7e]">Everything, in its place.</div>
          </aside>

          <div className="min-w-0 flex-1 bg-white px-4 pb-5 pt-5 sm:px-6 sm:pt-7">
            <div className="flex items-center justify-between gap-2">
              <div>
                <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-[#829072]">YOUR SPACE</p>
                <h3 className="mt-1 text-xl font-black tracking-[-0.055em] text-[#20251d] sm:text-2xl">Good things, kept.</h3>
              </div>
              <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-[#e9eadf] bg-[#fafbf7] text-[#7e8975]"><Search className="h-4 w-4" /></div>
            </div>
            <div className="mt-5 flex items-center gap-2 border-b border-[#eef0e6] pb-3">
              <span className="rounded-full bg-[#e6edb0] px-3 py-1 text-[10px] font-bold text-[#29321f]">Inbox</span>
              <span className="rounded-full px-2 py-1 text-[10px] font-semibold text-[#969c91]">Saved</span>
              <span className="rounded-full px-2 py-1 text-[10px] font-semibold text-[#969c91]">Someday</span>
            </div>
            <div className="mt-4 space-y-2.5">
              {itemCards.map((item) => {
                const Icon = item.icon;
                return (
                  <div key={item.title} className="flex items-center gap-3 rounded-[14px] border border-[#eef0e7] bg-white p-2.5 shadow-[0_2px_8px_rgba(30,38,25,0.025)] sm:p-3">
                    <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-[#384430] sm:h-12 sm:w-12 ${item.tone}`}><Icon className="h-5 w-5" /></div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-xs font-bold text-[#252b21] sm:text-[13px]">{item.title}</p>
                      <p className="mt-1 text-[10px] font-medium text-[#979e90]">{item.source}</p>
                    </div>
                    <span className="hidden shrink-0 rounded-full bg-[#f4f6ef] px-2.5 py-1.5 text-[10px] font-semibold text-[#747f67] sm:inline-flex">{item.note}</span>
                  </div>
                );
              })}
            </div>
            <p className="mt-5 flex items-center gap-2 text-[10px] font-medium text-[#7d8970]"><CheckCheck className="h-3.5 w-3.5" /> Ready whenever you are.</p>
          </div>
        </div>
      </div>

      <div className="absolute -bottom-5 left-1 z-10 flex items-center gap-3 rounded-2xl border border-[#cbd9a2] bg-[#e6edb0] px-4 py-3 shadow-[0_18px_50px_rgba(37,50,19,0.17)] sm:-bottom-7 sm:-left-8 sm:px-5 sm:py-4" aria-hidden="true">
        <span className="flex h-9 w-9 items-center justify-center rounded-full bg-[#25301e] text-[#e6edb0]"><Check className="h-4 w-4" strokeWidth={3} /></span>
        <div><p className="text-xs font-black text-[#27331d] sm:text-sm">Saved to LaterBox</p><p className="mt-0.5 text-[10px] font-semibold text-[#58664c] sm:text-xs">One less tab to keep open.</p></div>
      </div>
      <div className="absolute -right-2 -top-5 z-10 hidden items-center gap-2 rounded-full border border-[#e8eadf] bg-white px-4 py-2.5 text-xs font-bold text-[#313b29] shadow-[0_10px_32px_rgba(24,27,20,0.1)] sm:flex lg:-right-5" aria-hidden="true">
        <span className="flex h-6 w-6 items-center justify-center rounded-full bg-[#ecf2d4]"><Puzzle className="h-3.5 w-3.5" /></span>
        One click, saved.
        <Sparkles className="h-3.5 w-3.5 text-[#879956]" />
      </div>
    </div>
  );
}

export function MarketingHero() {
  const { user, isAuthenticated, continueAsGuest } = useAuth();
  const signedIn = Boolean(user || isAuthenticated);

  return (
    <section className="relative isolate overflow-hidden bg-[#f8f9f4]">
      <div className="pointer-events-none absolute inset-0 -z-10" style={{ background: 'radial-gradient(circle at 72% 34%, rgba(230,237,176,0.49) 0%, transparent 36%), radial-gradient(circle at 0% 100%, rgba(229,234,211,0.45) 0%, transparent 45%)' }} />
      <div className="mx-auto grid max-w-[1240px] items-center gap-16 px-5 pb-28 pt-16 sm:px-7 sm:pb-32 sm:pt-24 lg:grid-cols-[0.98fr_1.02fr] lg:gap-10 lg:px-8 lg:pb-36 lg:pt-28">
        <div className="relative z-10 max-w-[620px]">
          <div className="inline-flex items-center gap-2.5 rounded-full border border-[#dfe5ca] bg-white/90 px-3.5 py-2 text-[11px] font-black uppercase tracking-[0.15em] text-[#657550] sm:text-xs">
            <span className="flex h-5 w-5 items-center justify-center rounded-full bg-[#e6edb0]"><Sparkles className="h-3 w-3 text-[#334223]" /></span>
            Your space for later
          </div>
          <h1 className="mt-7 text-[clamp(3.25rem,5.4vw,5.8rem)] font-black leading-[0.99] tracking-[-0.077em] text-[#181d15]">
            Save it now.<br /><span className="font-serif font-normal italic tracking-[-0.065em] text-[#7a8c48]">Find it later.</span>
          </h1>
          <p className="mt-7 max-w-[505px] text-base leading-[1.8] text-[#666f60] sm:text-lg">
            That article, that video, that idea you don&apos;t have time for right now. Save it in seconds and come back when you&apos;re ready—without keeping another tab open.
          </p>
          <div className="mt-9 flex flex-col gap-3 sm:flex-row sm:items-center">
            <Link href={signedIn ? `${APP_ORIGIN}/inbox` : `${APP_ORIGIN}/signup`} className="group inline-flex min-h-14 items-center justify-center gap-3 rounded-full bg-[#1c2419] px-7 text-[15px] font-extrabold text-white shadow-[0_12px_28px_rgba(26,35,19,0.18)] transition-all hover:-translate-y-0.5 hover:bg-[#34442c] hover:shadow-[0_16px_34px_rgba(26,35,19,0.22)] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#7a8c48]">
              {signedIn ? 'Open your LaterBox' : 'Start saving for free'}<ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
            </Link>
            <Link href="/#how-it-works" className="group inline-flex min-h-14 items-center justify-center gap-2 rounded-full border border-[#d9dfd0] bg-white/80 px-6 text-sm font-bold text-[#30382c] transition-colors hover:border-[#a3b27e] hover:bg-white focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#7a8c48]">
              See how it works<ArrowUpRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
            </Link>
          </div>
          <div className="mt-5 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs font-medium text-[#7c8677]">
            <span className="inline-flex items-center gap-1.5"><Check className="h-3.5 w-3.5 text-[#738749]" /> Free account sync</span>
            <span className="inline-flex items-center gap-1.5"><Check className="h-3.5 w-3.5 text-[#738749]" /> Save in one tap</span>
            {!signedIn && <Link href={`${APP_ORIGIN}/inbox?guest=1`} onClick={() => continueAsGuest()} className="font-bold text-[#485d37] underline decoration-[#aab89b] underline-offset-4 hover:text-[#1b2419]">Or explore as a guest</Link>}
          </div>
          <div className="mt-11 flex flex-wrap items-center gap-x-6 gap-y-3 border-t border-[#dfe5d7] pt-5 text-xs font-bold text-[#657262]">
            <span className="text-[10px] font-black uppercase tracking-[0.16em] text-[#9ca695]">Find it on</span>
            <span className="inline-flex items-center gap-2"><Globe2 className="h-4 w-4" /> Web</span>
            <span className="inline-flex items-center gap-2"><Puzzle className="h-4 w-4" /> Chrome</span>
            <span className="inline-flex items-center gap-2"><Smartphone className="h-4 w-4" /> iOS</span>
          </div>
        </div>

        <div className="relative pt-7 sm:pt-10 lg:pt-0">
          <LibraryIllustration />
        </div>
      </div>
    </section>
  );
}
