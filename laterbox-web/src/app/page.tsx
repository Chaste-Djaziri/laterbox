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
      icon: <Puzzle className="w-6 h-6 text-emerald-500" />,
      title: 'Universal 1-Tap Save',
      description:
        'Save articles, YouTube videos, tweets, and notes instantly via Browser Extensions, macOS, iOS, Android, or Web.',
    },
    {
      icon: <Sparkles className="w-6 h-6 text-amber-500" />,
      title: 'Smart AI Enrichment',
      description:
        'Automatically extract high-res preview covers, structured metadata, favicons, and categorize content without lifting a finger.',
    },
    {
      icon: <PlayCircle className="w-6 h-6 text-red-500" />,
      title: 'Native Media Embeds',
      description:
        'Watch YouTube videos, Vimeo streams, and listen to Spotify music and podcasts directly inside laterbox without ads or clutter.',
    },
    {
      icon: <Zap className="w-6 h-6 text-blue-500" />,
      title: 'Offline-First & Fast',
      description:
        'Instant response times with local SQLite/browser storage and seamless background Supabase cloud sync.',
    },
    {
      icon: <Layers className="w-6 h-6 text-purple-500" />,
      title: 'Collections & Filters',
      description:
        'Organize your digital memory with custom collections, category filters (Articles, Videos, Audio, Notes), and Starred archives.',
    },
    {
      icon: <ShieldCheck className="w-6 h-6 text-emerald-500" />,
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
    <div className="min-h-screen bg-zinc-50 text-zinc-900 selection:bg-emerald-500 selection:text-white">
      <Header />

      {/* Hero Section */}
      <section className="relative pt-16 sm:pt-24 pb-20 overflow-hidden">
        {/* Background glow */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-emerald-500/10 blur-[120px] rounded-full pointer-events-none" />

        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center relative z-10">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 border border-emerald-200/80 text-emerald-700 text-xs font-bold mb-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
            <Sparkles className="w-3.5 h-3.5 text-emerald-500" />
            <span>Universal Save-For-Later Memory</span>
          </div>

          {/* Heading */}
          <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-zinc-900 leading-[1.08] mb-6">
            Save anything now. <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-600 to-teal-500">
              Read, watch & organize later.
            </span>
          </h1>

          {/* Subheading */}
          <p className="max-w-2xl mx-auto text-base sm:text-xl text-zinc-600 leading-relaxed mb-10">
            laterbox automatically enriches your saved links, articles, videos, and notes with key AI summaries, preview cards, favicons, and embedded media players.
          </p>

          {/* CTA Buttons */}
          <div className="flex flex-wrap items-center justify-center gap-3.5">
            <Link
              href="/inbox"
              className="inline-flex items-center gap-2 px-7 py-3.5 rounded-full bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-extrabold text-sm sm:text-base shadow-lg shadow-emerald-600/25 transition-all duration-150 group"
            >
              <span>Get Started Free</span>
              <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
            </Link>

            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-white border border-zinc-200 text-zinc-800 hover:bg-zinc-50 font-bold text-sm sm:text-base shadow-sm transition-all"
            >
              <Download className="w-4 h-4 text-emerald-600" />
              <span>Download App</span>
            </Link>

            <Link
              href="/inbox"
              onClick={() => continueAsGuest()}
              className="inline-flex items-center gap-2 px-6 py-3.5 rounded-full bg-zinc-100 text-zinc-700 hover:bg-zinc-200/70 font-bold text-sm sm:text-base transition-all"
            >
              <Compass className="w-4 h-4 text-zinc-500" />
              <span>Try Guest Mode</span>
            </Link>
          </div>

          {/* Interactive Mockup Preview Card */}
          <div className="mt-14 sm:mt-20 max-w-4xl mx-auto rounded-3xl bg-white border border-zinc-200/80 p-3 sm:p-5 shadow-2xl shadow-zinc-900/10">
            {/* Window bar */}
            <div className="flex items-center gap-2 pb-3 mb-3 border-b border-zinc-100 px-2">
              <div className="w-3 h-3 rounded-full bg-red-400" />
              <div className="w-3 h-3 rounded-full bg-amber-400" />
              <div className="w-3 h-3 rounded-full bg-emerald-400" />
              <div className="mx-auto text-xs font-mono font-medium text-zinc-400">
                laterbox.app/inbox
              </div>
            </div>

            {/* Mock Items Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-left">
              <div className="p-4 rounded-2xl bg-zinc-50 border border-zinc-200/60">
                <div className="flex items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 rounded bg-red-500 flex items-center justify-center text-white text-[9px] font-bold">
                      Y
                    </div>
                    <span className="text-xs font-bold text-zinc-500">youtube.com</span>
                  </div>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-red-50 text-red-600">
                    Video
                  </span>
                </div>
                <h4 className="text-sm font-bold text-zinc-900 line-clamp-1 mb-1">
                  Building Next.js 16 Apps on Cloudflare OpenNext
                </h4>
                <p className="text-xs text-zinc-500 line-clamp-2">
                  A full walkthrough of deploying edge-rendered Next.js with Supabase backend and instant sync.
                </p>
              </div>

              <div className="p-4 rounded-2xl bg-zinc-50 border border-zinc-200/60">
                <div className="flex items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 rounded bg-blue-500 flex items-center justify-center text-white text-[9px] font-bold">
                      G
                    </div>
                    <span className="text-xs font-bold text-zinc-500">github.com</span>
                  </div>
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-blue-50 text-blue-600">
                    Article
                  </span>
                </div>
                <h4 className="text-sm font-bold text-zinc-900 line-clamp-1 mb-1">
                  Universal Browser Extension Architecture with MV3
                </h4>
                <p className="text-xs text-zinc-500 line-clamp-2">
                  Learn how laterbox connects Chrome & Firefox extensions securely via token exchange.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Available Platforms Section */}
      <section className="py-12 border-y border-zinc-200/80 bg-zinc-100/50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <p className="text-center text-xs font-bold uppercase tracking-widest text-zinc-400 mb-8">
            Available Everywhere You Browse & Read
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6 text-center">
            <div className="flex flex-col items-center gap-2">
              <Laptop className="w-7 h-7 text-emerald-600" />
              <span className="text-sm font-bold text-zinc-900">macOS & Windows</span>
              <span className="text-xs text-zinc-400">Desktop Apps</span>
            </div>
            <div className="flex flex-col items-center gap-2">
              <Smartphone className="w-7 h-7 text-emerald-600" />
              <span className="text-sm font-bold text-zinc-900">iOS & Android</span>
              <span className="text-xs text-zinc-400">Mobile Apps</span>
            </div>
            <div className="flex flex-col items-center gap-2">
              <Puzzle className="w-7 h-7 text-emerald-600" />
              <span className="text-sm font-bold text-zinc-900">Chrome & Firefox</span>
              <span className="text-xs text-zinc-400">Browser Extensions</span>
            </div>
            <div className="flex flex-col items-center gap-2">
              <Globe2 className="w-7 h-7 text-emerald-600" />
              <span className="text-sm font-bold text-zinc-900">Web App</span>
              <span className="text-xs text-zinc-400">Cloud & Offline Sync</span>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid Section */}
      <section id="features" className="py-24 max-w-6xl mx-auto px-4 sm:px-6">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-zinc-900 mb-4">
            Everything you need in a modern save-for-later tool.
          </h2>
          <p className="text-base text-zinc-600">
            Engineered for speed, privacy, and simplicity. No ads, no algorithmic feeds, just your curated library.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, idx) => (
            <div
              key={idx}
              className="p-7 rounded-3xl bg-white border border-zinc-200/80 hover:border-emerald-500/50 hover:shadow-xl transition-all duration-300"
            >
              <div className="w-12 h-12 rounded-2xl bg-zinc-100 flex items-center justify-center mb-5">
                {feature.icon}
              </div>
              <h3 className="text-lg font-extrabold text-zinc-900 mb-2">
                {feature.title}
              </h3>
              <p className="text-sm text-zinc-500 leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* How It Works Section */}
      <section id="how-it-works" className="py-20 bg-zinc-100/60 border-y border-zinc-200/80">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 text-center">
          <h2 className="text-3xl sm:text-4xl font-black tracking-tight text-zinc-900 mb-16">
            How laterbox works
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-left">
            {steps.map((s) => (
              <div
                key={s.step}
                className="p-6 rounded-3xl bg-white border border-zinc-200/80 space-y-3"
              >
                <span className="text-3xl font-black text-emerald-600 font-mono">
                  {s.step}
                </span>
                <h3 className="text-lg font-bold text-zinc-900">{s.title}</h3>
                <p className="text-sm text-zinc-500 leading-relaxed">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Bottom CTA Banner */}
      <section className="py-20 max-w-5xl mx-auto px-4 sm:px-6">
        <div className="relative rounded-3xl bg-gradient-to-br from-emerald-600 to-teal-700 p-8 sm:p-12 text-center text-white shadow-2xl overflow-hidden">
          <div className="relative z-10 max-w-2xl mx-auto space-y-6">
            <h2 className="text-3xl sm:text-5xl font-black tracking-tight leading-tight">
              Ready to tame your digital bookmark overload?
            </h2>
            <p className="text-base sm:text-lg text-emerald-100">
              Join laterbox today. Start saving from any device with zero friction.
            </p>
            <div className="flex flex-wrap items-center justify-center gap-4 pt-2">
              <Link
                href="/inbox"
                className="px-7 py-3.5 rounded-full bg-white text-emerald-800 hover:bg-emerald-50 active:bg-emerald-100 font-extrabold text-sm sm:text-base shadow-lg transition-all"
              >
                Launch Web App
              </Link>
              <Link
                href="/download"
                className="px-7 py-3.5 rounded-full bg-emerald-800/70 hover:bg-emerald-800 text-white font-bold text-sm sm:text-base transition-all"
              >
                Download Apps
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-zinc-200/80 py-12 text-xs text-zinc-500">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 relative">
              <Image src="/branding/laterbox-icon.png" alt="" fill className="object-contain" />
            </div>
            <span className="font-bold text-zinc-700">laterbox</span>
            <span>© {new Date().getFullYear()} laterbox. All rights reserved.</span>
          </div>
          <div className="flex items-center gap-6">
            <Link href="/tutorial" className="hover:text-emerald-600">Guide</Link>
            <Link href="/download" className="hover:text-emerald-600">Downloads</Link>
            <Link href="/inbox" className="hover:text-emerald-600">Web App</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
