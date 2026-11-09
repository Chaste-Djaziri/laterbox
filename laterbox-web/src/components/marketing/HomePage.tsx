'use client';

import { useRef } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useGSAP } from '@gsap/react';
import { APP_ORIGIN } from '@/lib/auth/config';
import { useAuth } from '@/lib/store/AuthContext';
import { Apple, Sparkles, ArrowRight, Compass } from 'lucide-react';
import { MarketingPlatformsSection } from '@/components/marketing/MarketingPlatformsSection';
import { InteractiveDashboardPreview } from '@/components/marketing/InteractiveDashboardPreview';
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
  const { continueAsGuest } = useAuth();
  const containerRef = useRef<HTMLDivElement>(null);

  useGSAP(
    () => {
      if (typeof window === 'undefined') return;

      const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      if (prefersReducedMotion) return;

      gsap.registerPlugin(ScrollTrigger);

      // Hero Timeline on mount
      const heroTl = gsap.timeline({ defaults: { ease: 'power3.out' } });
      heroTl
        .fromTo('.gsap-hero-badge', { opacity: 0, y: -16 }, { opacity: 1, y: 0, duration: 0.6, clearProps: 'all' })
        .fromTo('.gsap-hero-title', { opacity: 0, y: 28 }, { opacity: 1, y: 0, duration: 0.75, clearProps: 'all' }, '-=0.35')
        .fromTo('.gsap-hero-sub', { opacity: 0, y: 18 }, { opacity: 1, y: 0, duration: 0.6, clearProps: 'all' }, '-=0.4')
        .fromTo('.gsap-hero-cta > *', { opacity: 0, y: 16 }, { opacity: 1, y: 0, stagger: 0.08, duration: 0.5, clearProps: 'all' }, '-=0.3')
        .fromTo('.gsap-hero-meta', { opacity: 0, y: 10 }, { opacity: 1, y: 0, duration: 0.5, clearProps: 'all' }, '-=0.25')
        .fromTo('.gsap-hero-preview', { opacity: 0, y: 35, scale: 0.98 }, { opacity: 1, y: 0, scale: 1, duration: 0.8, clearProps: 'all' }, '-=0.3');

      // Problem Section ScrollTrigger
      gsap.from('.gsap-problem-title', {
        scrollTrigger: {
          trigger: '.gsap-problem-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 30,
        duration: 0.7,
        ease: 'power3.out',
      });

      gsap.from('.gsap-problem-card', {
        scrollTrigger: {
          trigger: '.gsap-problem-grid',
          start: 'top 80%',
        },
        opacity: 0,
        y: 40,
        stagger: 0.1,
        duration: 0.65,
        ease: 'back.out(1.2)',
      });

      gsap.from('.gsap-problem-punchline', {
        scrollTrigger: {
          trigger: '.gsap-problem-punchline',
          start: 'top 85%',
        },
        opacity: 0,
        y: 20,
        duration: 0.6,
        ease: 'power2.out',
      });

      // When later becomes now (dark section)
      gsap.from('.gsap-now-heading', {
        scrollTrigger: {
          trigger: '.gsap-now-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 30,
        duration: 0.7,
        ease: 'power3.out',
      });

      gsap.from('.gsap-now-card', {
        scrollTrigger: {
          trigger: '.gsap-now-section',
          start: 'top 75%',
        },
        opacity: 0,
        y: 35,
        scale: 0.96,
        duration: 0.75,
        ease: 'power3.out',
      });

      // Not another todo list
      gsap.from('.gsap-not-todo-heading', {
        scrollTrigger: {
          trigger: '.gsap-not-todo-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 25,
        duration: 0.6,
        ease: 'power3.out',
      });

      gsap.from('.gsap-not-todo-row', {
        scrollTrigger: {
          trigger: '.gsap-not-todo-table',
          start: 'top 80%',
        },
        opacity: 0,
        x: -20,
        stagger: 0.08,
        duration: 0.5,
        ease: 'power2.out',
      });

      // Someday vault
      gsap.from('.gsap-someday-text', {
        scrollTrigger: {
          trigger: '.gsap-someday-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 30,
        duration: 0.7,
        ease: 'power3.out',
      });

      gsap.from('.gsap-someday-deck', {
        scrollTrigger: {
          trigger: '.gsap-someday-section',
          start: 'top 75%',
        },
        opacity: 0,
        scale: 0.94,
        y: 25,
        duration: 0.75,
        ease: 'power3.out',
      });

      // Designed to stay out of your way
      gsap.from('.gsap-stay-heading, .gsap-stay-subheading', {
        scrollTrigger: {
          trigger: '.gsap-stay-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 25,
        stagger: 0.1,
        duration: 0.65,
        ease: 'power3.out',
      });

      gsap.from('.gsap-stay-card', {
        scrollTrigger: {
          trigger: '.gsap-stay-section',
          start: 'top 75%',
        },
        opacity: 0,
        y: 30,
        stagger: 0.12,
        duration: 0.65,
        ease: 'power3.out',
      });

      // Your LaterBox Your Rules
      gsap.from('.gsap-rules-text', {
        scrollTrigger: {
          trigger: '.gsap-rules-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 30,
        duration: 0.7,
        ease: 'power3.out',
      });

      gsap.from('.gsap-rules-visual', {
        scrollTrigger: {
          trigger: '.gsap-rules-section',
          start: 'top 75%',
        },
        opacity: 0,
        y: 35,
        duration: 0.8,
        ease: 'power3.out',
      });

      // One shortcut away
      gsap.from('.gsap-shortcut-content', {
        scrollTrigger: {
          trigger: '.gsap-shortcut-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 30,
        duration: 0.7,
        ease: 'power3.out',
      });

      // Your things stay
      gsap.from('.gsap-things-heading', {
        scrollTrigger: {
          trigger: '.gsap-things-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 30,
        duration: 0.7,
        ease: 'power3.out',
      });

      gsap.from('.gsap-things-card', {
        scrollTrigger: {
          trigger: '.gsap-things-grid',
          start: 'top 80%',
        },
        opacity: 0,
        y: 35,
        stagger: 0.12,
        duration: 0.6,
        ease: 'power3.out',
      });

      // Less mental clutter
      gsap.from('.gsap-clutter-heading', {
        scrollTrigger: {
          trigger: '.gsap-clutter-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 25,
        duration: 0.7,
        ease: 'power3.out',
      });

      gsap.from('.gsap-clutter-pill', {
        scrollTrigger: {
          trigger: '.gsap-clutter-section',
          start: 'top 75%',
        },
        opacity: 0,
        scale: 0.9,
        stagger: 0.08,
        duration: 0.5,
        ease: 'back.out(1.4)',
      });

      // Wont forget it later
      gsap.from('.gsap-wont-forget-text', {
        scrollTrigger: {
          trigger: '.gsap-wont-forget-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 30,
        duration: 0.75,
        ease: 'power3.out',
      });

      gsap.from('.gsap-wont-forget-line', {
        scrollTrigger: {
          trigger: '.gsap-wont-forget-section',
          start: 'top 75%',
        },
        scaleX: 0,
        duration: 0.8,
        ease: 'power3.out',
      });

      // FAQ
      gsap.from('.gsap-faq-header', {
        scrollTrigger: {
          trigger: '.gsap-faq-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 25,
        duration: 0.65,
        ease: 'power3.out',
      });

      gsap.from('.gsap-faq-item', {
        scrollTrigger: {
          trigger: '.gsap-faq-section',
          start: 'top 75%',
        },
        opacity: 0,
        y: 20,
        stagger: 0.05,
        duration: 0.5,
        ease: 'power2.out',
      });

      // Marketing platforms
      gsap.from('.gsap-platforms-header', {
        scrollTrigger: {
          trigger: '.gsap-platforms-section',
          start: 'top 80%',
        },
        opacity: 0,
        y: 25,
        duration: 0.65,
        ease: 'power3.out',
      });

      gsap.from('.gsap-platform-card', {
        scrollTrigger: {
          trigger: '.gsap-platforms-section',
          start: 'top 75%',
        },
        opacity: 0,
        y: 35,
        stagger: 0.12,
        duration: 0.65,
        ease: 'power3.out',
      });
    },
    { scope: containerRef }
  );

  return (
    <div ref={containerRef} className="selection:bg-[#171711] selection:text-white">
      {/* Hero Section */}
      <section className="relative pt-12 sm:pt-20 pb-16 sm:pb-24 overflow-hidden">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center relative z-10">
          {/* Pro Pill Badge */}
          <div className="gsap-hero-badge inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-extrabold mb-8 shadow-xs">
            <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
            <span>LaterBox Pro • Built for Power Users, Developers &amp; Curators</span>
          </div>

          {/* Main Hero Heading */}
          <h1 className="gsap-hero-title text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.08] mb-6">
            LaterBox: save now. <br />
            Return to it <span className="font-serif italic font-normal">later.</span>
          </h1>

          {/* Subheading */}
          <p className="gsap-hero-sub max-w-2xl mx-auto text-base sm:text-xl text-[#6c6b63] leading-relaxed mb-10">
            Your save-for-later app and bookmark manager for links, articles, videos, notes, and files. Organize collections and find what you saved when you need it.
          </p>

          {/* Action CTAs */}
          <div className="gsap-hero-cta relative z-20 flex flex-wrap items-center justify-center gap-3.5">
            <Link
              href={`${APP_ORIGIN}/inbox?guest=1`}
              className="inline-flex items-center gap-2 px-7 py-3.5 rounded-full bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-extrabold text-sm sm:text-base shadow-sm transition-all duration-150 group"
            >
              <span>Launch Web App Free</span>
              <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
            </Link>

            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] hover:bg-[#ebe7dc]/50 font-bold text-sm sm:text-base shadow-xs transition-all"
            >
              <Apple className="w-4 h-4 text-[#171711]" />
              <span>Get for iOS &amp; Downloads</span>
            </Link>

            <Link
              href={`${APP_ORIGIN}/inbox?guest=1`}
              onClick={() => continueAsGuest()}
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-[#ebe7dc]/70 text-[#171711] hover:bg-[#ebe7dc] font-bold text-sm sm:text-base transition-all"
            >
              <Compass className="w-4 h-4 text-[#6c6b63]" />
              <span>Try Guest Sandbox</span>
            </Link>
          </div>

          {/* Meta Trust Badges */}
          <div className="gsap-hero-meta mt-8 text-xs text-[#6c6b63] space-y-1 font-medium">
            <p className="flex items-center justify-center gap-2">
              <span>Free</span>
              <span>•</span>
              <span>Offline</span>
              <span>•</span>
              <span>No account required</span>
            </p>
            <p className="text-[11px] text-[#9e9b92]">
              Made by{' '}
              <a
                href="https://micorp.pro"
                target="_blank"
                rel="noopener noreferrer"
                className="underline decoration-[#9e9b92]/50 hover:text-[#171711] font-semibold text-[#6c6b63] transition-colors"
              >
                MiCorp
              </a>
              .
            </p>
          </div>
        </div>

        {/* Hero Dashboard Preview Container */}
        <div className="gsap-hero-preview max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          {/* ============================================================ */}
          {/* Desktop: Floating Try It Badge Indicator + Interactive Dashboard Preview */}
          {/* ============================================================ */}
          <div className="hidden md:block">
            <div className="mt-12 sm:mt-16 flex justify-start pl-6 sm:pl-10 mb-[-12px] relative z-20">
              <a
                href="#live-guest-sandbox"
                className="inline-flex flex-col items-center group cursor-pointer"
              >
                <div className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-[#171711] group-hover:bg-[#282723] text-[#e6edb0] font-black text-xs tracking-wider uppercase shadow-md transition-all group-hover:scale-105">
                  <span>TRY IT</span>
                  <span className="text-xs leading-none font-black">↓</span>
                </div>
                <div className="w-0 h-0 border-x-4 border-x-transparent border-t-[5px] border-t-[#171711] group-hover:border-t-[#282723] transition-colors" />
              </a>
            </div>

            <InteractiveDashboardPreview id="live-guest-sandbox" className="scroll-mt-24" />
          </div>

          {/* ============================================================ */}
          {/* Mobile: iOS Native App Preview with Graceful Bottom Fade Out */}
          {/* ============================================================ */}
          <div className="block md:hidden mt-8 sm:mt-10">
            <div className="relative mx-auto max-w-[320px] rounded-[42px] border-4 border-[#171711] bg-white p-2 shadow-[0_25px_60px_rgba(24,27,20,0.18)] overflow-hidden">
              {/* Inner viewport with fade out at bottom */}
              <div className="relative h-[480px] w-full overflow-hidden rounded-[34px] bg-white">
                <Image
                  src="/branding/mobile-inbox-preview.png"
                  alt="LaterBox iOS Mobile App"
                  width={471}
                  height={1024}
                  priority
                  className="w-full h-auto object-cover object-top"
                />
                {/* Bottom graceful fade out gradient */}
                <div
                  className="pointer-events-none absolute inset-x-0 bottom-0 h-44 bg-gradient-to-t from-white via-white/85 to-transparent"
                  aria-hidden="true"
                />
              </div>

              {/* Floating iOS CTA over the faded bottom */}
              <div className="absolute inset-x-0 bottom-6 flex flex-col items-center justify-center px-4 z-10">
                <Link
                  href="/download"
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#171711] hover:bg-[#282723] active:scale-95 text-white font-extrabold text-xs shadow-lg transition-all"
                >
                  <Apple className="w-3.5 h-3.5 text-white" />
                  <span>Get LaterBox for iOS</span>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/* "We all have a place called Later" Problem Section */}
      {/* ============================================================ */}
      <section className="gsap-problem-section py-20 sm:py-28 px-4 sm:px-6 relative overflow-hidden bg-white border-b border-[#e4e0d5]">
        <div className="max-w-4xl mx-auto text-center">
          {/* Main Statement Heading */}
          <h2 className="gsap-problem-title text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight text-[#171711] uppercase leading-tight">
            We all have a place <br />
            called <br />
            <span className="font-serif italic font-normal text-4xl sm:text-6xl lg:text-7xl normal-case tracking-normal block mt-2">
              &ldquo;LATER.&rdquo;
            </span>
          </h2>

          {/* 2x2 Behavioral Quote Cards */}
          <div className="gsap-problem-grid grid grid-cols-1 sm:grid-cols-2 gap-6 sm:gap-7 max-w-2xl mx-auto mt-14 sm:mt-16 p-2">
            {/* Card 1: Watch Later (-2.5 deg tilt) */}
            <div className="gsap-problem-card rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] -rotate-[2.5deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll watch it later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                WATCH LATER
              </span>
            </div>

            {/* Card 2: Bookmarks (+2.5 deg tilt) */}
            <div className="gsap-problem-card rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] rotate-[2.5deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll read it later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                BOOKMARKS
              </span>
            </div>

            {/* Card 3: Downloads (-2 deg tilt) */}
            <div className="gsap-problem-card rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] -rotate-[2deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll finish it later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                DOWNLOADS
              </span>
            </div>

            {/* Card 4: Open Tabs (+2 deg tilt) */}
            <div className="gsap-problem-card rounded-2xl sm:rounded-3xl bg-white border border-[#e4e0d5] p-8 sm:p-10 text-center shadow-[0_8px_30px_rgb(0,0,0,0.03)] rotate-[2deg] hover:rotate-0 hover:scale-[1.02] hover:border-[#171711] hover:shadow-[0_12px_40px_rgba(23,23,17,0.08)] transition-all duration-300 ease-out flex flex-col items-center justify-center space-y-3.5 group cursor-pointer relative z-10 hover:z-20">
              <p className="text-lg sm:text-xl font-bold text-[#171711]">
                &ldquo;I&apos;ll reply later.&rdquo;
              </p>
              <span className="px-3.5 py-1 rounded-full bg-[#f0ede4] group-hover:bg-[#171711] text-[#6c6b63] group-hover:text-white text-[10px] sm:text-xs font-extrabold uppercase tracking-wider transition-colors duration-200">
                OPEN TABS
              </span>
            </div>
          </div>

          {/* Bottom Punchline */}
          <div className="gsap-problem-punchline mt-14 sm:mt-18 text-center space-y-1">
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
      {/* "Designed to stay out of your way." Core Philosophy Section */}
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
      {/* "You don't need to do everything now." Core Statement */}
      {/* ============================================================ */}
      <WontForgetItLaterSection />

      {/* ============================================================ */}
      {/* Discovery Navigation Bar */}
      {/* ============================================================ */}
      <nav aria-label="Learn about LaterBox" className="mx-auto flex max-w-5xl flex-wrap justify-center gap-3.5 px-6 py-12">
        <Link
          href="/features"
          className="inline-flex items-center gap-1.5 px-5 py-2.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] text-xs font-bold hover:border-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-all"
        >
          <span>Explore LaterBox features</span>
          <ArrowRight className="w-3.5 h-3.5 text-[#6c6b63]" />
        </Link>
        <Link
          href="/about"
          className="inline-flex items-center gap-1.5 px-5 py-2.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] text-xs font-bold hover:border-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-all"
        >
          <span>About LaterBox &amp; Philosophy</span>
          <ArrowRight className="w-3.5 h-3.5 text-[#6c6b63]" />
        </Link>
        <Link
          href="/browser-extension"
          className="inline-flex items-center gap-1.5 px-5 py-2.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] text-xs font-bold hover:border-[#171711] hover:bg-[#faf8f5] shadow-2xs transition-all"
        >
          <span>Save with Browser Extension</span>
          <ArrowRight className="w-3.5 h-3.5 text-[#6c6b63]" />
        </Link>
      </nav>

      {/* ============================================================ */}
      {/* 2-Column Landing FAQ Section */}
      {/* ============================================================ */}
      <LandingFaqSection />

      {/* ============================================================ */}
      {/* Multi-Platform Ecosystem Cards */}
      {/* ============================================================ */}
      <MarketingPlatformsSection />
    </div>
  );
}
