// laterbox-web/src/components/layout/Footer.tsx
import Image from 'next/image';
import Link from 'next/link';
import { Activity, ArrowRight, ArrowUpRight, Globe2, Mail, Puzzle, Smartphone } from 'lucide-react';
import { APP_ORIGIN } from '@/lib/auth/config';
import { APP_VERSION } from '@/lib/version';

const sections = [
  {
    title: 'Explore',
    links: [
      { label: 'Features', href: '/features' },
      { label: 'How it works', href: '/#how-it-works' },
      { label: 'Storage plans', href: '/pricing' },
      { label: 'Getting started', href: '/guide' },
    ],
  },
  {
    title: 'Get LaterBox',
    links: [
      { label: 'Web app', href: `${APP_ORIGIN}/inbox` },
      { label: 'Chrome extension', href: 'https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp' },
      { label: 'iOS & iPadOS', href: 'https://apps.apple.com/us/app/laterbox-save-for-later/id6804139119' },
      { label: 'All downloads', href: '/download' },
    ],
  },
  {
    title: 'Resources',
    links: [
      { label: 'About us', href: '/about' },
      { label: 'Help & guides', href: '/docs' },
      { label: 'Privacy', href: '/privacy' },
      { label: 'Terms of service', href: '/terms' },
      { label: 'Refund policy', href: '/refund' },
    ],
  },
] as const;

function FooterNavLink({ href, children }: { href: string; children: React.ReactNode }) {
  const isExternal = href.startsWith('https://');
  const className = 'inline-flex items-center gap-1.5 py-1 text-sm font-medium text-[#abb3a3] transition-colors hover:text-[#e6edb0] focus-visible:rounded-sm focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#e6edb0]';
  if (isExternal) {
    return (
      <a href={href} target="_blank" rel="noopener noreferrer" className={className}>
        {children}<ArrowUpRight className="h-3 w-3 opacity-50" aria-hidden="true" />
      </a>
    );
  }
  return <Link href={href} className={className}>{children}</Link>;
}

export function Footer() {
  return (
    <footer className="relative isolate overflow-hidden bg-[#192018] text-[#f8faf1]">
      <div className="pointer-events-none absolute -right-40 -top-48 -z-10 h-[580px] w-[580px] rounded-full bg-[#657841]/15 blur-[115px]" aria-hidden="true" />
      <div className="mx-auto max-w-[1240px] px-5 sm:px-7 lg:px-8">
        <div className="flex flex-col gap-7 border-b border-white/10 py-16 sm:py-20 lg:flex-row lg:items-end lg:justify-between lg:gap-10">
          <div className="max-w-[700px]">
            <p className="text-[11px] font-black uppercase tracking-[0.2em] text-[#afbe90]">A little less to remember</p>
            <h2 className="mt-4 text-[clamp(2.4rem,4.4vw,4.6rem)] font-black leading-[1.07] tracking-[-0.065em]">
              Keep the good stuff.<br /><span className="font-serif font-normal italic text-[#e6edb0]">Clear your mind.</span>
            </h2>
            <p className="mt-5 max-w-md text-sm leading-7 text-[#abb5a5] sm:text-base">A calmer place for the things you want to come back to, whether that&apos;s five minutes from now or next month.</p>
          </div>
          <Link href={`${APP_ORIGIN}/signup`} className="group inline-flex min-h-14 shrink-0 items-center justify-center gap-3 self-start rounded-full bg-[#e6edb0] px-7 text-sm font-black text-[#26321e] shadow-[0_8px_30px_rgba(0,0,0,0.15)] transition-all hover:-translate-y-0.5 hover:bg-[#f0f5ca] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#e6edb0]">
            Start saving for free <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" aria-hidden="true" />
          </Link>
        </div>

        <div className="grid gap-x-9 gap-y-12 py-14 sm:grid-cols-2 sm:py-16 lg:grid-cols-[1.55fr_1fr_1fr_1fr] lg:gap-x-12">
          <div className="max-w-[280px]">
            <Link href="/" className="group inline-flex items-center gap-2.5 rounded-md focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#e6edb0]" aria-label="LaterBox homepage">
              <span className="relative h-10 w-10 overflow-hidden rounded-xl bg-[#e6edb0] shadow-sm">
                <Image src="/branding/laterbox-icon.png" alt="" fill sizes="40px" className="object-contain p-1" />
              </span>
              <span className="text-[25px] font-black tracking-[-0.065em]">laterbox<span className="text-[#e6edb0]">.</span></span>
            </Link>
            <p className="mt-5 text-sm leading-7 text-[#aab3a6]">Save links, videos, notes, and ideas in one place. Find them again when it&apos;s time.</p>
            <div className="mt-5 flex flex-wrap items-center gap-2 text-[11px] font-semibold text-[#bbc8a9]">
              <span className="inline-flex items-center gap-1.5 rounded-full border border-white/10 px-3 py-1.5"><Globe2 className="h-3.5 w-3.5" /> Web</span>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-white/10 px-3 py-1.5"><Puzzle className="h-3.5 w-3.5" /> Chrome</span>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-white/10 px-3 py-1.5"><Smartphone className="h-3.5 w-3.5" /> iOS</span>
            </div>
          </div>
          {sections.map(section => (
            <nav key={section.title} aria-label={section.title}>
              <h3 className="mb-5 text-xs font-black uppercase tracking-[0.14em] text-[#f5f8ed]">{section.title}</h3>
              <ul className="space-y-3.5">
                {section.links.map(link => (
                  <li key={link.href}><FooterNavLink href={link.href}>{link.label}</FooterNavLink></li>
                ))}
              </ul>
            </nav>
          ))}
        </div>

        <div className="flex flex-col gap-5 border-t border-white/10 py-7 text-xs text-[#939d90] md:flex-row md:items-center md:justify-between">
          <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
            <span>© {new Date().getFullYear()} LaterBox · Made by MiCorp.</span>
            <span className="hidden h-1 w-1 rounded-full bg-white/30 md:block" aria-hidden="true" />
            <span className="font-mono text-[11px] text-[#849181]">v{APP_VERSION}</span>
          </div>
          <div className="flex flex-wrap items-center gap-5">
            <a href="https://status.laterbox.dev" target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1.5 transition-colors hover:text-white focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#e6edb0]"><Activity className="h-3.5 w-3.5" aria-hidden="true"/> System status</a>
            <a href="mailto:support@micorp.pro" className="inline-flex items-center gap-1.5 transition-colors hover:text-white focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#e6edb0]"><Mail className="h-3.5 w-3.5" aria-hidden="true"/> Contact support</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
