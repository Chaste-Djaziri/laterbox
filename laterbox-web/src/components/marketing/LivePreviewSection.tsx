// laterbox-web/src/components/marketing/LivePreviewSection.tsx
import Link from 'next/link';
import { ArrowRight, ArrowUpRight, CheckCircle2, Globe2, MonitorPlay } from 'lucide-react';
import { APP_ORIGIN } from '@/lib/auth/config';

export function LivePreviewSection() {
  return (
    <section id="live-guest-sandbox" className="scroll-mt-28 border-y border-[#e7e9df] bg-white py-20 sm:py-24 lg:py-28">
      <div className="mx-auto max-w-[1180px] px-5 sm:px-7 lg:px-8">
        <div className="mb-9 flex flex-col justify-between gap-6 md:mb-11 md:flex-row md:items-end">
          <div className="max-w-[660px]">
            <div className="mb-4 flex items-center gap-2 text-[11px] font-black uppercase tracking-[0.18em] text-[#7a8d56]">
              <span className="h-1.5 w-1.5 rounded-full bg-[#91a567]" /> Explore LaterBox
            </div>
            <h2 className="text-[clamp(2.25rem,4.2vw,4.25rem)] font-black leading-[1.08] tracking-[-0.065em] text-[#1d241a]">
              Less explaining.<br /><span className="font-serif font-normal italic text-[#7c8f4a]">More experiencing.</span>
            </h2>
            <p className="mt-5 max-w-[540px] text-sm leading-7 text-[#6f786c] sm:text-base">
              Explore a real guest inbox and see how your saved things come together. No signup required to look around.
            </p>
          </div>
          <Link href={`${APP_ORIGIN}/inbox?guest=1`} className="group inline-flex min-h-12 shrink-0 items-center justify-center gap-2 self-start rounded-full border border-[#d6dfcc] bg-[#f5f8eb] px-5 text-sm font-bold text-[#2b3625] transition-colors hover:bg-[#e6edb0] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#7c8f4a]">
            Open the guest app <ArrowUpRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
          </Link>
        </div>

        <div className="overflow-hidden rounded-[25px] border border-[#dfe5d9] bg-[#f8f9f5] shadow-[0_30px_90px_rgba(24,31,21,0.08)] sm:rounded-[30px]">
          <div className="flex min-h-[52px] items-center justify-between border-b border-[#e3e7df] bg-[#f8f9f6] px-4 sm:px-6">
            <div className="flex items-center gap-1.5" aria-hidden="true">
              <span className="h-2.5 w-2.5 rounded-full bg-[#dcae9a]"/><span className="h-2.5 w-2.5 rounded-full bg-[#e8dca5]"/><span className="h-2.5 w-2.5 rounded-full bg-[#b8cf9d]"/>
            </div>
            <div className="hidden rounded-lg border border-[#e4e8df] bg-white px-7 py-1.5 text-[11px] font-semibold text-[#7d8879] sm:block">app.laterbox.dev / inbox</div>
            <div className="flex items-center gap-2 text-[11px] font-bold text-[#627452]"><span className="h-1.5 w-1.5 rounded-full bg-[#9cb773]" /> Guest preview</div>
          </div>
          <iframe
            title="Interactive LaterBox guest inbox"
            src={`${APP_ORIGIN}/inbox?guest=1&embed=welcome`}
            loading="lazy"
            className="hidden h-[555px] w-full border-0 bg-white md:block lg:h-[625px]"
          />
          <div className="relative flex min-h-[315px] flex-col items-center justify-center overflow-hidden bg-[#f6f8ef] px-7 py-11 text-center md:hidden">
            <div className="pointer-events-none absolute -right-14 -top-20 h-64 w-64 rounded-full bg-[#e6edb0]/70 blur-3xl" aria-hidden="true" />
            <span className="relative flex h-14 w-14 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#31432a]"><MonitorPlay className="h-6 w-6"/></span>
            <h3 className="relative mt-5 text-2xl font-black tracking-tight text-[#263221]">Your library, ready to explore.</h3>
            <p className="relative mt-3 max-w-xs text-sm leading-6 text-[#697565]">The live preview opens in the app for the best experience on smaller screens.</p>
            <Link href={`${APP_ORIGIN}/inbox?guest=1`} className="relative mt-6 inline-flex min-h-12 items-center gap-2 rounded-full bg-[#202b1c] px-6 text-sm font-bold text-white">Try LaterBox <ArrowRight className="h-4 w-4"/></Link>
          </div>
        </div>
        <div className="mt-6 flex flex-wrap items-center justify-center gap-x-7 gap-y-2 text-xs font-medium text-[#859080]">
          <span className="inline-flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-[#809954]"/> Try before you sign up</span>
          <span className="inline-flex items-center gap-2"><Globe2 className="h-4 w-4 text-[#809954]"/> Accessible from your browser</span>
        </div>
      </div>
    </section>
  );
}
