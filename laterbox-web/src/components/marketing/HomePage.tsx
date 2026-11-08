import Link from 'next/link';
import { MarketingHero } from '@/components/marketing/MarketingHero';
import { LivePreviewSection } from '@/components/marketing/LivePreviewSection';
import { MarketingPlatformsSection } from '@/components/marketing/MarketingPlatformsSection';
import { ScrollConvergenceSection } from '@/components/marketing/ScrollConvergenceSection';
import { HowItWorksStepsSection } from '@/components/marketing/HowItWorksStepsSection';
import { WhenLaterBecomesNowSection } from '@/components/marketing/WhenLaterBecomesNowSection';
import { NotAnotherTodoListSection } from '@/components/marketing/NotAnotherTodoListSection';
import { SomedayVaultSection } from '@/components/marketing/SomedayVaultSection';
import { DesignedToStayOutOfWaySection } from '@/components/marketing/DesignedToStayOutOfWaySection';
import { YourLaterBoxYourRulesSection } from '@/components/marketing/YourLaterBoxYourRulesSection';
import { OneShortcutAwaySection } from '@/components/marketing/OneShortcutAwaySection';
import { YourThingsStaySection } from '@/components/marketing/YourThingsStaySection';
import { LessMentalClutterSection } from '@/components/marketing/LessMentalClutterSection';
import { WontForgetItLaterSection } from '@/components/marketing/WontForgetItLaterSection';
import { LandingFaqSection } from '@/components/marketing/LandingFaqSection';

export default function LandingPage() {
  return (
    <div className="selection:bg-[#171711] selection:text-white">
      <MarketingHero />
      <LivePreviewSection />

      {/* ============================================================ */}
      {/* "We all have a place called Later" Problem Section */}
      {/* ============================================================ */}
      <section className="py-20 sm:py-28 px-4 sm:px-6 relative overflow-hidden bg-white border-b border-[#e4e0d5]">
        <div className="max-w-4xl mx-auto text-center">
          {/* Main Statement Heading */}
          <h2 className="text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight text-[#171711] uppercase leading-tight">
            We all have a place <br />
            called <br />
            <span className="font-serif italic font-normal text-4xl sm:text-6xl lg:text-7xl normal-case tracking-normal block mt-2">
              &ldquo;LATER.&rdquo;
            </span>
          </h2>

          {/* 2x2 Behavioral Quote Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 sm:gap-7 max-w-2xl mx-auto mt-14 sm:mt-16 p-2">
            {/* Card 1: Watch Later (-2.5 deg tilt) */}
            <div className="rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] -rotate-[2.5deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll watch it later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                WATCH LATER
              </span>
            </div>

            {/* Card 2: Bookmarks (+2.5 deg tilt) */}
            <div className="rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] rotate-[2.5deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll read it later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                BOOKMARKS
              </span>
            </div>

            {/* Card 3: Downloads (-2 deg tilt) */}
            <div className="rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] -rotate-[2deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll finish it later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                DOWNLOADS
              </span>
            </div>

            {/* Card 4: Open Tabs (+2 deg tilt) */}
            <div className="rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] rotate-[2deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll reply later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                OPEN TABS
              </span>
            </div>
          </div>

          {/* Bottom Punchline */}
          <div className="mt-14 sm:mt-18 text-center space-y-1">
            <p className="text-xl sm:text-2xl text-[#171711] font-medium">
              Most things we save for later
            </p>
            <p className="text-xl sm:text-2xl text-[#171711] font-black tracking-tight">
              never find their way back.
            </p>
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/* Scroll Convergence Animation Section ("Later shouldn't mean lost") */}
      {/* ============================================================ */}
      <ScrollConvergenceSection />

      {/* ============================================================ */}
      {/* 4-Step Workflow Storytelling Section (Drop it, Choose when, etc.) */}
      {/* ============================================================ */}
      <div id="how-it-works" className="scroll-mt-24">
        <HowItWorksStepsSection />
      </div>

      {/* ============================================================ */}
      {/* "When later becomes now." Dark Section */}
      {/* ============================================================ */}
      <WhenLaterBecomesNowSection />

      {/* ============================================================ */}
      {/* "Not another to-do list." Capability Section */}
      {/* ============================================================ */}
      <NotAnotherTodoListSection />

      {/* ============================================================ */}
      {/* "Some things don't need a deadline." Someday Vault Section */}
      {/* ============================================================ */}
      <SomedayVaultSection />

      {/* ============================================================ */}
      {/* "Designed to stay out of your way." App Dashboard Showcase */}
      {/* ============================================================ */}
      <DesignedToStayOutOfWaySection />

      {/* ============================================================ */}
      {/* "Your LaterBox. Your rules." Preferences & Rules Showcase */}
      {/* ============================================================ */}
      <YourLaterBoxYourRulesSection />

      {/* ============================================================ */}
      {/* "LaterBox is always one shortcut away." Animated Capture */}
      {/* ============================================================ */}
      <OneShortcutAwaySection />

      {/* ============================================================ */}
      {/* "Your things stay where they belong." Local-First Section */}
      {/* ============================================================ */}
      <YourThingsStaySection />

      {/* ============================================================ */}
      {/* "Less mental clutter. Not more software clutter." Section */}
      {/* ============================================================ */}
      <LessMentalClutterSection />

      {/* ============================================================ */}
      {/* "The Ultimate Windows Productivity Organizer" Feature Tabs */}
      {/* ============================================================ */}


      {/* ============================================================ */}
      {/* "You don't need to do everything now." Core Statement */}
      {/* ============================================================ */}
      <WontForgetItLaterSection />

      {/* ============================================================ */}
      <nav aria-label="Learn about LaterBox" className="mx-auto flex max-w-5xl flex-wrap justify-center gap-6 px-6 py-10 font-bold underline">
        <Link href="/features">Explore LaterBox features</Link>
        <Link href="/about">About LaterBox</Link>
        <Link href="/browser-extension">Save with the browser extension</Link>
      </nav>
      {/* 2-Column Landing FAQ Section */}
      {/* ============================================================ */}
      <LandingFaqSection />



      <MarketingPlatformsSection />
    </div>
  );
}
