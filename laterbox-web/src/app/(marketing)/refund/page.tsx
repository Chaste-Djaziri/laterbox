'use client';

import React from 'react';
import Link from 'next/link';
import {
  Ban,
  Receipt,
  Clock,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
  Mail,
  ShieldAlert,
  ArrowRight,
} from 'lucide-react';

export default function RefundPolicyPage() {
  const lastUpdated = 'November 8, 2026';

  return (
    <div className="w-full flex-1">
      <main className="flex-1 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-10 sm:py-16 space-y-12">
        {/* Title Header */}
        <div className="space-y-4 border-b border-[#e4e0d5] pb-8">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] text-[#171711] text-xs font-extrabold border border-[#d0db84]">
            <Receipt className="w-4 h-4" />
            <span>Billing & Cancellations</span>
          </div>
          <h1 className="text-3xl sm:text-5xl font-black tracking-tight text-[#171711]">
            Refund Policy
          </h1>
          <p className="text-sm sm:text-base text-[#6c6b63] font-medium leading-relaxed max-w-2xl">
            This policy explains refunds and cancellations for LaterBox storage subscriptions, including Whop purchases and legacy providers. Mandatory consumer rights under applicable law always apply.
          </p>
          <p className="text-xs font-semibold text-[#9e9b92]">
            Last Updated: {lastUpdated}
          </p>
        </div>

        {/* Core Principles */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-amber-100 flex items-center justify-center text-amber-900 border border-amber-200">
              <Ban className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Refund Eligibility</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Paid subscriptions generally renew until canceled. Refund requests remain subject to applicable consumer law and the payment provider's rules.
            </p>
          </div>

          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <Clock className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Free Plan</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Save links and sync across devices for free. Upgrade only when you need more cloud storage.
            </p>
          </div>

          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <Receipt className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">Cancel Anytime</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Easily manage or cancel your subscription self-serve from your billing portal before the next renewal.
            </p>
          </div>
        </div>

        {/* Detailed Policy Sections */}
        <div className="space-y-10 text-sm leading-relaxed text-[#3a3935]">
          {/* Section 1: Strict No-Refund Policy */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Ban className="w-5 h-5 text-amber-700" />
              <span>1. Strict No-Refund Policy</span>
            </h2>
            <p>
              Except where required by applicable local law or the payment provider, <strong>paid subscription charges are generally non-refundable once the billing period begins</strong>.
            </p>
            <p>
              We do not provide prorated refunds, partial refunds, or credits for unused subscription time, early cancellations, downgrades, or accidental renewals once a billing period has commenced.
            </p>
            <div className="p-4 rounded-2xl bg-amber-50/70 border border-amber-200/80 text-xs text-amber-950 space-y-1">
              <p className="font-bold flex items-center gap-1.5">
                <AlertCircle className="w-4 h-4 text-amber-700 shrink-0" />
                <span>Important Notice Before Subscribing</span>
              </p>
              <p>
                Paid plans allocate additional cloud storage immediately. Basic cloud sync remains free for all signed-in accounts.
              </p>
            </div>
          </section>

          {/* Section 2: 14-Day Free Trial & Evaluation */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Clock className="w-5 h-5 text-[#171711]" />
              <span>2. Free Evaluation & Optional Promotions</span>
            </h2>
            <p>
              You can evaluate LaterBox before purchasing more storage:
            </p>
            <ul className="space-y-2.5 pl-1">
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span><strong>Free Tier:</strong> Saving, reading, searching, organizing, device sync, and 500 MB of cloud storage are free without payment details.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span><strong>Optional promotions:</strong> A trial is available only if explicitly shown during checkout. New Whop storage plans are not configured with a trial by default.</span>
              </li>
            </ul>
            <p>
              Review the final price, renewal terms, and any eligible promotion before confirming a paid subscription.
            </p>
          </section>

          {/* Section 3: Self-Serve Cancellation */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5 text-[#171711]" />
              <span>3. How Cancellation Works</span>
            </h2>
            <p>
              You may cancel your subscription at any time. Cancellation is completely self-serve and takes effect at the conclusion of your current paid billing period:
            </p>
            <ul className="space-y-2 pl-2">
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[#171711] shrink-0 mt-2" />
                <span><strong>Web Purchases (Whop and legacy Paddle):</strong> Open Account Settings in LaterBox and select Manage Subscription to reach your original payment provider.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[#171711] shrink-0 mt-2" />
                <span><strong>Apple In-App Purchases (iOS / macOS):</strong> Manage or cancel directly via your device&apos;s Apple ID Settings under <em>Subscriptions</em>.</span>
              </li>
            </ul>
            <p>
              Cancellation follows the provider's confirmed effective date. When your paid storage allowance ends, free syncing remains available. Existing saved data is not automatically deleted, but new uploads may pause when your files exceed the Free quota.
            </p>
          </section>

          {/* Section 4: Apple App Store Purchases */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <ShieldAlert className="w-5 h-5 text-[#171711]" />
              <span>4. Subscriptions Purchased via Apple (App Store)</span>
            </h2>
            <p>
              If you subscribed to LaterBox Pro through the Apple App Store on iOS or macOS, all transactions, billing, and refund requests are governed exclusively by Apple&apos;s terms and processed directly by Apple Media Services.
            </p>
            <p>
              LaterBox does not process payments or issue refunds for App Store transactions. To request a refund from Apple, you must visit{' '}
              <a
                href="https://reportaproblem.apple.com"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[#171711] font-semibold underline inline-flex items-center gap-0.5"
              >
                reportaproblem.apple.com
              </a>{' '}
              and submit your request directly to Apple Support.
            </p>
          </section>

          {/* Section 5: Billing Questions & Contact */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <HelpCircle className="w-5 h-5 text-[#171711]" />
              <span>5. Billing Inquiries & Exceptional Issues</span>
            </h2>
            <p>
              If you suspect you were charged in error (for example, duplicate billing or unauthorized account access), please contact our support team immediately before initiating a dispute:
            </p>
            <div className="p-4 rounded-2xl bg-[#e6edb0]/40 border border-[#d0db84] space-y-1">
              <p className="font-bold text-xs text-[#171711]">MICORP PRO (LaterBox Support)</p>
              <p className="text-xs text-[#6c6b63]">
                Billing Email:{' '}
                <a
                  href="mailto:support@micorp.pro"
                  className="font-semibold text-[#171711] underline"
                >
                  support@micorp.pro
                </a>
              </p>
              <p className="text-xs text-[#6c6b63]">
                Website:{' '}
                <a
                  href="https://laterbox.dev"
                  className="font-semibold text-[#171711] underline"
                >
                  https://laterbox.dev
                </a>
              </p>
            </div>
            <p className="text-xs text-[#6c6b63] pt-2">
              Please include your LaterBox account email address and transaction reference number so we can look up your record promptly.
            </p>
          </section>
        </div>

        {/* Quick Back to Pricing CTA */}
        <div className="p-6 rounded-3xl bg-[#f7f5ee] border border-[#e4e0d5] flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>
            <h3 className="text-sm font-bold text-[#171711]">Ready to explore LaterBox storage?</h3>
            <p className="text-xs text-[#6c6b63]">Start with free cloud sync, then upgrade your storage when you need it.</p>
          </div>
          <Link
            href="/pricing"
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#171711] text-white text-xs font-bold hover:bg-[#2c2b26] transition-colors"
          >
            <span>View Pricing & Plans</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>
      </main>
    </div>
  );
}
