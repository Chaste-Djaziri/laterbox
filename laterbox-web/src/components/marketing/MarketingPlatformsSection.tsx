// laterbox-web/src/components/marketing/MarketingPlatformsSection.tsx
import { ArrowUpRight, Globe2, Puzzle, Smartphone } from 'lucide-react';
import { APP_ORIGIN } from '@/lib/auth/config';

const platforms = [
  {
    id: '01',
    name: 'Web app',
    headline: 'Your library, one tab away.',
    description: 'Open your inbox, organize what you saved, and pick up where you left off. No installation needed.',
    cta: 'Open web app',
    href: `${APP_ORIGIN}/inbox?guest=1`,
    icon: Globe2,
    external: false,
    theme: 'dark',
  },
  {
    id: '02',
    name: 'Chrome extension',
    headline: 'Save without breaking your flow.',
    description: 'Found something good? Send it to LaterBox in a click and get back to what you were doing.',
    cta: 'Add to Chrome',
    href: 'https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp',
    icon: Puzzle,
    external: true,
    theme: 'green',
  },
  {
    id: '03',
    name: 'iPhone & iPad',
    headline: 'Take your saved stuff along.',
    description: 'Keep ideas close and capture from the iOS share sheet, even when you are away from your desk.',
    cta: 'Get the iOS app',
    href: 'https://apps.apple.com/us/app/laterbox-save-for-later/id6804139119',
    icon: Smartphone,
    external: true,
    theme: 'light',
  },
] as const;

export function MarketingPlatformsSection() {
  return (
    <section id="platforms" aria-labelledby="marketing-platforms-heading" className="border-t border-[#e3e9dd] bg-[#f8f9f4] px-5 py-20 sm:px-7 sm:py-28 lg:px-8">
      <div className="mx-auto max-w-[1240px]">
        <div className="mb-10 flex flex-col justify-between gap-6 lg:mb-12 lg:flex-row lg:items-end">
          <div className="max-w-[680px]">
            <p className="text-[11px] font-black uppercase tracking-[0.19em] text-[#7f9257]">Right where you need it</p>
            <h2 id="marketing-platforms-heading" className="mt-4 text-[clamp(2.45rem,4.5vw,4.75rem)] font-black leading-[1.07] tracking-[-0.07em] text-[#1b2419]">
              One home for all the things <span className="font-serif font-normal italic text-[#7d914d]">you find.</span>
            </h2>
          </div>
          <p className="max-w-[360px] text-sm leading-7 text-[#697565] sm:text-base">
            Save from Chrome, organize on the web, and revisit from your iPhone. Your LaterBox follows your account.
          </p>
        </div>

        <div className="grid gap-4 md:grid-cols-3 lg:gap-5">
          {platforms.map(platform => {
            const Icon = platform.icon;
            const dark = platform.theme === 'dark';
            const green = platform.theme === 'green';
            return (
              <article
                key={platform.name}
                className={`group flex min-h-[345px] flex-col overflow-hidden rounded-[28px] border p-7 transition-all duration-300 hover:-translate-y-1 hover:shadow-[0_22px_55px_rgba(31,43,23,0.09)] sm:p-8 ${
                  dark ? 'border-[#1c281a] bg-[#1b261a] text-white' : green ? 'border-[#d5e3a1] bg-[#e6edb0] text-[#1b261a]' : 'border-[#e1e7db] bg-white text-[#1b261a]'
                }`}
              >
                <div className="flex items-start justify-between">
                  <span className={`flex h-14 w-14 items-center justify-center rounded-2xl ${
                    dark ? 'bg-[#e6edb0] text-[#23321c]' : green ? 'bg-[#f9fbe9] text-[#36482d]' : 'bg-[#eef3e1] text-[#546a3d]'
                  }`}><Icon className="h-6 w-6" strokeWidth={1.75} aria-hidden="true" /></span>
                  <span className={`text-xs font-black tracking-[0.14em] ${dark ? 'text-[#99af82]' : 'text-[#93a372]'}`}>{platform.id} / 03</span>
                </div>
                <div className="mt-9 flex-1">
                  <p className={`text-xs font-black uppercase tracking-[0.14em] ${dark ? 'text-[#b6ca9f]' : 'text-[#687e52]'}`}>{platform.name}</p>
                  <h3 className="mt-3 max-w-[330px] text-[24px] font-black leading-tight tracking-[-0.045em] sm:text-[26px]">{platform.headline}</h3>
                  <p className={`mt-4 max-w-[330px] text-sm leading-7 ${dark ? 'text-[#b5bfb0]' : 'text-[#697464]'}`}>{platform.description}</p>
                </div>
                <a
                  href={platform.href}
                  target={platform.external ? '_blank' : undefined}
                  rel={platform.external ? 'noopener noreferrer' : undefined}
                  className={`mt-8 inline-flex min-h-12 items-center justify-between gap-3 rounded-full px-5 text-sm font-bold transition-colors focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#a2ba77] ${
                    dark ? 'bg-[#e6edb0] text-[#1b261a] hover:bg-white' : green ? 'bg-[#1b261a] text-white hover:bg-[#34442b]' : 'border border-[#d6e1cd] bg-[#f4f7ee] text-[#263521] hover:bg-[#e6edb0]'
                  }`}
                >
                  {platform.cta} <ArrowUpRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" aria-hidden="true" />
                </a>
              </article>
            );
          })}
        </div>
        <p className="mt-7 text-center text-xs font-medium text-[#929b8d]">More platforms are on the roadmap. Web, Chrome, and iOS are the focus today.</p>
      </div>
    </section>
  );
}
