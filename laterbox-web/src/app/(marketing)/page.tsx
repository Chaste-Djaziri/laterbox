'use client';

import Link from 'next/link';
import { ArrowRight, Bookmark, Check, FileText, Folder, Play, Search, Sparkles, Zap } from 'lucide-react';
import { useAuth } from '@/lib/store/AuthContext';

const features = [
  [Zap, 'Capture without friction', 'Save a link, note, or file from your browser and devices without leaving your flow.'],
  [Sparkles, 'Organized automatically', 'Laterbox adds useful titles, covers, and context so every save is ready when you return.'],
  [Search, 'Find anything quickly', 'Search your library or browse collections instead of digging through tabs and bookmarks.'],
] as const;

const steps = [
  ['01', 'Save it', 'Send anything worth keeping to your laterbox.'],
  ['02', 'We tidy it', 'Your save gets a clean preview and useful details.'],
  ['03', 'Return anytime', 'Pick up exactly where you left off, on any device.'],
];

export default function LandingPage() {
  const { continueAsGuest } = useAuth();

  return (
    <div className="overflow-hidden selection:bg-[#214c38] selection:text-white">
      <section className="relative px-5 pb-20 pt-12 sm:px-8 sm:pb-28 sm:pt-20">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_75%_20%,rgba(204,226,211,0.75),transparent_32%)]" />
        <div className="relative mx-auto grid max-w-6xl items-center gap-14 lg:grid-cols-[1.05fr_0.95fr] lg:gap-20">
          <div className="text-center lg:text-left">
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#cbdccf] bg-[#e7f1e9] px-3 py-1.5 text-[11px] font-extrabold tracking-[0.12em] text-[#295b43]">
              <Sparkles className="h-3.5 w-3.5" /> YOUR PLACE TO REMEMBER
            </div>
            <h1 className="text-balance text-5xl font-black leading-[0.98] tracking-[-0.055em] text-[#17211b] sm:text-6xl lg:text-7xl">
              Save it now.<span className="mt-2 block text-[#526259]">Enjoy it later.</span>
            </h1>
            <p className="mx-auto mt-7 max-w-xl text-pretty text-lg leading-8 text-[#657269] lg:mx-0">
              Keep articles, videos, notes, and useful links in one calm place. Laterbox keeps them organized and easy to find when the moment is right.
            </p>
            <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row lg:justify-start">
              <Link href="/inbox" className="group inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[#214c38] px-6 py-4 text-sm font-bold text-white shadow-[0_12px_32px_rgba(33,76,56,0.18)] transition hover:-translate-y-0.5 hover:bg-[#183c2c] sm:w-auto">
                Start saving free <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
              </Link>
              <Link href="/inbox" onClick={() => continueAsGuest()} className="inline-flex w-full items-center justify-center rounded-xl border border-[#d9e0da] bg-white px-6 py-4 text-sm font-bold text-[#17211b] transition hover:border-[#b7c7bb] hover:bg-[#f8faf7] sm:w-auto">
                Try guest mode
              </Link>
            </div>
            <div className="mt-6 flex flex-wrap items-center justify-center gap-x-5 gap-y-2 text-xs font-medium text-[#6c786f] lg:justify-start">
              {['Free to start', 'No credit card', 'Works everywhere'].map((label) => (
                <span key={label} className="inline-flex items-center gap-1.5"><Check className="h-3.5 w-3.5 text-[#2f7652]" />{label}</span>
              ))}
            </div>
          </div>
          <ProductPreview />
        </div>
      </section>

      <section id="features" className="border-y border-[#e1e6e1] bg-white px-5 py-20 sm:px-8 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <SectionHeading label="ONE HOME FOR EVERYTHING" title="Save less. Remember more." description="The essentials you need to turn scattered finds into a useful personal library." />
          <div className="mt-12 grid gap-4 md:grid-cols-3">
            {features.map(([Icon, title, description]) => (
              <article key={title} className="rounded-2xl border border-[#e1e6e1] bg-[#fafbf8] p-7 transition duration-300 hover:-translate-y-1 hover:border-[#cbd8ce] hover:shadow-[0_16px_40px_rgba(34,62,45,0.07)]">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#e4f0e7] text-[#286044]"><Icon className="h-5 w-5" /></div>
                <h3 className="mt-6 text-xl font-bold tracking-tight text-[#17211b]">{title}</h3>
                <p className="mt-3 text-[15px] leading-7 text-[#68746c]">{description}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="how-it-works" className="bg-[#17211b] px-5 py-20 text-white sm:px-8 sm:py-24">
        <div className="mx-auto max-w-6xl">
          <SectionHeading dark label="A SIMPLE FLOW" title="From found to saved in seconds." description="Laterbox stays out of your way, then brings everything back when you need it." />
          <div className="mt-14 grid gap-8 md:grid-cols-3 md:gap-5">
            {steps.map(([number, title, description], index) => (
              <div key={number} className="relative text-center">
                {index < steps.length - 1 && <div className="absolute left-[62%] top-6 hidden h-px w-[76%] bg-[#3a4a40] md:block" />}
                <div className="relative mx-auto flex h-12 w-12 items-center justify-center rounded-xl border border-[#466052] bg-[#24352c] text-xs font-black text-[#acd0b8]">{number}</div>
                <h3 className="mt-5 text-lg font-bold">{title}</h3>
                <p className="mx-auto mt-2 max-w-xs text-sm leading-6 text-[#b5c0b9]">{description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-white px-5 py-20 sm:px-8 sm:py-24">
        <div className="mx-auto max-w-6xl rounded-3xl bg-[#e5f0e7] px-6 py-14 text-center sm:px-12 sm:py-16">
          <p className="text-xs font-black tracking-[0.14em] text-[#326249]">YOUR FUTURE SELF WILL THANK YOU</p>
          <h2 className="mx-auto mt-4 max-w-2xl text-balance text-4xl font-black tracking-[-0.04em] text-[#17211b] sm:text-5xl">Make space for what matters.</h2>
          <p className="mx-auto mt-5 max-w-xl text-base leading-7 text-[#5d6c63]">Start your personal library today. It only takes a few seconds.</p>
          <Link href="/inbox" className="group mt-8 inline-flex items-center gap-2 rounded-xl bg-[#214c38] px-6 py-4 text-sm font-bold text-white transition hover:bg-[#183c2c]">
            Create your laterbox <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
          </Link>
        </div>
      </section>
    </div>
  );
}

function SectionHeading({ label, title, description, dark = false }: { label: string; title: string; description: string; dark?: boolean }) {
  return (
    <div className="mx-auto max-w-2xl text-center">
      <p className={`text-[11px] font-black tracking-[0.14em] ${dark ? 'text-[#9fc3aa]' : 'text-[#326249]'}`}>{label}</p>
      <h2 className={`mt-4 text-balance text-3xl font-black tracking-[-0.04em] sm:text-4xl ${dark ? 'text-white' : 'text-[#17211b]'}`}>{title}</h2>
      <p className={`mt-4 text-base leading-7 ${dark ? 'text-[#aebbb3]' : 'text-[#68746c]'}`}>{description}</p>
    </div>
  );
}

function ProductPreview() {
  const saves = [
    [FileText, 'designbetter.co', 'A practical guide to thoughtful product design', 'Design', 'bg-[#e2ede5]'],
    [Play, 'youtube.com', 'A simple system for learning anything', 'Watch', 'bg-[#eee9df]'],
    [Bookmark, 'Personal note', 'Ideas for the next weekend project', 'Ideas', 'bg-[#e6eaf0]'],
  ] as const;

  return (
    <div className="relative mx-auto w-full max-w-lg">
      <div className="absolute -inset-5 -rotate-2 rounded-[2rem] bg-[#d9e8dd]/70" />
      <div className="relative rounded-[1.4rem] border border-[#dbe3dc] bg-white p-2.5 shadow-[0_30px_80px_rgba(30,62,43,0.16)]">
        <div className="rounded-2xl bg-[#f5f7f3] p-5 sm:p-6">
          <div className="flex items-center">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#214c38] text-white"><Folder className="h-4 w-4" /></div>
            <div className="ml-3"><p className="text-sm font-bold text-[#17211b]">My inbox</p><p className="text-[10px] text-[#7a857e]">Everything worth keeping</p></div>
            <div className="ml-auto flex h-9 w-9 items-center justify-center rounded-lg bg-white text-[#607067] shadow-sm"><Search className="h-4 w-4" /></div>
          </div>
          <div className="mt-5 space-y-2.5">
            {saves.map(([Icon, source, title, tag, color]) => (
              <div key={title} className="flex items-center gap-3 rounded-xl border border-[#e5e9e5] bg-white p-3.5">
                <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-lg text-[#315d46] ${color}`}><Icon className="h-5 w-5" /></div>
                <div className="min-w-0 flex-1"><p className="text-[10px] font-medium text-[#7c877f]">{source}</p><p className="mt-0.5 truncate text-xs font-semibold text-[#26322b] sm:text-sm">{title}</p></div>
                <span className="hidden rounded-full bg-[#e8f2ea] px-2 py-1 text-[9px] font-bold text-[#326249] sm:block">{tag}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
