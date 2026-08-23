'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Header } from '@/components/layout/Header';
import { useAuth } from '@/lib/store/AuthContext';
import {
  Sparkles,
  ArrowRight,
  Download,
  Compass,
  PlayCircle,
  Layers,
  Zap,
  ShieldCheck,
  Globe2,
  Smartphone,
  Laptop,
  Puzzle,
} from 'lucide-react';

export default function LandingPage() {
  const { continueAsGuest } = useAuth();

  const features = [
    {
      icon: <Puzzle className="w-6 h-6 text-[#171711]" />,
      title: 'Universal 1-Tap Save',
      description:
        'Save articles, YouTube videos, tweets, and notes instantly via Browser Extensions, macOS, iOS, Android, or Web.',
    },
    {
      icon: <Sparkles className="w-6 h-6 text-[#171711]" />,
      title: 'Smart AI Enrichment',
      description:
        'Automatically extract high-res preview covers, structured metadata, favicons, and categorize content without lifting a finger.',
    },
    {
      icon: <PlayCircle className="w-6 h-6 text-[#171711]" />,
      title: 'Native Media Embeds',
      description:
        'Watch YouTube videos, Vimeo streams, and listen to Spotify music and podcasts directly inside laterbox without ads or clutter.',
    },
    {
      icon: <Zap className="w-6 h-6 text-[#171711]" />,
      title: 'Offline-First & Fast',
      description:
        'Instant response times with local SQLite/browser storage and seamless background Supabase cloud sync.',
    },
    {
      icon: <Layers className="w-6 h-6 text-[#171711]" />,
      title: 'Collections & Filters',
      description:
        'Organize your digital memory with custom collections, category filters (Articles, Videos, Audio, Notes), and Starred archives.',
    },
    {
      icon: <ShieldCheck className="w-6 h-6 text-[#171711]" />,
      title: 'Privacy & Ownership',
      description:
        'Your data belongs to you. Zero tracking, end-to-end cloud sync with Supabase, and full offline export anytime.',
    },
  ];

  const steps = [
    {
      step: '01',
      title: 'Capture Anything in 1 Second',
      desc: 'Use the browser extension, share sheet on mobile, desktop hotkey, or web app to capture any link or selected text.',
    },
    {
      step: '02',
      title: 'Auto-Organize with AI',
      desc: 'laterbox enriches the link with clean readable metadata, cover art, tags, and creates an instant reader view.',
    },
    {
      step: '03',
      title: 'Read, Watch & Annotate Later',
      desc: 'Enjoy a clean distraction-free view with personal markdown notes, quote highlighting, and offline access across all devices.',
    },
  ];

  return (
    <div className="min-h-screen bg-[#f7f5ee] text-[#171711] selection:bg-[#171711] selection:text-white">
      <Header />

      {/* Hero Section */}
      <section className="relative pt-16 sm:pt-24 pb-20 overflow-hidden">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center relative z-10">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[#171711] text-xs font-bold mb-6 shadow-2xs">
            <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
            <span>Universal Save-For-Later Memory</span>
          </div>

          {/* Heading */}
          <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#171711] leading-[1.08] mb-6">
            Save anything now. <br />
            <span className="text-[#6c6b63]">
              Read, watch & organize later.
            </span>
          </h1>

          {/* Subheading */}
          <p className="max-w-2xl mx-auto text-base sm:text-xl text-[#6c6b63] leading-relaxed mb-10">
            laterbox automatically enriches your saved links, articles, videos, and notes with key AI summaries, preview cards, favicons, and embedded media players.
          </p>

          {/* CTA Buttons */}
          <div className="flex flex-wrap items-center justify-center gap-3.5">
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-7 py-3.5 rounded-full bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-extrabold text-sm sm:text-base shadow-sm transition-all duration-150 group"
            >
              <span>Get Started Free</span>
              <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
            </Link>

            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] hover:bg-[#ebe7dc]/50 font-bold text-sm sm:text-base shadow-xs transition-all"
            >
              <Download className="w-4 h-4 text-[#171711]" />
              <span>Download App</span>
            </Link>

            <Link
              href="/inbox"
              onClick={() => continueAsGuest()}
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-[#ebe7dc]/70 text-[#171711] hover:bg-[#ebe7dc] font-bold text-sm sm:text-base transition-all"
            >
              <Compass className="w-4 h-4 text-[#6c6b63]" />
              <span>Try Guest Mode</span>
            </Link>
          </div>

          {/* Interactive Mockup Preview Card */}
          <div className="mt-14 sm:mt-20 max-w-4xl mx-auto rounded-3xl bg-white border border-[#e4e0d5] p-3 sm:p-5 shadow-sm">
            {/* Window bar */}
            <div className="flex items-center gap-2 pb-3 mb-3 border-b border-[#e4e0d5] px-2">
              <div className="w-3 h-3 rounded-full bg-[#e4e0d5]" />
              <div className="w-3 h-3 rounded-full bg-[#e4e0d5]" />
              <div className="w-3 h-3 rounded-full bg-[#e4e0d5]" />
              <div className="mx-auto text-xs font-mono font-medium text-[#9e9b92]">
                laterbox.app/inbox
              </div>
            </div>

            {/* Mock Items Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-left">
              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]">
                <div className="flex items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 rounded bg-[#171711] flex items-center justify-center text-white text-[9px] font-bold">
                      Y
                    </div>
                    <span className="text-xs font-bold text-[#6c6b63]">youtube.com</span>
                  </div>
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase bg-[#fee2e2] text-[#b91c1c]">
                    Video
                  </span>
                </div>
                <h4 className="text-sm font-bold text-[#171711] line-clamp-1 mb-1">
                  Building Next.js 16 Apps on Cloudflare OpenNext
                </h4>
                <p className="text-xs text-[#6c6b63] line-clamp-2">
                  A full walkthrough of deploying edge-rendered Next.js with Supabase backend and instant sync.
                </p>
              </div>

              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]">
                <div className="flex items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 rounded bg-[#171711] flex items-center justify-center text-white text-[9px] font-bold">
                      G
                    </div>
                    <span className="text-xs font-bold text-[#6c6b63]">github.com</span>
                  </div>
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase bg-[#e6edb0] text-[#171711]">
                    Article
                  </span>
                </div>
                <h4 className="text-sm font-bold text-[#171711] line-clamp-1 mb-1">
                  Universal Browser Extension Architecture with MV3
                </h4>
                <p className="text-xs text-[#6c6b63] line-clamp-2">
                  Learn how laterbox connects Chrome & Firefox extensions securely via token exchange.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Available Platforms Section */}
      <section className="py-12 border-y border-[#e4e0d5] bg-[#ebe7dc]/30">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <p className="text-center text-xs font-bold uppercase tracking-widest text-[#9e9b92] mb-8">
            Available Everywhere You Browse & Read
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6 text-center">
            <div className="flex flex-col items-center gap-2">
              <Laptop className="w-7 h-7 text-[#171711]" />
              <span className="text-sm font-bold text-[#171711]">macOS & Windows</span>
              <span className="text-xs text-[#6c6b63]">Desktop Apps</span>
            </div>
            <div className="flex flex-col items-center gap-2">
              <Smartphone className="w-7 h-7 text-[#171711]" />
              <span className="text-sm font-bold text-[#171711]">iOS & Android</span>
              <span className="text-xs text-[#6c6b63]">Mobile Apps</span>
            </div>
            <div className="flex flex-col items-center gap-2">
              <Puzzle className="w-7 h-7 text-[#171711]" />
              <span className="text-sm font-bold text-[#171711]">Chrome & Firefox</span>
              <span className="text-xs text-[#6c6b63]">Browser Extensions</span>
            </div>
            <div className="flex flex-col items-center gap-2">
              <Globe2 className="w-7 h-7 text-[#171711]" />
              <span className="text-sm font-bold text-[#171711]">Web App</span>
              <span className="text-xs text-[#6c6b63]">Cloud & Offline Sync</span>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid Section */}
      <section id="features" className="py-24 max-w-6xl mx-auto px-4 sm:px-6">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711] mb-4">
            Everything you need in a modern save-for-later tool.
          </h2>
          <p className="text-base text-[#6c6b63]">
            Engineered for speed, privacy, and simplicity. No ads, no algorithmic feeds, just your curated library.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, idx) => (
            <div
              key={idx}
              className="p-7 rounded-3xl bg-white border border-[#e4e0d5] hover:border-[#cfdb84] hover:shadow-md transition-all duration-300"
            >
              <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] flex items-center justify-center mb-5">
                {feature.icon}
              </div>
              <h3 className="text-lg font-extrabold text-[#171711] mb-2">
                {feature.title}
              </h3>
              <p className="text-sm text-[#6c6b63] leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="py-20 bg-[#ebe7dc]/30 border-y border-[#e4e0d5]">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center">
          <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-[#171711] mb-16">
            How laterbox works
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-left">
            {steps.map((s) => (
              <div
                key={s.step}
                className="p-6 rounded-3xl bg-white border border-[#e4e0d5] space-y-3"
              >
                <span className="text-3xl font-black text-[#171711] font-mono">
                  {s.step}
                </span>
                <h3 className="text-lg font-bold text-[#171711]">{s.title}</h3>
                <p className="text-sm text-[#6c6b63] leading-relaxed">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Bottom CTA Banner */}
      <section className="py-20 max-w-5xl mx-auto px-4 sm:px-6">
        <div className="relative rounded-3xl bg-[#171711] p-8 sm:p-12 text-center text-white shadow-lg overflow-hidden">
          <div className="relative z-10 max-w-2xl mx-auto space-y-6">
            <h2 className="text-3xl sm:text-5xl font-black tracking-tight leading-tight">
              Ready to tame your digital bookmark overload?
            </h2>
            <p className="text-base sm:text-lg text-[#ebe7dc]">
              Join laterbox today. Start saving from any device with zero friction.
            </p>
            <div className="flex flex-wrap items-center justify-center gap-4 pt-2">
              <Link
                href="/inbox"
                className="px-7 py-3.5 rounded-full bg-[#e6edb0] text-[#171711] hover:bg-[#d8e09e] font-extrabold text-sm sm:text-base shadow-sm transition-all"
              >
                Launch Web App
              </Link>
              <Link
                href="/download"
                className="px-7 py-3.5 rounded-full bg-white/10 hover:bg-white/20 text-white font-bold text-sm sm:text-base transition-all"
              >
                Download Apps
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-[#e4e0d5] py-12 text-xs text-[#6c6b63]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 relative">
              <Image src="/branding/laterbox-icon.png" alt="" fill className="object-contain" />
            </div>
            <span className="font-bold text-[#171711]">laterbox</span>
            <span>© {new Date().getFullYear()} laterbox. All rights reserved.</span>
          </div>
          <div className="flex items-center gap-6">
            <Link href="/tutorial" className="hover:text-[#171711]">Guide</Link>
            <Link href="/download" className="hover:text-[#171711]">Downloads</Link>
            <Link href="/inbox" className="hover:text-[#171711]">Web App</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
