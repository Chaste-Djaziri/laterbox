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
  const lastUpdated = 'September 11, 2026';

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
            LaterBox operates under a strict no-refund policy for all subscription plans and digital purchases. Please read this policy carefully before purchasing a LaterBox Pro subscription.
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
            <h3 className="text-sm font-bold text-[#171711]">No Refunds</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              All sales, renewals, and subscription charges are final and non-refundable once processed.
            </p>
          </div>

          <div className="p-5 rounded-3xl bg-white border border-[#e4e0d5] space-y-2 shadow-2xs">
            <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
              <Clock className="w-5 h-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">14-Day Free Trial</h3>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Test all Pro features completely free before you are charged. Cancel anytime during the trial.
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
              Except where strictly required by applicable local law, <strong>all payments made for LaterBox Pro (including both monthly and annual plans) are final and non-refundable</strong>.
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
                Because LaterBox Pro provides immediate digital access to cloud sync, storage infrastructure, and premium automation features, processing fees and server costs are incurred immediately upon subscription activation.
              </p>
            </div>
          </section>

          {/* Section 2: 14-Day Free Trial & Evaluation */}
          <section className="space-y-3 p-6 sm:p-8 rounded-3xl bg-white border border-[#e4e0d5]">
            <h2 className="text-xl font-extrabold text-[#171711] flex items-center gap-2">
              <Clock className="w-5 h-5 text-[#171711]" />
              <span>2. Risk-Free Evaluation & 14-Day Free Trial</span>
            </h2>
            <p>
              To ensure that LaterBox Pro completely meets your needs prior to making any financial commitment, we provide multiple risk-free ways to evaluate our platform:
            </p>
            <ul className="space-y-2.5 pl-1">
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span><strong>Free Tier:</strong> Basic saving, reading, searching, organizing, and local exports are 100% free forever without requiring payment details.</span>
              </li>
              <li className="flex items-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <span><strong>14-Day Free Trial:</strong> Both monthly and annual subscriptions include a full 14-day free trial for eligible new subscribers. You have full access to all Pro features with zero charge during this window.</span>
              </li>
            </ul>
            <p>
              If you decide that LaterBox Pro is not for you, simply cancel your subscription before the 14-day trial period concludes. You will not be billed.
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
                <span><strong>Web & Direct Purchases (Paddle):</strong> Navigate to your Account Settings in LaterBox and open the customer billing portal to cancel with a single click.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[#171711] shrink-0 mt-2" />
                <span><strong>Apple In-App Purchases (iOS / macOS):</strong> Manage or cancel directly via your device&apos;s Apple ID Settings under <em>Subscriptions</em>.</span>
              </li>
            </ul>
            <p>
              When you cancel, your account remains active with full Pro features until the end of the current billing cycle. Afterward, your account reverts to the Free plan. Your local saved items and data remain entirely intact and exportable.
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
            <h3 className="text-sm font-bold text-[#171711]">Ready to explore LaterBox Pro?</h3>
            <p className="text-xs text-[#6c6b63]">Start your 14-day free trial today with no commitment.</p>
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
