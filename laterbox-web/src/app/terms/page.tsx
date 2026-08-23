'use client';

import React from 'react';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import {
  FileText,
  Scale,
  UserCheck,
  ShieldAlert,
  FolderLock,
  RefreshCw,
  Mail,
  CheckCircle2,
} from 'lucide-react';

export default function TermsOfServicePage() {
  const lastUpdated = 'August 23, 2026';

  return (
    <div className="min-h-screen flex flex-col bg-[#f7f5ee] text-[#171711] selection:bg-zinc-900 selection:text-white">
      <Header />

      <main className="flex-1 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10 sm:py-16 space-y-12">
        {/* Title Header */}
        <div className="space-y-4 border-b border-[#e4e0d5] pb-8">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-xs font-extrabold border border-[#d0db84]">
            <Scale className="w-4 h-4" />
            <span>Terms of Service</span>
          </div>
          <h1 className="text-3xl sm:text-5xl font-black tracking-tight text-[#171711]">
            Terms of Service
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] font-medium leading-relaxed max-w-2xl">
            Welcome to LaterBox. These Terms of Service govern your use of the LaterBox application, website, browser extension, and related synchronization services provided by MICORP PRO.
          </p>
          <p className="text-xs font-semibold text-[#9e9b92]">
            Last Updated: {lastUpdated}
          </p>
        </div>

        {/* Core Principles */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <FolderLock className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Your Content Stays Yours</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              You retain 100% intellectual property ownership of all links, notes, and attachments you store.
            </p>
          </div>

          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <UserCheck className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Fair & Responsible Use</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Use LaterBox for legitimate personal and professional productivity without abusing resources.
            </p>
          </div>

          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <RefreshCw className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Reliable Syncing</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Seamlessly capture, organize, and sync your reading inbox across all supported operating systems.
            </p>
          </div>
        </div>

        {/* Detailed Terms */}
        <div className="space-y-10 text-sm leading-relaxed text-[#3a3935]">
          {/* Section 1 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <FileText className="w-5 h-5 text-[#171711]" />
              <span>1. Acceptance of Terms</span>
            </h2>
            <p>
              By accessing, installing, or using LaterBox (including the web app at <a href="https://laterbox.dev" className="text-[#171711] font-semibold underline">laterbox.dev</a>, desktop clients on macOS/Windows/Linux, mobile apps on iOS/Android, and the browser extension), you agree to be bound by these Terms. If you do not agree to these Terms, please do not use the service.
            </p>
          </section>

          {/* Section 2 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <UserCheck className="w-5 h-5 text-[#171711]" />
              <span>2. Accounts and Authentication</span>
            </h2>
            <p>
              To synchronize your bookmarks, reading queue, and attachments across multiple devices, you may create an account using your email address or third-party sign-in providers.
            </p>
            <ul className="space-y-2 pl-2">
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>You are responsible for safeguarding your password and account session credentials.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>You must promptly notify us at <a href="mailto:support@micorp.pro" className="text-[#171711] font-semibold underline">support@micorp.pro</a> of any unauthorized access to your account.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span>Guest / Offline users may use local client features without registering an online account.</span>
              </li>
            </ul>
          </section>

          {/* Section 3 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <FolderLock className="w-5 h-5 text-[#171711]" />
              <span>3. User Content & Intellectual Property</span>
            </h2>
            <p>
              You retain full ownership and intellectual property rights to all text, URLs, notes, images, documents, and file attachments you capture or upload to LaterBox.
            </p>
            <p>
              By uploading or saving content to LaterBox, you grant us only the limited technical license required to host, parse, cache, and transmit your data to your authorized devices and provide metadata enrichment previews.
            </p>
          </section>

          {/* Section 4 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <ShieldAlert className="w-5 h-5 text-[#171711]" />
              <span>4. Acceptable Use Policy</span>
            </h2>
            <p>
              You agree not to misuse LaterBox services. Prohibited activities include:
            </p>
            <ul className="space-y-2 pl-2">
              <li>• Uploading or distributing malware, viruses, or malicious file payloads.</li>
              <li>• Attempting to reverse engineer, disrupt, or overload the backend API or R2 storage.</li>
              <li>• Using the service to store or transmit illegal or infringing content.</li>
              <li>• Attempting to circumvent database security rules or access another user&apos;s data.</li>
            </ul>
          </section>

          {/* Section 5 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <RefreshCw className="w-5 h-5 text-[#171711]" />
              <span>5. Service Availability & Modifications</span>
            </h2>
            <p>
              We continually improve LaterBox with new features, offline capabilities, and enhancements. We reserve the right to modify, suspend, or discontinue aspects of the service with reasonable notice when possible.
            </p>
            <p>
              The service is provided on an &ldquo;AS IS&rdquo; and &ldquo;AS AVAILABLE&rdquo; basis.
            </p>
          </section>

          {/* Section 6 */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Mail className="w-5 h-5 text-[#171711]" />
              <span>6. Contact Us</span>
            </h2>
            <p>
              If you have any questions or concerns regarding these Terms of Service, please reach out to us:
            </p>
            <div className="p-4 rounded-2xl bg-[#e6edb0]/40 border border-[#d0db84] space-y-1">
              <p className="font-bold text-xs text-[#171711]">MICORP PRO (LaterBox)</p>
              <p className="text-xs text-[#6c6b63]">Support Email: <a href="mailto:support@micorp.pro" className="font-semibold text-[#171711] underline">support@micorp.pro</a></p>
              <p className="text-xs text-[#6c6b63]">Website: <a href="https://laterbox.dev" className="font-semibold text-[#171711] underline">https://laterbox.dev</a></p>
            </div>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
