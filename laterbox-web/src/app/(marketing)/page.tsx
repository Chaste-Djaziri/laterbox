'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/lib/store/AuthContext';
import { DashboardPreviewMockup } from '@/components/marketing/DashboardPreviewMockup';
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
import { UltimateWindowsOrganizerSection } from '@/components/marketing/UltimateWindowsOrganizerSection';
import { WontForgetItLaterSection } from '@/components/marketing/WontForgetItLaterSection';
import { LandingFaqSection } from '@/components/marketing/LandingFaqSection';
import {
  Sparkles,
  ArrowRight,
  Download,
  Compass,
  PlayCircle,
  Play,
  Layers,
  Globe2,
  Smartphone,
  Laptop,
  Puzzle,
  Search,
  Bookmark,
  FileText,
  BookOpen,
  Video,
  Music,
  Code2,
  Terminal,
} from 'lucide-react';

export default function LandingPage() {
  const { continueAsGuest } = useAuth();

  return (
    <div className="selection:bg-[#171711] selection:text-white">
      {/* Hero Section */}
      <section className="relative pt-12 sm:pt-20 pb-16 sm:pb-24 overflow-hidden">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center relative z-10">
          {/* Pro Pill Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-extrabold mb-8 shadow-xs">
            <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
            <span>LaterBox Pro • Built for Power Users, Developers & Curators</span>
          </div>

          {/* Main Hero Heading */}
          <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.08] mb-6">
            Drop it now. <br />
            Deal with it <span className="font-serif italic font-normal">later.</span>
          </h1>

          {/* Subheading */}
          <p className="max-w-2xl mx-auto text-base sm:text-xl text-[#6c6b63] leading-relaxed mb-10">
            Save files, links, tasks, and ideas for later. <br className="hidden sm:inline" />
            We&apos;ll bring them back when you&apos;re ready.
          </p>

          {/* Action CTAs */}
          <div className="flex flex-wrap items-center justify-center gap-3.5">
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-7 py-3.5 rounded-full bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-extrabold text-sm sm:text-base shadow-sm transition-all duration-150 group"
            >
              <span>Launch Web App Free</span>
              <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
            </Link>

            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] hover:bg-[#ebe7dc]/50 font-bold text-sm sm:text-base shadow-xs transition-all"
            >
              <Download className="w-4 h-4 text-[#171711]" />
              <span>Download Desktop & Mobile</span>
            </Link>

            <Link
              href="/inbox"
              onClick={() => continueAsGuest()}
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-[#ebe7dc]/70 text-[#171711] hover:bg-[#ebe7dc] font-bold text-sm sm:text-base transition-all"
            >
              <Compass className="w-4 h-4 text-[#6c6b63]" />
              <span>Try Guest Sandbox</span>
            </Link>
          </div>

          {/* Meta Trust Badges */}
          <div className="mt-8 text-xs text-[#6c6b63] space-y-1 font-medium">
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

          {/* Floating Try It Badge Indicator */}
          <div className="mt-12 sm:mt-16 max-w-5xl mx-auto flex justify-start pl-6 sm:pl-10 mb-[-12px] relative z-20">
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

          {/* ============================================================ */}
          {/* Interactive Native Dashboard Preview */}
          {/* ============================================================ */}
          <DashboardPreviewMockup />
        </div>
      </section>

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
      <HowItWorksStepsSection />

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
      <UltimateWindowsOrganizerSection />

      {/* ============================================================ */}
      {/* "You don't need to do everything now." Core Statement */}
      {/* ============================================================ */}
      <WontForgetItLaterSection />

      {/* ============================================================ */}
      {/* 2-Column Landing FAQ Section */}
      {/* ============================================================ */}
      <LandingFaqSection />



      {/* ============================================================ */}
      {/* All-Platform Ecosystem Showcase */}
      {/* ============================================================ */}
      <section className="py-16 border-y border-[#e4e0d5] bg-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 text-center">
          <p className="text-xs font-bold uppercase tracking-widest text-[#9e9b92] mb-8">
            One Unified Vault Across All Your Devices
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
            <Link
              href="/download"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Laptop className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">macOS & Windows</span>
              <span className="text-xs text-[#6c6b63]">DMG, PKG, EXE & Inno Setup</span>
            </Link>

            <Link
              href="/download"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Smartphone className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">iOS & Android</span>
              <span className="text-xs text-[#6c6b63]">App Store & Google Play Beta</span>
            </Link>

            <Link
              href="/download"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Puzzle className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">Browser Extensions</span>
              <span className="text-xs text-[#6c6b63]">Chrome, Firefox & Safari MV3</span>
            </Link>

            <Link
              href="/inbox"
              className="p-5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all flex flex-col items-center gap-2 group"
            >
              <Globe2 className="w-7 h-7 text-[#171711] transition-transform group-hover:scale-110" />
              <span className="text-sm font-bold text-[#171711]">Cloud Web App</span>
              <span className="text-xs text-[#6c6b63]">Zero install, instant access</span>
            </Link>
          </div>
        </div>
      </section>


      {/* ============================================================ */}
      {/* Pre-Footer Final Download CTA Banner (White Section, Black Container) */}
      {/* ============================================================ */}
      <section className="bg-white py-20 sm:py-28 px-4 sm:px-6">
        <div className="max-w-5xl mx-auto relative rounded-3xl sm:rounded-[36px] bg-[#171711] p-10 sm:p-16 lg:p-20 text-center text-white shadow-2xl overflow-hidden border border-[#2e2d28]">
          <div className="relative z-10 max-w-3xl mx-auto flex flex-col items-center">
            {/* Main Headline */}
            <div className="space-y-1 sm:space-y-2 mb-8 sm:mb-10">
              <h2 className="text-4xl sm:text-6xl md:text-7xl lg:text-[76px] font-black tracking-tight leading-none text-white">
                Drop it now.
              </h2>
              <p className="font-serif italic font-normal text-3xl sm:text-5xl md:text-6xl lg:text-[68px] leading-tight text-[#e6edb0]">
                Deal with it later.
              </p>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-wrap items-center justify-center gap-3.5 sm:gap-4 w-full">
              <Link
                href="/download?platform=windows"
                className="px-8 sm:px-9 py-4 rounded-full bg-[#e6edb0] text-[#171711] hover:bg-[#d8e09e] font-extrabold text-xs sm:text-sm tracking-wider uppercase shadow-md hover:scale-102 transition-all cursor-pointer"
              >
                Download for Windows
              </Link>
              <Link
                href="/download?platform=macos"
                className="px-8 sm:px-9 py-4 rounded-full bg-white/10 hover:bg-white/20 text-white font-bold text-xs sm:text-sm tracking-wider uppercase transition-all border border-white/10 hover:scale-102"
              >
                Download for Mac
              </Link>
            </div>

            {/* Subtext */}
            <p className="text-xs sm:text-sm text-[#9e9b92] tracking-wide mt-7 sm:mt-9 select-none font-medium">
              Free • Offline • No account required
            </p>

            {/* Attribution */}
            <p className="text-[11px] sm:text-xs text-[#6c6b63] mt-3">
              Made by{' '}
              <a
                href="https://micorp.pro"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[#9e9b92] hover:text-white underline decoration-dotted transition-colors"
              >
                Nexaura Dev
              </a>
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
