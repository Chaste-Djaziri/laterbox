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
      gsap.fromTo(
        '.gsap-problem-title',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-problem-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.7,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-problem-card',
        { opacity: 0, y: 35 },
        {
          scrollTrigger: {
            trigger: '.gsap-problem-grid',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          stagger: 0.1,
          duration: 0.65,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-problem-punchline',
        { opacity: 0, y: 20 },
        {
          scrollTrigger: {
            trigger: '.gsap-problem-punchline',
            start: 'top 90%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.6,
          ease: 'power2.out',
          clearProps: 'all',
        }
      );

      // When later becomes now (dark section)
      gsap.fromTo(
        '.gsap-now-heading',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-now-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.7,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-now-card',
        { opacity: 0, y: 35, scale: 0.96 },
        {
          scrollTrigger: {
            trigger: '.gsap-now-section',
            start: 'top 80%',
            once: true,
          },
          opacity: 1,
          y: 0,
          scale: 1,
          duration: 0.75,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // Not another todo list
      gsap.fromTo(
        '.gsap-not-todo-heading',
        { opacity: 0, y: 25 },
        {
          scrollTrigger: {
            trigger: '.gsap-not-todo-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.6,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-not-todo-row',
        { opacity: 0, x: -20 },
        {
          scrollTrigger: {
            trigger: '.gsap-not-todo-table',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          x: 0,
          stagger: 0.08,
          duration: 0.5,
          ease: 'power2.out',
          clearProps: 'all',
        }
      );

      // Someday vault
      gsap.fromTo(
        '.gsap-someday-text',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-someday-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.7,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-someday-deck',
        { opacity: 0, scale: 0.94, y: 25 },
        {
          scrollTrigger: {
            trigger: '.gsap-someday-section',
            start: 'top 80%',
            once: true,
          },
          opacity: 1,
          scale: 1,
          y: 0,
          duration: 0.75,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // Designed to stay out of your way
      gsap.fromTo(
        '.gsap-stay-heading, .gsap-stay-subheading',
        { opacity: 0, y: 25 },
        {
          scrollTrigger: {
            trigger: '.gsap-stay-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          stagger: 0.1,
          duration: 0.65,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-stay-card',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-stay-section',
            start: 'top 80%',
            once: true,
          },
          opacity: 1,
          y: 0,
          stagger: 0.12,
          duration: 0.65,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // Your LaterBox Your Rules
      gsap.fromTo(
        '.gsap-rules-text',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-rules-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.7,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-rules-visual',
        { opacity: 0, y: 35 },
        {
          scrollTrigger: {
            trigger: '.gsap-rules-section',
            start: 'top 80%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.8,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // One shortcut away
      gsap.fromTo(
        '.gsap-shortcut-content',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-shortcut-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.7,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // Your things stay
      gsap.fromTo(
        '.gsap-things-heading',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-things-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.7,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-things-card',
        { opacity: 0, y: 35 },
        {
          scrollTrigger: {
            trigger: '.gsap-things-grid',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          stagger: 0.12,
          duration: 0.6,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // Less mental clutter
      gsap.fromTo(
        '.gsap-clutter-heading',
        { opacity: 0, y: 25 },
        {
          scrollTrigger: {
            trigger: '.gsap-clutter-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.7,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-clutter-pill',
        { opacity: 0, scale: 0.9 },
        {
          scrollTrigger: {
            trigger: '.gsap-clutter-section',
            start: 'top 80%',
            once: true,
          },
          opacity: 1,
          scale: 1,
          stagger: 0.08,
          duration: 0.5,
          ease: 'back.out(1.4)',
          clearProps: 'all',
        }
      );

      // Wont forget it later
      gsap.fromTo(
        '.gsap-wont-forget-text',
        { opacity: 0, y: 30 },
        {
          scrollTrigger: {
            trigger: '.gsap-wont-forget-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.75,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-wont-forget-line',
        { scaleX: 0 },
        {
          scrollTrigger: {
            trigger: '.gsap-wont-forget-section',
            start: 'top 80%',
            once: true,
          },
          scaleX: 1,
          duration: 0.8,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // FAQ
      gsap.fromTo(
        '.gsap-faq-header',
        { opacity: 0, y: 25 },
        {
          scrollTrigger: {
            trigger: '.gsap-faq-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.65,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-faq-item',
        { opacity: 0, y: 20 },
        {
          scrollTrigger: {
            trigger: '.gsap-faq-section',
            start: 'top 80%',
            once: true,
          },
          opacity: 1,
          y: 0,
          stagger: 0.05,
          duration: 0.5,
          ease: 'power2.out',
          clearProps: 'all',
        }
      );

      // Marketing platforms
      gsap.fromTo(
        '.gsap-platforms-header',
        { opacity: 0, y: 25 },
        {
          scrollTrigger: {
            trigger: '.gsap-platforms-section',
            start: 'top 85%',
            once: true,
          },
          opacity: 1,
          y: 0,
          duration: 0.65,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      gsap.fromTo(
        '.gsap-platform-card',
        { opacity: 0, y: 35 },
        {
          scrollTrigger: {
            trigger: '.gsap-platforms-section',
            start: 'top 80%',
            once: true,
          },
          opacity: 1,
          y: 0,
          stagger: 0.12,
          duration: 0.65,
          ease: 'power3.out',
          clearProps: 'all',
        }
      );

      // Recalculate ScrollTrigger start points after layout stabilizes
      if (typeof window !== 'undefined') {
        window.requestAnimationFrame(() => {
          ScrollTrigger.refresh();
        });
      }
    },
    { scope: containerRef }
  );

  return (
    <div ref={containerRef} className="selection:bg-[#171711] selection:text-white">
      {/* Hero Section */}
      <section className="relative pt-12 sm:pt-20 pb-16 sm:pb-24 overflow-hidden">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center relative z-10">
          {/* Pro Pill Badge */}
          <div className="gsap-hero-badge inline-flex items-center gap-2 px-3.5 sm:px-4 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-extrabold mb-5 sm:mb-8 shadow-xs">
            <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
            <span className="sm:hidden">LaterBox Pro • Save now, find later</span>
            <span className="hidden sm:inline">LaterBox Pro • Built for Power Users, Developers &amp; Curators</span>
          </div>

          {/* Main Hero Heading */}
          <h1 className="gsap-hero-title text-3xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.1] sm:leading-[1.08] mb-4 sm:mb-6">
            <span className="sm:hidden">Save now. <br />Find it <span className="font-serif italic font-normal">later.</span></span>
            <span className="hidden sm:inline">LaterBox: save now. <br />Return to it <span className="font-serif italic font-normal">later.</span></span>
          </h1>

          {/* Subheading */}
          <p className="gsap-hero-sub max-w-2xl mx-auto text-sm sm:text-xl text-[#6c6b63] leading-relaxed mb-6 sm:mb-10">
            <span className="sm:hidden">Your bookmark manager for articles, links, and videos. Offline-first and organized.</span>
            <span className="hidden sm:inline">Your save-for-later app and bookmark manager for links, articles, videos, notes, and files. Organize collections and find what you saved when you need it.</span>
          </p>

          {/* Action CTAs (Hidden on mobile, desktop only) */}
          <div className="gsap-hero-cta relative z-20 hidden md:flex flex-wrap items-center justify-center gap-3.5">
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

          {/* Meta Trust Badges (Hidden on mobile, desktop only) */}
          <div className="gsap-hero-meta hidden md:block mt-8 text-xs text-[#6c6b63] space-y-1 font-medium">
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
          {/* Mobile: iOS Native App Preview (Full Height) */}
          {/* ============================================================ */}
          <div className="block md:hidden mt-8 sm:mt-10">
            <div className="relative mx-auto max-w-[320px] rounded-[44px] border-4 border-[#171711] bg-white p-2 shadow-[0_25px_60px_rgba(24,27,20,0.18)]">
              {/* Inner viewport displaying full image height */}
              <div className="relative w-full overflow-hidden rounded-[36px] bg-white">
                <Image
                  src="/branding/mobile-inbox-preview.png"
                  alt="LaterBox iOS Mobile App"
                  width={471}
                  height={1024}
                  priority
                  className="w-full h-auto block"
                />
              </div>
            </div>

            {/* iOS Download CTA below the phone frame */}
            <div className="mt-6 flex justify-center">
              <Link
                href="/download"
                className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#171711] hover:bg-[#282723] active:scale-95 text-white font-extrabold text-xs shadow-md transition-all"
              >
                <Apple className="w-3.5 h-3.5 text-white" />
                <span>Get LaterBox for iOS</span>
              </Link>
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
