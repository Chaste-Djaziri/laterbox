'use client';

import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import {
  ShieldCheck,
  Lock,
  EyeOff,
  Database,
  Cloud,
  HardDrive,
  Trash2,
  Mail,
  CheckCircle2,
  FileText,
} from 'lucide-react';

export default function PrivacyPolicyPage() {
  const lastUpdated = 'August 23, 2026';

  return (
    <div className="min-h-screen flex flex-col bg-[#f7f5ee] text-[#171711] selection:bg-zinc-900 selection:text-white">
      <Header />

      <main className="flex-1 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10 sm:py-16 space-y-12">
        {/* Title Header */}
        <div className="space-y-4 border-b border-[#e4e0d5] pb-8">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-xs font-extrabold border border-[#d0db84]">
            <ShieldCheck className="w-4 h-4" />
            <span>LaterBox Privacy Commitment</span>
          </div>
          <h1 className="text-3xl sm:text-5xl font-black tracking-tight text-[#171711]">
            Privacy Policy
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] font-medium leading-relaxed max-w-2xl">
            At LaterBox (a MICORP PRO service), your privacy is our foundational principle. We believe your bookmarks, reading queue, notes, and file attachments are strictly your own personal knowledge base.
          </p>
          <p className="text-xs font-semibold text-[#9e9b92]">
            Last Updated: {lastUpdated}
          </p>
        </div>

        {/* Key Guarantees Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <EyeOff className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Zero Ad Tracking</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              We never sell your personal data, reading habits, or saved links to advertisers or data brokers.
            </p>
          </div>

          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <Lock className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Isolated User Data</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Strict database Row Level Security (RLS) ensures only your authenticated account can access your data.
            </p>
          </div>

          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <HardDrive className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Local-First Freedom</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              LaterBox works offline on your devices and syncs smoothly with encrypted cloud backups.
            </p>
          </div>
        </div>

        {/* Detailed Sections */}
        <div className="space-y-10 text-sm leading-relaxed text-[#3a3935]">
          {/* Section 1 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Database className="w-5 h-5 text-[#171711]" />
              <span>1. Information We Collect</span>
            </h2>
            <p>
              When you use LaterBox across our web app, browser extension, mobile apps (iOS, Android), and desktop apps (macOS, Windows, Linux), we collect only what is necessary to provide the service:
            </p>
            <ul className="space-y-2.5 pl-2 list-none">
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>
                  <strong className="text-[#171711]">Account Data:</strong> Your email address and authentication credentials when you sign up or log in via Supabase Authentication.
                </span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>
                  <strong className="text-[#171711]">Saved Content:</strong> URLs you bookmark, web page titles, highlights/text selections, notes you write, collections you create, and status tags (inbox, kept, archived, favorite).
                </span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>
                  <strong className="text-[#171711]">File Attachments:</strong> Images, PDF documents, videos, audio recordings, spreadsheets, code files, and notes you upload to attach to saved items.
                </span>
              </li>
              <li className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>
                  <strong className="text-[#171711]">Pairing & Extension Tokens:</strong> Cryptographic session tokens (e.g. <code className="px-1.5 py-0.5 bg-[#f7f5ee] rounded-md text-xs font-mono">lb_ext_...</code>) used to securely authorize your browser extension to save links to your inbox.
                </span>
              </li>
            </ul>
          </section>

          {/* Section 2 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Cloud className="w-5 h-5 text-[#171711]" />
              <span>2. How Your Data Is Processed & Stored</span>
            </h2>
            <p>
              Your content is stored and processed with industry-standard security practices:
            </p>
            <div className="space-y-3 pt-1">
              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] space-y-1">
                <h4 className="font-bold text-xs text-[#171711]">Cloud Database (Supabase)</h4>
                <p className="text-xs text-[#6c6b63]">
                  Your bookmarks, metadata, collections, and account records reside in PostgreSQL databases hosted via Supabase, protected by Row Level Security (RLS) rules that restrict query access strictly to your authenticated User ID.
                </p>
              </div>
              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] space-y-1">
                <h4 className="font-bold text-xs text-[#171711]">Object Storage (Cloudflare R2)</h4>
                <p className="text-xs text-[#6c6b63]">
                  Uploaded file attachments are stored in private Cloudflare R2 buckets. Download and preview links are generated with signed, time-limited cryptographic URLs.
                </p>
              </div>
              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] space-y-1">
                <h4 className="font-bold text-xs text-[#171711]">Link Enrichment</h4>
                <p className="text-xs text-[#6c6b63]">
                  When you save a public link, our enrichment service retrieves standard public OpenGraph metadata (page title, description, favicon, and preview image) to render readable card summaries in your inbox.
                </p>
              </div>
            </div>
          </section>

          {/* Section 3 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Trash2 className="w-5 h-5 text-[#171711]" />
              <span>3. Data Retention & Your Rights</span>
            </h2>
            <p>
              You maintain complete authority over your information:
            </p>
            <ul className="space-y-2 pl-2">
              <li>
                • <strong className="text-[#171711]">Delete Items:</strong> Deleting an item or attachment immediately soft-deletes and removes it from your inbox, and purges attached files.
              </li>
              <li>
                • <strong className="text-[#171711]">Account Deletion:</strong> You can request full permanent deletion of your account and all associated bookmarks, files, and tokens at any time.
              </li>
              <li>
                • <strong className="text-[#171711]">Offline Mode:</strong> If you use LaterBox as a guest without signing in, your data stays entirely on your local device storage.
              </li>
            </ul>
          </section>

          {/* Section 4 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Mail className="w-5 h-5 text-[#171711]" />
              <span>4. Contact & Support</span>
            </h2>
            <p>
              If you have any questions about this Privacy Policy or wish to exercise your data rights, please contact our team:
            </p>
            <div className="p-4 rounded-2xl bg-[#e6edb0]/40 border border-[#d0db84] space-y-1">
              <p className="font-bold text-xs text-[#171711]">MICORP PRO — LaterBox Privacy Team</p>
              <p className="text-xs text-[#6c6b63]">Email: <a href="mailto:support@micorp.pro" className="font-semibold text-[#171711] underline">support@micorp.pro</a></p>
              <p className="text-xs text-[#6c6b63]">Tester Community: <a href="https://groups.google.com/g/laterbox-testers" target="_blank" rel="noreferrer" className="font-semibold text-[#171711] underline">Google Group laterbox-testers</a></p>
            </div>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
